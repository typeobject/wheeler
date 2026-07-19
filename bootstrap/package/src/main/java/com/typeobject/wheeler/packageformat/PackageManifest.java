package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.regex.Pattern;

/** Immutable canonical model of one {@code wheeler.package} manifest. */
public record PackageManifest(
    String name,
    String version,
    String profile,
    List<Target> targets,
    List<Dependency> dependencies,
    List<Capability> capabilities) {
  private static final int MAX_ITEMS = 10_000;
  private static final int MAX_TEXT = 4096;
  private static final Pattern NAME = Pattern.compile("[a-z][a-z0-9]*(?:\\.[a-z][a-z0-9]*)*");
  private static final Pattern TARGET_NAME = Pattern.compile(
      "[a-z][a-z0-9]*(?:[.-][a-z0-9]+)*");
  private static final Pattern VERSION = Pattern.compile(
      "(?:0|[1-9][0-9]*)\\.(?:0|[1-9][0-9]*)\\.(?:0|[1-9][0-9]*)"
          + "(?:-[0-9A-Za-z.-]+)?");
  private static final Pattern CONSTRAINT = Pattern.compile(
      "[=^~]?(?:" + VERSION.pattern() + ")");

  public PackageManifest {
    name = packageName(name);
    version = checked(version, "version");
    profile = checked(profile, "profile");
    try {
      SemanticVersion.parse(version);
    } catch (PackageFormatException exception) {
      throw new PackageFormatException("Invalid package version " + version, exception);
    }
    targets = sortedUnique(targets, Comparator.comparing(Target::name), Target::name, "target");
    dependencies = sortedUnique(
        dependencies, Comparator.comparing(Dependency::name), Dependency::name, "dependency");
    capabilities = sortedUnique(
        capabilities,
        Comparator.comparing(Capability::name).thenComparing(Capability::pattern),
        value -> value.name() + "\u0000" + value.pattern(),
        "capability");
    if (targets.isEmpty()) {
      throw new PackageFormatException("Package must declare at least one target");
    }
  }

  public String canonicalText() {
    StringBuilder text = new StringBuilder();
    text.append("package ").append(quoted(name))
        .append(" version ").append(quoted(version))
        .append(" profile ").append(quoted(profile)).append(";\n");
    for (Target target : targets) {
      text.append("target ").append(target.kind().keyword()).append(' ')
          .append(quoted(target.name())).append(" root ")
          .append(quoted(target.root()));
      if (target.module() != null) {
        text.append(" module ").append(quoted(target.module()));
        for (String source : target.sources()) {
          text.append(" source ").append(quoted(source));
        }
      }
      if (target.test()) {
        text.append(" test");
      }
      text.append(";\n");
    }
    for (Dependency dependency : dependencies) {
      text.append("dependency ").append(dependency.kind().keyword()).append(' ')
          .append(quoted(dependency.name())).append(" version ")
          .append(quoted(dependency.constraint())).append(";\n");
    }
    for (Capability capability : capabilities) {
      text.append("capability ").append(quoted(capability.name()))
          .append(" path ").append(quoted(capability.pattern())).append(";\n");
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

  public record Target(
      TargetKind kind,
      String name,
      String root,
      String module,
      List<String> sources,
      boolean test) {
    private static final Pattern MODULE = Pattern.compile(
        "[A-Za-z_][A-Za-z0-9_]*(?:\\.[A-Za-z_][A-Za-z0-9_]*)*");

    public Target(TargetKind kind, String name, String root) {
      this(kind, name, root, null, List.of(root), false);
    }

    public Target(
        TargetKind kind, String name, String root, String module, List<String> sources) {
      this(kind, name, root, module, sources, false);
    }

    public Target {
      kind = Objects.requireNonNull(kind, "kind");
      name = checked(name, "target name");
      if (!TARGET_NAME.matcher(name).matches()) {
        throw new PackageFormatException("Invalid target name " + name);
      }
      root = logicalPath(root);
      if (test && kind == TargetKind.LIBRARY) {
        throw new PackageFormatException(
            "Entryless library target cannot be test-selected: " + name);
      }
      if (module == null) {
        sources = List.of(root);
      } else {
        module = checked(module, "root module");
        if (!MODULE.matcher(module).matches()) {
          throw new PackageFormatException("Invalid root module " + module);
        }
        sources = sortedUnique(
            sources,
            Comparator.naturalOrder(),
            value -> value,
            "target source").stream().map(PackageManifest::logicalPath).toList();
        if (sources.isEmpty() || sources.size() > 1_024 || !sources.contains(root)) {
          throw new PackageFormatException(
              "Module target sources must include its root and fit the 1,024-source limit");
        }
      }
    }

    public boolean modular() {
      return module != null;
    }
  }

  public record Dependency(DependencyKind kind, String name, String constraint) {
    public Dependency {
      kind = Objects.requireNonNull(kind, "kind");
      name = packageName(name);
      constraint = checked(constraint, "dependency constraint");
      if (!CONSTRAINT.matcher(constraint).matches()) {
        throw new PackageFormatException("Invalid dependency constraint " + constraint);
      }
      VersionConstraint.parse(constraint);
    }
  }

  public record Capability(String name, String pattern) {
    public Capability {
      name = checked(name, "capability name");
      pattern = logicalPattern(pattern);
    }
  }

  public enum TargetKind {
    DEPLOYABLE,
    LIBRARY,
    TOOL;

    public String keyword() {
      return name().toLowerCase(java.util.Locale.ROOT);
    }

    public static TargetKind parse(String text) {
      return enumKeyword(values(), text, "target kind");
    }
  }

  public enum DependencyKind {
    NORMAL,
    DEVELOPMENT,
    BUILD;

    public String keyword() {
      return name().toLowerCase(java.util.Locale.ROOT);
    }

    public static DependencyKind parse(String text) {
      return enumKeyword(values(), text, "dependency kind");
    }
  }

  public static String logicalPath(String value) {
    String path = checked(value, "logical path");
    if (path.startsWith("/") || path.endsWith("/") || path.contains("\\")
        || path.indexOf('\0') >= 0) {
      throw new PackageFormatException("Invalid logical path " + path);
    }
    for (String component : path.split("/", -1)) {
      if (component.isEmpty() || component.equals(".") || component.equals("..")) {
        throw new PackageFormatException("Invalid logical path " + path);
      }
    }
    return path;
  }

  private static String logicalPattern(String value) {
    String pattern = checked(value, "logical pattern");
    String skeleton = pattern.replace("**", "wildcard").replace("*", "wildcard");
    logicalPath(skeleton);
    return pattern;
  }

  private static String packageName(String value) {
    String name = checked(value, "package name");
    if (!NAME.matcher(name).matches()) {
      throw new PackageFormatException("Invalid package name " + name);
    }
    return name;
  }

  private static String checked(String value, String description) {
    Objects.requireNonNull(value, description);
    if (value.isBlank() || value.length() > MAX_TEXT || value.indexOf('\0') >= 0) {
      throw new PackageFormatException("Blank or oversized " + description);
    }
    return value;
  }

  private static <T> List<T> sortedUnique(
      List<T> values,
      Comparator<T> comparator,
      java.util.function.Function<T, String> identity,
      String description) {
    List<T> result = new ArrayList<>(List.copyOf(values));
    if (result.size() > MAX_ITEMS) {
      throw new PackageFormatException("Too many " + description + " records");
    }
    result.sort(comparator);
    Set<String> identities = new HashSet<>();
    for (T value : result) {
      if (!identities.add(identity.apply(value))) {
        throw new PackageFormatException("Duplicate " + description + " " + identity.apply(value));
      }
    }
    return List.copyOf(result);
  }

  private static String quoted(String value) {
    return '"' + value.replace("\\", "\\\\").replace("\"", "\\\"") + '"';
  }

  private static <T extends Enum<T>> T enumKeyword(T[] values, String text, String description) {
    for (T value : values) {
      if (value.name().equalsIgnoreCase(text)) {
        return value;
      }
    }
    throw new PackageFormatException("Unknown " + description + " " + text);
  }
}
