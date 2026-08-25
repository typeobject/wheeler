package com.typeobject.wheeler.packageformat;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.Objects;

/** Reproducible ELF64 image adapter for position-independent runtime text and one capsule. */
public final class ElfImage {
  public static final int MAX_IMAGE_BYTES = 64 * 1024 * 1024;
  public static final int MAX_RUNTIME_BYTES = 16 * 1024 * 1024;
  private static final int ELF_HEADER_BYTES = 64;
  private static final int PROGRAM_HEADER_BYTES = 56;
  private static final int PROGRAM_HEADER_COUNT = 3;
  public static final int LOCATOR_FILE_OFFSET =
      ELF_HEADER_BYTES + PROGRAM_HEADER_BYTES * PROGRAM_HEADER_COUNT;
  public static final int RUNTIME_FILE_OFFSET = 336;
  public static final int LOCATOR_CAPSULE_OFFSET_FIELD = 48;
  private static final int LOCATOR_BYTES = 96;
  private static final int PT_LOAD = 1;
  private static final int PT_GNU_STACK = 0x6474_e551;
  private static final int PF_EXECUTE = 1;
  private static final int PF_WRITE = 2;
  private static final int PF_READ = 4;
  private static final byte[] ELF_MAGIC = {0x7f, 'E', 'L', 'F'};
  private static final byte[] LOCATOR_MAGIC = {'W', 'H', 'L', 'L', 'O', 'C', '0', '1'};

  private ElfImage() {}

  /** Stable locator magic consumed by the mapped Linux entry shim. */
  public static byte[] locatorMagic() {
    return LOCATOR_MAGIC.clone();
  }

  public static byte[] build(
      NativeImagePlan plan,
      PlatformAbi abi,
      ApplicationCapsule capsule,
      byte[] runtimeText,
      int runtimeEntryOffset) {
    validateInputs(plan, abi, capsule, runtimeText, runtimeEntryOffset);
    return encode(
        plan,
        abi,
        capsule.canonicalBytes(),
        runtimeText.clone(),
        runtimeEntryOffset);
  }

  public static VerifiedImage verify(
      byte[] image,
      NativeImagePlan plan,
      PlatformAbi abi) {
    Objects.requireNonNull(image, "image");
    Objects.requireNonNull(plan, "plan");
    Objects.requireNonNull(abi, "abi");
    if (image.length < RUNTIME_FILE_OFFSET + 1 || image.length > MAX_IMAGE_BYTES) {
      throw new PackageFormatException("Invalid ELF image length");
    }
    ByteBuffer input = ByteBuffer.wrap(image).order(ByteOrder.LITTLE_ENDIAN);
    byte[] ident = new byte[16];
    input.get(ident);
    requireIdent(ident);
    int machine = Short.toUnsignedInt(input.getShort(18));
    int expectedMachine = machine(abi);
    int type = Short.toUnsignedInt(input.getShort(16));
    int version = input.getInt(20);
    long entryAddress = input.getLong(24);
    long programHeaderOffset = input.getLong(32);
    long sectionHeaderOffset = input.getLong(40);
    int flags = input.getInt(48);
    int headerBytes = Short.toUnsignedInt(input.getShort(52));
    int programHeaderBytes = Short.toUnsignedInt(input.getShort(54));
    int programHeaderCount = Short.toUnsignedInt(input.getShort(56));
    int sectionHeaderBytes = Short.toUnsignedInt(input.getShort(58));
    int sectionHeaderCount = Short.toUnsignedInt(input.getShort(60));
    int sectionNameIndex = Short.toUnsignedInt(input.getShort(62));
    if (type != 3
        || machine != expectedMachine
        || version != 1
        || programHeaderOffset != ELF_HEADER_BYTES
        || sectionHeaderOffset != 0
        || flags != 0
        || headerBytes != ELF_HEADER_BYTES
        || programHeaderBytes != PROGRAM_HEADER_BYTES
        || programHeaderCount != PROGRAM_HEADER_COUNT
        || sectionHeaderBytes != 0
        || sectionHeaderCount != 0
        || sectionNameIndex != 0) {
      throw new PackageFormatException("Invalid canonical ELF header");
    }

    Locator locator = readLocator(image);
    if (!locator.planIdentity().equals(plan.identity())
        || !locator.capsuleIdentity().equals(plan.capsule())
        || locator.runtimeOffset() != RUNTIME_FILE_OFFSET
        || locator.runtimeLength() <= 0
        || locator.runtimeLength() > MAX_RUNTIME_BYTES
        || locator.runtimeEntryOffset() < 0
        || locator.runtimeEntryOffset() >= locator.runtimeLength()
        || entryAddress != (long) locator.runtimeOffset() + locator.runtimeEntryOffset()) {
      throw new PackageFormatException("ELF locator does not match the native image plan");
    }
    long runtimeEnd = (long) locator.runtimeOffset() + locator.runtimeLength();
    long capsuleEnd = (long) locator.capsuleOffset() + locator.capsuleLength();
    if (runtimeEnd > image.length
        || locator.capsuleOffset() != align(runtimeEnd, abi.pageBytes())
        || locator.capsuleOffset() % abi.pageBytes() != 0
        || locator.capsuleLength() <= 0
        || capsuleEnd != image.length) {
      throw new PackageFormatException("Invalid ELF runtime or capsule range");
    }
    requireProgramHeaders(input, abi, locator);

    byte[] runtime = Arrays.copyOfRange(
        image, locator.runtimeOffset(), Math.toIntExact(runtimeEnd));
    byte[] capsuleBytes = Arrays.copyOfRange(
        image, locator.capsuleOffset(), Math.toIntExact(capsuleEnd));
    ApplicationCapsule capsule = ApplicationCapsule.parse(capsuleBytes);
    validateInputs(plan, abi, capsule, runtime, locator.runtimeEntryOffset());
    byte[] canonical = encode(
        plan, abi, capsuleBytes, runtime, locator.runtimeEntryOffset());
    if (!Arrays.equals(image, canonical)) {
      throw new PackageFormatException("ELF image bytes are not canonical");
    }
    return new VerifiedImage(
        identity(image),
        plan.identity(),
        capsule,
        runtime,
        locator.runtimeEntryOffset(),
        locator.capsuleOffset());
  }

