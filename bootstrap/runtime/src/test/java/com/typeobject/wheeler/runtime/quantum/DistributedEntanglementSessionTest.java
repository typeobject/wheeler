package com.typeobject.wheeler.runtime.quantum;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.Set;
import org.junit.jupiter.api.Test;

/** Persisted distributed heralding keeps local branch discard distinct from remote rollback. */
final class DistributedEntanglementSessionTest {
  private static final String HERALD =
      "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789";

  @Test
  void delayedHeraldRestoresWithoutAnotherRequestAndPersistsExactIdentity() {
    TargetDescriptor descriptor = networkDescriptor();
    DistributedEntanglementSession session = DistributedEntanglementSession.request(
        descriptor, "target-b", "target-a", 10, 20);
    DistributedEntanglementSession.Snapshot waiting = session.snapshot();
    DistributedEntanglementSession restored =
        DistributedEntanglementSession.restore(waiting);

    restored.herald(HERALD, 19);
    DistributedEntanglementSession.Snapshot heralded = restored.snapshot();

    assertEquals(waiting.sessionIdentity(), heralded.sessionIdentity());
    assertEquals("target-a", heralded.leftEndpoint());
    assertEquals("target-b", heralded.rightEndpoint());
    assertEquals(DistributedEntanglementSession.State.HERALDED, heralded.state());
    assertEquals(HERALD, heralded.heraldIdentity());
    assertNotEquals(waiting.branchIdentity(), heralded.branchIdentity());
    assertEquals(heralded, DistributedEntanglementSession.restore(heralded).snapshot());
  }

  @Test
  void timeoutDiscardsOnlyTheLocalBranchAndMissingCapabilityFailsClosed() {
    DistributedEntanglementSession session = DistributedEntanglementSession.request(
        networkDescriptor(), "target-a", "target-b", 1, 3);
    session.expire(4);
    assertEquals(DistributedEntanglementSession.State.EXPIRED, session.snapshot().state());
    assertThrows(IllegalStateException.class, () -> session.herald(HERALD, 2));
    session.discard();
    assertEquals(DistributedEntanglementSession.State.DISCARDED, session.snapshot().state());

    TargetDescriptor staticOnly = new TargetDescriptor(
        "static", "physical", Set.of(TargetCapability.STATIC_CIRCUIT), 8, 8);
    assertThrows(
        QuantumExecutionException.class,
        () -> DistributedEntanglementSession.request(
            staticOnly, "target-a", "target-b", 1, 3));
  }

  private static TargetDescriptor networkDescriptor() {
    return new TargetDescriptor(
        "mock-network",
        "loopback-entanglement",
        Set.of(TargetCapability.NETWORK_ENTANGLEMENT),
        2,
        1);
  }
}
