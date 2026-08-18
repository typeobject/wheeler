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
    REMOTE_READ_WRITE;

    private boolean permitsRead() {
      return this == REMOTE_READ || this == REMOTE_READ_WRITE;
    }

    private boolean permitsWrite() {
      return this == REMOTE_WRITE || this == REMOTE_READ_WRITE;
    }

    private boolean permitsAtomic() {
      return this == REMOTE_READ_WRITE;
    }
  }

  /** Opaque native registration fields returned by an RNIC backend. */
  public record NativeHandle(
      long address,
      int length,
      long localKey,
      long remoteKey,
      long generation) {}

  /** Raw backend evidence for one ordered peer stage. */
  public record NativePeerEvidence(
      long generation,
      String predecessorIdentity,
      String evidenceIdentity) {}

  /** Raw backend completion for one native 64-bit compare-and-swap. */
  public record NativeAtomicCompletion(
      long generation,
      int relativeOffset,
      long expected,
      long update,
      long observed,
      String evidenceIdentity) {}

  /** Raw backend completion for one native one-sided read. */
  public record NativeReadCompletion(
      long generation,
      int relativeOffset,
      int bytes,
      String evidenceIdentity) {}

  /** Raw backend completion for one native one-sided write. */
  public record NativeWriteCompletion(
      long generation,
      int relativeOffset,
      int bytes,
      String evidenceIdentity) {}

  /** Host RNIC registration and disconnect boundary. */
  public interface Backend {
    /** Pins or maps the held owner and returns its exact native registration. */
    NativeHandle register(
        OwnedIoBuffer owner,
        int offset,
        int length,
        Rights rights,
        long generation);

    /** Performs one native 64-bit compare-and-swap against a current registration. */
    IoProviderResult<NativeAtomicCompletion> compareAndSwap64(
        long operation,
        NativeHandle target,
        int relativeOffset,
        long expected,
        long update);

    /** Performs one native one-sided read against a current registration. */
    IoProviderResult<NativeReadCompletion> read(
        long operation,
        NativeHandle source,
        int relativeOffset,
        OwnedIoBuffer destination,
        int destinationOffset,
        int length);

    /** Performs one native one-sided write against a current registration. */
    IoProviderResult<NativeWriteCompletion> write(
        long operation,
        NativeHandle target,
        int relativeOffset,
        OwnedIoBuffer source,
        int sourceOffset,
        int length);

    /** Obtains peer protocol acknowledgement for one exact write completion. */
    IoProviderResult<NativePeerEvidence> acknowledge(
        long operation,
        NativeHandle target,
        String writeCompletionIdentity);

    /** Obtains peer application acceptance after exact acknowledgement. */
    IoProviderResult<NativePeerEvidence> apply(
        long operation,
        NativeHandle target,
        String acknowledgementIdentity);

    /** Obtains profile-bound remote persistence after peer application. */
    IoProviderResult<NativePeerEvidence> persist(
        long operation,
        NativeHandle target,
        String applicationIdentity,
        String profileIdentity);

    /** Requests cancellation of one started native operation. */
    void cancel(long operation);

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

  @FunctionalInterface
  private interface PeerAction {
    IoProviderResult<NativePeerEvidence> execute(
        long operation,
        NativeHandle handle,
        String predecessorIdentity);
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
  private long operation;
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

  /** Prepares peer acknowledgement of one exact native write completion. */
  public synchronized IoRequest<NativeRnicPeerEvidence.Acknowledgement> acknowledge(
      NativeRnicCompletion.Write write) {
    Objects.requireNonNull(write, "write");
    Registration registration = write.registration();
    Active current = requireCurrent(registration);
    long currentOperation = nextOperation();
    return IoRequest.prepare(
        "native-rnic-ack:" + currentOperation + ':' + write.identity(),
        1,
        () -> executePeer(
            currentOperation,
            registration,
            current.handle,
            write.identity(),
            backend::acknowledge).mapSuccess(evidence -> {
              String identity = digest(
                  "wheeler-native-rnic-peer-acknowledgement-1",
                  write.identity() + '\0' + evidence.evidenceIdentity());
              return NativeRnicPeerEvidence.acknowledgement(
                  write, evidence.evidenceIdentity(), identity);
            }),
        () -> {},
        () -> backend.cancel(currentOperation));
  }

  /** Prepares peer application acceptance after exact acknowledgement. */
  public synchronized IoRequest<NativeRnicPeerEvidence.Application> apply(
      NativeRnicPeerEvidence.Acknowledgement acknowledgement) {
    Objects.requireNonNull(acknowledgement, "acknowledgement");
    Registration registration = NativeRnicPeerEvidence.registration(acknowledgement);
    Active current = requireCurrent(registration);
    long currentOperation = nextOperation();
    return IoRequest.prepare(
        "native-rnic-apply:" + currentOperation + ':' + acknowledgement.identity(),
        1,
        () -> executePeer(
            currentOperation,
            registration,
            current.handle,
            acknowledgement.identity(),
            backend::apply).mapSuccess(evidence -> {
              String identity = digest(
                  "wheeler-native-rnic-peer-application-1",
                  acknowledgement.identity() + '\0' + evidence.evidenceIdentity());
              return NativeRnicPeerEvidence.application(
                  acknowledgement, evidence.evidenceIdentity(), identity);
            }),
        () -> {},
        () -> backend.cancel(currentOperation));
  }

  /** Prepares profile-bound remote persistence after peer application. */
  public synchronized IoRequest<NativeRnicPeerEvidence.Persistence> persist(
      NativeRnicPeerEvidence.Application application,
      String profileIdentity) {
    Objects.requireNonNull(application, "application");
    if (!validHash(profileIdentity)) {
      throw new IllegalArgumentException("remote-persistence profile must be lowercase SHA-256");
    }
    Registration registration = NativeRnicPeerEvidence.registration(application);
    Active current = requireCurrent(registration);
    long currentOperation = nextOperation();
    return IoRequest.prepare(
        "native-rnic-persist:" + currentOperation + ':' + application.identity(),
        1,
        () -> executePeer(
            currentOperation,
            registration,
            current.handle,
            application.identity(),
            (operation, handle, predecessor) -> backend.persist(
                operation, handle, predecessor, profileIdentity)).mapSuccess(evidence -> {
                  String identity = digest(
                      "wheeler-native-rnic-remote-persistence-1",
                      application.identity() + '\0' + profileIdentity
                          + '\0' + evidence.evidenceIdentity());
                  return NativeRnicPeerEvidence.persistence(
                      application, profileIdentity, evidence.evidenceIdentity(), identity);
                }),
        () -> {},
        () -> backend.cancel(currentOperation));
  }

  /** Prepares one native 64-bit compare-and-swap without running backend work. */
  public synchronized IoRequest<NativeRnicCompletion.Atomic> compareAndSwap64(
      Registration target,
      int relativeOffset,
      long expected,
      long update) {
    Active current = requireCurrent(target);
    if (!target.rights.permitsAtomic()) {
      throw new IllegalStateException("RNIC registration does not permit remote atomics");
    }
    if (relativeOffset < 0 || target.length - Long.BYTES < relativeOffset
        || ((current.handle.address() + relativeOffset) & (Long.BYTES - 1)) != 0) {
      throw new IllegalArgumentException("native RNIC atomic range or alignment is invalid");
    }

    long currentOperation = nextOperation();
    return IoRequest.prepare(
        "native-rnic-cas64:" + currentOperation + ':' + target.identity + ':' + relativeOffset
            + ':' + expected + ':' + update,
        Long.BYTES,
        () -> executeCompareAndSwap64(
            currentOperation, target, current.handle, relativeOffset, expected, update),
        () -> {},
        () -> backend.cancel(currentOperation));
  }

  /** Prepares one native one-sided read without running backend work. */
  public synchronized IoRequest<NativeRnicCompletion.Read> read(
      Registration source,
      int relativeOffset,
      OwnedIoBuffer destination,
      int destinationOffset,
      int length) {
    Active current = requireCurrent(source);
    if (!source.rights.permitsRead()) {
      throw new IllegalStateException("RNIC registration does not permit remote reads");
    }
    Objects.requireNonNull(destination, "destination");
    int destinationLength = destination.length();
    if (relativeOffset < 0 || length < 1 || source.length < relativeOffset
        || source.length - relativeOffset < length || destinationOffset < 0
        || destinationLength < destinationOffset
        || destinationLength - destinationOffset < length) {
      throw new IllegalArgumentException("native RNIC read range is out of bounds");
    }

    long currentOperation = nextOperation();
    destination.hold();
    try {
      return IoRequest.prepare(
          "native-rnic-read:" + currentOperation + ':' + source.identity
              + ':' + relativeOffset + ':' + length,
          length,
          () -> executeRead(
              currentOperation,
              source,
              current.handle,
              relativeOffset,
              destination,
              destinationOffset,
              length),
          destination::release,
          () -> backend.cancel(currentOperation));
    } catch (RuntimeException failure) {
      destination.release();
      throw failure;
    }
  }

  /** Prepares one native one-sided write without running backend work. */
  public synchronized IoRequest<NativeRnicCompletion.Write> write(
      Registration target,
      int relativeOffset,
      OwnedIoBuffer source,
      int sourceOffset,
      int length) {
    Active current = requireCurrent(target);
    if (!target.rights.permitsWrite()) {
      throw new IllegalStateException("RNIC registration does not permit remote writes");
    }
    Objects.requireNonNull(source, "source");
    byte[] sourceBytes = source.snapshot();
    int sourceLength = sourceBytes.length;
    if (relativeOffset < 0 || length < 1 || target.length < relativeOffset
        || target.length - relativeOffset < length || sourceOffset < 0
        || sourceLength < sourceOffset || sourceLength - sourceOffset < length) {
      throw new IllegalArgumentException("native RNIC write range is out of bounds");
    }

    byte[] content = new byte[length];
    System.arraycopy(sourceBytes, sourceOffset, content, 0, length);
    String contentIdentity = sha256(content);
    long currentOperation = nextOperation();
    source.hold();
    try {
      return IoRequest.prepare(
          "native-rnic-write:" + currentOperation + ':' + target.identity
              + ':' + relativeOffset + ':' + length,
          length,
          () -> executeWrite(
              currentOperation,
              target,
              current.handle,
              relativeOffset,
              source,
              sourceOffset,
              length,
              contentIdentity),
          source::release,
          () -> backend.cancel(currentOperation));
    } catch (RuntimeException failure) {
      source.release();
      throw failure;
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

  private IoProviderResult<NativePeerEvidence> executePeer(
      long operation,
      Registration registration,
      NativeHandle handle,
      String predecessorIdentity,
      PeerAction action) {
    synchronized (this) {
      if (!isCurrent(registration)) {
        return IoProviderResult.uncertain("native-rnic-registration-became-stale", 0);
      }
    }

    IoProviderResult<NativePeerEvidence> result = Objects.requireNonNull(
        action.execute(operation, handle, predecessorIdentity),
        "native RNIC peer result");
    if (result.kind() != IoProviderResult.Kind.SUCCESS) {
      return carryFailure(result);
    }

    NativePeerEvidence evidence = Objects.requireNonNull(
        result.value(), "native RNIC peer evidence");
    synchronized (this) {
      if (!isCurrent(registration)) {
        return IoProviderResult.uncertain(
            "native-rnic-registration-became-stale", boundedProgress(result.progress(), 1));
      }
    }
    if (evidence.generation() != registration.generation
        || !predecessorIdentity.equals(evidence.predecessorIdentity())
        || !validHash(evidence.evidenceIdentity())
        || result.progress() != 1) {
      return IoProviderResult.uncertain(
          "native-rnic-peer-evidence-mismatch", boundedProgress(result.progress(), 1));
    }
    return result;
  }

  private IoProviderResult<NativeRnicCompletion.Atomic> executeCompareAndSwap64(
      long operation,
      Registration target,
      NativeHandle handle,
      int relativeOffset,
      long expected,
      long update) {
    synchronized (this) {
      if (!isCurrent(target)) {
        return IoProviderResult.uncertain("native-rnic-registration-became-stale", 0);
      }
    }

    IoProviderResult<NativeAtomicCompletion> result = Objects.requireNonNull(
        backend.compareAndSwap64(operation, handle, relativeOffset, expected, update),
        "native RNIC atomic result");
    if (result.kind() != IoProviderResult.Kind.SUCCESS) {
      return carryFailure(result);
    }

    NativeAtomicCompletion completion = Objects.requireNonNull(
        result.value(), "native RNIC atomic completion");
    synchronized (this) {
      if (!isCurrent(target)) {
        return IoProviderResult.uncertain(
            "native-rnic-registration-became-stale",
            boundedProgress(result.progress(), Long.BYTES));
      }
    }
    if (completion.generation() != target.generation
        || completion.relativeOffset() != relativeOffset
        || completion.expected() != expected
        || completion.update() != update
        || result.progress() != Long.BYTES
        || !validHash(completion.evidenceIdentity())) {
      return IoProviderResult.uncertain(
          "native-rnic-completion-mismatch",
          boundedProgress(result.progress(), Long.BYTES));
    }

    String canonical = target.identity + '\0' + relativeOffset + '\0' + expected
        + '\0' + update + '\0' + completion.observed() + '\0' + completion.evidenceIdentity();
    NativeRnicCompletion.Atomic completed = NativeRnicCompletion.atomic(
        target,
        relativeOffset,
        expected,
        update,
        completion.observed(),
        completion.evidenceIdentity(),
        digest("wheeler-native-rnic-cas64-completion-1", canonical));
    return IoProviderResult.success(completed, Long.BYTES);
  }

  private IoProviderResult<NativeRnicCompletion.Read> executeRead(
      long operation,
      Registration source,
      NativeHandle handle,
      int relativeOffset,
      OwnedIoBuffer destination,
      int destinationOffset,
      int length) {
    synchronized (this) {
      if (!isCurrent(source)) {
        return IoProviderResult.uncertain("native-rnic-registration-became-stale", 0);
      }
    }

    IoProviderResult<NativeReadCompletion> result = Objects.requireNonNull(
        backend.read(
            operation, handle, relativeOffset, destination, destinationOffset, length),
        "native RNIC read result");
    if (result.kind() != IoProviderResult.Kind.SUCCESS) {
      return carryFailure(result);
    }

    NativeReadCompletion completion = Objects.requireNonNull(
        result.value(), "native RNIC read completion");
    synchronized (this) {
      if (!isCurrent(source)) {
        return IoProviderResult.uncertain(
            "native-rnic-registration-became-stale", boundedProgress(completion.bytes(), length));
      }
    }
    if (completion.generation() != source.generation
        || completion.relativeOffset() != relativeOffset
        || completion.bytes() != length
        || result.progress() != length
        || !validHash(completion.evidenceIdentity())) {
      return IoProviderResult.uncertain(
          "native-rnic-completion-mismatch", boundedProgress(completion.bytes(), length));
    }

    byte[] content = new byte[length];
    destination.copyTo(destinationOffset, content, 0, length);
    String contentIdentity = sha256(content);
    String canonical = source.identity + '\0' + relativeOffset + '\0' + length
        + '\0' + contentIdentity + '\0' + completion.evidenceIdentity();
    NativeRnicCompletion.Read completed = NativeRnicCompletion.read(
        source,
        relativeOffset,
        length,
        contentIdentity,
        completion.evidenceIdentity(),
        digest("wheeler-native-rnic-read-completion-1", canonical));
    return IoProviderResult.success(completed, length);
  }

  private IoProviderResult<NativeRnicCompletion.Write> executeWrite(
      long operation,
      Registration target,
      NativeHandle handle,
      int relativeOffset,
      OwnedIoBuffer source,
      int sourceOffset,
      int length,
      String contentIdentity) {
    synchronized (this) {
      if (!isCurrent(target)) {
        return IoProviderResult.uncertain("native-rnic-registration-became-stale", 0);
      }
    }

    IoProviderResult<NativeWriteCompletion> result = Objects.requireNonNull(
        backend.write(operation, handle, relativeOffset, source, sourceOffset, length),
        "native RNIC write result");
    if (result.kind() != IoProviderResult.Kind.SUCCESS) {
      return carryFailure(result);
    }

    NativeWriteCompletion completion = Objects.requireNonNull(
        result.value(), "native RNIC write completion");
    synchronized (this) {
      if (!isCurrent(target)) {
        return IoProviderResult.uncertain(
            "native-rnic-registration-became-stale", boundedProgress(completion.bytes(), length));
      }
    }
    if (completion.generation() != target.generation
        || completion.relativeOffset() != relativeOffset
        || completion.bytes() != length
        || result.progress() != length
        || !validHash(completion.evidenceIdentity())) {
      return IoProviderResult.uncertain(
          "native-rnic-completion-mismatch", boundedProgress(completion.bytes(), length));
    }

    String canonical = target.identity + '\0' + relativeOffset + '\0' + length
        + '\0' + contentIdentity + '\0' + completion.evidenceIdentity();
    NativeRnicCompletion.Write completed = NativeRnicCompletion.write(
        target,
        relativeOffset,
        length,
        contentIdentity,
        completion.evidenceIdentity(),
        digest("wheeler-native-rnic-write-completion-1", canonical));
    return IoProviderResult.success(completed, length);
  }

  private static <T> IoProviderResult<T> carryFailure(IoProviderResult<?> result) {
    return switch (result.kind()) {
      case SUCCESS -> throw new IllegalArgumentException("expected nonsuccess RNIC result");
      case FAILURE -> IoProviderResult.failure(result.detail(), result.progress());
      case CANCELED_BEFORE_EFFECT -> IoProviderResult.canceledBeforeEffect(result.detail());
      case CANCELED_AFTER_PARTIAL_EFFECT ->
          IoProviderResult.canceledAfterPartial(result.detail(), result.progress());
      case UNCERTAIN -> IoProviderResult.uncertain(result.detail(), result.progress());
    };
  }

  private static long boundedProgress(long progress, long length) {
    return Math.max(0, Math.min(progress, length));
  }

  private static boolean validHash(String value) {
    return value != null && value.matches("[0-9a-f]{64}");
  }

  private long nextOperation() {
    if (operation == Long.MAX_VALUE) {
      throw new IllegalStateException("RNIC operation identity exhausted");
    }
    return ++operation;
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
    return sha256((domain + '\0' + canonical).getBytes(StandardCharsets.UTF_8));
  }

  private static String sha256(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException impossible) {
      throw new IllegalStateException("SHA-256 is unavailable", impossible);
    }
  }
}
