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
import java.util.Set;
import org.junit.jupiter.api.Test;

/** Conformance tests for bounded deterministic dependency resolution. */
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
    assertFalse(VersionConstraint.parse("^1.2.0").accepts(
        SemanticVersion.parse("1.3.0-preview.1")));
    assertTrue(VersionConstraint.parse("^1.2.0-preview.1").accepts(
        SemanticVersion.parse("1.3.0-preview.2")));
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
  void firstRepositoryWithAnAdmissibleReleaseOwnsTheLookup() {
    PackageManifest root = manifest("root.app", "1.0.0", List.of(
        dependency("lib.a", "^1.0.0", DependencyKind.NORMAL)));
    PackageRelease privateLow = release(manifest("lib.a", "1.0.0", List.of()), 'a');
    PackageRelease publicHigh = release(manifest("lib.a", "1.9.0", List.of()), 'b');
    PackageResolver resolver = PackageResolver.orderedRepositories(List.of(
        new PackageResolver.RepositoryCatalog("1".repeat(64), List.of(privateLow)),
        new PackageResolver.RepositoryCatalog("2".repeat(64), List.of(publicHigh))));

    PackageLock privateLock = resolver.resolve(root, false);
    assertEquals("1.0.0", privateLock.entries().getFirst().version());
    assertEquals("1".repeat(64), privateLock.entries().getFirst().repositoryIdentity());

    PackageManifest requiresHigh = manifest("root.app", "1.0.0", List.of(
        dependency("lib.a", "=1.9.0", DependencyKind.NORMAL)));
    PackageLock publicLock = resolver.resolve(requiresHigh, false);
    assertEquals("1.9.0", publicLock.entries().getFirst().version());
    assertEquals("2".repeat(64), publicLock.entries().getFirst().repositoryIdentity());
  }

  @Test
  void stableRequirementsIgnorePrereleaseCandidatesUnlessNamed() {
    PackageRelease preview = release(manifest("lib.a", "1.1.0-preview.1", List.of()), 'a');
    PackageRelease stable = release(manifest("lib.a", "1.0.9", List.of()), 'b');
    PackageResolver resolver = new PackageResolver(List.of(preview, stable));
    PackageManifest stableRoot = manifest("root.app", "1.0.0", List.of(
        dependency("lib.a", "^1.0.0", DependencyKind.NORMAL)));

    PackageLock stableLock = resolver.resolve(stableRoot, false);

    assertEquals("1.0.9", stableLock.entries().getFirst().version());
    PackageManifest previewRoot = manifest("root.app", "1.0.0", List.of(
        dependency("lib.a", "=1.1.0-preview.1", DependencyKind.NORMAL)));
    assertEquals(
        "1.1.0-preview.1",
        resolver.resolve(previewRoot, false).entries().getFirst().version());
  }

  @Test
  void resolverBacktracksAcrossIncompatibleSourceProfiles() {
    PackageManifest root = manifest("root.app", "1.0.0", List.of(
        dependency("lib.a", "^1.0.0", DependencyKind.NORMAL)));
    PackageRelease incompatible = release(manifestWithProfile(
        "lib.a", "1.1.0", "future-2", List.of()), 'c');
    PackageRelease compatible = release(manifest("lib.a", "1.0.0", List.of()), 'd');

    PackageLock lock = new PackageResolver(List.of(incompatible, compatible))
        .resolve(root, false);

    assertEquals("1.0.0", lock.entries().getFirst().version());
    PackageFormatException failure = assertThrows(
        PackageFormatException.class,
        () -> new PackageResolver(List.of(incompatible)).resolve(root, false));
    assertTrue(failure.getMessage().contains("profile bootstrap-1"));
  }

  @Test
  void preferredLockRetainsValidSelectionsAndMovesForcedOnes() {
    PackageManifest root = manifest("root.app", "1.0.0", List.of(
        dependency("lib.a", "^1.0.0", DependencyKind.NORMAL)));
    PackageRelease low = release(manifest("lib.a", "1.0.0", List.of()), 'e');
    PackageRelease high = release(manifest("lib.a", "1.1.0", List.of()), 'f');
    PackageLock preferred = new PackageResolver(List.of(low)).resolve(root, false);
    PackageResolver expanded = new PackageResolver(List.of(high, low));

    assertEquals("1.1.0", expanded.resolve(root, false).entries().getFirst().version());
    assertEquals(
        "1.0.0",
        expanded.resolve(root, false, preferred).entries().getFirst().version());
    assertEquals(
        "1.1.0",
        expanded.resolve(root, false, preferred, Set.of("lib.a"))
            .entries().getFirst().version());
    PackageFormatException unknown = assertThrows(
        PackageFormatException.class,
        () -> expanded.resolve(root, false, preferred, Set.of("lib.missing")));
    assertTrue(unknown.getMessage().contains("not in the resolved graph: lib.missing"));

    PackageManifest forced = manifest("root.app", "1.0.1", List.of(
        dependency("lib.a", "=1.1.0", DependencyKind.NORMAL)));
    assertEquals(
        "1.1.0",
        expanded.resolve(forced, false, preferred).entries().getFirst().version());
  }

  @Test
  void developmentDependenciesAreExplicitAndConflictsFailClosed() {
    PackageManifest root = manifest("root.app", "1.0.0", List.of(
        dependency("test.support", "^1.0.0", DependencyKind.DEVELOPMENT)));
    PackageRelease support = release(manifest("test.support", "1.0.0", List.of(
        dependency("transitive.fixture", "^1.0.0", DependencyKind.DEVELOPMENT))), 'e');

    assertTrue(new PackageResolver(List.of(support)).resolve(root, false).entries().isEmpty());
    PackageLock developmentLock = new PackageResolver(List.of(support)).resolve(root, true);
    assertEquals(1, developmentLock.entries().size());
    assertTrue(developmentLock.entries().getFirst().dependencies().isEmpty());

    PackageManifest impossible = manifest("root.app", "1.0.0", List.of(
        dependency("test.support", "^2.0.0", DependencyKind.NORMAL)));
    PackageFormatException failure = assertThrows(
        PackageFormatException.class,
        () -> new PackageResolver(List.of(support)).resolve(impossible, false));
    assertTrue(failure.getMessage().contains("No package solution"));
  }

  @Test
  void workExhaustionIsDistinctFromUnsatisfiability() {
    PackageManifest root = manifest("root.app", "1.0.0", List.of(
        dependency("lib.a", "=0.0.0", DependencyKind.NORMAL)));
    List<PackageRelease> largeCatalog = new ArrayList<>();
    for (int minor = 0; minor <= 10_000; minor++) {
      largeCatalog.add(release(manifest("lib.a", "0." + minor + ".0", List.of()), 'a'));
    }

    PackageFormatException exhausted = assertThrows(
        PackageFormatException.class,
        () -> new PackageResolver(largeCatalog).resolve(root, false));
    PackageFormatException unsatisfied = assertThrows(
        PackageFormatException.class,
        () -> new PackageResolver(List.of(
            release(manifest("lib.a", "0.1.0", List.of()), 'b'))).resolve(root, false));

    assertTrue(exhausted.getMessage().contains("work limit exceeded after 10000 units"));
    assertTrue(unsatisfied.getMessage().contains("No package solution"));
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
        () -> new PackageLockParser().parse(lock.canonicalText().replace("packages:", " packages:")));
  }

  @Test
  void lockDecoderRejectsMalformedUtf8AndUnknownEdges() {
    PackageLock lock = new PackageLock(
        PackageLock.SCHEMA_VERSION,
        "0".repeat(64),
        List.of(
            new PackageLock.Entry(
                "lib.a", "1.0.0", "a".repeat(64), "1".repeat(64), "2".repeat(64),
                List.of("lib.b")),
            new PackageLock.Entry(
                "lib.b", "1.0.0", "a".repeat(64), "3".repeat(64), "4".repeat(64),
                List.of())));
    PackageLockParser parser = new PackageLockParser();

    assertThrows(PackageFormatException.class, () -> parser.parse(new byte[] {(byte) 0xc3}));
    assertThrows(
        PackageFormatException.class,
        () -> parser.parse(lock.canonicalText().replace(
            "      - \"lib.b\"\n", "      - \"lib.missing\"\n")));
    assertThrows(
        PackageFormatException.class,
        () -> parser.parse("lock".getBytes(StandardCharsets.UTF_8)));
  }

  private static PackageManifest manifest(
      String name, String version, List<Dependency> dependencies) {
    return manifestWithProfile(name, version, "bootstrap-1", dependencies);
  }

  private static PackageManifest manifestWithProfile(
      String name, String version, String profile, List<Dependency> dependencies) {
    return new PackageManifest(
        name,
        version,
        profile,
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
