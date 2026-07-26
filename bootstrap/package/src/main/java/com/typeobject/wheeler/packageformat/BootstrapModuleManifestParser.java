package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;

/** Strict decoder for {@code wheeler.bootstrap-modules.yaml}. */
public final class BootstrapModuleManifestParser {
  public BootstrapModuleManifest parse(byte[] bytes) {
    String text = strictUtf8(bytes);
    CanonicalYaml.Mapping root = CanonicalYaml.mapping(
        CanonicalYaml.parse(text, BootstrapModuleManifest.FILE_NAME), "bootstrap modules");
    CanonicalYaml.fields(
        root, Set.of("schema", "profile", "root", "externals", "modules"),
        "bootstrap modules");
    int schema = integer(root, "schema", "bootstrap modules");
    if (schema != BootstrapModuleManifest.SCHEMA_VERSION) {
      throw new PackageFormatException("Unsupported bootstrap module schema " + schema);
    }
    String profile = string(root, "profile", "bootstrap modules");
    String rootModule = string(root, "root", "bootstrap modules");
    List<String> externals = names(
        CanonicalYaml.required(root, "externals", "bootstrap modules"), "external module");
    CanonicalYaml.Sequence sequence = CanonicalYaml.sequence(
        CanonicalYaml.required(root, "modules", "bootstrap modules"), "modules");
    List<BootstrapModuleManifest.Module> modules = new ArrayList<>();
    for (CanonicalYaml.Value value : sequence.values()) {
      CanonicalYaml.Mapping module = CanonicalYaml.mapping(value, "bootstrap module");
      CanonicalYaml.fields(
          module, Set.of("name", "source", "identity", "imports"), "bootstrap module");
      modules.add(new BootstrapModuleManifest.Module(
          string(module, "name", "bootstrap module"),
          string(module, "source", "bootstrap module"),
          string(module, "identity", "bootstrap module"),
          names(CanonicalYaml.required(module, "imports", "bootstrap module"), "module import")));
    }
    BootstrapModuleManifest manifest = new BootstrapModuleManifest(
        profile, rootModule, externals, modules);
    if (!text.equals(manifest.canonicalText())) {
      throw new PackageFormatException("Bootstrap module manifest is not canonical");
    }
    return manifest;
  }

  private static List<String> names(CanonicalYaml.Value value, String description) {
    List<String> names = new ArrayList<>();
    for (CanonicalYaml.Value item : CanonicalYaml.sequence(value, description).values()) {
      names.add(CanonicalYaml.string(item, description));
    }
    return names;
  }

  private static int integer(
      CanonicalYaml.Mapping mapping, String key, String description) {
    return CanonicalYaml.integer(
        CanonicalYaml.required(mapping, key, description), description + "." + key);
  }

  private static String string(
      CanonicalYaml.Mapping mapping, String key, String description) {
    return CanonicalYaml.string(
        CanonicalYaml.required(mapping, key, description), description + "." + key);
  }

  private static String strictUtf8(byte[] bytes) {
    String text = new String(bytes, StandardCharsets.UTF_8);
    if (!Arrays.equals(bytes, text.getBytes(StandardCharsets.UTF_8))) {
      throw new PackageFormatException("Bootstrap modules are not strict UTF-8");
    }
    return text;
  }
}
