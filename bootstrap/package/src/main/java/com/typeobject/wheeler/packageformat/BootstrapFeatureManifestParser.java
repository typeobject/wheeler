package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;

/** Strict decoder for {@code wheeler.bootstrap-features.yaml}. */
public final class BootstrapFeatureManifestParser {
  public BootstrapFeatureManifest parse(byte[] bytes) {
    String text = strictUtf8(bytes);
    CanonicalYaml.Mapping root = CanonicalYaml.mapping(
        CanonicalYaml.parse(text, BootstrapFeatureManifest.FILE_NAME), "bootstrap features");
    CanonicalYaml.fields(root, Set.of("schema", "profile", "features"), "bootstrap features");
    int schema = CanonicalYaml.integer(
        CanonicalYaml.required(root, "schema", "bootstrap features"), "schema");
    if (schema != BootstrapFeatureManifest.SCHEMA_VERSION) {
      throw new PackageFormatException("Unsupported bootstrap feature schema " + schema);
    }
    String profile = CanonicalYaml.string(
        CanonicalYaml.required(root, "profile", "bootstrap features"), "profile");
    CanonicalYaml.Sequence sequence = CanonicalYaml.sequence(
        CanonicalYaml.required(root, "features", "bootstrap features"), "features");
    List<BootstrapFeatureManifest.Feature> features = new ArrayList<>();
    for (CanonicalYaml.Value value : sequence.values()) {
      CanonicalYaml.Mapping feature = CanonicalYaml.mapping(value, "bootstrap feature");
      CanonicalYaml.fields(feature, Set.of("name", "version"), "bootstrap feature");
      features.add(new BootstrapFeatureManifest.Feature(
          CanonicalYaml.string(
              CanonicalYaml.required(feature, "name", "bootstrap feature"), "feature name"),
          CanonicalYaml.integer(
              CanonicalYaml.required(feature, "version", "bootstrap feature"),
              "feature version")));
    }
    BootstrapFeatureManifest manifest = new BootstrapFeatureManifest(profile, features);
    if (!text.equals(manifest.canonicalText())) {
      throw new PackageFormatException("Bootstrap feature manifest is not canonical");
    }
    return manifest;
  }

  private static String strictUtf8(byte[] bytes) {
    String text = new String(bytes, StandardCharsets.UTF_8);
    if (!Arrays.equals(bytes, text.getBytes(StandardCharsets.UTF_8))) {
      throw new PackageFormatException("Bootstrap features are not strict UTF-8");
    }
    return text;
  }
}
