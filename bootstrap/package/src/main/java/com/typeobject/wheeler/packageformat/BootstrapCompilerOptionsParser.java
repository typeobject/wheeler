package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Set;

/** Strict decoder for {@code wheeler.compiler-options.yaml}. */
public final class BootstrapCompilerOptionsParser {
  public BootstrapCompilerOptions parse(byte[] bytes) {
    String text = strictUtf8(bytes);
    CanonicalYaml.Mapping root = CanonicalYaml.mapping(
        CanonicalYaml.parse(text, BootstrapCompilerOptions.FILE_NAME), "compiler options");
    CanonicalYaml.fields(root, Set.of("schema", "compiler"), "compiler options");
    int schema = CanonicalYaml.integer(
        CanonicalYaml.required(root, "schema", "compiler options"), "schema");
    if (schema != BootstrapCompilerOptions.SCHEMA_VERSION) {
      throw new PackageFormatException("Unsupported compiler options schema " + schema);
    }
    CanonicalYaml.Mapping compiler = CanonicalYaml.mapping(
        CanonicalYaml.required(root, "compiler", "compiler options"), "compiler options.compiler");
    CanonicalYaml.fields(compiler, Set.of("profile", "source-maps"), "compiler options.compiler");
    return new BootstrapCompilerOptions(
        CanonicalYaml.string(
            CanonicalYaml.required(compiler, "profile", "compiler options.compiler"), "profile"),
        CanonicalYaml.bool(
            CanonicalYaml.required(compiler, "source-maps", "compiler options.compiler"),
            "source-maps"));
  }

  private static String strictUtf8(byte[] bytes) {
    String text = new String(bytes, StandardCharsets.UTF_8);
    if (!Arrays.equals(bytes, text.getBytes(StandardCharsets.UTF_8))) {
      throw new PackageFormatException("Compiler options are not strict UTF-8");
    }
    return text;
  }
}
