package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.runtime.io.DeterministicIo.Delivery;
import com.typeobject.wheeler.runtime.io.IoCompletion.CancellationRelation;
import com.typeobject.wheeler.runtime.io.IoCompletion.TerminalKind;
import com.typeobject.wheeler.runtime.io.RemoteMemory.Rights;
import java.lang.reflect.Modifier;
import java.nio.charset.StandardCharsets;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Exercises epoch-scoped remote placement and explicit peer evidence stages. */
final class RemoteMemoryTest {
  private static final IoLimits LIMITS = new IoLimits(8, 8, 8, 8, 8, 64);

  @Test
  void oneSidedPlacementCarriesNeitherPeerNorPersistenceAuthority() {
    RemoteMemory memory = new RemoteMemory("remote-a", 16);
    RemoteMemory.Advertisement advertisement = memory.advertise(4, 6, Rights.READ_WRITE);
    OwnedIoBuffer source = OwnedIoBuffer.copyOf("placed".getBytes(StandardCharsets.UTF_8));
    IoRequest<RemoteMemory.Placement> request = memory.place(advertisement, 0, source);
    assertThrows(IllegalStateException.class, source::snapshot);

    RemoteMemory.Placement placement;
    try (IoScope scope = new CompletionIo(1, 8).scope(LIMITS)) {
      placement = scope.await(request).value();
    }
    assertArrayEquals("placed".getBytes(StandardCharsets.UTF_8), source.snapshot());
    assertArrayEquals("placed".getBytes(StandardCharsets.UTF_8), memory.read(advertisement));
    assertFalse(DurabilityReceipt.class.isInstance(placement));
    assertFalse(RemoteMemory.PeerAcknowledgement.class.isInstance(placement));
    assertFalse(RemoteMemory.Persistence.class.isInstance(placement));
  }

  @Test
  void peerAcknowledgementApplicationAndPersistenceAreDistinctIssuerStages() {
    RemoteMemory memory = new RemoteMemory("remote-b", 8);
    RemoteMemory.Advertisement advertisement = memory.advertise(0, 8, Rights.READ_WRITE);
    RemoteMemory.Placement placement;
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      placement = scope.await(memory.place(
          advertisement, 0, OwnedIoBuffer.copyOf(new byte[] {1, 2}))).value();
    }
    RemoteMemory.PeerAcknowledgement acknowledgement = memory.acknowledge(
        placement, "a".repeat(64));
    RemoteMemory.PeerApplication application = memory.apply(
        acknowledgement, "b".repeat(64));
    RemoteMemory.Persistence persistence = memory.persist(
        application, "c".repeat(64));
    assertEquals(placement, acknowledgement.placement());
    assertEquals(acknowledgement, application.acknowledgement());
    assertEquals(application, persistence.application());
    assertFalse(DurabilityReceipt.class.isInstance(persistence));

    for (Class<?> type : List.of(
        RemoteMemory.Advertisement.class,
        RemoteMemory.Placement.class,
        RemoteMemory.PeerAcknowledgement.class,
        RemoteMemory.PeerApplication.class,
        RemoteMemory.Persistence.class)) {
      assertTrue(Modifier.isPrivate(type.getDeclaredConstructors()[0].getModifiers()));
    }
  }

  @Test
  void revocationRaceReturnsUncertaintyAndReleasesTheSource() {
    RemoteMemory memory = new RemoteMemory("remote-c", 8);
    RemoteMemory.Advertisement stale = memory.advertise(0, 4, Rights.READ_WRITE);
    OwnedIoBuffer source = OwnedIoBuffer.copyOf(new byte[] {7, 7, 7, 7});
    IoRequest<RemoteMemory.Placement> request = memory.place(stale, 0, source);
    memory.revoke();

    try (IoScope scope = new CompletionIo(1, 8).scope(LIMITS)) {
      IoCompletion<RemoteMemory.Placement> completion = scope.await(request);
      assertEquals(TerminalKind.UNCERTAIN, completion.terminalKind());
      assertEquals(
          CancellationRelation.UNCERTAIN_WITHOUT_CANCELLATION,
          completion.cancellationRelation());
      assertTrue(completion.detail().startsWith("rdma-connection-or-revocation:"));
      assertEquals(0, completion.progress());
    }
    assertArrayEquals(new byte[] {7, 7, 7, 7}, source.snapshot());
    RemoteMemory.Advertisement current = memory.advertise(0, 4, Rights.READ_WRITE);
    assertArrayEquals(new byte[4], memory.read(current));
  }

  @Test
  void disconnectRaceReturnsUncertaintyAndReconnectRestoresNoOldAuthority() {
    RemoteMemory memory = new RemoteMemory("remote-connection", 8);
    RemoteMemory.Advertisement stale = memory.advertise(0, 4, Rights.READ_WRITE);
    OwnedIoBuffer source = OwnedIoBuffer.copyOf(new byte[] {4, 3, 2, 1});
    IoRequest<RemoteMemory.Placement> request = memory.place(stale, 0, source);
    memory.disconnect();

    try (IoScope scope = new CompletionIo(1, 8).scope(LIMITS)) {
      assertEquals(TerminalKind.UNCERTAIN, scope.await(request).terminalKind());
    }
    assertThrows(IllegalStateException.class, () -> memory.read(stale));
    memory.reconnect();
    assertThrows(IllegalStateException.class, () -> memory.read(stale));
    RemoteMemory.Advertisement current = memory.advertise(0, 4, Rights.READ_WRITE);
    assertArrayEquals(new byte[4], memory.read(current));
  }

  @Test
  void queuedCancellationPerformsNoPlacement() {
    RemoteMemory memory = new RemoteMemory("remote-d", 8);
    RemoteMemory.Advertisement advertisement = memory.advertise(0, 4, Rights.READ_WRITE);
    OwnedIoBuffer source = OwnedIoBuffer.copyOf(new byte[] {1, 2, 3, 4});
    try (IoScope scope = new CompletionIo(1, 8).scope(LIMITS)) {
      IoOperation<RemoteMemory.Placement> operation = scope.submit(
          memory.place(advertisement, 0, source));
      assertTrue(operation.cancel());
      assertEquals(TerminalKind.CANCELED, operation.await().terminalKind());
    }
    assertArrayEquals(new byte[4], memory.read(advertisement));
    assertArrayEquals(new byte[] {1, 2, 3, 4}, source.snapshot());
  }

  @Test
  void wrongRightsRangesRegionsAndEpochsFailClosedBeforeCaptureOrPromotion() {
    RemoteMemory first = new RemoteMemory("remote-e", 8);
    RemoteMemory second = new RemoteMemory("remote-f", 8);
    RemoteMemory.Advertisement readOnly = first.advertise(0, 4, Rights.READ);
    OwnedIoBuffer source = OwnedIoBuffer.copyOf(new byte[] {1});
    assertThrows(IllegalStateException.class, () -> first.place(readOnly, 0, source));
    assertThrows(IllegalArgumentException.class, () -> second.place(readOnly, 0, source));
    assertThrows(
        IllegalArgumentException.class,
        () -> first.advertise(7, 2, Rights.READ_WRITE));
    assertArrayEquals(new byte[] {1}, source.snapshot());

    RemoteMemory.Advertisement writable = first.advertise(0, 4, Rights.READ_WRITE);
    RemoteMemory.Placement placement;
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      placement = scope.await(first.place(writable, 0, source)).value();
    }
    first.revoke();
    assertThrows(
        IllegalStateException.class,
        () -> first.acknowledge(placement, "a".repeat(64)));
    assertThrows(IllegalStateException.class, () -> first.read(writable));
  }
}
