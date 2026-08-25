package com.typeobject.wheeler.packageformat;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.Objects;

/** Reproducible arm64 Mach-O adapter for position-independent runtime text and one capsule. */
public final class MachOImage {
  public static final int MAX_IMAGE_BYTES = 64 * 1024 * 1024;
  public static final int MAX_RUNTIME_BYTES = 16 * 1024 * 1024;
  private static final int HEADER_BYTES = 32;
  private static final int SEGMENT_COMMAND_BYTES = 72;
  private static final int THREAD_COMMAND_BYTES = 288;
  private static final int BUILD_VERSION_COMMAND_BYTES = 24;
  private static final int COMMAND_COUNT = 5;
  private static final int COMMAND_BYTES =
      SEGMENT_COMMAND_BYTES * 3 + THREAD_COMMAND_BYTES + BUILD_VERSION_COMMAND_BYTES;
  private static final int LOCATOR_OFFSET = HEADER_BYTES + COMMAND_BYTES;
  private static final int LOCATOR_BYTES = 96;
  private static final int RUNTIME_OFFSET = LOCATOR_OFFSET + LOCATOR_BYTES;
  private static final long IMAGE_BASE = 0x1_0000_0000L;
  private static final int MH_MAGIC_64 = 0xfeed_facf;
  private static final int CPU_TYPE_ARM64 = 0x0100_000c;
  private static final int CPU_SUBTYPE_ARM64_ALL = 0;
  private static final int MH_EXECUTE = 2;
  private static final int MH_NOUNDEFS = 1;
  private static final int LC_SEGMENT_64 = 0x19;
  private static final int LC_UNIXTHREAD = 5;
  private static final int LC_BUILD_VERSION = 0x32;
  private static final int ARM_THREAD_STATE64 = 6;
  private static final int ARM_THREAD_STATE64_COUNT = 68;
  private static final int PLATFORM_MACOS = 1;
  private static final int MACOS_13 = 0x000d_0000;
  private static final int VM_PROT_READ = 1;
  private static final int VM_PROT_WRITE = 2;
  private static final int VM_PROT_EXECUTE = 4;
  private static final byte[] LOCATOR_MAGIC = {'W', 'H', 'M', 'L', 'O', 'C', '0', '1'};

  private MachOImage() {}

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
    if (image.length < RUNTIME_OFFSET + 1 || image.length > MAX_IMAGE_BYTES) {
      throw new PackageFormatException("Invalid Mach-O image length");
    }
    requireProfile(abi);
    ByteBuffer input = ByteBuffer.wrap(image).order(ByteOrder.LITTLE_ENDIAN);
    if (input.getInt() != MH_MAGIC_64
        || input.getInt() != CPU_TYPE_ARM64
        || input.getInt() != CPU_SUBTYPE_ARM64_ALL
        || input.getInt() != MH_EXECUTE
        || input.getInt() != COMMAND_COUNT
        || input.getInt() != COMMAND_BYTES
        || input.getInt() != MH_NOUNDEFS
        || input.getInt() != 0) {
      throw new PackageFormatException("Invalid canonical Mach-O header");
    }

    Locator locator = readLocator(image);
    if (!locator.planIdentity().equals(plan.identity())
        || !locator.capsuleIdentity().equals(plan.capsule())
        || locator.runtimeOffset() != RUNTIME_OFFSET
        || locator.runtimeLength() <= 0
        || locator.runtimeLength() > MAX_RUNTIME_BYTES
        || locator.runtimeEntryOffset() < 0
        || locator.runtimeEntryOffset() >= locator.runtimeLength()) {
      throw new PackageFormatException("Mach-O locator does not match the native image plan");
    }
    long runtimeEnd = (long) locator.runtimeOffset() + locator.runtimeLength();
    long capsuleEnd = (long) locator.capsuleOffset() + locator.capsuleLength();
    if (runtimeEnd > image.length
        || locator.capsuleOffset() != align(runtimeEnd, abi.pageBytes())
        || locator.capsuleOffset() % abi.pageBytes() != 0
        || locator.capsuleLength() <= 0
        || capsuleEnd != image.length) {
      throw new PackageFormatException("Invalid Mach-O runtime or capsule range");
    }
    requireCommands(input, abi, locator);

