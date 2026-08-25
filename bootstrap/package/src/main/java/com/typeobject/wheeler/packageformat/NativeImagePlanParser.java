package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Set;

/** Strict canonical decoder for schema-1 native image build inputs. */
public final class NativeImagePlanParser {
  private static final int MAX_BYTES = 16 * 1024;
  private static final Set<String> ROOT_FIELDS = Set.of("schema", "native-image");
  private static final Set<String> IMAGE_FIELDS = Set.of(
      "format",
      "target",
      "runtime-mode",
      "sealed",
      "stripped",
      "portable-artifact",
      "platform-abi",
      "capsule",
      "backend",
      "runtime",
      "compiler",
      "sysroot",
      "providers",
      "options",
      "link-arguments");

  public NativeImagePlan parse(byte[] bytes) {
    String text = strictUtf8(bytes);
    CanonicalYaml.Mapping root = CanonicalYaml.mapping(
        CanonicalYaml.parse(text, "native image plan"), "native image plan");
    CanonicalYaml.fields(root, ROOT_FIELDS, "native image plan");
    int schema = CanonicalYaml.integer(
        CanonicalYaml.required(root, "schema", "native image plan"), "native image schema");
    if (schema != NativeImagePlan.SCHEMA_VERSION) {
      throw new PackageFormatException("Unsupported native image plan schema " + schema);
    }
    CanonicalYaml.Mapping image = CanonicalYaml.mapping(
        CanonicalYaml.required(root, "native-image", "native image plan"),
        "native image record");
    CanonicalYaml.fields(image, IMAGE_FIELDS, "native image record");
    NativeImagePlan result = new NativeImagePlan(
        format(string(image, "format")),
        string(image, "target"),
        runtimeMode(string(image, "runtime-mode")),
        bool(image, "sealed"),
        bool(image, "stripped"),
        string(image, "portable-artifact"),
        string(image, "platform-abi"),
        string(image, "capsule"),
        string(image, "backend"),
        string(image, "runtime"),
        string(image, "compiler"),
        string(image, "sysroot"),
        string(image, "providers"),
        string(image, "options"),
        string(image, "link-arguments"));
    if (!result.canonicalText().equals(text)) {
      throw new PackageFormatException("Native image plan is not canonical");
    }
    return result;
  }

  private static PlatformAbi.Format format(String value) {
    for (PlatformAbi.Format format : PlatformAbi.Format.values()) {
      if (format.wireName().equals(value)) {
        return format;
      }
    }
    throw new PackageFormatException("Unknown native image format " + value);
  }

  private static NativeImagePlan.RuntimeMode runtimeMode(String value) {
    for (NativeImagePlan.RuntimeMode mode : NativeImagePlan.RuntimeMode.values()) {
      if (mode.wireName().equals(value)) {
        return mode;
      }
    }
    throw new PackageFormatException("Unknown native image runtime mode " + value);
  }

  private static String string(CanonicalYaml.Mapping mapping, String key) {
    return CanonicalYaml.string(
        CanonicalYaml.required(mapping, key, "native image"), "native image " + key);
  }

  private static boolean bool(CanonicalYaml.Mapping mapping, String key) {
    return CanonicalYaml.bool(
        CanonicalYaml.required(mapping, key, "native image"), "native image " + key);
  }

  private static String strictUtf8(byte[] bytes) {
    if (bytes == null || bytes.length > MAX_BYTES) {
      throw new PackageFormatException("Native image plan is oversized");
    }
    String text = new String(bytes, StandardCharsets.UTF_8);
    if (!Arrays.equals(bytes, text.getBytes(StandardCharsets.UTF_8))) {
      throw new PackageFormatException("Native image plan is not strict UTF-8");
    }
    return text;
  }
}
