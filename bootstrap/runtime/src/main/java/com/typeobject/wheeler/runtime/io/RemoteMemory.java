package com.typeobject.wheeler.runtime.io;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;

/** Bounded remote-memory placement profile with epoch-scoped advertisements. */
public final class RemoteMemory {
  private static final int MAX_REGION_BYTES = 16 * 1024 * 1024;

  /** Rights carried by one remote advertisement. */
  public enum Rights {
    READ,
    WRITE,
    READ_WRITE;

    private boolean permitsRead() {
      return this == READ || this == READ_WRITE;
    }

    private boolean permitsWrite() {
      return this == WRITE || this == READ_WRITE;
    }
  }

  /** Unforgeable region-issued remote range and epoch authority. */
  public static final class Advertisement {
    private final String regionIdentity;
    private final int offset;
    private final int length;
    private final Rights rights;
    private final long epoch;
    private final String identity;

    private Advertisement(
        String regionIdentity,
        int offset,
        int length,
        Rights rights,
        long epoch,
        String identity) {
      this.regionIdentity = regionIdentity;
      this.offset = offset;
      this.length = length;
      this.rights = rights;
      this.epoch = epoch;
      this.identity = identity;
    }

    public String regionIdentity() {
      return regionIdentity;
    }

    public int offset() {
      return offset;
    }

    public int length() {
      return length;
    }

    public Rights rights() {
      return rights;
    }

    public long epoch() {
      return epoch;
    }

    public String identity() {
      return identity;
    }
  }

  /** Exact one-sided placement, without peer or persistence claims. */
  public static final class Placement {
    private final String regionIdentity;
    private final String advertisementIdentity;
    private final long epoch;
    private final int offset;
    private final int length;
    private final String contentIdentity;
    private final String identity;

    private Placement(
        String regionIdentity,
        String advertisementIdentity,
        long epoch,
        int offset,
        int length,
        String contentIdentity,
        String identity) {
      this.regionIdentity = regionIdentity;
      this.advertisementIdentity = advertisementIdentity;
      this.epoch = epoch;
      this.offset = offset;
      this.length = length;
      this.contentIdentity = contentIdentity;
      this.identity = identity;
    }

    public String regionIdentity() {
      return regionIdentity;
    }

    public String advertisementIdentity() {
      return advertisementIdentity;
    }

    public long epoch() {
      return epoch;
    }

    public int offset() {
      return offset;
    }

    public int length() {
      return length;
    }

    public String contentIdentity() {
      return contentIdentity;
    }

    public String identity() {
      return identity;
    }
  }

  /** Peer protocol acknowledgement of one exact placement. */
  public static final class PeerAcknowledgement {
    private final Placement placement;
    private final String evidenceIdentity;
    private final String identity;

    private PeerAcknowledgement(
        Placement placement, String evidenceIdentity, String identity) {
      this.placement = placement;
      this.evidenceIdentity = evidenceIdentity;
      this.identity = identity;
    }

    public Placement placement() {
      return placement;
    }

    public String evidenceIdentity() {
      return evidenceIdentity;
    }

    public String identity() {
      return identity;
    }
  }

  /** Peer application acceptance after protocol acknowledgement. */
  public static final class PeerApplication {
    private final PeerAcknowledgement acknowledgement;
    private final String evidenceIdentity;
    private final String identity;

    private PeerApplication(
        PeerAcknowledgement acknowledgement, String evidenceIdentity, String identity) {
      this.acknowledgement = acknowledgement;
      this.evidenceIdentity = evidenceIdentity;
      this.identity = identity;
    }

    public PeerAcknowledgement acknowledgement() {
      return acknowledgement;
    }

    public String evidenceIdentity() {
      return evidenceIdentity;
    }

    public String identity() {
      return identity;
    }
  }

  /** Remote persistence evidence after peer application acceptance. */
  public static final class Persistence {
    private final PeerApplication application;
    private final String evidenceIdentity;
    private final String identity;

    private Persistence(
        PeerApplication application, String evidenceIdentity, String identity) {
      this.application = application;
      this.evidenceIdentity = evidenceIdentity;
      this.identity = identity;
    }

    public PeerApplication application() {
      return application;
    }

    public String evidenceIdentity() {
      return evidenceIdentity;
    }

