package com.typeobject.wheeler.runtime.io;

import com.typeobject.wheeler.runtime.io.DurabilityEvidence.Source;
import com.typeobject.wheeler.runtime.io.DurabilityReceipt.Kind;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.OpenOption;
import java.nio.file.StandardOpenOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;

/** Bounded native positional-file capability beneath the portable request lifecycle. */
public final class NativePositionalFile implements AutoCloseable {
  /** Rights fixed at capability construction. */
  public enum Rights {
    READ_ONLY,
    READ_WRITE
  }

  /** Successful positional read with exact request and buffer coordinates. */
  public static final class ReadCompleted {
    private final OwnedIoBuffer buffer;
    private final long position;
    private final int bufferOffset;
    private final int bytesRead;
    private final String operationIdentity;

    private ReadCompleted(
        OwnedIoBuffer buffer,
        long position,
        int bufferOffset,
        int bytesRead,
        String operationIdentity) {
      this.buffer = buffer;
      this.position = position;
      this.bufferOffset = bufferOffset;
      this.bytesRead = bytesRead;
      this.operationIdentity = operationIdentity;
    }

    public OwnedIoBuffer buffer() {
      return buffer;
    }

    public long position() {
      return position;
    }

    public int bufferOffset() {
      return bufferOffset;
    }

    public int bytesRead() {
      return bytesRead;
    }

    public String operationIdentity() {
      return operationIdentity;
    }
  }

  /** Successful positional write with exact request and buffer coordinates. */
  public static final class WriteCompleted {
    private final NativePositionalFile owner;
    private final OwnedIoBuffer buffer;
    private final long position;
    private final int bufferOffset;
    private final int bytesWritten;
    private final String operationIdentity;

    private WriteCompleted(
        NativePositionalFile owner,
        OwnedIoBuffer buffer,
        long position,
        int bufferOffset,
        int bytesWritten,
        String operationIdentity) {
      this.owner = owner;
      this.buffer = buffer;
      this.position = position;
      this.bufferOffset = bufferOffset;
      this.bytesWritten = bytesWritten;
      this.operationIdentity = operationIdentity;
    }

    public OwnedIoBuffer buffer() {
      return buffer;
    }

    public long position() {
      return position;
    }

    public int bufferOffset() {
      return bufferOffset;
    }

    public int bytesWritten() {
      return bytesWritten;
    }

    public String operationIdentity() {
      return operationIdentity;
    }
  }

  private static final long MAX_CAPABILITY_BYTES = 16L * 1024 * 1024;

  private final String identity;
  private final Rights rights;
  private final long maximumBytes;
  private final int alignment;
  private final boolean direct;
  private final FileChannel channel;
  private final AtomicInteger activeRequests = new AtomicInteger();
  private boolean closed;

  private NativePositionalFile(
      String identity,
      Rights rights,
      long maximumBytes,
      int alignment,
      boolean direct,
      FileChannel channel) {
    this.identity = DurabilitySubject.visibleAscii("identity", identity, 160, false);
    this.rights = Objects.requireNonNull(rights, "rights");
    if (maximumBytes < 1 || MAX_CAPABILITY_BYTES < maximumBytes) {
      throw new IllegalArgumentException("native file extent must be 1 byte through 16 MiB");
    }
    if (alignment < 1 || 4_096 < alignment || Integer.bitCount(alignment) != 1) {
      throw new IllegalArgumentException("native file alignment must be a power of two up to 4096");
    }
    this.maximumBytes = maximumBytes;
    this.alignment = alignment;
    this.direct = direct;
    this.channel = Objects.requireNonNull(channel, "channel");
  }

  /** Opens one physical file without following a symbolic-link final component. */
  public static NativePositionalFile open(
      String identity, Path path, Rights rights, long maximumBytes) throws IOException {
    return open(identity, path, rights, maximumBytes, 1, false);
  }

  /** Opens one required host direct-I/O capability with exact alignment. */
  public static NativePositionalFile openDirect(
      String identity,
      Path path,
      Rights rights,
      long maximumBytes,
      int alignment) throws IOException {
    return open(identity, path, rights, maximumBytes, alignment, true);
  }

