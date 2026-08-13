package com.typeobject.wheeler.packageformat;

import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/** Strict decoder for {@code wheeler.seed.yaml}. */
public final class BootstrapSeedRecordParser {
  private static final Set<String> SEED_FIELDS = Set.of(
      "kind",
      "artifact",
      "platform",
      "output",
      "output-length",
      "source-revision",
      "source",
      "build-command",
      "working-directory",
      "builder",
      "dependencies",
      "environment",
      "parent",
      "attestations",
      "opaque",
      "origin",
      "transport",
      "acquired",
      "reason");

  public BootstrapSeedRecord parse(byte[] bytes) {
    String text = strictUtf8(bytes);
    CanonicalYaml.Mapping root = CanonicalYaml.mapping(
        CanonicalYaml.parse(text, BootstrapSeedRecord.FILE_NAME), "bootstrap seed");
    CanonicalYaml.fields(root, Set.of("schema", "seed"), "bootstrap seed");
    int schema = CanonicalYaml.integer(
        CanonicalYaml.required(root, "schema", "bootstrap seed"), "schema");
    if (schema != BootstrapSeedRecord.SCHEMA_VERSION) {
      throw new PackageFormatException("Unsupported bootstrap seed schema " + schema);
    }
    CanonicalYaml.Mapping seed = CanonicalYaml.mapping(
        CanonicalYaml.required(root, "seed", "bootstrap seed"), "bootstrap seed.seed");
    CanonicalYaml.fields(seed, SEED_FIELDS, "bootstrap seed.seed");
    BootstrapSeedRecord record = new BootstrapSeedRecord(
        BootstrapSeedRecord.Kind.fromKeyword(string(seed, "kind")),
        string(seed, "artifact"),
        string(seed, "platform"),
        string(seed, "output"),
        CanonicalYaml.integer(required(seed, "output-length"), "output-length"),
        string(seed, "source-revision"),
        string(seed, "source"),
        string(seed, "build-command"),
        string(seed, "working-directory"),
        string(seed, "builder"),
        strings(seed, "dependencies"),
        string(seed, "environment"),
        string(seed, "parent"),
        strings(seed, "attestations"),
        string(seed, "origin"),
        string(seed, "transport"),
        string(seed, "acquired"),
        string(seed, "reason"));
    if (CanonicalYaml.bool(required(seed, "opaque"), "opaque") != record.opaque()) {
      throw new PackageFormatException("Bootstrap seed opaque marker contradicts its kind");
    }
    if (!text.equals(record.canonicalText())) {
      throw new PackageFormatException("Bootstrap seed record is not canonical");
    }
    return record;
  }

  private static CanonicalYaml.Value required(CanonicalYaml.Mapping seed, String name) {
    return CanonicalYaml.required(seed, name, "bootstrap seed.seed");
  }

  private static String string(CanonicalYaml.Mapping seed, String name) {
    return CanonicalYaml.string(required(seed, name), name);
  }

  private static List<String> strings(CanonicalYaml.Mapping seed, String name) {
    CanonicalYaml.Sequence sequence = CanonicalYaml.sequence(required(seed, name), name);
    List<String> values = new ArrayList<>(sequence.values().size());
    for (CanonicalYaml.Value value : sequence.values()) {
      values.add(CanonicalYaml.string(value, name + " item"));
    }
    return values;
  }

  private static String strictUtf8(byte[] bytes) {
    try {
      return StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(bytes))
          .toString();
    } catch (CharacterCodingException exception) {
      throw new PackageFormatException("Bootstrap seed is not strict UTF-8", exception);
    }
  }
}
