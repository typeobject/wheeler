package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Set;
import java.util.regex.Pattern;

/** Canonical, closed feature vocabulary for one bootstrap source profile. */
public record BootstrapFeatureManifest(String profile, List<Feature> features) {
  public static final int SCHEMA_VERSION = 1;
  public static final String FILE_NAME = "wheeler.bootstrap-features.yaml";
  private static final int MAX_FEATURES = 1_024;
  private static final Pattern NAME = Pattern.compile("[a-z][a-z0-9]*(?:-[a-z0-9]+)*");
  private static final Pattern PROFILE = Pattern.compile("[A-Za-z0-9][A-Za-z0-9._-]{0,127}");

  public BootstrapFeatureManifest {
    if (profile == null || !PROFILE.matcher(profile).matches()) {
      throw new PackageFormatException("Invalid bootstrap feature profile");
    }
    if (features == null || features.isEmpty() || features.size() > MAX_FEATURES) {
      throw new PackageFormatException("Bootstrap profile needs 1 through 1,024 features");
    }
    List<Feature> ordered = new ArrayList<>(features);
    ordered.sort(Comparator.comparing(Feature::name));
    Set<String> names = new HashSet<>();
    for (Feature feature : ordered) {
      if (!names.add(feature.name())) {
        throw new PackageFormatException("Duplicate bootstrap feature " + feature.name());
      }
    }
    features = List.copyOf(ordered);
  }

  /** Returns the sole canonical YAML representation. */
  public String canonicalText() {
    StringBuilder text = new StringBuilder("schema: 1\nprofile: ")
        .append(CanonicalYaml.quote(profile)).append("\nfeatures:\n");
    for (Feature feature : features) {
      text.append("  - name: ").append(CanonicalYaml.quote(feature.name())).append('\n')
          .append("    version: ").append(feature.version()).append('\n');
    }
    return text.toString();
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

  /** One required semantic contract; versions change only when that contract changes. */
  public record Feature(String name, int version) {
    public Feature {
      if (name == null || !NAME.matcher(name).matches()) {
        throw new PackageFormatException("Invalid bootstrap feature name");
      }
      if (version < 1 || version > 1_000_000) {
        throw new PackageFormatException("Invalid bootstrap feature version for " + name);
      }
    }
  }
}
