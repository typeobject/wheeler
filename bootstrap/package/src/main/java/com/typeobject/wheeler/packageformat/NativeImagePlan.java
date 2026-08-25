package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.regex.Pattern;

/** Canonical identity inputs for one derived target-qualified native image. */
public record NativeImagePlan(
    PlatformAbi.Format format,
    String target,
    RuntimeMode runtimeMode,
    boolean sealed,
    boolean stripped,
    String portableArtifact,
    String platformAbi,
    String capsule,
    String backend,
    String runtime,
    String compiler,
    String sysroot,
    String providers,
    String options,
    String linkArguments) {
  public static final int SCHEMA_VERSION = 1;
  private static final Pattern IDENTITY = Pattern.compile("[0-9a-f]{64}");
  private static final Pattern TARGET = Pattern.compile("[a-z0-9_]+-[a-z0-9_.-]+-[a-z0-9_.-]+");

  /** Execution engine embedded in or derived into the image. */
  public enum RuntimeMode {
    EMBEDDED_VM("embedded-vm"),
    AOT("aot");

    private final String wireName;

    RuntimeMode(String wireName) {
      this.wireName = wireName;
    }

    public String wireName() {
      return wireName;
    }
  }

  public NativeImagePlan {
    if (format == null || runtimeMode == null) {
      throw new PackageFormatException("Native image format and runtime mode are required");
    }
    if (target == null || !TARGET.matcher(target).matches() || 128 < target.length()) {
      throw new PackageFormatException("Invalid native image target");
    }
    portableArtifact = identity(portableArtifact, "portable artifact");
    platformAbi = identity(platformAbi, "platform ABI");
    capsule = identity(capsule, "application capsule");
    backend = identity(backend, "native backend");
    runtime = identity(runtime, "native runtime");
    compiler = identity(compiler, "native compiler");
    sysroot = identity(sysroot, "native sysroot");
    providers = identity(providers, "native provider closure");
    options = identity(options, "native options");
    linkArguments = identity(linkArguments, "native link arguments");
  }

  /** Returns canonical schema-1 bytes without executable output or signing data. */
  public byte[] canonicalBytes() {
    return canonicalText().getBytes(StandardCharsets.UTF_8);
  }

  /** Returns the SHA-256 build-input identity of the complete image plan. */
  public String identity() {
    try {
      return HexFormat.of().formatHex(
          MessageDigest.getInstance("SHA-256").digest(canonicalBytes()));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  /** Returns canonical schema-1 YAML. */
  public String canonicalText() {
    return "schema: " + SCHEMA_VERSION + "\n"
        + "native-image:\n"
        + field("format", format.wireName())
        + field("target", target)
        + field("runtime-mode", runtimeMode.wireName())
        + "  sealed: " + sealed + "\n"
        + "  stripped: " + stripped + "\n"
        + field("portable-artifact", portableArtifact)
        + field("platform-abi", platformAbi)
        + field("capsule", capsule)
        + field("backend", backend)
        + field("runtime", runtime)
        + field("compiler", compiler)
        + field("sysroot", sysroot)
        + field("providers", providers)
        + field("options", options)
        + field("link-arguments", linkArguments);
  }

  private static String identity(String value, String description) {
    if (value == null || !IDENTITY.matcher(value).matches()) {
      throw new PackageFormatException("Invalid SHA-256 identity for " + description);
    }
    return value;
  }

  private static String field(String name, String value) {
    return "  " + name + ": " + CanonicalYaml.quote(value) + "\n";
  }
}
