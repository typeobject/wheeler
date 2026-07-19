package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Set;

/** Strict decoder for {@code wheeler.toolchain.yaml}. */
public final class BootstrapToolchainParser {
  private static final Set<String> TOOLCHAIN_FIELDS = Set.of(
      "kind", "source", "builder", "dependencies", "environment");

  public BootstrapToolchain parse(byte[] bytes) {
    String text = strictUtf8(bytes);
    CanonicalYaml.Mapping root = CanonicalYaml.mapping(
        CanonicalYaml.parse(text, BootstrapToolchain.FILE_NAME), "toolchain provenance");
    CanonicalYaml.fields(root, Set.of("schema", "toolchain"), "toolchain provenance");
    int schema = CanonicalYaml.integer(
        CanonicalYaml.required(root, "schema", "toolchain provenance"), "schema");
    if (schema != BootstrapToolchain.SCHEMA_VERSION) {
      throw new PackageFormatException("Unsupported toolchain provenance schema " + schema);
    }
    CanonicalYaml.Mapping toolchain = CanonicalYaml.mapping(
        CanonicalYaml.required(root, "toolchain", "toolchain provenance"),
        "toolchain provenance.toolchain");
    CanonicalYaml.fields(toolchain, TOOLCHAIN_FIELDS, "toolchain provenance.toolchain");
    return new BootstrapToolchain(
        BootstrapToolchain.Kind.fromKeyword(string(toolchain, "kind")),
        string(toolchain, "source"),
        string(toolchain, "builder"),
        string(toolchain, "dependencies"),
        string(toolchain, "environment"));
  }

  private static String string(CanonicalYaml.Mapping toolchain, String name) {
    return CanonicalYaml.string(
        CanonicalYaml.required(toolchain, name, "toolchain provenance.toolchain"), name);
  }

  private static String strictUtf8(byte[] bytes) {
    String text = new String(bytes, StandardCharsets.UTF_8);
    if (!Arrays.equals(bytes, text.getBytes(StandardCharsets.UTF_8))) {
      throw new PackageFormatException("Toolchain provenance is not strict UTF-8");
    }
    return text;
  }
}