    byte[] runtime = Arrays.copyOfRange(
        image, locator.runtimeOffset(), Math.toIntExact(runtimeEnd));
    byte[] capsuleBytes = Arrays.copyOfRange(
        image, locator.capsuleOffset(), Math.toIntExact(capsuleEnd));
    ApplicationCapsule capsule = ApplicationCapsule.parse(capsuleBytes);
    validateInputs(plan, abi, capsule, runtime, locator.runtimeEntryOffset());
    byte[] canonical = encode(
        plan, abi, capsuleBytes, runtime, locator.runtimeEntryOffset());
    if (!Arrays.equals(image, canonical)) {
      throw new PackageFormatException("Mach-O image bytes are not canonical");
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
    int runtimeEnd = Math.addExact(RUNTIME_OFFSET, runtime.length);
    int capsuleOffset = Math.toIntExact(align(runtimeEnd, abi.pageBytes()));
    int totalBytes = Math.addExact(capsuleOffset, capsule.length);
    if (totalBytes > MAX_IMAGE_BYTES || totalBytes > abi.maximumMemoryBytes()) {
      throw new PackageFormatException("Mach-O image is oversized");
    }
    ByteArrayOutputStream output = new ByteArrayOutputStream(totalBytes);
    writeHeader(output);
    writeSegment(
        output,
        "__PAGEZERO",
        0,
        IMAGE_BASE,
        0,
        0,
        0,
        0);
    writeSegment(
        output,
        "__TEXT",
        IMAGE_BASE,
        align(runtimeEnd, abi.pageBytes()),
        0,
        runtimeEnd,
        VM_PROT_READ | VM_PROT_EXECUTE,
        VM_PROT_READ | VM_PROT_EXECUTE);
    writeSegment(
        output,
        "__WHEELER",
        IMAGE_BASE + capsuleOffset,
        align(capsule.length, abi.pageBytes()),
        capsuleOffset,
        capsule.length,
        VM_PROT_READ,
        VM_PROT_READ);
    writeThread(output, IMAGE_BASE + RUNTIME_OFFSET + entryOffset);
    writeBuildVersion(output);
    if (output.size() != LOCATOR_OFFSET) {
      throw new IllegalStateException("Mach-O commands have the wrong encoded size");
    }
    writeLocator(
        output,
        plan.identity(),
        runtime.length,
        capsuleOffset,
        capsule.length,
        entryOffset,
        plan.capsule());
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
      throw new PackageFormatException("Invalid Mach-O runtime text length");
    }
    if (entryOffset < 0 || entryOffset >= runtime.length) {
      throw new PackageFormatException("Invalid Mach-O runtime entry offset");
    }
    requireProfile(abi);
    if (plan.format() != PlatformAbi.Format.MACH_O
        || !plan.stripped()
        || plan.runtimeMode() != NativeImagePlan.RuntimeMode.EMBEDDED_VM
        || !plan.platformAbi().equals(abi.identity())
        || !plan.capsule().equals(capsule.identity())
        || !plan.runtime().equals(identity(runtime))
        || !capsule.root().platformAbi().equals(abi.identity())
        || capsule.root().runtimeMode() != plan.runtimeMode()
        || !plan.target().equals("aarch64-apple-darwin")) {
      throw new PackageFormatException("Mach-O inputs do not match the native image plan");
    }
    CapsuleEntry rootWbc = capsule.entries().stream()
        .filter(entry -> entry.name().equals(capsule.root().rootWbc()))
        .findFirst()
        .orElseThrow(() -> new PackageFormatException("Capsule root WBC is missing"));
    if (!plan.portableArtifact().equals(rootWbc.identity())) {
      throw new PackageFormatException("Mach-O plan portable artifact is not the root WBC");
    }
  }

  private static void requireProfile(PlatformAbi abi) {
    if (abi.format() != PlatformAbi.Format.MACH_O
        || !abi.architecture().equals("aarch64")
        || !abi.osAbi().equals("darwin")) {
      throw new PackageFormatException("Mach-O image profile requires aarch64 Darwin");
    }
  }

  private static void requireCommands(
      ByteBuffer input, PlatformAbi abi, Locator locator) {
    input.position(HEADER_BYTES);
    requireSegment(input, "__PAGEZERO", 0, IMAGE_BASE, 0, 0, 0, 0);
    long runtimeEnd = (long) locator.runtimeOffset() + locator.runtimeLength();
    requireSegment(
        input,
        "__TEXT",
        IMAGE_BASE,
        align(runtimeEnd, abi.pageBytes()),
        0,
        runtimeEnd,
        VM_PROT_READ | VM_PROT_EXECUTE,
        VM_PROT_READ | VM_PROT_EXECUTE);
    requireSegment(
        input,
        "__WHEELER",
        IMAGE_BASE + locator.capsuleOffset(),
        align(locator.capsuleLength(), abi.pageBytes()),
        locator.capsuleOffset(),
        locator.capsuleLength(),
        VM_PROT_READ,
        VM_PROT_READ);
    if (input.getInt() != LC_UNIXTHREAD
        || input.getInt() != THREAD_COMMAND_BYTES
        || input.getInt() != ARM_THREAD_STATE64
        || input.getInt() != ARM_THREAD_STATE64_COUNT) {
      throw new PackageFormatException("Invalid canonical Mach-O thread command");
    }
    for (int register = 0; register < 32; register++) {
      if (input.getLong() != 0) {
        throw new PackageFormatException("Nonzero canonical Mach-O entry register");
      }
    }
    long expectedPc = IMAGE_BASE + locator.runtimeOffset() + locator.runtimeEntryOffset();
    if (input.getLong() != expectedPc || input.getInt() != 0 || input.getInt() != 0) {
      throw new PackageFormatException("Invalid canonical Mach-O entry state");
    }
    if (input.getInt() != LC_BUILD_VERSION
        || input.getInt() != BUILD_VERSION_COMMAND_BYTES
        || input.getInt() != PLATFORM_MACOS
        || input.getInt() != MACOS_13
        || input.getInt() != MACOS_13
        || input.getInt() != 0) {
      throw new PackageFormatException("Invalid canonical Mach-O build version");
    }
  }

  private static void requireSegment(
      ByteBuffer input,
      String name,
      long address,
      long memoryBytes,
      long fileOffset,
      long fileBytes,
      int maximumProtection,
      int initialProtection) {
    if (input.getInt() != LC_SEGMENT_64 || input.getInt() != SEGMENT_COMMAND_BYTES) {
      throw new PackageFormatException("Invalid canonical Mach-O segment command");
    }
    byte[] encodedName = new byte[16];
    input.get(encodedName);
    if (!Arrays.equals(encodedName, segmentName(name))
        || input.getLong() != address
        || input.getLong() != memoryBytes
        || input.getLong() != fileOffset
        || input.getLong() != fileBytes
        || input.getInt() != maximumProtection
        || input.getInt() != initialProtection
        || input.getInt() != 0
        || input.getInt() != 0) {
      throw new PackageFormatException("Invalid canonical Mach-O segment");
    }
  }

  private static Locator readLocator(byte[] image) {
    ByteBuffer input = ByteBuffer.wrap(image).order(ByteOrder.LITTLE_ENDIAN);
    input.position(LOCATOR_OFFSET);
    byte[] magic = new byte[LOCATOR_MAGIC.length];
    input.get(magic);
    if (!Arrays.equals(magic, LOCATOR_MAGIC)) {
      throw new PackageFormatException("Invalid Wheeler Mach-O locator magic");
    }
    String plan = readHash(input);
    int runtimeOffset = nonnegative(input.getInt(), "runtime offset");
    int runtimeLength = nonnegative(input.getInt(), "runtime length");
    int capsuleOffset = nonnegative(input.getInt(), "capsule offset");
    int capsuleLength = nonnegative(input.getInt(), "capsule length");
    int entryOffset = nonnegative(input.getInt(), "runtime entry offset");
    if (input.getInt() != 0) {
      throw new PackageFormatException("Invalid Wheeler Mach-O locator reserved field");
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

  private static void writeHeader(ByteArrayOutputStream output) {
    writeInt(output, MH_MAGIC_64);
    writeInt(output, CPU_TYPE_ARM64);
    writeInt(output, CPU_SUBTYPE_ARM64_ALL);
    writeInt(output, MH_EXECUTE);
    writeInt(output, COMMAND_COUNT);
    writeInt(output, COMMAND_BYTES);
    writeInt(output, MH_NOUNDEFS);
    writeInt(output, 0);
  }

  private static void writeSegment(
      ByteArrayOutputStream output,
      String name,
      long address,
      long memoryBytes,
      long fileOffset,
      long fileBytes,
      int maximumProtection,
      int initialProtection) {
    writeInt(output, LC_SEGMENT_64);
    writeInt(output, SEGMENT_COMMAND_BYTES);
    output.writeBytes(segmentName(name));
    writeLong(output, address);
    writeLong(output, memoryBytes);
    writeLong(output, fileOffset);
    writeLong(output, fileBytes);
    writeInt(output, maximumProtection);
    writeInt(output, initialProtection);
    writeInt(output, 0);
    writeInt(output, 0);
  }

  private static void writeThread(ByteArrayOutputStream output, long programCounter) {
    writeInt(output, LC_UNIXTHREAD);
    writeInt(output, THREAD_COMMAND_BYTES);
    writeInt(output, ARM_THREAD_STATE64);
    writeInt(output, ARM_THREAD_STATE64_COUNT);
    for (int register = 0; register < 32; register++) {
      writeLong(output, 0);
    }
    writeLong(output, programCounter);
    writeInt(output, 0);
    writeInt(output, 0);
  }

  private static void writeBuildVersion(ByteArrayOutputStream output) {
    writeInt(output, LC_BUILD_VERSION);
    writeInt(output, BUILD_VERSION_COMMAND_BYTES);
    writeInt(output, PLATFORM_MACOS);
    writeInt(output, MACOS_13);
    writeInt(output, MACOS_13);
    writeInt(output, 0);
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
    writeInt(output, RUNTIME_OFFSET);
    writeInt(output, runtimeLength);
    writeInt(output, capsuleOffset);
    writeInt(output, capsuleLength);
    writeInt(output, entryOffset);
    writeInt(output, 0);
    output.writeBytes(HexFormat.of().parseHex(capsule));
    if (output.size() != LOCATOR_OFFSET + LOCATOR_BYTES) {
      throw new IllegalStateException("Wheeler Mach-O locator has the wrong encoded size");
    }
  }

  private static byte[] segmentName(String name) {
    byte[] result = new byte[16];
    byte[] encoded = name.getBytes(java.nio.charset.StandardCharsets.US_ASCII);
    System.arraycopy(encoded, 0, result, 0, encoded.length);
    return result;
  }

  private static int nonnegative(int value, String description) {
    if (value < 0) {
      throw new PackageFormatException("Invalid Mach-O " + description);
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

  /** Verified unsigned Mach-O image and exact embedded runtime and capsule ranges. */
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
