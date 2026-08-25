package com.typeobject.wheeler.packageformat;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;
import java.util.Set;

/** Canonical bounded application capsule codec and independent verifier. */
public final class ApplicationCapsule {
  public static final int SCHEMA_VERSION = 1;
  public static final int MAX_CAPSULE_BYTES = 32 * 1024 * 1024;
  public static final int MAX_ENTRIES = 128;
  public static final int MAX_RECEIPTS = 64;
  private static final int HEADER_BYTES = 32;
  private static final int MAX_METADATA_BYTES = 1024 * 1024;
  private static final int DIGEST_BYTES = 32;
  private static final byte[] MAGIC = {
      'W', 'H', 'L', 'C', 'A', 'P', 0, SCHEMA_VERSION
  };
  private static final Comparator<CapsuleEntry> ENTRY_ORDER = (left, right) -> {
    int kind = Integer.compare(left.kind().code(), right.kind().code());
    if (kind != 0) {
      return kind;
    }
    int name = Arrays.compareUnsigned(utf8(left.name()), utf8(right.name()));
    return name != 0 ? name : left.identity().compareTo(right.identity());
  };
  private static final Comparator<CapsulePackageReceipt> RECEIPT_ORDER =
      Comparator.comparing(CapsulePackageReceipt::coordinate)
          .thenComparing(CapsulePackageReceipt::variant)
          .thenComparing(CapsulePackageReceipt::instance);

  private final CapsuleRoot root;
  private final List<CapsulePackageReceipt> receipts;
  private final List<CapsuleEntry> entries;
  private final byte[] canonicalBytes;

  /** Stable framing magic consumed before allocation by embedded startup. */
  public static byte[] framingMagic() {
    return MAGIC.clone();
  }

  public ApplicationCapsule(
      CapsuleRoot root,
      List<CapsulePackageReceipt> receipts,
      List<CapsuleEntry> entries) {
    this.root = Objects.requireNonNull(root, "root");
    this.receipts = canonicalReceipts(receipts);
    this.entries = canonicalEntries(entries);
    requireRootBindings();
    canonicalBytes = encode();
  }

  public CapsuleRoot root() {
    return root;
  }

  public List<CapsulePackageReceipt> receipts() {
    return receipts;
  }

  public List<CapsuleEntry> entries() {
    return entries;
  }

  public String identity() {
    return CapsuleEntry.identity(canonicalBytes);
  }

  public byte[] canonicalBytes() {
    return canonicalBytes.clone();
  }

  private byte[] encode() {
    byte[] rootBytes = encodeRoot(root);
    List<byte[]> receiptBytes = receipts.stream().map(ApplicationCapsule::encodeReceipt).toList();
    int metadataLength = HEADER_BYTES + rootBytes.length;
    for (byte[] receipt : receiptBytes) {
      metadataLength = Math.addExact(metadataLength, receipt.length);
    }
    for (CapsuleEntry entry : entries) {
      metadataLength = Math.addExact(metadataLength, descriptorLength(entry));
    }
    if (metadataLength > MAX_METADATA_BYTES) {
      throw new PackageFormatException("Capsule metadata is oversized");
    }

    ArrayList<Integer> offsets = new ArrayList<>(entries.size());
    long cursor = metadataLength;
    for (CapsuleEntry entry : entries) {
      cursor = align(cursor, entry.alignment());
      if (cursor > Integer.MAX_VALUE) {
        throw new PackageFormatException("Capsule entry offset is oversized");
      }
      offsets.add((int) cursor);
      cursor = Math.addExact(cursor, entry.length());
      if (cursor > MAX_CAPSULE_BYTES) {
        throw new PackageFormatException("Capsule is oversized");
      }
    }
    int totalLength = Math.toIntExact(cursor);
    ByteArrayOutputStream output = new ByteArrayOutputStream(totalLength);
    output.writeBytes(MAGIC);
    writeInt(output, totalLength);
    writeInt(output, metadataLength);
    writeInt(output, receipts.size());
    writeInt(output, entries.size());
    writeLong(output, 0);
    output.writeBytes(rootBytes);
    receiptBytes.forEach(output::writeBytes);
    for (int index = 0; index < entries.size(); index++) {
      writeDescriptor(output, entries.get(index), offsets.get(index));
    }
    if (output.size() != metadataLength) {
      throw new IllegalStateException("Capsule metadata length disagrees with encoder");
    }
    for (int index = 0; index < entries.size(); index++) {
      while (output.size() < offsets.get(index)) {
        output.write(0);
      }
      output.writeBytes(entries.get(index).bytes());
    }
    return output.toByteArray();
  }

