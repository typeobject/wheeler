package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.List;
import java.util.Set;
import java.util.regex.Pattern;

/** Canonical first-profile boundary between native Wheeler code and host services. */
public record PlatformAbi(
    Format format,
    String architecture,
    String osAbi,
    int pointerBits,
    Endianness endianness,
    int pageBytes,
    int minimumAlignment,
    int maximumArgumentBytes,
    int maximumIoBytes,
    int maximumPathBytes,
    int maximumHandles,
    long maximumMemoryBytes,
    List<String> cpuFeatures,
    List<String> baselineLibraries,
    List<Service> services) {
  public static final int SCHEMA_VERSION = 1;
  private static final int MAX_ARGUMENT_BYTES = 1 << 20;
  private static final int MAX_IO_BYTES = 16 << 20;
  private static final int MAX_PATH_BYTES = 4096;
  private static final int MAX_HANDLES = 65_535;
  private static final long MAX_MEMORY_BYTES = 1L << 40;
  private static final Pattern NAME = Pattern.compile("[a-z][a-z0-9_.-]{0,63}");
  private static final Set<Service> REQUIRED_SERVICES = Set.of(
      Service.PROCESS_ARGUMENTS,
      Service.PROCESS_EXIT,
      Service.STDIN_READ,
      Service.STDOUT_WRITE,
      Service.STDERR_WRITE,
      Service.CAPABILITY_FILE_OPEN,
      Service.FILE_READ_AT,
      Service.FILE_ATOMIC_REPLACE,
      Service.DIRECTORY_MANIFEST,
      Service.MEMORY_RESERVE,
      Service.MEMORY_RELEASE,
      Service.MEMORY_PROTECT);

  /** Loader-native file family. */
  public enum Format {
    ELF("elf"),
    MACH_O("mach-o"),
    PE_COFF("pe-coff");

    private final String wireName;

    Format(String wireName) {
      this.wireName = wireName;
    }

    public String wireName() {
      return wireName;
    }
  }

  /** Native scalar byte order. */
  public enum Endianness {
    LITTLE("little");

    private final String wireName;

    Endianness(String wireName) {
      this.wireName = wireName;
    }

    public String wireName() {
      return wireName;
    }
  }

  /** Stable result code returned instead of a host exception. */
  public enum Status {
    OK(0),
    INVALID(1),
    DENIED(2),
    NOT_FOUND(3),
    EXHAUSTED(4),
    IO(5),
    INTERRUPTED(6),
    UNSUPPORTED(7),
    CHANGED(8);

    private final int code;

    Status(int code) {
      this.code = code;
    }

    public int code() {
      return code;
    }
  }

  /** Version-one host call with fixed-width scalar, span, status, and handle fields. */
  public enum Service {
    CAPABILITY_FILE_OPEN(
        "capability-file-open", "(u32,byte-span,u32)->(status,u32)"),
    DIRECTORY_MANIFEST(
        "directory-manifest", "(u32,mut-span)->(status,u64)"),
    FILE_ATOMIC_REPLACE(
        "file-atomic-replace", "(u32,byte-span,byte-span)->status"),
    FILE_READ_AT(
        "file-read-at", "(u32,u64,mut-span)->(status,u64)"),
    MEMORY_PROTECT(
        "memory-protect", "(u32,u64,u64,u32)->status"),
    MEMORY_RELEASE(
        "memory-release", "(u32)->status"),
    MEMORY_RESERVE(
        "memory-reserve", "(u64,u64)->(status,u32,u64)"),
    MONOTONIC_DEADLINE(
        "monotonic-deadline", "()->(status,u64)"),
    PROCESS_ARGUMENTS(
        "process-arguments", "(u32,mut-span)->(status,u64)"),
    PROCESS_EXIT(
        "process-exit", "(i32)->noreturn"),
    STDERR_WRITE(
        "stderr-write", "(byte-span)->(status,u64)"),
    STDIN_READ(
        "stdin-read", "(mut-span)->(status,u64)"),
    STDOUT_WRITE(
        "stdout-write", "(byte-span)->(status,u64)"),
    TARGET_SUBMIT(
        "target-submit", "(u32,byte-span,mut-span)->(status,u64)");

    private final String wireName;
    private final String signature;

    Service(String wireName, String signature) {
      this.wireName = wireName;
      this.signature = signature;
    }

    public String wireName() {
      return wireName;
    }

    public String signature() {
      return signature;
    }
  }

  public PlatformAbi {
    if (format == null || endianness == null) {
      throw new PackageFormatException("Platform ABI format and endianness are required");
    }
    architecture = name(architecture, "platform architecture");
    osAbi = name(osAbi, "platform OS ABI");
    if (pointerBits != 64 || endianness != Endianness.LITTLE) {
      throw new PackageFormatException(
          "Platform ABI profile 1 requires little-endian 64-bit pointers");
    }
    if (!powerOfTwo(pageBytes) || pageBytes < 4096 || 65_536 < pageBytes) {
      throw new PackageFormatException(
          "Platform ABI page bytes must be a power of two from 4096 to 65536");
    }
    if (!powerOfTwo(minimumAlignment)
        || minimumAlignment < 8
        || pageBytes < minimumAlignment) {
      throw new PackageFormatException("Invalid platform ABI minimum alignment");
    }
    positiveBound(maximumArgumentBytes, MAX_ARGUMENT_BYTES, "argument bytes");
    positiveBound(maximumIoBytes, MAX_IO_BYTES, "I/O bytes");
    positiveBound(maximumPathBytes, MAX_PATH_BYTES, "path bytes");
    positiveBound(maximumHandles, MAX_HANDLES, "handles");
    if (maximumMemoryBytes < pageBytes || MAX_MEMORY_BYTES < maximumMemoryBytes) {
      throw new PackageFormatException("Invalid platform ABI memory bound");
    }
    if (maximumMemoryBytes % pageBytes != 0) {
      throw new PackageFormatException("Platform ABI memory bound must contain complete pages");
    }
    cpuFeatures = names(cpuFeatures, 32, "CPU feature");
    baselineLibraries = names(baselineLibraries, 16, "baseline library");
    if (services == null
        || services.size() > Service.values().length
        || services.stream().anyMatch(service -> service == null)) {
      throw new PackageFormatException("Invalid platform ABI service list");
    }
    services = List.copyOf(services);
    requireSortedDistinct(
        services.stream().map(Service::wireName).toList(), "platform ABI services");
    if (!services.containsAll(REQUIRED_SERVICES)) {
      throw new PackageFormatException("Platform ABI omits a required profile-1 service");
    }
  }

  /** Returns canonical schema-1 bytes without host-derived fields. */
  public byte[] canonicalBytes() {
    return canonicalText().getBytes(StandardCharsets.UTF_8);
  }

  /** Returns the SHA-256 identity of the complete canonical descriptor. */
  public String identity() {
    try {
      return HexFormat.of().formatHex(
          MessageDigest.getInstance("SHA-256").digest(canonicalBytes()));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  /** Parses one exact canonical schema-1 descriptor. */
  public static PlatformAbi parse(byte[] bytes) {
    return new PlatformAbiParser().parse(bytes);
  }

  /** Returns canonical schema-1 YAML. */
  public String canonicalText() {
    return "schema: " + SCHEMA_VERSION + "\n"
        + "platform-abi:\n"
        + field("format", format.wireName())
        + field("architecture", architecture)
        + field("os-abi", osAbi)
        + "  pointer-bits: " + pointerBits + "\n"
        + field("endianness", endianness.wireName())
        + "  page-bytes: " + pageBytes + "\n"
        + "  minimum-alignment: " + minimumAlignment + "\n"
        + "  maximum-argument-bytes: " + maximumArgumentBytes + "\n"
        + "  maximum-io-bytes: " + maximumIoBytes + "\n"
        + "  maximum-path-bytes: " + maximumPathBytes + "\n"
        + "  maximum-handles: " + maximumHandles + "\n"
        + "  maximum-memory-bytes: " + maximumMemoryBytes + "\n"
        + sequence("cpu-features", cpuFeatures)
        + sequence("baseline-libraries", baselineLibraries)
        + sequence("services", services.stream().map(Service::wireName).toList());
  }

  private static List<String> names(List<String> values, int maximum, String description) {
    if (values == null || maximum < values.size()) {
      throw new PackageFormatException("Invalid " + description + " list");
    }
    List<String> result = values.stream().map(value -> name(value, description)).toList();
    requireSortedDistinct(result, description + " list");
    return result;
  }

  private static String name(String value, String description) {
    if (value == null || !NAME.matcher(value).matches()) {
      throw new PackageFormatException("Invalid " + description);
    }
    return value;
  }

  private static void requireSortedDistinct(List<String> values, String description) {
    List<String> sorted = values.stream().sorted(Comparator.naturalOrder()).distinct().toList();
    if (!values.equals(sorted)) {
      throw new PackageFormatException(description + " must be sorted and distinct");
    }
  }

  private static void positiveBound(int value, int maximum, String description) {
    if (value < 1 || maximum < value) {
      throw new PackageFormatException("Invalid platform ABI " + description + " bound");
    }
  }

  private static boolean powerOfTwo(int value) {
    return 0 < value && (value & (value - 1)) == 0;
  }

  private static String field(String name, String value) {
    return "  " + name + ": " + CanonicalYaml.quote(value) + "\n";
  }

  private static String sequence(String name, List<String> values) {
    if (values.isEmpty()) {
      return "  " + name + ": []\n";
    }
    StringBuilder result = new StringBuilder("  ").append(name).append(":\n");
    for (String value : values) {
      result.append("    - ").append(CanonicalYaml.quote(value)).append('\n');
    }
    return result.toString();
  }
}
