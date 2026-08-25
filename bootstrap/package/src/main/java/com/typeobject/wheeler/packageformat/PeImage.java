package com.typeobject.wheeler.packageformat;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.Objects;

/** Reproducible PE32+ adapter for position-independent runtime text and one capsule. */
public final class PeImage {
  public static final int MAX_IMAGE_BYTES = 64 * 1024 * 1024;
  public static final int MAX_RUNTIME_BYTES = 16 * 1024 * 1024;
  private static final int DOS_HEADER_BYTES = 64;
  private static final int PE_OFFSET = 128;
  private static final int OPTIONAL_HEADER_BYTES = 240;
  private static final int HEADER_BYTES = 512;
  private static final int LOCATOR_BYTES = 96;
  private static final int RUNTIME_OFFSET = HEADER_BYTES + LOCATOR_BYTES;
  private static final int SECTION_ALIGNMENT = 4096;
  private static final int FILE_ALIGNMENT = 512;
  private static final int TEXT_RVA = SECTION_ALIGNMENT;
  private static final long IMAGE_BASE = 0x1_4000_0000L;
  private static final int MACHINE_AMD64 = 0x8664;
  private static final int MACHINE_ARM64 = 0xaa64;
  private static final int IMAGE_FILE_EXECUTABLE_IMAGE = 0x0002;
  private static final int IMAGE_FILE_LARGE_ADDRESS_AWARE = 0x0020;
  private static final int IMAGE_NT_OPTIONAL_HDR64_MAGIC = 0x020b;
  private static final int IMAGE_SUBSYSTEM_WINDOWS_CUI = 3;
  private static final int IMAGE_DLLCHARACTERISTICS_HIGH_ENTROPY_VA = 0x0020;
  private static final int IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE = 0x0040;
  private static final int IMAGE_DLLCHARACTERISTICS_NX_COMPAT = 0x0100;
  private static final int TEXT_CHARACTERISTICS = 0x6000_0020;
  private static final int CAPSULE_CHARACTERISTICS = 0x4000_0040;
  private static final byte[] LOCATOR_MAGIC = {'W', 'H', 'P', 'L', 'O', 'C', '0', '1'};