  public static ApplicationCapsule parse(byte[] bytes) {
    Objects.requireNonNull(bytes, "bytes");
    if (bytes.length < HEADER_BYTES || bytes.length > MAX_CAPSULE_BYTES) {
      throw new PackageFormatException("Invalid capsule length");
    }
    Reader input = new Reader(bytes);
    if (!Arrays.equals(MAGIC, input.bytes(MAGIC.length, "magic"))) {
      throw new PackageFormatException("Invalid capsule magic");
    }
    int totalLength = input.boundedInt(MAX_CAPSULE_BYTES, "total length");
    int metadataLength = input.boundedInt(MAX_METADATA_BYTES, "metadata length");
    int receiptCount = input.boundedInt(MAX_RECEIPTS, "receipt count");
    int entryCount = input.boundedInt(MAX_ENTRIES, "entry count");
    if (totalLength != bytes.length
        || metadataLength < HEADER_BYTES
        || metadataLength > totalLength
        || receiptCount == 0
        || entryCount == 0
        || input.longValue("reserved header") != 0) {
      throw new PackageFormatException("Invalid capsule header");
    }

    CapsuleRoot root = readRoot(input);
    ArrayList<CapsulePackageReceipt> receipts = new ArrayList<>(receiptCount);
    for (int index = 0; index < receiptCount; index++) {
      receipts.add(readReceipt(input));
    }
    ArrayList<EntryDescriptor> descriptors = new ArrayList<>(entryCount);
    for (int index = 0; index < entryCount; index++) {
      descriptors.add(readDescriptor(input));
    }
    if (input.position() != metadataLength) {
      throw new PackageFormatException("Capsule metadata length mismatch");
    }

    ArrayList<CapsuleEntry> entries = new ArrayList<>(entryCount);
    for (EntryDescriptor descriptor : descriptors) {
      long end = (long) descriptor.offset() + descriptor.length();
      if (descriptor.offset() < metadataLength || end > bytes.length) {
        throw new PackageFormatException("Capsule entry range escapes the capsule");
      }
      byte[] entryBytes = Arrays.copyOfRange(bytes, descriptor.offset(), Math.toIntExact(end));
      entries.add(new CapsuleEntry(
          descriptor.kind(),
          descriptor.name(),
          descriptor.identity(),
          descriptor.alignment(),
          descriptor.flags(),
          entryBytes));
    }
    ApplicationCapsule capsule = new ApplicationCapsule(root, receipts, entries);
    if (!Arrays.equals(bytes, capsule.canonicalBytes)) {
      throw new PackageFormatException("Capsule bytes are not canonical");
    }
    return capsule;
  }

  private void requireRootBindings() {
    long rootReceipts = receipts.stream()
        .filter(receipt -> receipt.instance().equals(root.packageInstance())
            && receipt.selectedExport().equals(root.target()))
        .count();
    if (rootReceipts != 1) {
      throw new PackageFormatException("Capsule root package receipt is missing or ambiguous");
    }
    long rootEntries = entries.stream()
        .filter(entry -> entry.kind() == CapsuleEntry.Kind.WBC
            && entry.name().equals(root.rootWbc())
            && (entry.flags() & CapsuleEntry.STARTUP) != 0)
        .count();
    long startupEntries = entries.stream()
        .filter(entry -> (entry.flags() & CapsuleEntry.STARTUP) != 0)
        .count();
    if (rootEntries != 1 || startupEntries != 1) {
      throw new PackageFormatException("Capsule has no unique root WBC entry");
    }
  }

  private static List<CapsulePackageReceipt> canonicalReceipts(
      List<CapsulePackageReceipt> source) {
    if (source == null || source.isEmpty() || source.size() > MAX_RECEIPTS) {
      throw new PackageFormatException("Invalid capsule receipt count");
    }
    ArrayList<CapsulePackageReceipt> result = new ArrayList<>(source);
    if (result.stream().anyMatch(Objects::isNull)) {
      throw new PackageFormatException("Null capsule receipt");
    }
    result.sort(RECEIPT_ORDER);
    Set<String> instances = new HashSet<>();
    for (CapsulePackageReceipt receipt : result) {
      if (!instances.add(receipt.instance())) {
        throw new PackageFormatException(
            "Duplicate capsule package instance " + receipt.instance());
      }
    }
    return List.copyOf(result);
  }