  private static NativePositionalFile open(
      String identity,
      Path path,
      Rights rights,
      long maximumBytes,
      int alignment,
      boolean direct) throws IOException {
    DurabilitySubject.visibleAscii("identity", identity, 160, false);
    Objects.requireNonNull(path, "path");
    Objects.requireNonNull(rights, "rights");
    if (maximumBytes < 1 || MAX_CAPABILITY_BYTES < maximumBytes) {
      throw new IllegalArgumentException("native file extent must be 1 byte through 16 MiB");
    }
    if (alignment < 1 || 4_096 < alignment || Integer.bitCount(alignment) != 1) {
      throw new IllegalArgumentException("native file alignment must be a power of two up to 4096");
    }
    Path normalized = path.toAbsolutePath().normalize();
    if (Files.isSymbolicLink(normalized)) {
      throw new IOException("native file capability rejects symbolic links");
    }
    Set<OpenOption> options = new HashSet<>();
    options.add(StandardOpenOption.READ);
    options.add(LinkOption.NOFOLLOW_LINKS);
    if (rights == Rights.READ_WRITE) {
      options.add(StandardOpenOption.CREATE);
      options.add(StandardOpenOption.WRITE);
    }
    if (direct) {
      options.add(directOpenOption());
    }
    FileChannel channel = FileChannel.open(normalized, options);
    try {
      if (channel.size() > maximumBytes) {
        throw new IOException("native file exceeds its capability extent");
      }
      return new NativePositionalFile(
          identity, rights, maximumBytes, alignment, direct, channel);
    } catch (Throwable failure) {
      channel.close();
      throw failure;
    }
  }

  /** Prepares a positional read without touching the file or destination. */
  public synchronized IoRequest<ReadCompleted> readAt(
      long position, OwnedIoBuffer destination, int bufferOffset, int length) {
    requireOpen();
    Objects.requireNonNull(destination, "destination");
    checkBufferRange(destination, bufferOffset, length);
    checkFileRange(position, length);
    checkAlignment(position, bufferOffset, length);
    String operationIdentity = operationIdentity("read", position, bufferOffset, length);
    destination.hold();
    activeRequests.incrementAndGet();
    try {
      return IoRequest.prepare(
          operationIdentity,
          Math.max(1, length),
          () -> executeRead(position, destination, bufferOffset, length, operationIdentity),
          () -> release(destination));
    } catch (RuntimeException failure) {
      release(destination);
      throw failure;
    }
  }

  /** Prepares a complete positional write without touching the file or source. */
  public synchronized IoRequest<WriteCompleted> writeAt(
      long position, OwnedIoBuffer source, int bufferOffset, int length) {
    requireOpen();
    if (rights != Rights.READ_WRITE) {
      throw new IllegalStateException("native file capability is read-only");
    }
    Objects.requireNonNull(source, "source");
    checkBufferRange(source, bufferOffset, length);
    checkFileRange(position, length);
    checkAlignment(position, bufferOffset, length);
    String operationIdentity = operationIdentity("write", position, bufferOffset, length);
    source.hold();
    activeRequests.incrementAndGet();
    try {
      return IoRequest.prepare(
          operationIdentity,
          Math.max(1, length),
          () -> executeWrite(position, source, bufferOffset, length, operationIdentity),
          () -> release(source));
    } catch (RuntimeException failure) {
      release(source);
      throw failure;
    }
  }

  /** Issues operation-completion evidence for one exact successful native write. */
  public DurabilityReceipt writeCompleted(
      WriteCompleted completed,
      DurabilitySubject subject,
      DurabilityProfile profile) {
    Objects.requireNonNull(completed, "completed");
    Objects.requireNonNull(subject, "subject");
    if (profile.failureModel() != DurabilityProfile.FailureModel.PROCESS_CRASH
        || profile.replicas() != 1
        || profile.quorum() != 1
        || !profile.assumptions().contains("filechannel-force-contract")) {
      throw new IllegalArgumentException(
          "native file receipts require the bounded process-crash profile");
    }
    if (completed.owner != this
        || !subject.resourceIdentity().equals(identity)
        || subject.offset() != completed.position()
        || subject.length() != completed.bytesWritten()) {
      throw new IllegalArgumentException("native write does not match durability subject");
    }
    DurabilityEvidence evidence = new DurabilityEvidence(
        Source.OPERATION_COMPLETION,
        digest("native-write-completion-1\n" + completed.operationIdentity() + "\n"
            + subject.contentIdentity() + "\n"),
        "native-positional-write-completed");
    return DurabilityReceiptIssuer.writeCompleted(subject, profile, evidence);
  }

  /** Forces prior completed data and promotes only to data-stable evidence. */
  public synchronized DurabilityReceipt forceData(DurabilityReceipt prior) throws IOException {
    requirePrior(prior, Kind.WRITE_COMPLETED);
    requireOpen();
    channel.force(false);
    return DurabilityReceiptIssuer.promote(
        prior,
        Kind.DATA_STABLE,
        new DurabilityEvidence(
            Source.DATA_FLUSH,
            digest("native-data-force-1\n" + prior.identity() + "\n"),
            "native-file-data-force-completed"));
  }

  /** Forces data and metadata and promotes only a prior data-stable receipt. */
  public synchronized DurabilityReceipt forceMetadata(DurabilityReceipt prior) throws IOException {
    requirePrior(prior, Kind.DATA_STABLE);
    requireOpen();
    channel.force(true);
    return DurabilityReceiptIssuer.promote(
        prior,
        Kind.FILE_STABLE,
        new DurabilityEvidence(
            Source.METADATA_FLUSH,
            digest("native-metadata-force-1\n" + prior.identity() + "\n"),
            "native-file-metadata-force-completed"));
  }

