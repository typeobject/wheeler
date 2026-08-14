package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

/** Conformance evidence that placement tiers cannot impersonate durability receipts. */
final class StagedDataTest {
  private static final String CONTENT = "a".repeat(64);

  @Test
  void placementNamesItsTierFailureDomainAndExactAncestry() {
    StagedData memory = StagedData.initial("memory", "host-a", CONTENT, 4096);
    StagedData local = memory.restage("local-nvme", "chassis-a");

    assertEquals("memory", memory.tier());
    assertEquals("host-a", memory.failureDomain());
    assertEquals("-", memory.parentIdentity());
    assertEquals(memory.identity(), local.parentIdentity());
    assertEquals("local-nvme", local.tier());
    assertEquals("chassis-a", local.failureDomain());
    assertNotEquals(memory.identity(), local.identity());
    assertEquals(
        local,
        StagedData.initial("memory", "host-a", CONTENT, 4096)
            .restage("local-nvme", "chassis-a"));
  }

  @Test
  void stagedPlacementHasNoDurabilityReceiptTypeOrImplicitClaim() {
    assertFalse(DurabilityReceipt.class.isAssignableFrom(StagedData.class));
    StagedData staged = StagedData.initial("remote-memory", "rack-7", CONTENT, 8);
    for (DurabilityReceipt.Kind kind : DurabilityReceipt.Kind.values()) {
      assertNotEquals(kind.name(), staged.tier());
    }
  }

  @Test
  void malformedOrForgedPlacementEvidenceFailsClosed() {
    StagedData valid = StagedData.initial("memory", "host-a", CONTENT, 1);
    assertThrows(
        IllegalArgumentException.class,
        () -> StagedData.initial("memory", "host a", CONTENT, 1));
    assertThrows(
        IllegalArgumentException.class,
        () -> StagedData.initial("memory", "host-a", "A".repeat(64), 1));
    assertThrows(
        IllegalArgumentException.class,
        () -> StagedData.initial("memory", "host-a", CONTENT, -1));
    assertThrows(
        IllegalArgumentException.class,
        () -> new StagedData(
            valid.tier(),
            valid.failureDomain(),
            valid.contentIdentity(),
            valid.bytes(),
            valid.parentIdentity(),
            "0".repeat(64)));
  }
}
