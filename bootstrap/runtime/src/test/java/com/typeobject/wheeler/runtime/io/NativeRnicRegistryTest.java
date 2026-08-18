package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.runtime.io.IoCompletion.TerminalKind;
import com.typeobject.wheeler.runtime.io.NativeRnicRegistry.NativeHandle;
import com.typeobject.wheeler.runtime.io.NativeRnicRegistry.NativeWriteCompletion;
import com.typeobject.wheeler.runtime.io.NativeRnicRegistry.Rights;
import java.lang.reflect.Modifier;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Exercises bounded native RNIC registration and revocation authority. */
final class NativeRnicRegistryTest {
  @Test
  void registrationBindsRangeRightsGenerationAndNativeHandle() {
    RecordingBackend backend = new RecordingBackend();
    NativeRnicRegistry registry = new NativeRnicRegistry("rnic-a", 4, backend);
    OwnedIoBuffer owner = OwnedIoBuffer.allocate(16);

    NativeRnicRegistry.Registration registration = registry.register(
        owner, 3, 8, Rights.REMOTE_READ_WRITE);

    assertThrows(IllegalStateException.class, owner::snapshot);
    assertEquals("rnic-a", registration.providerIdentity());
    assertEquals(1, registration.generation());
    assertEquals(3, registration.offset());
    assertEquals(8, registration.length());
    assertEquals(Rights.REMOTE_READ_WRITE, registration.rights());
    assertEquals(
        "dc52c61fd42d156606ec34ee6613b3560983a70f6d364d476cbbf901252793b1",
        registration.identity());
    assertTrue(registry.isCurrent(registration));
    assertTrue(Modifier.isPrivate(
        NativeRnicRegistry.Registration.class.getDeclaredConstructors()[0].getModifiers()));

    registry.revoke(registration);

    assertFalse(registry.isCurrent(registration));
    assertEquals(16, owner.snapshot().length);
    assertEquals(List.of(1L), backend.deregisteredGenerations);
    assertThrows(IllegalStateException.class, () -> registry.revoke(registration));
    registry.close();
    assertTrue(backend.disconnected);
  }

  @Test
  void capacityAndProviderIdentityFailBeforeAuthorityChanges() {
    RecordingBackend firstBackend = new RecordingBackend();
    NativeRnicRegistry first = new NativeRnicRegistry("rnic-first", 1, firstBackend);
    NativeRnicRegistry second = new NativeRnicRegistry(
        "rnic-second", 1, new RecordingBackend());
    OwnedIoBuffer firstOwner = OwnedIoBuffer.allocate(4);
    NativeRnicRegistry.Registration firstRegistration = first.register(
        firstOwner, 0, 4, Rights.REMOTE_WRITE);

    OwnedIoBuffer rejected = OwnedIoBuffer.allocate(2);
    assertThrows(
        IllegalStateException.class,
        () -> first.register(rejected, 0, 2, Rights.REMOTE_READ));
    assertEquals(2, rejected.snapshot().length);
    assertFalse(second.isCurrent(firstRegistration));
    assertThrows(
        IllegalArgumentException.class,
        () -> second.revoke(firstRegistration));
    assertThrows(
        IllegalArgumentException.class,
        () -> first.register(rejected, 2, 1, Rights.REMOTE_READ));

    first.revoke(firstRegistration);
    NativeRnicRegistry.Registration replacement = first.register(
        rejected, 0, 2, Rights.REMOTE_READ);
    assertEquals(2, replacement.generation());
    assertNotEquals(firstRegistration.identity(), replacement.identity());
    first.close();
    second.close();
  }