  private static List<CapsuleEntry> canonicalEntries(List<CapsuleEntry> source) {
    if (source == null || source.isEmpty() || source.size() > MAX_ENTRIES) {
      throw new PackageFormatException("Invalid capsule entry count");
    }
    ArrayList<CapsuleEntry> result = new ArrayList<>(source);
    if (result.stream().anyMatch(Objects::isNull)) {
      throw new PackageFormatException("Null capsule entry");
    }
    result.sort(ENTRY_ORDER);
    Set<String> names = new HashSet<>();
    for (CapsuleEntry entry : result) {
      if (!names.add(entry.name())) {
        throw new PackageFormatException("Duplicate capsule entry name " + entry.name());
      }
    }
    return List.copyOf(result);
  }

  private static byte[] encodeRoot(CapsuleRoot root) {
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    writeHash(output, root.packageInstance());
    writeString(output, root.target());
    writeString(output, root.rootWbc());
    writeString(output, root.entryFunction());
    writeHash(output, root.runtimeProfile());
    writeHash(output, root.bytecodeProfile());
    writeHash(output, root.proofProfile());
    writeHash(output, root.targetProfile());
    writeHash(output, root.platformAbi());
    writeHash(output, root.executionLimits());
    output.write(runtimeModeCode(root.runtimeMode()));
    output.write(0);
    writeShort(output, root.requiredCapabilities().size());
    root.requiredCapabilities().forEach(capability -> writeString(output, capability));
    return output.toByteArray();
  }

  private static CapsuleRoot readRoot(Reader input) {
    String packageInstance = input.hash("root package instance");
    String target = input.string(CapsuleRoot.MAX_NAME_BYTES, "root target");
    String rootWbc = input.string(CapsuleRoot.MAX_NAME_BYTES, "root WBC");
    String entryFunction = input.string(CapsuleRoot.MAX_NAME_BYTES, "entry function");
    String runtimeProfile = input.hash("runtime profile");
    String bytecodeProfile = input.hash("bytecode profile");
    String proofProfile = input.hash("proof profile");
    String targetProfile = input.hash("target profile");
    String platformAbi = input.hash("platform ABI");
    String executionLimits = input.hash("execution limits");
    NativeImagePlan.RuntimeMode mode = runtimeMode(input.unsignedByte("runtime mode"));
    if (input.unsignedByte("root reserved byte") != 0) {
      throw new PackageFormatException("Invalid capsule root reserved byte");
    }
    int capabilityCount = input.unsignedShort("capability count");
    if (capabilityCount > CapsuleRoot.MAX_CAPABILITIES) {
      throw new PackageFormatException("Invalid capsule capability count");
    }
    ArrayList<String> capabilities = new ArrayList<>(capabilityCount);
    for (int index = 0; index < capabilityCount; index++) {
      capabilities.add(input.string(CapsuleRoot.MAX_NAME_BYTES, "capability"));
    }
    return new CapsuleRoot(
        packageInstance,
        target,
        rootWbc,
        entryFunction,
        runtimeProfile,
        bytecodeProfile,
        proofProfile,
        targetProfile,
        platformAbi,
        executionLimits,
        mode,
        capabilities);
  }

  private static byte[] encodeReceipt(CapsulePackageReceipt receipt) {
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    writeHash(output, receipt.repositorySnapshot());
    writeString(output, receipt.coordinate());
    writeHash(output, receipt.rrev());
    writeString(output, receipt.variant());
    writeHash(output, receipt.buildInput());
    writeHash(output, receipt.prev());
    writeString(output, receipt.selectedExport());
    writeHash(output, receipt.instance());
    return output.toByteArray();
  }

  private static CapsulePackageReceipt readReceipt(Reader input) {
    return new CapsulePackageReceipt(
        input.hash("repository snapshot"),
        input.string(CapsuleRoot.MAX_NAME_BYTES, "package coordinate"),
        input.hash("RREV"),
        input.string(CapsuleRoot.MAX_NAME_BYTES, "variant"),
        input.hash("build input"),
        input.hash("PREV"),
        input.string(CapsuleRoot.MAX_NAME_BYTES, "selected export"),
        input.hash("package instance"));
  }

  private static int descriptorLength(CapsuleEntry entry) {
    return 50 + utf8(entry.name()).length;
  }

  private static void writeDescriptor(
      ByteArrayOutputStream output, CapsuleEntry entry, int offset) {
    output.write(entry.kind().code());
    output.write(entry.flags());
    writeShort(output, 0);
    writeInt(output, entry.alignment());
    writeInt(output, offset);
    writeInt(output, entry.length());
    writeString(output, entry.name());
    writeHash(output, entry.identity());
  }

