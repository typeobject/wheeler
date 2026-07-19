package com.typeobject.wheeler.packageformat;

import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.Set;

/** Canonical mapping from one complete build input to one accepted package revision. */
public record BuildOutputRecord(String buildInputIdentity, String prev, long bytes) {
  public static final int SCHEMA_VERSION = 1;
  public static final String SUFFIX = ".output.yaml";
  private static final int MAX_RECORD_BYTES = 64 * 1024;
  private static final Set<String> FIELDS = Set.of("schema", "build-input", "prev", "bytes");

  public BuildOutputRecord {
    if (!hash(buildInputIdentity) || !hash(prev) || bytes <= 0 || bytes > 16L * 1024 * 1024) {
      throw new PackageFormatException("Invalid build output record");
    }
  }

  public String canonicalText() {
    return "schema: 1\n"
        + "build-input: " + CanonicalYaml.quote(buildInputIdentity) + "\n"
        + "prev: " + CanonicalYaml.quote(prev) + "\n"
        + "bytes: " + bytes + "\n";
  }

  public byte[] canonicalBytes() {
    return canonicalText().getBytes(StandardCharsets.UTF_8);
  }

  public static BuildOutputRecord parse(byte[] utf8) {
    if (utf8.length > MAX_RECORD_BYTES) {
      throw new PackageFormatException("Build output record is oversized");
    }
    try {
      String source = StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(utf8))
          .toString();
      CanonicalYaml.Mapping mapping = CanonicalYaml.mapping(
          CanonicalYaml.parse(source, "build output record"), "build output record");
      CanonicalYaml.fields(mapping, FIELDS, "build output record");
      int schema = CanonicalYaml.integer(
          CanonicalYaml.required(mapping, "schema", "build output record"), "record.schema");
      if (schema != SCHEMA_VERSION) {
        throw new PackageFormatException("Unsupported build output record schema " + schema);
      }
      BuildOutputRecord record = new BuildOutputRecord(
          string(mapping, "build-input"),
          string(mapping, "prev"),
          CanonicalYaml.integer(
              CanonicalYaml.required(mapping, "bytes", "build output record"), "record.bytes"));
      if (!record.canonicalText().equals(source)) {
        throw new PackageFormatException("Build output record is not canonical");
      }
      return record;
    } catch (CharacterCodingException exception) {
      throw new PackageFormatException("Build output record is not strict UTF-8", exception);
    }
  }

  private static String string(CanonicalYaml.Mapping mapping, String key) {
    return CanonicalYaml.string(
        CanonicalYaml.required(mapping, key, "build output record"), "record." + key);
  }

  private static boolean hash(String value) {
    return value != null && value.matches("[0-9a-f]{64}");
  }
}
