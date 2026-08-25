package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Set;

/** Strict canonical decoder for schema-1 native image signing records. */
public final class NativeImageSigningRecordParser {
  private static final Set<String> ROOT_FIELDS = Set.of("schema", "native-image-signing");
  private static final Set<String> SIGNING_FIELDS = Set.of(
      "method",
      "unsigned-record",
      "unsigned-prev",
      "distribution-artifact",
      "distribution-bytes",
      "signature-evidence",
      "signature-bytes",
      "signer",
      "signing-tool");

  public NativeImageSigningRecord parse(byte[] bytes) {
    String text = strictUtf8(bytes);
    CanonicalYaml.Mapping root = CanonicalYaml.mapping(
        CanonicalYaml.parse(text, "native image signing record"),
        "native image signing record");
    CanonicalYaml.fields(root, ROOT_FIELDS, "native image signing record");
    int schema = CanonicalYaml.integer(
        CanonicalYaml.required(root, "schema", "native image signing record"),
        "native image signing schema");
    if (schema != NativeImageSigningRecord.SCHEMA_VERSION) {
      throw new PackageFormatException("Unsupported native image signing schema " + schema);
    }
    CanonicalYaml.Mapping signing = CanonicalYaml.mapping(
        CanonicalYaml.required(root, "native-image-signing", "native image signing record"),
        "native image signing");
    CanonicalYaml.fields(signing, SIGNING_FIELDS, "native image signing");
    NativeImageSigningRecord result = new NativeImageSigningRecord(
        method(string(signing, "method")),
        string(signing, "unsigned-record"),
        string(signing, "unsigned-prev"),
        string(signing, "distribution-artifact"),
        integer(signing, "distribution-bytes"),
        string(signing, "signature-evidence"),
        integer(signing, "signature-bytes"),
        string(signing, "signer"),
        string(signing, "signing-tool"));
    if (!result.canonicalText().equals(text)) {
      throw new PackageFormatException("Native image signing record is not canonical");
    }
    return result;
  }

  private static NativeImageSigningRecord.SigningMethod method(String value) {
    for (NativeImageSigningRecord.SigningMethod method
        : NativeImageSigningRecord.SigningMethod.values()) {
      if (method.wireName().equals(value)) {
        return method;
      }
    }
    throw new PackageFormatException("Unknown native image signing method " + value);
  }

  private static String string(CanonicalYaml.Mapping mapping, String key) {
    return CanonicalYaml.string(
        CanonicalYaml.required(mapping, key, "native image signing"),
        "native image signing " + key);
  }

  private static int integer(CanonicalYaml.Mapping mapping, String key) {
    return CanonicalYaml.integer(
        CanonicalYaml.required(mapping, key, "native image signing"),
        "native image signing " + key);
  }

  private static String strictUtf8(byte[] bytes) {
    if (bytes == null || bytes.length > NativeImageSigningRecord.MAX_RECORD_BYTES) {
      throw new PackageFormatException("Native image signing record is oversized");
    }
    String text = new String(bytes, StandardCharsets.UTF_8);
    if (!Arrays.equals(bytes, text.getBytes(StandardCharsets.UTF_8))) {
      throw new PackageFormatException("Native image signing record is not strict UTF-8");
    }
    return text;
  }
}
