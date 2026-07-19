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

/** Canonical exact dependency graph for {@code wheeler.lock}. */
public record PackageLock(int schemaVersion, String rootManifestIdentity, List<Entry> entries) {
  public static final int SCHEMA_VERSION = 1;

  public PackageLock {
    if (schemaVersion != SCHEMA_VERSION || !hash(rootManifestIdentity)) {
      throw new PackageFormatException("Invalid package lock header");
    }
    List<Entry> ordered = new ArrayList<>(List.copyOf(entries));
    ordered.sort(Comparator.comparing(Entry::name));
    Set<String> names = new HashSet<>();
    for (Entry entry : ordered) {
      if (!names.add(entry.name())) {
        throw new PackageFormatException("Duplicate locked package " + entry.name());
      }
    }
    entries = List.copyOf(ordered);
  }

  public String canonicalText() {
    StringBuilder text = new StringBuilder();
    text.append("lock ").append(schemaVersion)
        .append(" root \"").append(rootManifestIdentity).append("\";\n");
    for (Entry entry : entries) {
      text.append("package \"").append(entry.name())
          .append("\" version \"").append(entry.version())
          .append("\" archive \"").append(entry.archiveIdentity())
          .append("\" manifest \"").append(entry.manifestIdentity()).append("\";\n");
    }
    for (Entry entry : entries) {
      for (String dependency : entry.dependencies()) {
        text.append("edge \"").append(entry.name()).append("\" \"")
            .append(dependency).append("\";\n");
      }
    }
    return text.toString();
  }

  public String identity() {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
          .digest(canonicalText().getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  public record Entry(
      String name,
      String version,
      String archiveIdentity,
      String manifestIdentity,
      List<String> dependencies) {
    public Entry {
      Objects.requireNonNull(name, "name");
      if (!name.matches("[a-z][a-z0-9]*(?:\\.[a-z][a-z0-9]*)*")) {
        throw new PackageFormatException("Invalid locked package name " + name);
      }
      SemanticVersion.parse(version);
      if (!hash(archiveIdentity) || !hash(manifestIdentity)) {
        throw new PackageFormatException("Invalid locked package identity");
      }
      List<String> ordered = new ArrayList<>(List.copyOf(dependencies));
      ordered.sort(String::compareTo);
      if (new HashSet<>(ordered).size() != ordered.size()) {
        throw new PackageFormatException("Duplicate locked dependency for " + name);
      }
      dependencies = List.copyOf(ordered);
    }
  }

  private static boolean hash(String value) {
    return value != null && value.matches("[0-9a-f]{64}");
  }
}
