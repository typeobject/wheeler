package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Set;

/** Strict decoder for {@code wheeler.compiler-limits.yaml}. */
public final class BootstrapCompilerLimitsParser {
  private static final Set<String> LIMIT_FIELDS = Set.of(
      "source-bytes",
      "tokens",
      "nesting",
      "declarations",
      "symbols",
      "instructions",
      "diagnostics",
      "heap-bytes",
      "stack-depth",
      "steps");

  public BootstrapCompilerLimits parse(byte[] bytes) {
    String text = strictUtf8(bytes);
    CanonicalYaml.Mapping root = CanonicalYaml.mapping(
        CanonicalYaml.parse(text, BootstrapCompilerLimits.FILE_NAME), "compiler limits");
    CanonicalYaml.fields(root, Set.of("schema", "limits"), "compiler limits");
    int schema = CanonicalYaml.integer(
        CanonicalYaml.required(root, "schema", "compiler limits"), "schema");
    if (schema != BootstrapCompilerLimits.SCHEMA_VERSION) {
      throw new PackageFormatException("Unsupported compiler limits schema " + schema);
    }
    CanonicalYaml.Mapping limits = CanonicalYaml.mapping(
        CanonicalYaml.required(root, "limits", "compiler limits"), "compiler limits.limits");
    CanonicalYaml.fields(limits, LIMIT_FIELDS, "compiler limits.limits");
    return new BootstrapCompilerLimits(
        integer(limits, "source-bytes"),
        integer(limits, "tokens"),
        integer(limits, "nesting"),
        integer(limits, "declarations"),
        integer(limits, "symbols"),
        integer(limits, "instructions"),
        integer(limits, "diagnostics"),
        integer(limits, "heap-bytes"),
        integer(limits, "stack-depth"),
        integer(limits, "steps"));
  }

  private static int integer(CanonicalYaml.Mapping limits, String name) {
    return CanonicalYaml.integer(
        CanonicalYaml.required(limits, name, "compiler limits.limits"), name);
  }

  private static String strictUtf8(byte[] bytes) {
    String text = new String(bytes, StandardCharsets.UTF_8);
    if (!Arrays.equals(bytes, text.getBytes(StandardCharsets.UTF_8))) {
      throw new PackageFormatException("Compiler limits are not strict UTF-8");
    }
    return text;
  }
}