  private static byte[] encode(
      NativeImagePlan plan,
      PlatformAbi abi,
      byte[] capsule,
      byte[] runtime,
      int entryOffset) {
    int runtimeEnd = Math.addExact(RUNTIME_FILE_OFFSET, runtime.length);
    int capsuleOffset = Math.toIntExact(align(runtimeEnd, abi.pageBytes()));
    int totalBytes = Math.addExact(capsuleOffset, capsule.length);
    if (totalBytes > MAX_IMAGE_BYTES || totalBytes > abi.maximumMemoryBytes()) {
      throw new PackageFormatException("ELF image is oversized");
    }
    ByteArrayOutputStream output = new ByteArrayOutputStream(totalBytes);
    writeElfHeader(output, machine(abi), RUNTIME_FILE_OFFSET + entryOffset);
    writeProgramHeader(
        output,
        PT_LOAD,
        PF_READ | PF_EXECUTE,
        0,
        0,
        runtimeEnd,
        runtimeEnd,
        abi.pageBytes());
    writeProgramHeader(
        output,
        PT_LOAD,
        PF_READ,
        capsuleOffset,
        capsuleOffset,
        capsule.length,
        capsule.length,
        abi.pageBytes());
    writeProgramHeader(output, PT_GNU_STACK, PF_READ | PF_WRITE, 0, 0, 0, 0, 16);
    writeLocator(
        output,
        plan.identity(),
        runtime.length,
        capsuleOffset,
        capsule.length,
        entryOffset,
        plan.capsule());
    while (output.size() < RUNTIME_FILE_OFFSET) {
      output.write(0);
    }
    output.writeBytes(runtime);
    while (output.size() < capsuleOffset) {
      output.write(0);
    }
    output.writeBytes(capsule);
    return output.toByteArray();
  }