  @Test
  void oneSidedWriteUsesThePortableLifecycleWithoutPeerOrDurabilityClaims() {
    RecordingBackend backend = new RecordingBackend();
    NativeRnicRegistry registry = new NativeRnicRegistry("rnic-write", 2, backend);
    OwnedIoBuffer targetOwner = OwnedIoBuffer.allocate(8);
    NativeRnicRegistry.Registration target = registry.register(
        targetOwner, 0, 8, Rights.REMOTE_WRITE);
    OwnedIoBuffer source = OwnedIoBuffer.copyOf(new byte[] {9, 8, 7, 6});

    IoRequest<NativeRnicRegistry.WriteCompleted> request = registry.write(
        target, 2, source, 1, 3);

    assertEquals(0, backend.writeCalls);
    assertThrows(IllegalStateException.class, source::snapshot);
    NativeRnicRegistry.WriteCompleted completed;
    try (IoScope scope = new DeterministicIo(
        DeterministicIo.Delivery.INLINE).scope(new IoLimits(4, 4, 4, 4, 4, 16))) {
      completed = scope.await(request).value();
    }
    assertEquals(1, backend.writeCalls);
    assertEquals(List.of(8, 7, 6), backend.writtenBytes);
    assertEquals(target, completed.registration());
    assertEquals(2, completed.relativeOffset());
    assertEquals(3, completed.bytes());
    assertEquals(
        "839aeb4316d7dfaca3d5d0c35009402f3d6b72e851ce3e03bc3446ddf819b0b8",
        completed.contentIdentity());
    assertEquals("d".repeat(64), completed.evidenceIdentity());
    assertFalse(DurabilityReceipt.class.isInstance(completed));
    assertFalse(RemoteMemory.PeerAcknowledgement.class.isInstance(completed));
    assertEquals(4, source.snapshot().length);
    assertThrows(IllegalStateException.class, targetOwner::snapshot);
    registry.close();
  }

  @Test
  void malformedNativeCompletionPublishesOnlyUncertainty() {
    RecordingBackend backend = new RecordingBackend();
    backend.malformedWrite = true;
    NativeRnicRegistry registry = new NativeRnicRegistry("rnic-write-malformed", 1, backend);
    OwnedIoBuffer targetOwner = OwnedIoBuffer.allocate(4);
    NativeRnicRegistry.Registration target = registry.register(
        targetOwner, 0, 4, Rights.REMOTE_WRITE);
    OwnedIoBuffer source = OwnedIoBuffer.copyOf(new byte[] {5, 4, 3});

    try (IoScope scope = new DeterministicIo(
        DeterministicIo.Delivery.INLINE).scope(new IoLimits(4, 4, 4, 4, 4, 16))) {
      IoCompletion<NativeRnicRegistry.WriteCompleted> completion = scope.await(
          registry.write(target, 0, source, 0, 3));
      assertEquals(TerminalKind.UNCERTAIN, completion.terminalKind());
      assertEquals("native-rnic-completion-mismatch", completion.detail());
      assertEquals(2, completion.progress());
    }
    assertEquals(3, source.snapshot().length);
    registry.close();
  }

  @Test
  void staleAndReadOnlyWritesFailBeforeNativeWork() {
    RecordingBackend backend = new RecordingBackend();
    NativeRnicRegistry registry = new NativeRnicRegistry("rnic-write-race", 2, backend);
    OwnedIoBuffer readOwner = OwnedIoBuffer.allocate(4);
    NativeRnicRegistry.Registration readOnly = registry.register(
        readOwner, 0, 4, Rights.REMOTE_READ);
    OwnedIoBuffer source = OwnedIoBuffer.copyOf(new byte[] {1, 2});
    assertThrows(
        IllegalStateException.class,
        () -> registry.write(readOnly, 0, source, 0, 2));
    assertEquals(2, source.snapshot().length);
    registry.revoke(readOnly);

    OwnedIoBuffer writeOwner = OwnedIoBuffer.allocate(4);
    NativeRnicRegistry.Registration writable = registry.register(
        writeOwner, 0, 4, Rights.REMOTE_WRITE);
    IoRequest<NativeRnicRegistry.WriteCompleted> request = registry.write(
        writable, 0, source, 0, 2);
    registry.revoke(writable);
    try (IoScope scope = new DeterministicIo(
        DeterministicIo.Delivery.INLINE).scope(new IoLimits(4, 4, 4, 4, 4, 16))) {
      assertEquals(TerminalKind.UNCERTAIN, scope.await(request).terminalKind());
    }
    assertEquals(0, backend.writeCalls);
    assertEquals(2, source.snapshot().length);
    registry.close();
  }

