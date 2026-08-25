package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;

/** Strict canonical decoder for a schema-1 platform ABI descriptor. */
public final class PlatformAbiParser {
  private static final int MAX_BYTES = 16 * 1024;
  private static final Set<String> ROOT_FIELDS = Set.of("schema", "platform-abi");
  private static final Set<String> ABI_FIELDS = Set.of(
      "format",
      "architecture",
      "os-abi",
      "pointer-bits",
      "endianness",
      "page-bytes",
      "minimum-alignment",
      "maximum-argument-bytes",
      "maximum-io-bytes",
      "maximum-path-bytes",
      "maximum-handles",
      "maximum-memory-bytes",
      "cpu-features",
      "baseline-libraries",
      "services");

  public PlatformAbi parse(byte[] bytes) {
    String text = strictUtf8(bytes, "Platform ABI");
    CanonicalYaml.Mapping root = CanonicalYaml.mapping(
        CanonicalYaml.parse(text, "platform ABI"), "platform ABI");
    CanonicalYaml.fields(root, ROOT_FIELDS, "platform ABI");
    int schema = integer(root, "schema", "platform ABI");
    if (schema != PlatformAbi.SCHEMA_VERSION) {
      throw new PackageFormatException("Unsupported platform ABI schema " + schema);
    }
    CanonicalYaml.Mapping abi = CanonicalYaml.mapping(
        CanonicalYaml.required(root, "platform-abi", "platform ABI"), "platform ABI record");
    CanonicalYaml.fields(abi, ABI_FIELDS, "platform ABI record");
    PlatformAbi result = new PlatformAbi(
        format(string(abi, "format")),
        string(abi, "architecture"),
        string(abi, "os-abi"),
        integer(abi, "pointer-bits", "platform ABI"),
        endianness(string(abi, "endianness")),
        integer(abi, "page-bytes", "platform ABI"),
        integer(abi, "minimum-alignment", "platform ABI"),
        integer(abi, "maximum-argument-bytes", "platform ABI"),
        integer(abi, "maximum-io-bytes", "platform ABI"),
        integer(abi, "maximum-path-bytes", "platform ABI"),
        integer(abi, "maximum-handles", "platform ABI"),
        CanonicalYaml.longInteger(
            CanonicalYaml.required(abi, "maximum-memory-bytes", "platform ABI"),
            "platform ABI maximum memory"),
        strings(abi, "cpu-features"),
        strings(abi, "baseline-libraries"),
        services(abi));
    if (!result.canonicalText().equals(text)) {
      throw new PackageFormatException("Platform ABI descriptor is not canonical");
    }
    return result;
  }

  private static PlatformAbi.Format format(String value) {
    for (PlatformAbi.Format format : PlatformAbi.Format.values()) {
      if (format.wireName().equals(value)) {
        return format;
      }
    }
    throw new PackageFormatException("Unknown platform ABI format " + value);
  }

  private static PlatformAbi.Endianness endianness(String value) {
    for (PlatformAbi.Endianness endianness : PlatformAbi.Endianness.values()) {
      if (endianness.wireName().equals(value)) {
        return endianness;
      }
    }
    throw new PackageFormatException("Unknown platform ABI endianness " + value);
  }

  private static List<PlatformAbi.Service> services(CanonicalYaml.Mapping mapping) {
    ArrayList<PlatformAbi.Service> result = new ArrayList<>();
    for (String value : strings(mapping, "services")) {
      PlatformAbi.Service matched = null;
      for (PlatformAbi.Service service : PlatformAbi.Service.values()) {
        if (service.wireName().equals(value)) {
          matched = service;
          break;
        }
      }
      if (matched == null) {
        throw new PackageFormatException("Unknown platform ABI service " + value);
      }
      result.add(matched);
    }
    return List.copyOf(result);
  }

  private static List<String> strings(CanonicalYaml.Mapping mapping, String key) {
    CanonicalYaml.Sequence sequence = CanonicalYaml.sequence(
        CanonicalYaml.required(mapping, key, "platform ABI"), "platform ABI " + key);
    ArrayList<String> result = new ArrayList<>(sequence.values().size());
    for (CanonicalYaml.Value value : sequence.values()) {
      result.add(CanonicalYaml.string(value, "platform ABI " + key));
    }
    return List.copyOf(result);
  }

  private static String string(CanonicalYaml.Mapping mapping, String key) {
    return CanonicalYaml.string(
        CanonicalYaml.required(mapping, key, "platform ABI"), "platform ABI " + key);
  }

  private static int integer(
      CanonicalYaml.Mapping mapping, String key, String description) {
    return CanonicalYaml.integer(
        CanonicalYaml.required(mapping, key, description), description + " " + key);
  }

  private static String strictUtf8(byte[] bytes, String description) {
    if (bytes == null || bytes.length > MAX_BYTES) {
      throw new PackageFormatException(description + " descriptor is oversized");
    }
    String text = new String(bytes, StandardCharsets.UTF_8);
    if (!Arrays.equals(bytes, text.getBytes(StandardCharsets.UTF_8))) {
      throw new PackageFormatException(description + " descriptor is not strict UTF-8");
    }
    return text;
  }
}
