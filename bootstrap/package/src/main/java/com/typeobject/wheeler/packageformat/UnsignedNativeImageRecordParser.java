package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Set;

/** Strict canonical decoder for schema-1 unsigned native image records. */
public final class UnsignedNativeImageRecordParser {
  private static final Set<String> ROOT_FIELDS = Set.of("schema", "unsigned-native-image");
  private static final Set<String> IMAGE_FIELDS = Set.of(
      "format", "target", "plan", "platform-abi", "capsule", "prev", "bytes");

  public UnsignedNativeImageRecord parse(byte[] bytes) {
    String text = strictUtf8(bytes);
    CanonicalYaml.Mapping root = CanonicalYaml.mapping(
        CanonicalYaml.parse(text, "unsigned native image record"),
        "unsigned native image record");
    CanonicalYaml.fields(root, ROOT_FIELDS, "unsigned native image record");
    int schema = CanonicalYaml.integer(
        CanonicalYaml.required(root, "schema", "unsigned native image record"),
        "unsigned native image schema");
    if (schema != UnsignedNativeImageRecord.SCHEMA_VERSION) {
      throw new PackageFormatException("Unsupported unsigned native image schema " + schema);
    }
    CanonicalYaml.Mapping image = CanonicalYaml.mapping(
        CanonicalYaml.required(root, "unsigned-native-image", "unsigned native image record"),
        "unsigned native image");
    CanonicalYaml.fields(image, IMAGE_FIELDS, "unsigned native image");
    UnsignedNativeImageRecord result = new UnsignedNativeImageRecord(
        format(string(image, "format")),
        string(image, "target"),
        string(image, "plan"),
        string(image, "platform-abi"),
        string(image, "capsule"),
        string(image, "prev"),
        integer(image, "bytes"));
    if (!result.canonicalText().equals(text)) {
      throw new PackageFormatException("Unsigned native image record is not canonical");
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

  private static String string(CanonicalYaml.Mapping mapping, String key) {
    return CanonicalYaml.string(
        CanonicalYaml.required(mapping, key, "unsigned native image"),
        "unsigned native image " + key);
  }

  private static int integer(CanonicalYaml.Mapping mapping, String key) {
    return CanonicalYaml.integer(
        CanonicalYaml.required(mapping, key, "unsigned native image"),
        "unsigned native image " + key);
  }

  private static String strictUtf8(byte[] bytes) {
    if (bytes == null || bytes.length > UnsignedNativeImageRecord.MAX_RECORD_BYTES) {
      throw new PackageFormatException("Unsigned native image record is oversized");
    }
    String text = new String(bytes, StandardCharsets.UTF_8);
    if (!Arrays.equals(bytes, text.getBytes(StandardCharsets.UTF_8))) {
      throw new PackageFormatException("Unsigned native image record is not strict UTF-8");
    }
    return text;
  }
}
