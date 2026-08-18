package com.typeobject.wheeler.runtime.io;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;
import java.util.TreeMap;

/** Bounded native RNIC registration authority with generation-scoped revocation. */
public final class NativeRnicRegistry implements AutoCloseable {
  /** Remote operations admitted by one native memory registration. */
  public enum Rights {
    REMOTE_READ,
    REMOTE_WRITE,
    REMOTE_READ_WRITE
  }

  /** Opaque native registration fields returned by an RNIC backend. */
  public record NativeHandle(
      long address,
      int length,
      long localKey,
      long remoteKey,
      long generation) {}

  /** Host RNIC registration and disconnect boundary. */
  public interface Backend {
    /** Pins or maps the held owner and returns its exact native registration. */
    NativeHandle register(
        OwnedIoBuffer owner,
        int offset,
        int length,
        Rights rights,
        long generation);

    /** Revokes one native registration. */
    void deregister(NativeHandle handle);

    /** Tears down the native association after all registration authority is revoked. */
    void disconnect();
  }

  /** Unforgeable provider-issued registration authority. */
  public static final class Registration {
    private final String providerIdentity;
    private final long generation;
    private final int offset;
    private final int length;
    private final Rights rights;
    private final String identity;

    private Registration(
        String providerIdentity,
        long generation,
        int offset,
        int length,
        Rights rights,
        String identity) {
      this.providerIdentity = providerIdentity;
      this.generation = generation;
      this.offset = offset;
      this.length = length;
      this.rights = rights;
      this.identity = identity;
    }

    /** Returns the issuing provider identity. */
    public String providerIdentity() {
      return providerIdentity;
    }

    /** Returns the monotonically increasing registration generation. */
    public long generation() {
      return generation;
    }

    /** Returns the first registered owner byte. */
    public int offset() {
      return offset;
    }

    /** Returns the exact registered byte count. */
    public int length() {
      return length;
    }

    /** Returns the fixed remote-operation rights. */
    public Rights rights() {
      return rights;
    }

    /** Returns the canonical registration identity. */
    public String identity() {
      return identity;
    }
  }

  private record Active(
      Registration registration,
      OwnedIoBuffer owner,
      NativeHandle handle) {}

  private static final int MAX_REGISTRATIONS = 4_096;

  private final String identity;
  private final int maximumRegistrations;
  private final Backend backend;
  private final TreeMap<Long, Active> active = new TreeMap<>();
  private long generation;
  private boolean connected = true;

  /** Creates one bounded native registration registry. */
  public NativeRnicRegistry(
      String identity,
      int maximumRegistrations,
      Backend backend) {
    DurabilitySubject.visibleAscii("RNIC provider identity", identity, 160, false);
    if (maximumRegistrations < 1 || MAX_REGISTRATIONS < maximumRegistrations) {
      throw new IllegalArgumentException("RNIC registration bound must be between 1 and 4096");
    }
    this.identity = identity;
    this.maximumRegistrations = maximumRegistrations;
    this.backend = Objects.requireNonNull(backend, "backend");
  }

  /** Registers and holds one exact owner range under fresh native authority. */
  public synchronized Registration register(
      OwnedIoBuffer owner,
      int offset,
      int length,
      Rights rights) {
    requireConnected();
    Objects.requireNonNull(owner, "owner");
    Objects.requireNonNull(rights, "rights");
    int ownerLength = owner.length();
    if (offset < 0 || length < 1 || ownerLength < offset || ownerLength - offset < length) {
      throw new IllegalArgumentException("RNIC registration range is out of bounds");
    }
    if (maximumRegistrations <= active.size()) {
      throw new IllegalStateException("RNIC registration bound exhausted");
    }
    if (generation == Long.MAX_VALUE) {
      throw new IllegalStateException("RNIC registration generation exhausted");
    }

    long nextGeneration = ++generation;
    owner.hold();
    NativeHandle handle = null;
    boolean accepted = false;
    try {
      handle = Objects.requireNonNull(
          backend.register(owner, offset, length, rights, nextGeneration),
          "native registration");
      validateHandle(handle, length, nextGeneration);
      String canonical = identity + '\0' + nextGeneration + '\0' + offset + '\0' + length
          + '\0' + rights + '\0' + handle.address() + '\0' + handle.localKey()
          + '\0' + handle.remoteKey();
      Registration registration = new Registration(
          identity,
          nextGeneration,
          offset,
          length,
          rights,
          digest("wheeler-native-rnic-registration-1", canonical));
      active.put(nextGeneration, new Active(registration, owner, handle));
      accepted = true;
      return registration;
    } finally {
      if (!accepted) {
        try {
          if (handle != null) {
            backend.deregister(handle);
          }
        } finally {
          owner.release();
        }
      }
    }
  }

  /** Reports whether this registry still owns the exact registration generation. */
  public synchronized boolean isCurrent(Registration registration) {
    if (registration == null || !identity.equals(registration.providerIdentity)) {
      return false;
    }
    Active current = active.get(registration.generation);
    return connected && current != null && current.registration == registration;
  }

  /** Revokes one registration before releasing its held owner. */
  public synchronized void revoke(Registration registration) {
    Active current = requireCurrent(registration);
    active.remove(registration.generation);
    try {
      backend.deregister(current.handle);
    } finally {
      current.owner.release();
    }
  }

  /** Revokes all registrations and disconnects the native association. */
  @Override
  public synchronized void close() {
    if (!connected) {
      return;
    }
    connected = false;
    List<Active> revoked = List.copyOf(active.values());
    active.clear();
    RuntimeException failure = null;
    for (Active current : revoked) {
      try {
        backend.deregister(current.handle);
      } catch (RuntimeException backendFailure) {
        failure = append(failure, backendFailure);
      } finally {
        current.owner.release();
      }
    }
    try {
      backend.disconnect();
    } catch (RuntimeException backendFailure) {
      failure = append(failure, backendFailure);
    }
    if (failure != null) {
      throw failure;
    }
  }

  private Active requireCurrent(Registration registration) {
    Objects.requireNonNull(registration, "registration");
    if (!identity.equals(registration.providerIdentity)) {
      throw new IllegalArgumentException("registration belongs to another RNIC provider");
    }
    Active current = active.get(registration.generation);
    if (!connected || current == null || current.registration != registration) {
      throw new IllegalStateException("RNIC registration generation is stale");
    }
    return current;
  }

  private static void validateHandle(
      NativeHandle handle,
      int length,
      long generation) {
    if (handle.address() == 0 || handle.length() != length
        || handle.localKey() < 0 || handle.remoteKey() < 0
        || handle.generation() != generation) {
      throw new IllegalArgumentException("native RNIC registration does not match its request");
    }
  }

  private void requireConnected() {
    if (!connected) {
      throw new IllegalStateException("RNIC provider is disconnected");
    }
  }

  private static RuntimeException append(
      RuntimeException current,
      RuntimeException added) {
    if (current == null) {
      return added;
    }
    current.addSuppressed(added);
    return current;
  }

  private static String digest(String domain, String canonical) {
    try {
      byte[] bytes = (domain + '\0' + canonical).getBytes(StandardCharsets.UTF_8);
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException impossible) {
      throw new IllegalStateException("SHA-256 is unavailable", impossible);
    }
  }
}