  private static void validateInputs(
      NativeImagePlan plan,
      PlatformAbi abi,
      ApplicationCapsule capsule,
      byte[] runtime,
      int entryOffset) {
    Objects.requireNonNull(plan, "plan");
    Objects.requireNonNull(abi, "abi");
    Objects.requireNonNull(capsule, "capsule");
    if (runtime == null || runtime.length == 0 || runtime.length > MAX_RUNTIME_BYTES) {
      throw new PackageFormatException("Invalid ELF runtime text length");
    }
    if (entryOffset < 0 || entryOffset >= runtime.length) {
      throw new PackageFormatException("Invalid ELF runtime entry offset");
    }
    machine(abi);
    if (plan.format() != PlatformAbi.Format.ELF
        || abi.format() != PlatformAbi.Format.ELF
        || !plan.stripped()
        || plan.runtimeMode() != NativeImagePlan.RuntimeMode.EMBEDDED_VM
        || !plan.platformAbi().equals(abi.identity())
        || !plan.capsule().equals(capsule.identity())
        || !plan.runtime().equals(identity(runtime))
        || !capsule.root().platformAbi().equals(abi.identity())
        || capsule.root().runtimeMode() != plan.runtimeMode()
        || !plan.target().equals(abi.architecture() + "-unknown-" + abi.osAbi())) {
      throw new PackageFormatException("ELF image inputs do not match the native image plan");
    }
    CapsuleEntry rootWbc = capsule.entries().stream()
        .filter(entry -> entry.name().equals(capsule.root().rootWbc()))
        .findFirst()
        .orElseThrow(() -> new PackageFormatException("Capsule root WBC is missing"));
    if (!plan.portableArtifact().equals(rootWbc.identity())) {
      throw new PackageFormatException("ELF plan portable artifact is not the root WBC");
    }
  }

  private static void requireProgramHeaders(
      ByteBuffer input, PlatformAbi abi, Locator locator) {
    input.position(ELF_HEADER_BYTES);
    requireProgramHeader(
        input,
        PT_LOAD,
        PF_READ | PF_EXECUTE,
        0,
        0,
        (long) locator.runtimeOffset() + locator.runtimeLength(),
        (long) locator.runtimeOffset() + locator.runtimeLength(),
        abi.pageBytes());
    requireProgramHeader(
        input,
        PT_LOAD,
        PF_READ,
        locator.capsuleOffset(),
        locator.capsuleOffset(),
        locator.capsuleLength(),
        locator.capsuleLength(),
        abi.pageBytes());
    requireProgramHeader(input, PT_GNU_STACK, PF_READ | PF_WRITE, 0, 0, 0, 0, 16);
  }

  private static void requireProgramHeader(
      ByteBuffer input,
      int type,
      int flags,
      long offset,
      long address,
      long fileBytes,
      long memoryBytes,
      long alignment) {
    if (input.getInt() != type
        || input.getInt() != flags
        || input.getLong() != offset
        || input.getLong() != address
        || input.getLong() != address
        || input.getLong() != fileBytes
        || input.getLong() != memoryBytes
        || input.getLong() != alignment) {
      throw new PackageFormatException("Invalid canonical ELF program header");
    }
  }

  private static Locator readLocator(byte[] image) {
    ByteBuffer input = ByteBuffer.wrap(image).order(ByteOrder.LITTLE_ENDIAN);
    input.position(LOCATOR_FILE_OFFSET);
    byte[] magic = new byte[LOCATOR_MAGIC.length];
    input.get(magic);
    if (!Arrays.equals(magic, LOCATOR_MAGIC)) {
      throw new PackageFormatException("Invalid Wheeler ELF locator magic");
    }
    String plan = readHash(input);
    int runtimeOffset = nonnegative(input.getInt(), "runtime offset");
    int runtimeLength = nonnegative(input.getInt(), "runtime length");
    int capsuleOffset = nonnegative(input.getInt(), "capsule offset");
    int capsuleLength = nonnegative(input.getInt(), "capsule length");
    int entryOffset = nonnegative(input.getInt(), "runtime entry offset");
    if (input.getInt() != 0) {
      throw new PackageFormatException("Invalid Wheeler ELF locator reserved field");
    }
    return new Locator(
        plan,
        runtimeOffset,
        runtimeLength,
        capsuleOffset,
        capsuleLength,
        entryOffset,
        readHash(input));
  }

  private static void writeElfHeader(
      ByteArrayOutputStream output, int machine, long entryAddress) {
    output.writeBytes(ELF_MAGIC);
    output.write(2);
    output.write(1);
    output.write(1);
    output.write(0);
    for (int index = 0; index < 8; index++) {
      output.write(0);
    }
    writeShort(output, 3);
    writeShort(output, machine);
    writeInt(output, 1);
    writeLong(output, entryAddress);
    writeLong(output, ELF_HEADER_BYTES);
    writeLong(output, 0);
    writeInt(output, 0);
    writeShort(output, ELF_HEADER_BYTES);
    writeShort(output, PROGRAM_HEADER_BYTES);
    writeShort(output, PROGRAM_HEADER_COUNT);
    writeShort(output, 0);
    writeShort(output, 0);
    writeShort(output, 0);
  }

