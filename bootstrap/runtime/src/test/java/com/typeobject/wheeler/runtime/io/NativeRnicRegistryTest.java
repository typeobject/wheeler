package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.runtime.io.IoCompletion.CancellationRelation;
import com.typeobject.wheeler.runtime.io.IoCompletion.TerminalKind;
import com.typeobject.wheeler.runtime.io.NativeRnicRegistry.NativeAtomicCompletion;
import com.typeobject.wheeler.runtime.io.NativeRnicRegistry.NativeHandle;
import com.typeobject.wheeler.runtime.io.NativeRnicRegistry.NativeReadCompletion;
import com.typeobject.wheeler.runtime.io.NativeRnicRegistry.NativeWriteCompletion;
import com.typeobject.wheeler.runtime.io.NativeRnicRegistry.Rights;
import java.lang.reflect.Modifier;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
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
  void compareAndSwapPublishesObservedValueAndExactExchangeResult() {
    RecordingBackend backend = new RecordingBackend();
    backend.aligned = true;
    backend.atomicValue = 11;
    NativeRnicRegistry registry = new NativeRnicRegistry("rnic-atomic", 1, backend);
    NativeRnicRegistry.Registration target = registry.register(
        OwnedIoBuffer.allocate(16), 0, 16, Rights.REMOTE_READ_WRITE);

    IoRequest<NativeRnicRegistry.AtomicCompleted> exchange = registry.compareAndSwap64(
        target, 0, 11, 19);

    assertEquals(0, backend.atomicCalls);
    try (IoScope scope = new DeterministicIo(
        DeterministicIo.Delivery.INLINE).scope(new IoLimits(4, 4, 4, 4, 4, 16))) {
      NativeRnicRegistry.AtomicCompleted completed = scope.await(exchange).value();
      assertEquals(11, completed.observed());
      assertEquals(11, completed.expected());
      assertEquals(19, completed.update());
      assertTrue(completed.exchanged());
      assertEquals("e".repeat(64), completed.evidenceIdentity());
    }
    assertEquals(19, backend.atomicValue);

    try (IoScope scope = new DeterministicIo(
        DeterministicIo.Delivery.INLINE).scope(new IoLimits(4, 4, 4, 4, 4, 16))) {
      NativeRnicRegistry.AtomicCompleted completed = scope.await(
          registry.compareAndSwap64(target, 0, 11, 23)).value();
      assertEquals(19, completed.observed());
      assertFalse(completed.exchanged());
    }
    assertEquals(19, backend.atomicValue);
    assertEquals(2, backend.atomicCalls);
    registry.close();
  }

  @Test
  void atomicRightsAlignmentAndRevocationFailClosed() {
    RecordingBackend backend = new RecordingBackend();
    NativeRnicRegistry registry = new NativeRnicRegistry("rnic-atomic-bounds", 2, backend);
    NativeRnicRegistry.Registration readOnly = registry.register(
        OwnedIoBuffer.allocate(16), 0, 16, Rights.REMOTE_READ);
    assertThrows(
        IllegalStateException.class,
        () -> registry.compareAndSwap64(readOnly, 0, 1, 2));
    registry.revoke(readOnly);

    NativeRnicRegistry.Registration unaligned = registry.register(
        OwnedIoBuffer.allocate(16), 0, 16, Rights.REMOTE_READ_WRITE);
    assertThrows(
        IllegalArgumentException.class,
        () -> registry.compareAndSwap64(unaligned, 0, 1, 2));
    backend.aligned = true;
    registry.revoke(unaligned);
    NativeRnicRegistry.Registration current = registry.register(
        OwnedIoBuffer.allocate(16), 0, 16, Rights.REMOTE_READ_WRITE);
    IoRequest<NativeRnicRegistry.AtomicCompleted> request = registry.compareAndSwap64(
        current, 0, 1, 2);
    registry.revoke(current);
    try (IoScope scope = new DeterministicIo(
        DeterministicIo.Delivery.INLINE).scope(new IoLimits(4, 4, 4, 4, 4, 16))) {
      assertEquals(TerminalKind.UNCERTAIN, scope.await(request).terminalKind());
    }
    assertEquals(0, backend.atomicCalls);
    registry.close();
  }

  @Test
  void queuedNativeCancellationRunsNoBackendHookAndReleasesTheSource() throws Exception {
    RecordingBackend backend = new RecordingBackend();
    NativeRnicRegistry registry = new NativeRnicRegistry("rnic-queued-cancel", 1, backend);
    NativeRnicRegistry.Registration target = registry.register(
        OwnedIoBuffer.allocate(4), 0, 4, Rights.REMOTE_WRITE);
    OwnedIoBuffer source = OwnedIoBuffer.copyOf(new byte[] {1, 2, 3, 4});
    CountDownLatch started = new CountDownLatch(1);
    CountDownLatch release = new CountDownLatch(1);

    try (ThreadedIo io = new ThreadedIo(1, 2);
        IoScope scope = io.scope(new IoLimits(4, 4, 4, 4, 4, 16))) {
      IoOperation<Integer> blocker = scope.submit(IoRequest.prepare(
          "rnic-cancel-blocker", 1, () -> {
            started.countDown();
            awaitLatch(release);
            return IoProviderResult.success(1, 1);
          }));
      assertTrue(started.await(2, TimeUnit.SECONDS));
      IoOperation<NativeRnicRegistry.WriteCompleted> queued = scope.submit(
          registry.write(target, 0, source, 0, 4));
      assertTrue(queued.cancel());
      assertEquals(TerminalKind.CANCELED, queued.await().terminalKind());
      release.countDown();
      blocker.await();
    }
    assertEquals(0, backend.writeCalls);
    assertTrue(backend.canceledOperations.isEmpty());
    assertEquals(4, source.snapshot().length);
    registry.close();
  }

  @Test
  void runningNativeCancellationUsesTheExactOperationIdentity() throws Exception {
    CancelingBackend backend = new CancelingBackend();
    NativeRnicRegistry registry = new NativeRnicRegistry("rnic-cancel", 1, backend);
    NativeRnicRegistry.Registration target = registry.register(
        OwnedIoBuffer.allocate(4), 0, 4, Rights.REMOTE_WRITE);
    OwnedIoBuffer source = OwnedIoBuffer.copyOf(new byte[] {1, 2, 3, 4});

    try (ThreadedIo io = new ThreadedIo(1, 1);
        IoScope scope = io.scope(new IoLimits(4, 4, 4, 4, 4, 16))) {
      IoOperation<NativeRnicRegistry.WriteCompleted> operation = scope.submit(
          registry.write(target, 0, source, 0, 4));
      assertTrue(backend.started.await(2, TimeUnit.SECONDS));
      assertFalse(operation.cancel());
      IoCompletion<NativeRnicRegistry.WriteCompleted> completion = operation.await();
      assertEquals(TerminalKind.CANCELED, completion.terminalKind());
      assertEquals(
          CancellationRelation.CANCELED_BEFORE_EFFECT,
          completion.cancellationRelation());
    }
    assertEquals(List.of(1L), backend.canceledOperations);
    assertEquals(4, source.snapshot().length);
    registry.close();
  }

  @Test
  void oneSidedReadReturnsExactReceivedContentThroughThePortableLifecycle() {
    RecordingBackend backend = new RecordingBackend();
    NativeRnicRegistry registry = new NativeRnicRegistry("rnic-read", 2, backend);
    OwnedIoBuffer sourceOwner = OwnedIoBuffer.allocate(8);
    NativeRnicRegistry.Registration source = registry.register(
        sourceOwner, 0, 8, Rights.REMOTE_READ);
    OwnedIoBuffer destination = OwnedIoBuffer.allocate(5);

    IoRequest<NativeRnicRegistry.ReadCompleted> request = registry.read(
        source, 2, destination, 1, 3);

    assertEquals(0, backend.readCalls);
    assertThrows(IllegalStateException.class, destination::snapshot);
    NativeRnicRegistry.ReadCompleted completed;
    try (IoScope scope = new DeterministicIo(
        DeterministicIo.Delivery.INLINE).scope(new IoLimits(4, 4, 4, 4, 4, 16))) {
      completed = scope.await(request).value();
    }
    assertEquals(1, backend.readCalls);
    assertEquals(source, completed.registration());
    assertEquals(2, completed.relativeOffset());
    assertEquals(3, completed.bytes());
    assertEquals(
        "2848698aa4b3431e3db06c343ca2cb0455f8aaf16c85cdd828c92ddf7dc134f8",
        completed.contentIdentity());
    assertEquals("c".repeat(64), completed.evidenceIdentity());
    assertEquals(List.of(0, 3, 4, 5, 0), unsigned(destination.snapshot()));
    assertFalse(DurabilityReceipt.class.isInstance(completed));
    registry.close();
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
    OwnedIoBuffer destination = OwnedIoBuffer.allocate(2);
    assertThrows(
        IllegalStateException.class,
        () -> registry.read(writable, 0, destination, 0, 2));
    assertEquals(2, destination.snapshot().length);
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

  private static void awaitLatch(CountDownLatch latch) {
    try {
      if (!latch.await(2, TimeUnit.SECONDS)) {
        throw new IllegalStateException("native test latch did not open");
      }
    } catch (InterruptedException interrupted) {
      Thread.currentThread().interrupt();
      throw new IllegalStateException("native test latch wait was interrupted", interrupted);
    }
  }

  private static List<Integer> unsigned(byte[] bytes) {
    List<Integer> values = new ArrayList<>();
    for (byte value : bytes) {
      values.add(Byte.toUnsignedInt(value));
    }
    return values;
  }

  private static class RecordingBackend implements NativeRnicRegistry.Backend {
    private final List<Long> deregisteredGenerations = new ArrayList<>();
    private final List<Integer> writtenBytes = new ArrayList<>();
    protected final List<Long> canceledOperations = new ArrayList<>();
    private boolean aligned;
    private boolean malformed;
    private boolean malformedWrite;
    private long failedDeregistration = -1;
    private int atomicCalls;
    private int readCalls;
    private int writeCalls;
    private long atomicValue;
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
      long address = aligned ? 4_096 + generation * 8 : 4_096 + generation;
      return new NativeHandle(
          address,
          length,
          100 + generation,
          200 + generation,
          handleGeneration);
    }

    @Override
    public IoProviderResult<NativeAtomicCompletion> compareAndSwap64(
        long operation,
        NativeHandle target,
        int relativeOffset,
        long expected,
        long update) {
      atomicCalls += 1;
      long observed = atomicValue;
      if (observed == expected) {
        atomicValue = update;
      }
      return IoProviderResult.success(
          new NativeAtomicCompletion(
              target.generation(), relativeOffset, expected, update, observed, "e".repeat(64)),
          Long.BYTES);
    }

    @Override
    public IoProviderResult<NativeReadCompletion> read(
        long operation,
        NativeHandle source,
        int relativeOffset,
        OwnedIoBuffer destination,
        int destinationOffset,
        int length) {
      readCalls += 1;
      byte[] bytes = new byte[length];
      for (int index = 0; index < length; index++) {
        bytes[index] = (byte) (relativeOffset + index + 1);
      }
      destination.copyFrom(bytes, 0, destinationOffset, length);
      return IoProviderResult.success(
          new NativeReadCompletion(
              source.generation(), relativeOffset, length, "c".repeat(64)),
          length);
    }

    @Override
    public IoProviderResult<NativeWriteCompletion> write(
        long operation,
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
    public void cancel(long operation) {
      canceledOperations.add(operation);
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

  private static final class CancelingBackend extends RecordingBackend {
    private final CountDownLatch started = new CountDownLatch(1);
    private final CountDownLatch canceled = new CountDownLatch(1);

    @Override
    public IoProviderResult<NativeWriteCompletion> write(
        long operation,
        NativeHandle target,
        int relativeOffset,
        OwnedIoBuffer source,
        int sourceOffset,
        int length) {
      started.countDown();
      awaitLatch(canceled);
      return IoProviderResult.canceledBeforeEffect("native-rnic-write-canceled");
    }

    @Override
    public void cancel(long operation) {
      super.cancel(operation);
      canceled.countDown();
    }

  }
}