  @Test
  void malformedBackendRegistrationNeverPublishesAndReleasesTheOwner() {
    RecordingBackend backend = new RecordingBackend();
    backend.malformed = true;
    NativeRnicRegistry registry = new NativeRnicRegistry("rnic-malformed", 2, backend);
    OwnedIoBuffer owner = OwnedIoBuffer.allocate(8);

    assertThrows(
        IllegalArgumentException.class,
        () -> registry.register(owner, 0, 8, Rights.REMOTE_READ_WRITE));

    assertEquals(8, owner.snapshot().length);
    assertEquals(List.of(2L), backend.deregisteredGenerations);
    registry.close();
  }

  @Test
  void disconnectRevokesInGenerationOrderAndReleasesOwnersOnBackendFailure() {
    RecordingBackend backend = new RecordingBackend();
    backend.failedDeregistration = 1;
    NativeRnicRegistry registry = new NativeRnicRegistry("rnic-close", 2, backend);
    OwnedIoBuffer firstOwner = OwnedIoBuffer.allocate(2);
    OwnedIoBuffer secondOwner = OwnedIoBuffer.allocate(2);
    NativeRnicRegistry.Registration first = registry.register(
        firstOwner, 0, 2, Rights.REMOTE_READ);
    NativeRnicRegistry.Registration second = registry.register(
        secondOwner, 0, 2, Rights.REMOTE_WRITE);

    IllegalStateException failure = assertThrows(IllegalStateException.class, registry::close);

    assertEquals("native deregistration failed", failure.getMessage());
    assertEquals(List.of(1L, 2L), backend.deregisteredGenerations);
    assertTrue(backend.disconnected);
    assertFalse(registry.isCurrent(first));
    assertFalse(registry.isCurrent(second));
    assertEquals(2, firstOwner.snapshot().length);
    assertEquals(2, secondOwner.snapshot().length);
    assertThrows(
        IllegalStateException.class,
        () -> registry.register(firstOwner, 0, 1, Rights.REMOTE_READ));
    registry.close();
  }

  private static final class RecordingBackend implements NativeRnicRegistry.Backend {
    private final List<Long> deregisteredGenerations = new ArrayList<>();
    private final List<Integer> writtenBytes = new ArrayList<>();
    private boolean malformed;
    private boolean malformedWrite;
    private long failedDeregistration = -1;
    private int writeCalls;
    private boolean disconnected;

    @Override
    public NativeHandle register(
        OwnedIoBuffer owner,
        int offset,
        int length,
        Rights rights,
        long generation) {
      assertThrows(IllegalStateException.class, owner::snapshot);
      long handleGeneration = malformed ? generation + 1 : generation;
      return new NativeHandle(
          4_096 + generation,
          length,
          100 + generation,
          200 + generation,
          handleGeneration);
    }

    @Override
    public IoProviderResult<NativeWriteCompletion> write(
        NativeHandle target,
        int relativeOffset,
        OwnedIoBuffer source,
        int sourceOffset,
        int length) {
      writeCalls += 1;
      byte[] bytes = new byte[length];
      source.copyTo(sourceOffset, bytes, 0, length);
      for (byte value : bytes) {
        writtenBytes.add(Byte.toUnsignedInt(value));
      }
      int completed = malformedWrite ? length - 1 : length;
      return IoProviderResult.success(
          new NativeWriteCompletion(
              target.generation(), relativeOffset, completed, "d".repeat(64)),
          length);
    }

    @Override
    public void deregister(NativeHandle handle) {
      deregisteredGenerations.add(handle.generation());
      if (handle.generation() == failedDeregistration) {
        throw new IllegalStateException("native deregistration failed");
      }
    }

    @Override
    public void disconnect() {
      disconnected = true;
    }
  }
}
