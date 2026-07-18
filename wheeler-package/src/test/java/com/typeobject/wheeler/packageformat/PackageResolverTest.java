package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.packageformat.PackageManifest.Dependency;
import com.typeobject.wheeler.packageformat.PackageManifest.DependencyKind;
import com.typeobject.wheeler.packageformat.PackageManifest.Target;
import com.typeobject.wheeler.packageformat.PackageManifest.TargetKind;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.junit.jupiter.api.Test;

class PackageResolverTest {
  @Test
  void semanticVersionsAndConstraintsFollowStableOrdering() {
    SemanticVersion prerelease = SemanticVersion.parse("1.2.3-alpha.2");
    SemanticVersion stable = SemanticVersion.parse("1.2.3");

    assertTrue(stable.compareTo(prerelease) > 0);
    assertTrue(VersionConstraint.parse("^1.2.0").accepts(SemanticVersion.parse("1.9.0")));
    assertFalse(VersionConstraint.parse("^1.2.0").accepts(SemanticVersion.parse("2.0.0")));
    assertTrue(VersionConstraint.parse("~1.2.0").accepts(SemanticVersion.parse("1.2.9")));
    assertFalse(VersionConstraint.parse("~1.2.0").accepts(SemanticVersion.parse("1.3.0")));
    assertThrows(PackageFormatException.class, () -> SemanticVersion.parse("01.2.3"));
  }

  @Test
  void resolverBacktracksAndProducesCanonicalLockIndependentOfCatalogOrder() {
    PackageManifest root = manifest("root.app", "1.0.0", List.of(
        dependency("lib.a", "^1.0.0", DependencyKind.NORMAL),
        dependency("lib.b", "~1.0.0", DependencyKind.NORMAL)));
    List<PackageRelease> catalog = new ArrayList<>(List.of(
        release(manifest("lib.a", "1.1.0", List.of(
            dependency("lib.b", "^2.0.0", DependencyKind.NORMAL))), 'a'),
        release(manifest("lib.a", "1.0.0", List.of(
            dependency("lib.b", "^1.0.0", DependencyKind.NORMAL))), 'b'),
        release(manifest("lib.b", "2.0.0", List.of()), 'c'),
        release(manifest("lib.b", "1.0.5", List.of()), 'd')));

    PackageLock expected = new PackageResolver(catalog).resolve(root, false);
    Collections.reverse(catalog);
    PackageLock actual = new PackageResolver(catalog).resolve(root, false);

    assertEquals(expected.canonicalText(), actual.canonicalText());
    assertEquals(List.of("1.0.0", "1.0.5"),
        actual.entries().stream().map(PackageLock.Entry::version).toList());
    assertEquals(actual, new PackageLockParser().parse(actual.canonicalText()));
    assertEquals(64, actual.identity().length());
  }

  @Test
  void developmentDependenciesAreExplicitAndConflictsFailClosed() {
    PackageManifest root = manifest("root.app", "1.0.0", List.of(
        dependency("test.support", "^1.0.0", DependencyKind.DEVELOPMENT)));
    PackageRelease support = release(manifest("test.support", "1.0.0", List.of()), 'e');

    assertTrue(new PackageResolver(List.of(support)).resolve(root, false).entries().isEmpty());
    assertEquals(1, new PackageResolver(List.of(support)).resolve(root, true).entries().size());

    PackageManifest impossible = manifest("root.app", "1.0.0", List.of(
        dependency("test.support", "^2.0.0", DependencyKind.NORMAL)));
    PackageFormatException failure = assertThrows(
        PackageFormatException.class,
        () -> new PackageResolver(List.of(support)).resolve(impossible, false));
    assertTrue(failure.getMessage().contains("No package solution"));
  }

  @Test
  void duplicateVersionsCyclesAndNoncanonicalLocksAreRejected() {
    PackageRelease duplicate = release(manifest("lib.a", "1.0.0", List.of()), '1');
    assertThrows(
        PackageFormatException.class,
        () -> new PackageResolver(List.of(duplicate, duplicate)));

    PackageRelease left = release(manifest("lib.left", "1.0.0", List.of(
        dependency("lib.right", "^1.0.0", DependencyKind.NORMAL))), '2');
    PackageRelease right = release(manifest("lib.right", "1.0.0", List.of(
        dependency("lib.left", "^1.0.0", DependencyKind.NORMAL))), '3');
    PackageManifest root = manifest("root.app", "1.0.0", List.of(
        dependency("lib.left", "^1.0.0", DependencyKind.NORMAL)));
    assertThrows(
        PackageFormatException.class,
        () -> new PackageResolver(List.of(left, right)).resolve(root, false));

    PackageLock lock = new PackageResolver(List.of(duplicate)).resolve(
        manifest("root.app", "1.0.0", List.of(
            dependency("lib.a", "^1.0.0", DependencyKind.NORMAL))),
        false);
    assertThrows(
        PackageFormatException.class,
        () -> new PackageLockParser().parse(lock.canonicalText().replace("package", " package")));
  }

  @Test
  void lockDecoderRejectsMalformedUtf8AndUnknownEdges() {
    PackageLock lock = new PackageLock(
        PackageLock.SCHEMA_VERSION,
        "0".repeat(64),
        List.of(
            new PackageLock.Entry(
                "lib.a", "1.0.0", "1".repeat(64), "2".repeat(64), List.of("lib.b")),
            new PackageLock.Entry(
                "lib.b", "1.0.0", "3".repeat(64), "4".repeat(64), List.of())));
    PackageLockParser parser = new PackageLockParser();

    assertThrows(PackageFormatException.class, () -> parser.parse(new byte[] {(byte) 0xc3}));
    assertThrows(
        PackageFormatException.class,
        () -> parser.parse(lock.canonicalText().replace("\"lib.b\";", "\"lib.missing\";")));
    assertThrows(
        PackageFormatException.class,
        () -> parser.parse("lock".getBytes(StandardCharsets.UTF_8)));
  }

  private static PackageManifest manifest(
      String name, String version, List<Dependency> dependencies) {
    return new PackageManifest(
        name,
        version,
        "bootstrap-1",
        List.of(new Target(TargetKind.LIBRARY, "main", "src/main.w")),
        dependencies,
        List.of());
  }

  private static Dependency dependency(
      String name, String constraint, DependencyKind kind) {
    return new Dependency(kind, name, constraint);
  }

  private static PackageRelease release(PackageManifest manifest, char hashCharacter) {
    return new PackageRelease(manifest, String.valueOf(hashCharacter).repeat(64));
  }
}
