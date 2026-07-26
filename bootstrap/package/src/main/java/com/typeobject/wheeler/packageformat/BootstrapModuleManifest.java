package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

/** Canonical closed module graph for one bootstrap compiler source set. */
public record BootstrapModuleManifest(
    String profile, String root, List<String> externals, List<Module> modules) {
  public static final int SCHEMA_VERSION = 1;
  public static final String FILE_NAME = "wheeler.bootstrap-modules.yaml";
  private static final int MAX_MODULES = 10_000;
  private static final int MAX_EDGES = 100_000;
  private static final Pattern MODULE = Pattern.compile(
      "[A-Za-z_][A-Za-z0-9_]*(?:\\.[A-Za-z_][A-Za-z0-9_]*)*");
  private static final Pattern PROFILE = Pattern.compile("[A-Za-z0-9][A-Za-z0-9._-]{0,127}");
  private static final Pattern PATH = Pattern.compile(
      "[A-Za-z0-9_-]+(?:\\.[A-Za-z0-9_-]+)*(?:/[A-Za-z0-9_-]+(?:\\.[A-Za-z0-9_-]+)*)*");
  private static final Pattern IDENTITY = Pattern.compile("[0-9a-f]{64}");

  public BootstrapModuleManifest {
    if (profile == null || !PROFILE.matcher(profile).matches()) {
      throw new PackageFormatException("Invalid bootstrap module profile");
    }
    root = moduleName(root, "root module");
    externals = sortedNames(externals, "external module");
    if (externals.size() > MAX_MODULES) {
      throw new PackageFormatException("Too many external bootstrap modules");
    }
    if (modules == null || modules.isEmpty() || modules.size() > MAX_MODULES) {
      throw new PackageFormatException("Bootstrap graph needs 1 through 10,000 modules");
    }
    List<Module> ordered = new ArrayList<>(modules);
    ordered.sort(Comparator.comparing(Module::name));
    modules = List.copyOf(ordered);
    verify(root, externals, modules);
  }

  /** Returns the sole canonical YAML representation. */
  public String canonicalText() {
    StringBuilder text = new StringBuilder("schema: 1\nprofile: ")
        .append(CanonicalYaml.quote(profile)).append("\nroot: ")
        .append(CanonicalYaml.quote(root)).append('\n');
    appendNames(text, "externals", externals, 0);
    text.append("modules:\n");
    for (Module module : modules) {
      text.append("  - name: ").append(CanonicalYaml.quote(module.name())).append('\n')
          .append("    source: ").append(CanonicalYaml.quote(module.source())).append('\n')
          .append("    identity: ").append(CanonicalYaml.quote(module.identity())).append('\n');
      appendNames(text, "imports", module.imports(), 4);
    }
    return text.toString();
  }

  public byte[] canonicalBytes() {
    return canonicalText().getBytes(StandardCharsets.UTF_8);
  }

  public String identity() {
    try {
      return HexFormat.of().formatHex(
          MessageDigest.getInstance("SHA-256").digest(canonicalBytes()));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  /** One source module and its exact direct imports. */
  public record Module(String name, String source, String identity, List<String> imports) {
    public Module {
      name = moduleName(name, "module");
      if (source == null || !source.endsWith(".w") || !PATH.matcher(source).matches()
          || source.contains("/../") || source.startsWith("../") || source.contains("//")) {
        throw new PackageFormatException("Invalid bootstrap module source path");
      }
      if (identity == null || !IDENTITY.matcher(identity).matches()) {
        throw new PackageFormatException("Invalid bootstrap module source identity");
      }
      imports = sortedNames(imports, "module import");
      if (imports.contains(name)) {
        throw new PackageFormatException("Bootstrap module imports itself: " + name);
      }
    }
  }

  private static void verify(String root, List<String> externals, List<Module> modules) {
    Map<String, Module> named = new HashMap<>();
    Set<String> sources = new HashSet<>();
    int edges = 0;
    for (Module module : modules) {
      if (named.put(module.name(), module) != null) {
        throw new PackageFormatException("Duplicate bootstrap module " + module.name());
      }
      if (!sources.add(module.source())) {
        throw new PackageFormatException("Duplicate bootstrap source " + module.source());
      }
      edges += module.imports().size();
      if (edges > MAX_EDGES) {
        throw new PackageFormatException("Bootstrap module graph exceeds 100,000 imports");
      }
    }
    if (!named.containsKey(root)) {
      throw new PackageFormatException("Bootstrap root module is not in the graph");
    }
    Set<String> externalSet = Set.copyOf(externals);
    for (String external : externals) {
      if (named.containsKey(external)) {
        throw new PackageFormatException("Local module also declared external: " + external);
      }
    }
    for (Module module : modules) {
      for (String imported : module.imports()) {
        if (!named.containsKey(imported) && !externalSet.contains(imported)) {
          throw new PackageFormatException("Unbound bootstrap import " + imported);
        }
      }
    }
    Set<String> reached = new HashSet<>();
    ArrayDeque<String> pending = new ArrayDeque<>();
    pending.add(root);
    while (!pending.isEmpty()) {
      String name = pending.removeFirst();
      if (reached.add(name)) {
        for (String imported : named.get(name).imports()) {
          if (named.containsKey(imported)) {
            pending.addLast(imported);
          }
        }
      }
    }
    if (reached.size() != modules.size()) {
      throw new PackageFormatException("Bootstrap graph contains unreachable modules");
    }
    detectCycle(named);
  }

  private static void detectCycle(Map<String, Module> modules) {
    Map<String, Integer> degrees = new HashMap<>();
    Map<String, List<String>> dependents = new HashMap<>();
    for (Module module : modules.values()) {
      int degree = 0;
      for (String imported : module.imports()) {
        if (modules.containsKey(imported)) {
          degree++;
          dependents.computeIfAbsent(imported, ignored -> new ArrayList<>()).add(module.name());
        }
      }
      degrees.put(module.name(), degree);
    }
    ArrayDeque<String> ready = new ArrayDeque<>();
    degrees.forEach((name, degree) -> {
      if (degree == 0) {
        ready.add(name);
      }
    });
    int visited = 0;
    while (!ready.isEmpty()) {
      String name = ready.removeFirst();
      visited++;
      for (String dependent : dependents.getOrDefault(name, List.of())) {
        int degree = degrees.merge(dependent, -1, Integer::sum);
        if (degree == 0) {
          ready.addLast(dependent);
        }
      }
    }
    if (visited != modules.size()) {
      throw new PackageFormatException("Bootstrap module graph is cyclic");
    }
  }

  private static List<String> sortedNames(List<String> names, String description) {
    if (names == null) {
      throw new PackageFormatException("Missing " + description + " list");
    }
    List<String> ordered = new ArrayList<>(names.size());
    Set<String> unique = new HashSet<>();
    for (String name : names) {
      String checked = moduleName(name, description);
      if (!unique.add(checked)) {
        throw new PackageFormatException("Duplicate " + description + " " + checked);
      }
      ordered.add(checked);
    }
    ordered.sort(Comparator.naturalOrder());
    return List.copyOf(ordered);
  }

  private static String moduleName(String name, String description) {
    if (name == null || !MODULE.matcher(name).matches()) {
      throw new PackageFormatException("Invalid " + description + " name");
    }
    return name;
  }

  private static void appendNames(StringBuilder text, String field, List<String> names, int indent) {
    String prefix = " ".repeat(indent);
    if (names.isEmpty()) {
      text.append(prefix).append(field).append(": []\n");
      return;
    }
    text.append(prefix).append(field).append(":\n");
    for (String name : names) {
      text.append(prefix).append("  - ").append(CanonicalYaml.quote(name)).append('\n');
    }
  }
}
