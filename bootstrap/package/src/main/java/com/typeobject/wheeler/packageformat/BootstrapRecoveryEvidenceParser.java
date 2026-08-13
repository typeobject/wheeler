package com.typeobject.wheeler.packageformat;

import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/** Strict decoder for {@code wheeler.recovery.yaml}. */
public final class BootstrapRecoveryEvidenceParser {
  private static final Set<String> RECOVERY_FIELDS = Set.of(
      "seed-chain",
      "seed-count",
      "opaque-count",
      "opaque-bytes",
      "opaque-roots",
      "source-archive",
      "lock",
      "compiler-options",
      "compiler-limits",
      "fixed-point",
      "diverse-compilation",
      "acceptance-artifacts",
      "parent-recovery");

  public BootstrapRecoveryEvidence parse(byte[] bytes) {
    String text = strictUtf8(bytes);
    CanonicalYaml.Mapping root = CanonicalYaml.mapping(
        CanonicalYaml.parse(text, BootstrapRecoveryEvidence.FILE_NAME), "recovery evidence");
    CanonicalYaml.fields(root, Set.of("schema", "recovery"), "recovery evidence");
    int schema = CanonicalYaml.integer(required(root, "schema", "recovery evidence"), "schema");
    if (schema != BootstrapRecoveryEvidence.SCHEMA_VERSION) {
      throw new PackageFormatException("Unsupported recovery evidence schema " + schema);
    }
    CanonicalYaml.Mapping recovery = CanonicalYaml.mapping(
        required(root, "recovery", "recovery evidence"), "recovery evidence.recovery");
    CanonicalYaml.fields(recovery, RECOVERY_FIELDS, "recovery evidence.recovery");
    BootstrapRecoveryEvidence evidence = new BootstrapRecoveryEvidence(
        string(recovery, "seed-chain"),
        integer(recovery, "seed-count"),
        integer(recovery, "opaque-count"),
        integer(recovery, "opaque-bytes"),
        strings(recovery, "opaque-roots"),
        string(recovery, "source-archive"),
        string(recovery, "lock"),
        string(recovery, "compiler-options"),
        string(recovery, "compiler-limits"),
        string(recovery, "fixed-point"),
        string(recovery, "diverse-compilation"),
        string(recovery, "acceptance-artifacts"),
        string(recovery, "parent-recovery"));
    if (!text.equals(evidence.canonicalText())) {
      throw new PackageFormatException("Recovery evidence is not canonical");
    }
    return evidence;
  }

  private static CanonicalYaml.Value required(
      CanonicalYaml.Mapping mapping, String name, String description) {
    return CanonicalYaml.required(mapping, name, description);
  }

  private static String string(CanonicalYaml.Mapping recovery, String name) {
    return CanonicalYaml.string(
        required(recovery, name, "recovery evidence.recovery"), name);
  }

  private static int integer(CanonicalYaml.Mapping recovery, String name) {
    return CanonicalYaml.integer(
        required(recovery, name, "recovery evidence.recovery"), name);
  }

  private static List<String> strings(CanonicalYaml.Mapping recovery, String name) {
    CanonicalYaml.Sequence sequence = CanonicalYaml.sequence(
        required(recovery, name, "recovery evidence.recovery"), name);
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
      throw new PackageFormatException("Recovery evidence is not strict UTF-8", exception);
    }
  }
}
