package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.runtime.io.NativeRnicRegistry.NativeHandle;
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
    private boolean malformed;
    private long failedDeregistration = -1;
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