  private static void writeProgramHeader(
      ByteArrayOutputStream output,
      int type,
      int flags,
      long offset,
      long address,
      long fileBytes,
      long memoryBytes,
      long alignment) {
    writeInt(output, type);
    writeInt(output, flags);
    writeLong(output, offset);
    writeLong(output, address);
    writeLong(output, address);
    writeLong(output, fileBytes);
    writeLong(output, memoryBytes);
    writeLong(output, alignment);
  }

  private static void writeLocator(
      ByteArrayOutputStream output,
      String plan,
      int runtimeLength,
      int capsuleOffset,
      int capsuleLength,
      int entryOffset,
      String capsule) {
    output.writeBytes(LOCATOR_MAGIC);
    output.writeBytes(HexFormat.of().parseHex(plan));
    writeInt(output, RUNTIME_FILE_OFFSET);
    writeInt(output, runtimeLength);
    writeInt(output, capsuleOffset);
    writeInt(output, capsuleLength);
    writeInt(output, entryOffset);
    writeInt(output, 0);
    output.writeBytes(HexFormat.of().parseHex(capsule));
    if (output.size() != LOCATOR_FILE_OFFSET + LOCATOR_BYTES) {
      throw new IllegalStateException("Wheeler ELF locator has the wrong encoded size");
    }
  }

  private static void requireIdent(byte[] ident) {
    if (!Arrays.equals(Arrays.copyOf(ident, ELF_MAGIC.length), ELF_MAGIC)
        || ident[4] != 2
        || ident[5] != 1
        || ident[6] != 1
        || ident[7] != 0) {
      throw new PackageFormatException("Invalid canonical ELF identification");
    }
    for (int index = 8; index < ident.length; index++) {
      if (ident[index] != 0) {
        throw new PackageFormatException("Nonzero ELF identification padding");
      }
    }
  }

  private static int machine(PlatformAbi abi) {
    if (!abi.osAbi().equals("linux-gnu")) {
      throw new PackageFormatException("ELF image profile requires linux-gnu");
    }
    return switch (abi.architecture()) {
      case "x86_64" -> 62;
      case "aarch64" -> 183;
      default -> throw new PackageFormatException(
          "Unsupported ELF architecture " + abi.architecture());
    };
  }

  private static int nonnegative(int value, String description) {
    if (value < 0) {
      throw new PackageFormatException("Invalid ELF " + description);
    }
    return value;
  }

  private static long align(long value, int alignment) {
    return Math.addExact(value, alignment - 1L) & -alignment;
  }

  private static String readHash(ByteBuffer input) {
    byte[] bytes = new byte[32];
    input.get(bytes);
    return HexFormat.of().formatHex(bytes);
  }

  private static String identity(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
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

  private record Locator(
      String planIdentity,
      int runtimeOffset,
      int runtimeLength,
      int capsuleOffset,
      int capsuleLength,
      int runtimeEntryOffset,
      String capsuleIdentity) {}

  /** Verified unsigned ELF image and exact embedded runtime and capsule ranges. */
  public static final class VerifiedImage {
    private final String prev;
    private final String planIdentity;
    private final ApplicationCapsule capsule;
    private final byte[] runtimeText;
    private final int runtimeEntryOffset;
    private final int capsuleOffset;

    private VerifiedImage(
        String prev,
        String planIdentity,
        ApplicationCapsule capsule,
        byte[] runtimeText,
        int runtimeEntryOffset,
        int capsuleOffset) {
      this.prev = prev;
      this.planIdentity = planIdentity;
      this.capsule = capsule;
      this.runtimeText = runtimeText.clone();
      this.runtimeEntryOffset = runtimeEntryOffset;
      this.capsuleOffset = capsuleOffset;
    }

    public String prev() {
      return prev;
    }

    public String planIdentity() {
      return planIdentity;
    }

    public ApplicationCapsule capsule() {
      return capsule;
    }

    public byte[] runtimeText() {
      return runtimeText.clone();
    }

    public int runtimeEntryOffset() {
      return runtimeEntryOffset;
    }

    public int capsuleOffset() {
      return capsuleOffset;
    }
  }
}
