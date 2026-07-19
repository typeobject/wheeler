package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;
import java.util.regex.Pattern;

/** Content-bound evidence required before promoting a Wheeler recovery compiler. */
public record BootstrapManifest(
    Source source,
    OrdinaryDerivation ordinary,
    DiverseDerivation diverse,
    String acceptanceArtifactSet) {
  public static final int SCHEMA_VERSION = 1;
  public static final String FILE_NAME = "wheeler.bootstrap.yaml";
  private static final Pattern IDENTITY = Pattern.compile("[0-9a-f]{64}");
  private static final Pattern PROFILE = Pattern.compile("[A-Za-z0-9][A-Za-z0-9._-]{0,127}");

  public BootstrapManifest {
    source = Objects.requireNonNull(source, "source");
    ordinary = Objects.requireNonNull(ordinary, "ordinary");
    diverse = Objects.requireNonNull(diverse, "diverse");
    acceptanceArtifactSet = identity(acceptanceArtifactSet, "acceptance artifact set");
    if (!ordinary.stage1().equals(ordinary.stage2())) {
      throw new PackageFormatException("Bootstrap stages do not form a fixed point");
    }
    if (!ordinary.stage1().equals(diverse.output())) {
      throw new PackageFormatException("Diverse output does not match the ordinary bootstrap");
    }
    if (!ordinary.diagnostics().equals(diverse.diagnostics())) {
      throw new PackageFormatException("Bootstrap diagnostics differ between derivations");
    }
    if (ordinary.toolchain().equals(diverse.toolchain())) {
      throw new PackageFormatException("Diverse bootstrap toolchains must have distinct identities");
    }
    if (ordinary.compiler().equals(diverse.compiler())) {
      throw new PackageFormatException("Diverse bootstrap compilers must have distinct identities");
    }
  }

  /** Returns the sole canonical YAML representation of this evidence. */
  public String canonicalText() {
    return "schema: " + SCHEMA_VERSION + "\n"
        + "source:\n"
        + field("  archive", source.archive())
        + field("  manifest", source.manifest())
        + field("  lock", source.lock())
        + "  profile: " + quote(source.profile()) + "\n"
        + field("  options", source.options())
        + field("  limits", source.limits())
        + "ordinary:\n"
        + fields(ordinary.toolchain(), ordinary.compiler(), ordinary.runtime(), ordinary.verifier())
        + field("  stage-1", ordinary.stage1())
        + field("  stage-2", ordinary.stage2())
        + field("  diagnostics", ordinary.diagnostics())
        + "diverse:\n"
        + fields(diverse.toolchain(), diverse.compiler(), diverse.runtime(), diverse.verifier())
        + field("  output", diverse.output())
        + field("  diagnostics", diverse.diagnostics())
        + "acceptance:\n"
        + field("  artifact-set", acceptanceArtifactSet);
  }

  public byte[] canonicalBytes() {
    return canonicalText().getBytes(StandardCharsets.UTF_8);
  }

  public String identity() {
    try {
      return HexFormat.of().formatHex(
          MessageDigest.getInstance("SHA-256").digest(canonicalBytes()));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static String fields(
      String toolchain, String compiler, String runtime, String verifier) {
    return field("  toolchain", toolchain)
        + field("  compiler", compiler)
        + field("  runtime", runtime)
        + field("  verifier", verifier);
  }

  private static String field(String name, String value) {
    return name + ": " + quote(value) + "\n";
  }

  private static String quote(String value) {
    return CanonicalYaml.quote(value);
  }

  private static String identity(String value, String description) {
    Objects.requireNonNull(value, description);
    if (!IDENTITY.matcher(value).matches()) {
      throw new PackageFormatException("Invalid SHA-256 identity for " + description);
    }
    return value;
  }

  /** Canonical compiler source, lock, options, and limits. */
  public record Source(
      String archive,
      String manifest,
      String lock,
      String profile,
      String options,
      String limits) {
    public Source {
      archive = identity(archive, "source archive");
      manifest = identity(manifest, "source manifest");
      lock = identity(lock, "source lock");
      Objects.requireNonNull(profile, "profile");
      if (!PROFILE.matcher(profile).matches()) {
        throw new PackageFormatException("Invalid bootstrap source profile");
      }
      options = identity(options, "compiler options");
      limits = identity(limits, "compiler limits");
    }
  }

  /** Ordinary stage-0, stage-1, and stage-2 derivation identities. */
  public record OrdinaryDerivation(
      String toolchain,
      String compiler,
      String runtime,
      String verifier,
      String stage1,
      String stage2,
      String diagnostics) {
    public OrdinaryDerivation {
      toolchain = identity(toolchain, "ordinary toolchain");
      compiler = identity(compiler, "ordinary compiler");
      runtime = identity(runtime, "ordinary runtime");
      verifier = identity(verifier, "ordinary verifier");
      stage1 = identity(stage1, "stage 1");
      stage2 = identity(stage2, "stage 2");
      diagnostics = identity(diagnostics, "ordinary diagnostics");
    }
  }

  /** Independently derived trusted compilation identities. */
  public record DiverseDerivation(
      String toolchain,
      String compiler,
      String runtime,
      String verifier,
      String output,
      String diagnostics) {
    public DiverseDerivation {
      toolchain = identity(toolchain, "diverse toolchain");
      compiler = identity(compiler, "diverse compiler");
      runtime = identity(runtime, "diverse runtime");
      verifier = identity(verifier, "diverse verifier");
      output = identity(output, "diverse output");
      diagnostics = identity(diagnostics, "diverse diagnostics");
    }
  }
}