    public String identity() {
      return identity;
    }
  }

  private final String identity;
  private final byte[] bytes;
  private long epoch = 1;
  private boolean connected = true;

  /** Creates one fixed remote region. */
  public RemoteMemory(String identity, int length) {
    this.identity = visibleName(identity, "remote region identity");
    if (length < 1 || length > MAX_REGION_BYTES) {
      throw new IllegalArgumentException("remote region length must be between 1 and 16 MiB");
    }
    bytes = new byte[length];
  }

  /** Advertises one bounded range at the current revocation epoch. */
  public synchronized Advertisement advertise(int offset, int length, Rights rights) {
    requireConnected();
    Objects.requireNonNull(rights, "rights");
    checkRange(offset, length, bytes.length, "advertisement");
    String canonical = identity + '\0' + offset + '\0' + length + '\0' + rights + '\0' + epoch;
    return new Advertisement(identity, offset, length, rights, epoch, digest(
        "wheeler-remote-advertisement-1", canonical));
  }

  /** Revokes every current advertisement before publishing the next epoch. */
  public synchronized long revoke() {
    requireConnected();
    return nextEpoch();
  }

  /** Disconnects the remote association and revokes every outstanding advertisement. */
  public synchronized long disconnect() {
    requireConnected();
    long next = nextEpoch();
    connected = false;
    return next;
  }

  /** Reconnects under a fresh epoch without restoring any prior authority. */
  public synchronized long reconnect() {
    if (connected) {
      throw new IllegalStateException("remote association is already connected");
    }
    long next = nextEpoch();
    connected = true;
    return next;
  }

  /** Prepares one one-sided placement while capturing its source owner. */
  public IoRequest<Placement> place(
      Advertisement advertisement, int relativeOffset, OwnedIoBuffer source) {
    Objects.requireNonNull(advertisement, "advertisement");
    Objects.requireNonNull(source, "source");
    int sourceLength;
    String contentIdentity;
    synchronized (source) {
      sourceLength = source.length();
      validateCurrent(advertisement, true);
      checkRange(relativeOffset, sourceLength, advertisement.length, "placement");
      contentIdentity = sha256(source.snapshot());
      source.hold();
    }
    String requestIdentity = "rdma-place:" + advertisement.identity + ':' + relativeOffset;
    try {
      return IoRequest.prepare(
          requestIdentity,
          Math.max(1, sourceLength),
          () -> placeHeld(
              advertisement,
              relativeOffset,
              source,
              sourceLength,
              contentIdentity),
          source::release);
    } catch (RuntimeException failure) {
      source.release();
      throw failure;
    }
  }

  /** Reads one currently advertised range for semantic conformance. */
  public synchronized byte[] read(Advertisement advertisement) {
    validateCurrent(advertisement, false);
    byte[] result = new byte[advertisement.length];
    System.arraycopy(bytes, advertisement.offset, result, 0, result.length);
    return result;
  }

  /** Issues peer acknowledgement from exact backend evidence. */
  public synchronized PeerAcknowledgement acknowledge(
      Placement placement, String evidenceIdentity) {
    validatePlacement(placement);
    String evidence = hash(evidenceIdentity, "peer acknowledgement evidence");
    return new PeerAcknowledgement(
        placement,
        evidence,
        digest("wheeler-remote-peer-acknowledgement-1", placement.identity + '\0' + evidence));
  }

  /** Issues peer application acceptance after acknowledgement. */
  public synchronized PeerApplication apply(
      PeerAcknowledgement acknowledgement, String evidenceIdentity) {
    Objects.requireNonNull(acknowledgement, "acknowledgement");
    validatePlacement(acknowledgement.placement);
    String evidence = hash(evidenceIdentity, "peer application evidence");
    return new PeerApplication(
        acknowledgement,
        evidence,
        digest("wheeler-remote-peer-application-1", acknowledgement.identity + '\0' + evidence));
  }

  /** Issues remote persistence after peer application and matching backend evidence. */
  public synchronized Persistence persist(
      PeerApplication application, String evidenceIdentity) {
    Objects.requireNonNull(application, "application");
    validatePlacement(application.acknowledgement.placement);
    String evidence = hash(evidenceIdentity, "remote persistence evidence");
    return new Persistence(
        application,
        evidence,
        digest("wheeler-remote-persistence-1", application.identity + '\0' + evidence));
  }