  private PeImage() {}

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
      throw new PackageFormatException("Invalid PE image length");
    }
    requireProfile(abi);
    Locator locator = readLocator(image);
    if (!locator.planIdentity().equals(plan.identity())
        || !locator.capsuleIdentity().equals(plan.capsule())
        || locator.runtimeOffset() != RUNTIME_OFFSET
        || locator.runtimeLength() <= 0
        || locator.runtimeLength() > MAX_RUNTIME_BYTES
        || locator.runtimeEntryOffset() < 0
        || locator.runtimeEntryOffset() >= locator.runtimeLength()) {
      throw new PackageFormatException("PE locator does not match the native image plan");
    }
    int textVirtualBytes = Math.addExact(LOCATOR_BYTES, locator.runtimeLength());
    int textRawBytes = Math.toIntExact(align(textVirtualBytes, FILE_ALIGNMENT));
    int capsuleOffset = Math.addExact(HEADER_BYTES, textRawBytes);
    int capsuleRawBytes = Math.toIntExact(align(locator.capsuleLength(), FILE_ALIGNMENT));
    long capsuleEnd = (long) capsuleOffset + locator.capsuleLength();
    if (locator.capsuleOffset() != capsuleOffset
        || locator.capsuleLength() <= 0
        || capsuleEnd > image.length
        || (long) capsuleOffset + capsuleRawBytes != image.length) {
      throw new PackageFormatException("Invalid PE runtime or capsule range");
    }
    int capsuleRva = Math.toIntExact(align(
        (long) TEXT_RVA + textVirtualBytes, SECTION_ALIGNMENT));
    int imageBytes = Math.toIntExact(align(
        (long) capsuleRva + locator.capsuleLength(), SECTION_ALIGNMENT));
    requireHeaders(
        image,
        abi,
        locator,
        textVirtualBytes,
        textRawBytes,
        capsuleRva,
        capsuleRawBytes,
        imageBytes);

    long runtimeEnd = (long) locator.runtimeOffset() + locator.runtimeLength();
    byte[] runtime = Arrays.copyOfRange(
        image, locator.runtimeOffset(), Math.toIntExact(runtimeEnd));
    byte[] capsuleBytes = Arrays.copyOfRange(
        image, locator.capsuleOffset(), Math.toIntExact(capsuleEnd));
    ApplicationCapsule capsule = ApplicationCapsule.parse(capsuleBytes);
    validateInputs(plan, abi, capsule, runtime, locator.runtimeEntryOffset());
    byte[] canonical = encode(
        plan, abi, capsuleBytes, runtime, locator.runtimeEntryOffset());
    if (!Arrays.equals(image, canonical)) {
      throw new PackageFormatException("PE image bytes are not canonical");
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
    int textVirtualBytes = Math.addExact(LOCATOR_BYTES, runtime.length);
    int textRawBytes = Math.toIntExact(align(textVirtualBytes, FILE_ALIGNMENT));
    int capsuleOffset = Math.addExact(HEADER_BYTES, textRawBytes);
    int capsuleRawBytes = Math.toIntExact(align(capsule.length, FILE_ALIGNMENT));
    int totalBytes = Math.addExact(capsuleOffset, capsuleRawBytes);
    int capsuleRva = Math.toIntExact(align(
        (long) TEXT_RVA + textVirtualBytes, SECTION_ALIGNMENT));
    int imageBytes = Math.toIntExact(align(
        (long) capsuleRva + capsule.length, SECTION_ALIGNMENT));
    if (totalBytes > MAX_IMAGE_BYTES || imageBytes > abi.maximumMemoryBytes()) {
      throw new PackageFormatException("PE image is oversized");
    }

    ByteArrayOutputStream output = new ByteArrayOutputStream(totalBytes);
    writeDosHeader(output);
    while (output.size() < PE_OFFSET) {
      output.write(0);
    }
    writePeHeaders(
        output,
        machine(abi),
        TEXT_RVA + LOCATOR_BYTES + entryOffset,
        textRawBytes,
        capsuleRawBytes,
        imageBytes);
    writeSection(
        output,
        ".text",
        textVirtualBytes,
        TEXT_RVA,
        textRawBytes,
        HEADER_BYTES,
        TEXT_CHARACTERISTICS);
    writeSection(
        output,
        ".wheel",
        capsule.length,
        capsuleRva,
        capsuleRawBytes,
        capsuleOffset,
        CAPSULE_CHARACTERISTICS);
    while (output.size() < HEADER_BYTES) {
      output.write(0);
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
    while (output.size() < totalBytes) {
      output.write(0);
    }
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
      throw new PackageFormatException("Invalid PE runtime text length");
    }
    if (entryOffset < 0 || entryOffset >= runtime.length) {
      throw new PackageFormatException("Invalid PE runtime entry offset");
    }
    int machine = machine(abi);
    String architecture = machine == MACHINE_AMD64 ? "x86_64" : "aarch64";
    if (plan.format() != PlatformAbi.Format.PE_COFF
        || !plan.stripped()
        || plan.runtimeMode() != NativeImagePlan.RuntimeMode.EMBEDDED_VM
        || !plan.platformAbi().equals(abi.identity())
        || !plan.capsule().equals(capsule.identity())
        || !plan.runtime().equals(identity(runtime))
        || !capsule.root().platformAbi().equals(abi.identity())
        || capsule.root().runtimeMode() != plan.runtimeMode()
        || !plan.target().equals(architecture + "-pc-windows-msvc")) {
      throw new PackageFormatException("PE inputs do not match the native image plan");
    }
    CapsuleEntry rootWbc = capsule.entries().stream()
        .filter(entry -> entry.name().equals(capsule.root().rootWbc()))
        .findFirst()
        .orElseThrow(() -> new PackageFormatException("Capsule root WBC is missing"));
    if (!plan.portableArtifact().equals(rootWbc.identity())) {
      throw new PackageFormatException("PE plan portable artifact is not the root WBC");
    }
  }

  private static void requireProfile(PlatformAbi abi) {
    machine(abi);
  }

  private static int machine(PlatformAbi abi) {
    if (abi.format() != PlatformAbi.Format.PE_COFF
        || !abi.osAbi().equals("windows-msvc")) {
      throw new PackageFormatException("PE image profile requires windows-msvc");
    }
    return switch (abi.architecture()) {
      case "x86_64" -> MACHINE_AMD64;
      case "aarch64" -> MACHINE_ARM64;
      default -> throw new PackageFormatException(
          "Unsupported PE architecture " + abi.architecture());
    };
  }

  private static void requireHeaders(
      byte[] image,
      PlatformAbi abi,
      Locator locator,
      int textVirtualBytes,
      int textRawBytes,
      int capsuleRva,
      int capsuleRawBytes,
      int imageBytes) {
    ByteBuffer input = ByteBuffer.wrap(image).order(ByteOrder.LITTLE_ENDIAN);
    if (Short.toUnsignedInt(input.getShort()) != 0x5a4d || input.getInt(60) != PE_OFFSET) {
      throw new PackageFormatException("Invalid canonical PE DOS header");
    }
    input.position(PE_OFFSET);
    if (input.getInt() != 0x0000_4550
        || Short.toUnsignedInt(input.getShort()) != machine(abi)
        || Short.toUnsignedInt(input.getShort()) != 2
        || input.getInt() != 0
        || input.getInt() != 0
        || input.getInt() != 0
        || Short.toUnsignedInt(input.getShort()) != OPTIONAL_HEADER_BYTES
        || Short.toUnsignedInt(input.getShort())
            != (IMAGE_FILE_EXECUTABLE_IMAGE | IMAGE_FILE_LARGE_ADDRESS_AWARE)) {
      throw new PackageFormatException("Invalid canonical PE COFF header");
    }
    requireOptionalHeader(
        input,
        TEXT_RVA + LOCATOR_BYTES + locator.runtimeEntryOffset(),
        textRawBytes,
        capsuleRawBytes,
        imageBytes);
    requireSection(
        input,
        ".text",
        textVirtualBytes,
        TEXT_RVA,
        textRawBytes,
        HEADER_BYTES,
        TEXT_CHARACTERISTICS);
    requireSection(
        input,
        ".wheel",
        locator.capsuleLength(),
        capsuleRva,
        capsuleRawBytes,
        locator.capsuleOffset(),
        CAPSULE_CHARACTERISTICS);
  }

  private static void requireOptionalHeader(
      ByteBuffer input,
      int entryRva,
      int textRawBytes,
      int capsuleRawBytes,
      int imageBytes) {
    if (Short.toUnsignedInt(input.getShort()) != IMAGE_NT_OPTIONAL_HDR64_MAGIC
        || input.get() != 0
        || input.get() != 0
        || input.getInt() != textRawBytes
        || input.getInt() != capsuleRawBytes
        || input.getInt() != 0
        || input.getInt() != entryRva
        || input.getInt() != TEXT_RVA
        || input.getLong() != IMAGE_BASE
        || input.getInt() != SECTION_ALIGNMENT
        || input.getInt() != FILE_ALIGNMENT
        || Short.toUnsignedInt(input.getShort()) != 6
        || Short.toUnsignedInt(input.getShort()) != 0
        || input.getInt() != 0
        || Short.toUnsignedInt(input.getShort()) != 6
        || Short.toUnsignedInt(input.getShort()) != 0
        || input.getInt() != 0
        || input.getInt() != imageBytes
        || input.getInt() != HEADER_BYTES
        || input.getInt() != 0
        || Short.toUnsignedInt(input.getShort()) != IMAGE_SUBSYSTEM_WINDOWS_CUI
        || Short.toUnsignedInt(input.getShort())
            != (IMAGE_DLLCHARACTERISTICS_HIGH_ENTROPY_VA
                | IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE
                | IMAGE_DLLCHARACTERISTICS_NX_COMPAT)
        || input.getLong() != 1024L * 1024
        || input.getLong() != 4096
        || input.getLong() != 1024L * 1024
        || input.getLong() != 4096
        || input.getInt() != 0
        || input.getInt() != 16) {
      throw new PackageFormatException("Invalid canonical PE optional header");
    }
    for (int directory = 0; directory < 16 * 2; directory++) {
      if (input.getInt() != 0) {
        throw new PackageFormatException("Nonzero canonical PE data directory");
      }
    }
  }

  private static void requireSection(
      ByteBuffer input,
      String name,
      int virtualBytes,
      int rva,
      int rawBytes,
      int rawOffset,
      int characteristics) {
    byte[] encodedName = new byte[8];
    input.get(encodedName);
    if (!Arrays.equals(encodedName, sectionName(name))
        || input.getInt() != virtualBytes
        || input.getInt() != rva
        || input.getInt() != rawBytes
        || input.getInt() != rawOffset
        || input.getInt() != 0
        || input.getInt() != 0
        || input.getShort() != 0
        || input.getShort() != 0
        || input.getInt() != characteristics) {
      throw new PackageFormatException("Invalid canonical PE section");
    }
  }

  private static Locator readLocator(byte[] image) {
    ByteBuffer input = ByteBuffer.wrap(image).order(ByteOrder.LITTLE_ENDIAN);
    input.position(HEADER_BYTES);
    byte[] magic = new byte[LOCATOR_MAGIC.length];
    input.get(magic);
    if (!Arrays.equals(magic, LOCATOR_MAGIC)) {
      throw new PackageFormatException("Invalid Wheeler PE locator magic");
    }
    String plan = readHash(input);
    int runtimeOffset = nonnegative(input.getInt(), "runtime offset");
    int runtimeLength = nonnegative(input.getInt(), "runtime length");
    int capsuleOffset = nonnegative(input.getInt(), "capsule offset");
    int capsuleLength = nonnegative(input.getInt(), "capsule length");
    int entryOffset = nonnegative(input.getInt(), "runtime entry offset");
    if (input.getInt() != 0) {
      throw new PackageFormatException("Invalid Wheeler PE locator reserved field");
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

  private static void writeDosHeader(ByteArrayOutputStream output) {
    writeShort(output, 0x5a4d);
    while (output.size() < DOS_HEADER_BYTES - Integer.BYTES) {
      output.write(0);
    }
    writeInt(output, PE_OFFSET);
  }

  private static void writePeHeaders(
      ByteArrayOutputStream output,
      int machine,
      int entryRva,
      int textRawBytes,
      int capsuleRawBytes,
      int imageBytes) {
    writeInt(output, 0x0000_4550);
    writeShort(output, machine);
    writeShort(output, 2);
    writeInt(output, 0);
    writeInt(output, 0);
    writeInt(output, 0);
    writeShort(output, OPTIONAL_HEADER_BYTES);
    writeShort(output, IMAGE_FILE_EXECUTABLE_IMAGE | IMAGE_FILE_LARGE_ADDRESS_AWARE);
    writeOptionalHeader(output, entryRva, textRawBytes, capsuleRawBytes, imageBytes);
  }

  private static void writeOptionalHeader(
      ByteArrayOutputStream output,
      int entryRva,
      int textRawBytes,
      int capsuleRawBytes,
      int imageBytes) {
    writeShort(output, IMAGE_NT_OPTIONAL_HDR64_MAGIC);
    output.write(0);
    output.write(0);
    writeInt(output, textRawBytes);
    writeInt(output, capsuleRawBytes);
    writeInt(output, 0);
    writeInt(output, entryRva);
    writeInt(output, TEXT_RVA);
    writeLong(output, IMAGE_BASE);
    writeInt(output, SECTION_ALIGNMENT);
    writeInt(output, FILE_ALIGNMENT);
    writeShort(output, 6);
    writeShort(output, 0);
    writeInt(output, 0);
    writeShort(output, 6);
    writeShort(output, 0);
    writeInt(output, 0);
    writeInt(output, imageBytes);
    writeInt(output, HEADER_BYTES);
    writeInt(output, 0);
    writeShort(output, IMAGE_SUBSYSTEM_WINDOWS_CUI);
    writeShort(output,
        IMAGE_DLLCHARACTERISTICS_HIGH_ENTROPY_VA
            | IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE
            | IMAGE_DLLCHARACTERISTICS_NX_COMPAT);
    writeLong(output, 1024L * 1024);
    writeLong(output, 4096);
    writeLong(output, 1024L * 1024);
    writeLong(output, 4096);
    writeInt(output, 0);
    writeInt(output, 16);
    for (int directory = 0; directory < 16 * 2; directory++) {
      writeInt(output, 0);
    }
  }

  private static void writeSection(
      ByteArrayOutputStream output,
      String name,
      int virtualBytes,
      int rva,
      int rawBytes,
      int rawOffset,
      int characteristics) {
    output.writeBytes(sectionName(name));
    writeInt(output, virtualBytes);
    writeInt(output, rva);
    writeInt(output, rawBytes);
    writeInt(output, rawOffset);
    writeInt(output, 0);
    writeInt(output, 0);
    writeShort(output, 0);
    writeShort(output, 0);
    writeInt(output, characteristics);
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
    if (output.size() != HEADER_BYTES + LOCATOR_BYTES) {
      throw new IllegalStateException("Wheeler PE locator has the wrong encoded size");
    }
  }

  private static byte[] sectionName(String name) {
    byte[] result = new byte[8];
    byte[] encoded = name.getBytes(java.nio.charset.StandardCharsets.US_ASCII);
    System.arraycopy(encoded, 0, result, 0, encoded.length);
    return result;
  }

  private static int nonnegative(int value, String description) {
    if (value < 0) {
      throw new PackageFormatException("Invalid PE " + description);
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

  /** Verified unsigned PE image and exact embedded runtime and capsule ranges. */
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
