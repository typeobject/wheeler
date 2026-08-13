package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.StandardCharsets;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Canonical bootstrap seed and ancestry validation tests. */
final class BootstrapSeedChainTest {
  private static final String EMPTY = "";

  @Test
  void reproducibleAndOpaqueRecordsRoundTripCanonically() {
    BootstrapSeedRecord reproducible = reproducible(1, EMPTY, List.of());
    BootstrapSeedRecord opaque = opaque(2);
    BootstrapSeedRecordParser parser = new BootstrapSeedRecordParser();

    assertEquals(reproducible, parser.parse(reproducible.canonicalBytes()));
    assertEquals(opaque, parser.parse(opaque.canonicalBytes()));
    assertFalse(reproducible.opaque());
    assertTrue(opaque.opaque());
    assertEquals(64, reproducible.identity().length());
  }

  @Test
  void chainWalksParentsAndAcceptsIndependentRebuildEvidence() {
    BootstrapSeedRecord root = reproducible(1, EMPTY, List.of());
    BootstrapSeedRecord witness = reproducible(
        2, EMPTY, List.of(), root.output(), root.source(), root.sourceRevision(), identity(12));
    BootstrapSeedRecord leaf = reproducible(3, root.identity(), List.of(witness.identity()));
    leaf = reproducible(
        3,
        root.identity(),
        List.of(witness.identity()),
        witness.output(),
        witness.source(),
        witness.sourceRevision(),
        identity(13));
    BootstrapSeedChain chain = new BootstrapSeedChain(List.of(leaf, witness, root));

    assertEquals(List.of(leaf, root), chain.ancestry(leaf.identity()));
    assertEquals(64, chain.identity().length());
  }

  @Test
  void missingCyclicAndFalseReproductionChainsFailClosed() {
    BootstrapSeedRecord root = reproducible(1, EMPTY, List.of());
    BootstrapSeedRecord missing = reproducible(2, identity(99), List.of());
    assertThrows(
        PackageFormatException.class,
        () -> new BootstrapSeedChain(List.of(root, missing)));

    BootstrapSeedRecord falseWitness = reproducible(5, EMPTY, List.of());
    BootstrapSeedRecord claimed = reproducible(6, EMPTY, List.of(falseWitness.identity()));
    assertThrows(
        PackageFormatException.class,
        () -> new BootstrapSeedChain(List.of(root, falseWitness, claimed)));
  }

  @Test
  void classificationAndCanonicalSyntaxCannotOverstateProvenance() {
    assertThrows(PackageFormatException.class, () -> new BootstrapSeedRecord(
        BootstrapSeedRecord.Kind.OPAQUE_ROOT,
        "compiler",
        "linux-x86_64",
        identity(1),
        10,
        "revision",
        identity(2),
        "download",
        ".",
        identity(3),
        List.of(),
        identity(4),
        EMPTY,
        List.of(),
        "https://example.invalid/seed",
        identity(5),
        "2026-08-13",
        "legacy bootstrap"));

    BootstrapSeedRecord record = reproducible(1, EMPTY, List.of());
    String contradictory = record.canonicalText().replace("  opaque: false", "  opaque: true");
    assertThrows(
        PackageFormatException.class,
        () -> new BootstrapSeedRecordParser().parse(
            contradictory.getBytes(StandardCharsets.UTF_8)));
    String unknown = record.canonicalText().replace(
        "  reason: \"\"\n", "  reason: \"\"\n  surprise: true\n");
    assertThrows(
        PackageFormatException.class,
        () -> new BootstrapSeedRecordParser().parse(unknown.getBytes(StandardCharsets.UTF_8)));
  }

  private static BootstrapSeedRecord reproducible(
      int marker, String parent, List<String> attestations) {
    return reproducible(
        marker,
        parent,
        attestations,
        identity(marker + 20),
        identity(marker + 30),
        "revision-" + marker,
        identity(marker + 40));
  }

  private static BootstrapSeedRecord reproducible(
      int marker,
      String parent,
      List<String> attestations,
      String output,
      String source,
      String revision,
      String builder) {
    return new BootstrapSeedRecord(
        BootstrapSeedRecord.Kind.ALTERNATE_STAGE0,
        "compiler-" + marker,
        "linux-x86_64",
        output,
        1_024 + marker,
        revision,
        source,
        "./bootstrap-stage0",
        ".",
        builder,
        List.of(identity(marker + 50)),
        identity(marker + 60),
        parent,
        attestations,
        EMPTY,
        EMPTY,
        EMPTY,
        EMPTY);
  }

  private static BootstrapSeedRecord opaque(int marker) {
    return new BootstrapSeedRecord(
        BootstrapSeedRecord.Kind.OPAQUE_ROOT,
        "host-toolchain-" + marker,
        "linux-x86_64",
        identity(marker),
        2_048,
        EMPTY,
        EMPTY,
        "download pinned archive",
        ".",
        identity(marker + 1),
        List.of(),
        identity(marker + 2),
        EMPTY,
        List.of(),
        "https://example.invalid/toolchain",
        identity(marker + 3),
        "2026-08-13",
        "host compiler binary");
  }

  private static String identity(int marker) {
    return "%064x".formatted(marker);
  }
}