  private static EntryDescriptor readDescriptor(Reader input) {
    CapsuleEntry.Kind kind = CapsuleEntry.Kind.fromCode(input.unsignedByte("entry kind"));
    int flags = input.unsignedByte("entry flags");
    if (input.unsignedShort("entry reserved bytes") != 0) {
      throw new PackageFormatException("Invalid capsule entry reserved bytes");
    }
    int alignment = input.integer("entry alignment");
    int offset = input.integer("entry offset");
    int length = input.integer("entry length");
    CapsuleEntry.validateDescriptor(kind, alignment, flags, length);
    String name = input.string(CapsuleRoot.MAX_NAME_BYTES, "entry name");
    String identity = input.hash("entry identity");
    return new EntryDescriptor(kind, name, identity, alignment, flags, offset, length);
  }

  private static int runtimeModeCode(NativeImagePlan.RuntimeMode mode) {
    return switch (mode) {
      case EMBEDDED_VM -> 0;
      case AOT -> 1;
    };
  }

  private static NativeImagePlan.RuntimeMode runtimeMode(int code) {
    return switch (code) {
      case 0 -> NativeImagePlan.RuntimeMode.EMBEDDED_VM;
      case 1 -> NativeImagePlan.RuntimeMode.AOT;
      default -> throw new PackageFormatException("Unknown capsule runtime mode " + code);
    };
  }

  private static long align(long value, int alignment) {
    return Math.addExact(value, alignment - 1L) & -alignment;
  }

  private static byte[] utf8(String value) {
    return value.getBytes(StandardCharsets.UTF_8);
  }

  private static void writeString(ByteArrayOutputStream output, String value) {
    byte[] bytes = utf8(value);
    if (bytes.length > CapsuleRoot.MAX_NAME_BYTES) {
      throw new PackageFormatException("Oversized capsule string");
    }
    writeShort(output, bytes.length);
    output.writeBytes(bytes);
  }

  private static void writeHash(ByteArrayOutputStream output, String identity) {
    output.writeBytes(HexFormat.of().parseHex(identity));
  }

  private static void writeShort(ByteArrayOutputStream output, int value) {
    output.write(value);
    output.write(value >>> Byte.SIZE);
  }

  private static void writeInt(ByteArrayOutputStream output, int value) {
    for (int shift = 0; shift < Integer.SIZE; shift += Byte.SIZE) {
      output.write(value >>> shift);
    }
  }

  private static void writeLong(ByteArrayOutputStream output, long value) {
    for (int shift = 0; shift < Long.SIZE; shift += Byte.SIZE) {
      output.write((int) (value >>> shift));
    }
  }

  private record EntryDescriptor(
      CapsuleEntry.Kind kind,
      String name,
      String identity,
      int alignment,
      int flags,
      int offset,
      int length) {}

  private static final class Reader {
    private final ByteBuffer input;

    private Reader(byte[] bytes) {
      input = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN);
    }

    private int position() {
      return input.position();
    }

    private int unsignedByte(String description) {
      require(Byte.BYTES, description);
      return Byte.toUnsignedInt(input.get());
    }

    private int unsignedShort(String description) {
      require(Short.BYTES, description);
      return Short.toUnsignedInt(input.getShort());
    }

    private int integer(String description) {
      require(Integer.BYTES, description);
      int value = input.getInt();
      if (value < 0) {
        throw new PackageFormatException("Invalid capsule " + description);
      }
      return value;
    }

    private int boundedInt(int maximum, String description) {
      int value = integer(description);
      if (value > maximum) {
        throw new PackageFormatException("Invalid capsule " + description);
      }
      return value;
    }

    private long longValue(String description) {
      require(Long.BYTES, description);
      return input.getLong();
    }

    private String hash(String description) {
      return HexFormat.of().formatHex(bytes(DIGEST_BYTES, description));
    }

    private String string(int maximumBytes, String description) {
      int length = unsignedShort(description + " length");
      if (length == 0 || length > maximumBytes) {
        throw new PackageFormatException("Invalid capsule " + description + " length");
      }
      byte[] bytes = bytes(length, description);
      try {
        return StandardCharsets.UTF_8.newDecoder()
            .onMalformedInput(CodingErrorAction.REPORT)
            .onUnmappableCharacter(CodingErrorAction.REPORT)
            .decode(ByteBuffer.wrap(bytes))
            .toString();
      } catch (CharacterCodingException exception) {
        throw new PackageFormatException(
            "Capsule " + description + " is not strict UTF-8", exception);
      }
    }

    private byte[] bytes(int length, String description) {
      require(length, description);
      byte[] result = new byte[length];
      input.get(result);
      return result;
    }

    private void require(int length, String description) {
      if (length < 0 || input.remaining() < length) {
        throw new PackageFormatException("Truncated capsule " + description);
      }
    }
  }
}
