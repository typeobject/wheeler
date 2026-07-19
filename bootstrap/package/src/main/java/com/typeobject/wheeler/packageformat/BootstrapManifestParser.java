package com.typeobject.wheeler.packageformat;

import com.typeobject.wheeler.packageformat.BootstrapManifest.DiverseDerivation;
import com.typeobject.wheeler.packageformat.BootstrapManifest.OrdinaryDerivation;
import com.typeobject.wheeler.packageformat.BootstrapManifest.Source;
import java.nio.charset.StandardCharsets;
import java.util.Set;

/** Strict schema decoder for {@code wheeler.bootstrap.yaml}. */
public final class BootstrapManifestParser {
  private static final Set<String> ROOT_FIELDS = Set.of(
      "schema", "source", "ordinary", "diverse", "acceptance");
  private static final Set<String> SOURCE_FIELDS = Set.of(
      "archive", "manifest", "lock", "profile", "options", "limits");
  private static final Set<String> ORDINARY_FIELDS = Set.of(
      "toolchain", "compiler", "runtime", "verifier", "stage-1", "stage-2", "diagnostics");
  private static final Set<String> DIVERSE_FIELDS = Set.of(
      "toolchain", "compiler", "runtime", "verifier", "output", "diagnostics");
  private static final Set<String> ACCEPTANCE_FIELDS = Set.of("artifact-set");

  public BootstrapManifest parse(byte[] bytes) {
    String text = strictUtf8(bytes);
    CanonicalYaml.Mapping root = mapping(
        CanonicalYaml.parse(text, BootstrapManifest.FILE_NAME), "bootstrap manifest");
    CanonicalYaml.fields(root, ROOT_FIELDS, "bootstrap manifest");
    int schema = CanonicalYaml.integer(
        CanonicalYaml.required(root, "schema", "bootstrap manifest"), "schema");
    if (schema != BootstrapManifest.SCHEMA_VERSION) {
      throw new PackageFormatException("Unsupported bootstrap manifest schema " + schema);
    }

    CanonicalYaml.Mapping source = child(root, "source");
    CanonicalYaml.Mapping ordinary = child(root, "ordinary");
    CanonicalYaml.Mapping diverse = child(root, "diverse");
    CanonicalYaml.Mapping acceptance = child(root, "acceptance");
    CanonicalYaml.fields(source, SOURCE_FIELDS, "bootstrap manifest.source");
    CanonicalYaml.fields(ordinary, ORDINARY_FIELDS, "bootstrap manifest.ordinary");
    CanonicalYaml.fields(diverse, DIVERSE_FIELDS, "bootstrap manifest.diverse");
    CanonicalYaml.fields(acceptance, ACCEPTANCE_FIELDS, "bootstrap manifest.acceptance");

    return new BootstrapManifest(
        new Source(
            string(source, "archive"),
            string(source, "manifest"),
            string(source, "lock"),
            string(source, "profile"),
            string(source, "options"),
            string(source, "limits")),
        new OrdinaryDerivation(
            string(ordinary, "toolchain"),
            string(ordinary, "compiler"),
            string(ordinary, "runtime"),
            string(ordinary, "verifier"),
            string(ordinary, "stage-1"),
            string(ordinary, "stage-2"),
            string(ordinary, "diagnostics")),
        new DiverseDerivation(
            string(diverse, "toolchain"),
            string(diverse, "compiler"),
            string(diverse, "runtime"),
            string(diverse, "verifier"),
            string(diverse, "output"),
            string(diverse, "diagnostics")),
        string(acceptance, "artifact-set"));
  }

  private static CanonicalYaml.Mapping child(CanonicalYaml.Mapping parent, String name) {
    return mapping(CanonicalYaml.required(parent, name, "bootstrap manifest"), name);
  }

  private static CanonicalYaml.Mapping mapping(CanonicalYaml.Value value, String description) {
    return CanonicalYaml.mapping(value, description);
  }

  private static String string(CanonicalYaml.Mapping mapping, String name) {
    return CanonicalYaml.string(
        CanonicalYaml.required(mapping, name, "bootstrap manifest"), name);
  }

  private static String strictUtf8(byte[] bytes) {
    String text = new String(bytes, StandardCharsets.UTF_8);
    if (!java.util.Arrays.equals(bytes, text.getBytes(StandardCharsets.UTF_8))) {
      throw new PackageFormatException("Bootstrap manifest is not strict UTF-8");
    }
    return text;
  }
}
