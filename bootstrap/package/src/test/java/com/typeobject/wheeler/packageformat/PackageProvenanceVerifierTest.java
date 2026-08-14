package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.packageformat.BuildPlan.ExecutionLimits;
import com.typeobject.wheeler.packageformat.BuildPlan.PackageInput;
import com.typeobject.wheeler.packageformat.PackageManifest.Dependency;
import com.typeobject.wheeler.packageformat.PackageManifest.DependencyKind;
import com.typeobject.wheeler.packageformat.PackageManifest.Target;
import com.typeobject.wheeler.packageformat.PackageManifest.TargetKind;
import com.typeobject.wheeler.packageformat.PackageProvenanceVerifier.Evidence;
import com.typeobject.wheeler.packageformat.PackageProvenanceVerifier.OutputExpectation;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Verifies the complete package-output provenance closure and every bound identity. */
final class PackageProvenanceVerifierTest {
  private static final String DEPENDENCY_ARCHIVE = "a".repeat(64);
  private static final byte[] OUTPUT = "verified output".getBytes(StandardCharsets.UTF_8);
  private static final byte[] SOURCE = "source input".getBytes(StandardCharsets.UTF_8);

  @Test
  void bindsArchiveLockPlanSourceToolchainDependenciesAndOutput() {
    Fixture fixture = fixture();

    Evidence first = fixture.verify(OUTPUT);
    Evidence second = fixture.verify(OUTPUT.clone());

    assertEquals(first, second);
    assertEquals(fixture.manifest.identity(), first.manifestIdentity());
    assertEquals(fixture.lock.identity(), first.lockIdentity());
    assertEquals(fixture.toolchain.identity(), first.toolchainIdentity());
    assertEquals(OUTPUT.length, first.outputLength());
    assertEquals(hash(OUTPUT), first.outputIdentity());
    assertNotEquals(first.dependencySetIdentity(), first.lockIdentity());
    assertThrows(PackageFormatException.class, () -> new Evidence(
        first.packageArchiveIdentity(),
        first.manifestIdentity(),
        first.lockIdentity(),
        first.sourceInputIdentity(),
        first.buildInputIdentity(),
        first.toolchainIdentity(),
        first.dependencySetIdentity(),
        first.outputIdentity(),
        first.outputLength() + 1,
        first.identity()));
  }

  @Test
  void rejectsEveryChangedProvenanceEdgeBeforeEvidencePublication() {
    Fixture fixture = fixture();
    byte[] changedOutput = OUTPUT.clone();
    changedOutput[0] ^= 1;
    assertThrows(PackageFormatException.class, () -> fixture.verify(changedOutput));

    byte[] changedSource = SOURCE.clone();
    changedSource[0] ^= 1;
    assertThrows(PackageFormatException.class, () -> PackageProvenanceVerifier.verify(
        fixture.manifest,
        fixture.archive,
        fixture.lock,
        fixture.plan,
        fixture.node,
        changedSource,
        fixture.toolchain,
        fixture.expectation,
        OUTPUT));

    PackageLock changedLock = new PackageLock(
        PackageLock.SCHEMA_VERSION, "f".repeat(64), fixture.lock.entries());
    assertThrows(PackageFormatException.class, () -> PackageProvenanceVerifier.verify(
        fixture.manifest,
        fixture.archive,
        changedLock,
        fixture.plan,
        fixture.node,
        SOURCE,
        fixture.toolchain,
        fixture.expectation,
        OUTPUT));

    byte[] changedArchive = fixture.archive.clone();
    changedArchive[changedArchive.length - 1] ^= 1;
    assertThrows(PackageFormatException.class, () -> PackageProvenanceVerifier.verify(
        fixture.manifest,
        changedArchive,
        fixture.lock,
        fixture.plan,
        fixture.node,
        SOURCE,
        fixture.toolchain,
        fixture.expectation,
        OUTPUT));

    BuildPlan foreignPlan = new BuildPlan(
        BuildPlan.SCHEMA_VERSION,
        "9".repeat(64),
        "8".repeat(64),
        "bootstrap-1",
        List.of());
    assertThrows(PackageFormatException.class, () -> PackageProvenanceVerifier.verify(
        fixture.manifest,
        fixture.archive,
        fixture.lock,
        foreignPlan,
        fixture.node,
        SOURCE,
        fixture.toolchain,
        fixture.expectation,
        OUTPUT));
  }

  private static Fixture fixture() {
    PackageManifest manifest = new PackageManifest(
        "portfolio.application",
        "1.0.0",
        "bootstrap-1",
        List.of(new Target(TargetKind.DEPLOYABLE, "main", "src/Main.w")),
        List.of(new Dependency(DependencyKind.NORMAL, "wheeler.core", "=1.0.0")),
        List.of());
    byte[] archive = new PackageArchive().encode(
        manifest, Map.of("src/Main.w", SOURCE));
    PackageLock lock = new PackageLock(
        PackageLock.SCHEMA_VERSION,
        manifest.identity(),
        List.of(new PackageLock.Entry(
            "wheeler.core",
            "1.0.0",
            "b".repeat(64),
            "c".repeat(64),
            DEPENDENCY_ARCHIVE,
            "d".repeat(64),
            List.of())));
    BuildPlan.Node node = BuildPlan.Node.create(
        manifest.name(),
        manifest.version(),
        manifest.identity(),
        "main",
        TargetKind.DEPLOYABLE,
        hash(SOURCE),
        "portfolio/main.wbc",
        List.of(new PackageInput("wheeler.core", DEPENDENCY_ARCHIVE)),
        List.of(),
        ExecutionLimits.DEFAULT,
        List.of());
    BuildPlan plan = new BuildPlan(
        BuildPlan.SCHEMA_VERSION,
        "e".repeat(64),
        "f".repeat(64),
        "bootstrap-1",
        List.of(node));
    BootstrapToolchain toolchain = new BootstrapToolchain(
        BootstrapToolchain.Kind.INDEPENDENT_STAGE0,
        "1".repeat(64),
        "2".repeat(64),
        "3".repeat(64),
        "4".repeat(64));
    return new Fixture(
        manifest,
        archive,
        lock,
        plan,
        node,
        toolchain,
        new OutputExpectation(hash(OUTPUT), OUTPUT.length));
  }

  private static String hash(byte[] value) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value));
    } catch (Exception exception) {
      throw new AssertionError(exception);
    }
  }

  private record Fixture(
      PackageManifest manifest,
      byte[] archive,
      PackageLock lock,
      BuildPlan plan,
      BuildPlan.Node node,
      BootstrapToolchain toolchain,
      OutputExpectation expectation) {
    private Fixture {
      archive = archive.clone();
    }

    @Override
    public byte[] archive() {
      return archive.clone();
    }

    private Evidence verify(byte[] output) {
      return PackageProvenanceVerifier.verify(
          manifest,
          archive,
          lock,
          plan,
          node,
          SOURCE,
          toolchain,
          expectation,
          output);
    }
  }
}
