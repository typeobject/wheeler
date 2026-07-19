package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.packageformat.BuildPlan;
import com.typeobject.wheeler.packageformat.BuildPlanCodec;
import com.typeobject.wheeler.packageformat.PackageLock;
import com.typeobject.wheeler.packageformat.PackageLockParser;
import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Integration tests for deterministic resolution, vendoring, and locked execution. */
class PackageResolutionCommandTest {
  @TempDir
  Path temporary;

  @Test
  void resolveSubcommandConsumesVerifiedArchivesAndWritesCanonicalLock() throws Exception {
    Path library = temporary.resolve("library");
    Files.createDirectories(library.resolve("src"));
    Files.writeString(library.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.library"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "library"
            name: "main"
            root: "src/Main.w"
            module: "demo.library.main"
            sources:
              - "src/Helper.w"
              - "src/Main.w"
            test: false
        dependencies: []
        capabilities:
          - name: "build.read"
            path: "src/**"
        """);
    Files.writeString(library.resolve("src/Helper.w"), """
        module demo.library.helper;
        classical class Helper {
          public long increment(long value) { return value + 1; }
        }
        """);
    Files.writeString(library.resolve("src/Main.w"), """
        module demo.library.main;
        import demo.library.helper;
        classical class Library {
          public long apply(long value) { return increment(value); }
        }
        """);
    Path application = temporary.resolve("application");
    Files.createDirectories(application.resolve("src"));
    Files.writeString(application.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "demo.application"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "deployable"
            name: "main"
            root: "src/Main.w"
            module: "demo.application.main"
            sources:
              - "src/Main.w"
            test: false
        dependencies:
          - kind: "normal"
            name: "demo.library"
            version: "^1.0.0"
        capabilities: []
        """);
    Files.writeString(application.resolve("src/Main.w"), """
        module demo.application.main;
        import demo.library.main;
        classical class Main {
            state long value = 0;
            entry void main() { value = apply(value); assert(value == 1); }
        }
        """);
    Path catalog = temporary.resolve("catalog");
    Files.createDirectories(catalog);
    Path archive = catalog.resolve("library.wpk");
    Path lockPath = temporary.resolve("wheeler.package.lock.yaml");
    ByteArrayOutputStream stdout = new ByteArrayOutputStream();
    PrintStream output = new PrintStream(stdout);
    PrintStream sink = new PrintStream(new ByteArrayOutputStream());

    assertEquals(0, Wheeler.execute(
        new String[] {"package", library.toString(), "-o", archive.toString()}, output, sink));
    assertEquals(0, Wheeler.execute(
        new String[] {
            "resolve", application.toString(), "--catalog", catalog.toString(),
            "-o", lockPath.toString()
        },
        output,
        sink));
    PackageLock lock = new PackageLockParser().parse(Files.readAllBytes(lockPath));
    assertEquals(List.of("demo.library"),
        lock.entries().stream().map(PackageLock.Entry::name).toList());
    String preferredLock = Files.readString(lockPath);
    Files.writeString(
        library.resolve("wheeler.package.yaml"),
        Files.readString(library.resolve("wheeler.package.yaml"))
            .replace("version: \"1.0.0\"", "version: \"1.1.0\""));
    assertEquals(0, Wheeler.execute(
        new String[] {
            "package", library.toString(), "-o", catalog.resolve("library-1.1.wpk").toString()
        },
        output,
        sink));
    assertEquals(0, Wheeler.execute(
        new String[] {
            "resolve", application.toString(), "--catalog", catalog.toString(),
            "-o", lockPath.toString()
        },
        output,
        sink));
    PackageLock retained = new PackageLockParser().parse(Files.readAllBytes(lockPath));
    assertEquals("1.0.0", retained.entries().getFirst().version());
    assertNotEquals(
        lock.entries().getFirst().snapshotIdentity(),
        retained.entries().getFirst().snapshotIdentity());
    assertEquals(0, Wheeler.execute(
        new String[] {
            "resolve", application.toString(), "--catalog", catalog.toString(),
            "-o", lockPath.toString(), "--update-all"
        },
        output,
        sink));
    PackageLock updated = new PackageLockParser().parse(Files.readAllBytes(lockPath));
    assertEquals("1.1.0", updated.entries().getFirst().version());
    Files.writeString(lockPath, preferredLock);
    assertEquals(0, Wheeler.execute(
        new String[] {
            "resolve", application.toString(), "--catalog", catalog.toString(),
            "-o", lockPath.toString(), "--update", "demo.library"
        },
        output,
        sink));
    updated = new PackageLockParser().parse(Files.readAllBytes(lockPath));
    assertEquals("1.1.0", updated.entries().getFirst().version());
    assertEquals(0, Wheeler.execute(
        new String[] {"verify-lock", lockPath.toString()}, output, sink));
    Path vendor = application.resolve("vendor");
    String[] vendorCommand = {
        "vendor", lockPath.toString(), "--catalog", catalog.toString(),
        "-o", vendor.toString()
    };
    assertEquals(0, Wheeler.execute(vendorCommand, output, sink));
    assertEquals(0, Wheeler.execute(vendorCommand, output, sink));
    assertEquals(Files.readString(lockPath), Files.readString(vendor.resolve("wheeler.package.lock.yaml")));
    try (var files = Files.list(vendor)) {
      assertEquals(2, files.count());
    }
    assertEquals(0, Wheeler.execute(
        new String[] {"check", application.toString()}, output, sink));
    assertEquals(0, Wheeler.execute(
        new String[] {"build", application.toString()}, output, sink));
    assertTrue(Files.isRegularFile(application.resolve("build/main.wbc")));
    assertTrue(Files.isRegularFile(
        application.resolve("build/dependencies/demo.library/main.wbc")));
    assertEquals(0, Wheeler.execute(
        new String[] {"run", application.toString(), "--target", "main"}, output, sink));

    Files.writeString(temporary.resolve("wheeler.workspace.yaml"), """
        schema: 1
        workspace:
          name: "locked"
          profile: "bootstrap-1"
        members:
          - name: "application"
            path: "application"
        """);
    Path planPath = temporary.resolve("locked.plan");
    assertEquals(0, Wheeler.execute(
        new String[] {
            "plan", temporary.toString(),
            "--grant-requested", "-o", planPath.toString()
        },
        output,
        sink));
    BuildPlan dependencyPlan = new BuildPlanCodec().decode(Files.readAllBytes(planPath));
    assertEquals(2, dependencyPlan.nodes().size());
    assertEquals(List.of("demo.library"), dependencyPlan.nodes().stream()
        .filter(node -> node.packageName().equals("demo.application"))
        .findFirst().orElseThrow().packageInputs().stream()
        .map(BuildPlan.PackageInput::name).toList());
    assertTrue(dependencyPlan.nodes().stream().allMatch(
        node -> node.capabilityGrants().equals(node.capabilityRequests())));

    Path vendoredArchive;
    try (var files = Files.list(vendor)) {
      vendoredArchive = files
          .filter(path -> path.getFileName().toString().endsWith(".wpk"))
          .findFirst()
          .orElseThrow();
    }
    Files.write(vendoredArchive, new byte[] {1});
    assertThrows(java.io.IOException.class, () -> Wheeler.execute(vendorCommand, output, sink));
    assertThrows(
        com.typeobject.wheeler.packageformat.PackageFormatException.class,
        () -> Wheeler.execute(
            new String[] {"check", application.toString()}, output, sink));
    assertTrue(stdout.toString(StandardCharsets.UTF_8).contains(lock.identity()));
  }

}