  private synchronized IoProviderResult<Placement> placeHeld(
      Advertisement advertisement,
      int relativeOffset,
      OwnedIoBuffer source,
      int sourceLength,
      String contentIdentity) {
    if (!connected
        || !advertisement.regionIdentity.equals(identity)
        || advertisement.epoch != epoch) {
      return IoProviderResult.uncertain(
          "rdma-connection-or-revocation:" + advertisement.identity.substring(0, 32), 0);
    }
    if (!advertisement.rights.permitsWrite()) {
      return IoProviderResult.failure("remote-advertisement-is-not-writable", 0);
    }
    int absoluteOffset = Math.addExact(advertisement.offset, relativeOffset);
    source.copyTo(0, bytes, absoluteOffset, sourceLength);
    String canonical = advertisement.identity + '\0' + absoluteOffset + '\0'
        + sourceLength + '\0' + contentIdentity;
    String placementIdentity = digest("wheeler-remote-placement-1", canonical);
    return IoProviderResult.success(new Placement(
        identity,
        advertisement.identity,
        epoch,
        absoluteOffset,
        sourceLength,
        contentIdentity,
        placementIdentity), sourceLength);
  }

  private synchronized void validateCurrent(Advertisement advertisement, boolean write) {
    requireConnected();
    if (!advertisement.regionIdentity.equals(identity)) {
      throw new IllegalArgumentException("advertisement belongs to another remote region");
    }
    if (advertisement.epoch != epoch) {
      throw new IllegalStateException("remote advertisement epoch is stale");
    }
    if (write ? !advertisement.rights.permitsWrite() : !advertisement.rights.permitsRead()) {
      throw new IllegalStateException("remote advertisement lacks the requested right");
    }
    String canonical = identity + '\0' + advertisement.offset + '\0'
        + advertisement.length + '\0' + advertisement.rights + '\0' + advertisement.epoch;
    String expected = digest("wheeler-remote-advertisement-1", canonical);
    if (!expected.equals(advertisement.identity)) {
      throw new IllegalArgumentException("remote advertisement identity mismatch");
    }
  }

  private void validatePlacement(Placement placement) {
    Objects.requireNonNull(placement, "placement");
    if (!placement.regionIdentity.equals(identity) || placement.epoch != epoch) {
      throw new IllegalStateException("remote placement is outside the current epoch");
    }
    String canonical = placement.advertisementIdentity + '\0' + placement.offset + '\0'
        + placement.length + '\0' + placement.contentIdentity;
    String expected = digest("wheeler-remote-placement-1", canonical);
    if (!expected.equals(placement.identity)) {
      throw new IllegalArgumentException("remote placement identity mismatch");
    }
  }

  private long nextEpoch() {
    if (epoch == Long.MAX_VALUE) {
      throw new IllegalStateException("remote advertisement epoch exhausted");
    }
    return ++epoch;
  }

  private void requireConnected() {
    if (!connected) {
      throw new IllegalStateException("remote association is disconnected");
    }
  }

  private static void checkRange(int offset, int length, int limit, String field) {
    if (offset < 0 || length < 1 || offset > limit - length) {
      throw new IllegalArgumentException(field + " range is out of bounds");
    }
  }

  private static String visibleName(String value, String field) {
    Objects.requireNonNull(value, field);
    if (value.isBlank() || value.length() > 128 || !value.equals(value.trim())) {
      throw new IllegalArgumentException(field + " must be 1..128 visible ASCII bytes");
    }
    for (int index = 0; index < value.length(); index++) {
      char scalar = value.charAt(index);
      if (scalar < 0x21 || scalar > 0x7e) {
        throw new IllegalArgumentException(field + " must use visible ASCII");
      }
    }
    return value;
  }

  private static String hash(String value, String field) {
    Objects.requireNonNull(value, field);
    if (!value.matches("[0-9a-f]{64}")) {
      throw new IllegalArgumentException(field + " must be lowercase SHA-256");
    }
    return value;
  }

  private static String digest(String domain, String canonical) {
    return sha256((domain + '\0' + canonical).getBytes(StandardCharsets.UTF_8));
  }

  private static String sha256(byte[] value) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }
}
