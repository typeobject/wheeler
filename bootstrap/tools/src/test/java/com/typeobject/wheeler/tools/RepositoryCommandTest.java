package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifest;
import com.typeobject.wheeler.packageformat.PackageManifest.Dependency;
import com.typeobject.wheeler.packageformat.PackageManifest.DependencyKind;
import com.typeobject.wheeler.packageformat.RepositoryPolicy;
import com.typeobject.wheeler.packageformat.RepositoryPolicy.Repository;
import com.typeobject.wheeler.packageformat.RepositoryPolicy.Transport;
import com.typeobject.wheeler.packageformat.RepositoryPolicyParser;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Physical-boundary tests for XDG paths and ordered repository policy updates. */
class RepositoryCommandTest {
  @TempDir
  Path temporary;

  @Test
  void xdgResolutionUsesAbsoluteOverridesAndDiagnosesRelativeOnes() {
    Path home = temporary.resolve("home").toAbsolutePath();
    XdgPaths paths = XdgPaths.resolve(
        Map.of(
            "XDG_CONFIG_HOME", temporary.resolve("config").toString(),
            "XDG_DATA_HOME", "relative-data",
            "XDG_CACHE_HOME", temporary.resolve("cache").toString()),
        home);

    assertEquals(temporary.resolve("config/wheeler/wheeler.repositories.yaml"),
        paths.repositoryPolicy());
    assertEquals(home.resolve(".local/share/wheeler/repository"), paths.dataRepository());
    assertEquals(temporary.resolve("cache/wheeler/artifacts"), paths.artifactCache());
    assertEquals(home.resolve(".local/state/wheeler"), paths.state());
    assertEquals(java.util.List.of("XDG_DATA_HOME is relative and was ignored"),
        paths.diagnostics());
  }

  @Test
  void commandsAtomicallyManageOneCanonicalOrderedPolicy() throws Exception {
    XdgPaths paths = paths();
    ByteArrayOutputStream outputBytes = new ByteArrayOutputStream();
    ByteArrayOutputStream errorBytes = new ByteArrayOutputStream();
    PrintStream output = new PrintStream(outputBytes);
    PrintStream error = new PrintStream(errorBytes);

    assertEquals(0, RepositoryCommand.execute(
        new String[] {"repository", "list"}, output, error, paths));
    assertTrue(outputBytes.toString(StandardCharsets.UTF_8).contains("alias: \"local\""));
    assertFalse(Files.exists(paths.repositoryPolicy()));

    Path remote = temporary.resolve("remote").toAbsolutePath();
    assertEquals(0, RepositoryCommand.execute(
        new String[] {
            "repository", "add", "private", "b".repeat(64), remote.toString(), "acme"
        }, output, error, paths));
    assertEquals(0, RepositoryCommand.execute(
        new String[] {"repository", "move", "private", "local"}, output, error, paths));
    assertEquals(0, RepositoryCommand.execute(
        new String[] {"repository", "disable", "private"}, output, error, paths));

    String text = Files.readString(paths.repositoryPolicy());
    RepositoryPolicy policy = new RepositoryPolicyParser().parse(text);
    assertEquals(text, policy.canonicalText());
    assertEquals(java.util.List.of("private", "local"),
        policy.repositories().stream().map(RepositoryPolicy.Repository::alias).toList());
    assertFalse(policy.repositories().getFirst().enabled());
    assertEquals(java.util.List.of("acme"), policy.repositories().getFirst().namespaces());

    assertEquals(0, RepositoryCommand.execute(
        new String[] {"repository", "remove", "private"}, output, error, paths));
    assertEquals(java.util.List.of("local"), RepositoryPolicyStore.load(paths).repositories()
        .stream().map(RepositoryPolicy.Repository::alias).toList());
  }

  @Test
  void orderedFetchUsesTheFirstAuthoritativeRepositoryContainingTheRelease() throws Exception {
    XdgPaths paths = paths();
    Path privateRoot = temporary.toRealPath().resolve("private");
    Repository privateRepository = new Repository(
        "private", "b".repeat(64), Transport.FILE, privateRoot.toString(), true, List.of("demo"));
    Repository local = RepositoryPolicy.defaultLocal(paths.dataRepository()).repositories().getFirst();
    RepositoryPolicyStore.write(paths, new RepositoryPolicy(1, List.of(privateRepository, local)));
    byte[] localBytes = archive((byte) 1);
    byte[] privateBytes = archive((byte) 2);

    RepositoryAccess.publication(paths, "local").publish(localBytes);
    assertArrayEquals(
        localBytes, RepositoryAccess.fetch(paths, null, "demo.library", "1.0.0"));

    PackageRegistry.openOrCreate(privateRoot).publish(privateBytes);
    assertTrue(Files.isRegularFile(
        privateRoot.resolve("releases/demo.library/1.0.0.release.yaml")));
    assertArrayEquals(
        privateBytes, RepositoryAccess.fetch(paths, null, "demo.library", "1.0.0"));
    assertArrayEquals(
        localBytes, RepositoryAccess.fetch(paths, "local", "demo.library", "1.0.0"));

    PackageManifest root = new PackageManifest(
        "demo.application",
        "1.0.0",
        "bootstrap-1",
        List.of(new PackageManifest.Target(
            PackageManifest.TargetKind.DEPLOYABLE, "main", "src/Main.w")),
        List.of(new Dependency(DependencyKind.NORMAL, "demo.library", "^1.0.0")),
        List.of());
    assertEquals(
        new PackageArchive().identity(privateBytes),
        RepositoryAccess.resolver(paths, List.of()).resolve(root, false)
            .entries().getFirst().archiveIdentity());
  }

  @Test
  void policyStoreRejectsSymbolicLinkConfigurationRoots() throws Exception {
    Path external = temporary.resolve("external");
    Files.createDirectories(external);
    Files.createSymbolicLink(temporary.resolve("config"), external);

    assertThrows(IOException.class, () -> RepositoryPolicyStore.write(
        paths(), RepositoryPolicy.defaultLocal(temporary.resolve("data/repository"))));
  }

  private static byte[] archive(byte marker) {
    PackageManifest manifest = new PackageManifest(
        "demo.library",
        "1.0.0",
        "bootstrap-1",
        List.of(new PackageManifest.Target(
            PackageManifest.TargetKind.LIBRARY,
            "library",
            "src/Main.w",
            "demo.library.main",
            List.of("src/Main.w"))),
        List.of(),
        List.of());
    return new PackageArchive().encode(manifest, Map.of("src/Main.w", new byte[] {marker}));
  }

  private XdgPaths paths() throws IOException {
    Path physical = temporary.toRealPath();
    return new XdgPaths(
        physical.resolve("config/wheeler/wheeler.repositories.yaml"),
        physical.resolve("data/repository"),
        physical.resolve("cache/artifacts"),
        physical.resolve("state"),
        java.util.List.of());
  }
}
