package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.nio.charset.StandardCharsets;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Recovery-release binding and opaque-root inventory tests. */
final class BootstrapRecoveryEvidenceTest {
  @Test
  void bindsTheCompleteSeedChainAndOpaqueInventoryCanonically() {
    BootstrapSeedRecord sourceSeed = sourceSeed();
    BootstrapSeedRecord opaqueSeed = opaqueSeed();
    BootstrapSeedChain chain = new BootstrapSeedChain(List.of(sourceSeed, opaqueSeed));
    BootstrapRecoveryEvidence evidence = evidence(chain);

    assertEquals(2, evidence.seedCount());
    assertEquals(1, evidence.opaqueCount());
    assertEquals(4_096, evidence.opaqueBytes());
    assertEquals(List.of(opaqueSeed.identity()), evidence.opaqueRoots());
    assertEquals(
        evidence,
        new BootstrapRecoveryEvidenceParser().parse(evidence.canonicalBytes()));
    evidence.validate(chain);
  }

  @Test
  void changedInventoryChainOrIndependentEvidenceFailsClosed() {
    BootstrapSeedChain chain = new BootstrapSeedChain(List.of(sourceSeed(), opaqueSeed()));
    BootstrapRecoveryEvidence evidence = evidence(chain);
    BootstrapSeedChain changed = new BootstrapSeedChain(List.of(sourceSeed()));
    assertThrows(PackageFormatException.class, () -> evidence.validate(changed));

    assertThrows(PackageFormatException.class, () -> new BootstrapRecoveryEvidence(
        evidence.seedChain(),
        evidence.seedCount(),
        0,
        evidence.opaqueBytes(),
        evidence.opaqueRoots(),
        evidence.sourceArchive(),
        evidence.lock(),
        evidence.compilerOptions(),
        evidence.compilerLimits(),
        evidence.fixedPoint(),
        evidence.diverseCompilation(),
        evidence.acceptanceArtifacts(),
        evidence.parentRecovery()));

    String reordered = evidence.canonicalText().replace(
        "  fixed-point: \"" + evidence.fixedPoint() + "\"\n"
            + "  diverse-compilation: \"" + evidence.diverseCompilation() + "\"\n",
        "  diverse-compilation: \"" + evidence.diverseCompilation() + "\"\n"
            + "  fixed-point: \"" + evidence.fixedPoint() + "\"\n");
    assertThrows(
        PackageFormatException.class,
        () -> new BootstrapRecoveryEvidenceParser().parse(
            reordered.getBytes(StandardCharsets.UTF_8)));
  }

  private static BootstrapRecoveryEvidence evidence(BootstrapSeedChain chain) {
    return BootstrapRecoveryEvidence.fromChain(
        chain,
        identity(10),
        identity(11),
        identity(12),
        identity(13),
        identity(14),
        identity(15),
        identity(16),
        "");
  }

  private static BootstrapSeedRecord sourceSeed() {
    return new BootstrapSeedRecord(
        BootstrapSeedRecord.Kind.ALTERNATE_STAGE0,
        "compiler",
        "linux-x86_64",
        identity(1),
        2_048,
        "revision-1",
        identity(2),
        "./bootstrap-stage0",
        ".",
        identity(3),
        List.of(),
        identity(4),
        "",
        List.of(),
        "",
        "",
        "",
        "");
  }

  private static BootstrapSeedRecord opaqueSeed() {
    return new BootstrapSeedRecord(
        BootstrapSeedRecord.Kind.OPAQUE_ROOT,
        "host-linker",
        "linux-x86_64",
        identity(5),
        4_096,
        "",
        "",
        "download pinned archive",
        ".",
        identity(6),
        List.of(),
        identity(7),
        "",
        List.of(),
        "https://example.invalid/linker",
        identity(8),
        "2026-08-13",
        "host linker binary");
  }

  private static String identity(int marker) {
    return "%064x".formatted(marker);
  }
}