  public String identity() {
    return identity;
  }

  public boolean direct() {
    return direct;
  }

  public int alignment() {
    return alignment;
  }

  public synchronized long size() throws IOException {
    requireOpen();
    return channel.size();
  }

  @Override
  public synchronized void close() throws IOException {
    if (closed) {
      return;
    }
    if (activeRequests.get() != 0) {
      throw new IllegalStateException("native file has unreaped request resources");
    }
    closed = true;
    channel.close();
  }

  private IoProviderResult<ReadCompleted> executeRead(
      long position,
      OwnedIoBuffer destination,
      int bufferOffset,
      int length,
      String operationIdentity) {
    byte[] bytes = new byte[length];
    int progress = 0;
    try {
      ByteBuffer target = direct ? ByteBuffer.allocateDirect(length) : ByteBuffer.wrap(bytes);
      while (target.hasRemaining()) {
        int read = channel.read(target, position + progress);
        if (read < 0) {
          break;
        }
        if (read == 0) {
          break;
        }
        progress += read;
      }
      if (direct) {
        target.flip();
        target.get(bytes, 0, progress);
      }
      destination.copyFrom(bytes, 0, bufferOffset, progress);
      return IoProviderResult.success(
          new ReadCompleted(destination, position, bufferOffset, progress, operationIdentity),
          progress);
    } catch (IOException failure) {
      return IoProviderResult.failure("native positional read failed", progress);
    }
  }

  private IoProviderResult<WriteCompleted> executeWrite(
      long position,
      OwnedIoBuffer source,
      int bufferOffset,
      int length,
      String operationIdentity) {
    byte[] bytes = new byte[length];
    source.copyTo(bufferOffset, bytes, 0, length);
    int progress = 0;
    try {
      ByteBuffer input;
      if (direct) {
        input = ByteBuffer.allocateDirect(length);
        input.put(bytes);
        input.flip();
      } else {
        input = ByteBuffer.wrap(bytes);
      }
      while (input.hasRemaining()) {
        int written = channel.write(input, position + progress);
        if (written < 1) {
          return IoProviderResult.failure("native positional write made no progress", progress);
        }
        progress += written;
      }
      return IoProviderResult.success(
          new WriteCompleted(this, source, position, bufferOffset, progress, operationIdentity),
          progress);
    } catch (IOException failure) {
      return IoProviderResult.failure("native positional write failed", progress);
    }
  }

  private synchronized void release(OwnedIoBuffer buffer) {
    buffer.release();
    if (activeRequests.decrementAndGet() < 0) {
      throw new IllegalStateException("native file request accounting underflow");
    }
  }

  private void checkBufferRange(OwnedIoBuffer buffer, int offset, int length) {
    int capacity = buffer.length();
    if (offset < 0 || length < 0 || capacity < offset || capacity - offset < length) {
      throw new IllegalArgumentException("buffer range is outside its capability");
    }
  }

  private void checkFileRange(long position, int length) {
    if (position < 0 || length < 0 || maximumBytes < position
        || maximumBytes - position < length) {
      throw new IllegalArgumentException("file range is outside its capability");
    }
  }

  private void checkAlignment(long position, int bufferOffset, int length) {
    if (direct && (position % alignment != 0
        || bufferOffset % alignment != 0
        || length % alignment != 0)) {
      throw new IllegalArgumentException(
          "direct file position, buffer offset, and length must be aligned");
    }
  }

  private String operationIdentity(String kind, long position, int offset, int length) {
    return identity + ":" + kind + ":" + position + ":" + offset + ":" + length;
  }

  private void requireOpen() {
    if (closed) {
      throw new IllegalStateException("native file capability is closed");
    }
  }

  private void requirePrior(DurabilityReceipt prior, Kind expected) {
    Objects.requireNonNull(prior, "prior");
    if (prior.kind() != expected || !prior.subject().resourceIdentity().equals(identity)) {
      throw new IllegalArgumentException("durability receipt is not the required native-file prior");
    }
  }

  private static OpenOption directOpenOption() throws IOException {
    try {
      Class<?> type = Class.forName("com.sun.nio.file.ExtendedOpenOption");
      Object[] constants = type.getEnumConstants();
      if (constants != null) {
        for (Object constant : constants) {
          if (constant.toString().equals("DIRECT") && constant instanceof OpenOption option) {
            return option;
          }
        }
      }
      throw new IOException("host JDK exposes no required direct-I/O option");
    } catch (ClassNotFoundException failure) {
      throw new IOException("host JDK exposes no required direct-I/O option", failure);
    }
  }

  private static String digest(String canonical) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
          .digest(canonical.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException impossible) {
      throw new IllegalStateException("SHA-256 is unavailable", impossible);
    }
  }
}
