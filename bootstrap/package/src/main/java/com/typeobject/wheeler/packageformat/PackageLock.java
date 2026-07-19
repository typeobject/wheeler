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

/** Canonical exact dependency graph for {@code wheeler.package.lock.yaml}. */
public record PackageLock(int schemaVersion, String rootManifestIdentity, List<Entry> entries) {
  public static final String FILE_NAME = "wheeler.package.lock.yaml";
  public static final int SCHEMA_VERSION = 2;

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
    for (Entry entry : ordered) {
      for (String dependency : entry.dependencies()) {
        if (!names.contains(dependency)) {
          throw new PackageFormatException(
              "Unknown locked dependency " + entry.name() + " -> " + dependency);
        }
      }
    }
    entries = List.copyOf(ordered);
  }

  public String canonicalText() {
    StringBuilder text = new StringBuilder();
    text.append("schema: ").append(schemaVersion).append('\n')
        .append("root: ").append(CanonicalYaml.quote(rootManifestIdentity)).append('\n');
    if (entries.isEmpty()) {
      return text.append("packages: []\n").toString();
    }
    text.append("packages:\n");
    for (Entry entry : entries) {
      text.append("  - name: ").append(CanonicalYaml.quote(entry.name())).append('\n')
          .append("    version: ").append(CanonicalYaml.quote(entry.version())).append('\n')
          .append("    repository: ")
          .append(CanonicalYaml.quote(entry.repositoryIdentity())).append('\n')
          .append("    archive: ").append(CanonicalYaml.quote(entry.archiveIdentity())).append('\n')
          .append("    manifest: ").append(CanonicalYaml.quote(entry.manifestIdentity())).append('\n');
      if (entry.dependencies().isEmpty()) {
        text.append("    dependencies: []\n");
      } else {
        text.append("    dependencies:\n");
        for (String dependency : entry.dependencies()) {
          text.append("      - ").append(CanonicalYaml.quote(dependency)).append('\n');
        }
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
      String repositoryIdentity,
      String archiveIdentity,
      String manifestIdentity,
      List<String> dependencies) {
    public Entry {
      Objects.requireNonNull(name, "name");
      if (!name.matches("[a-z][a-z0-9]*(?:\\.[a-z][a-z0-9]*)*")) {
        throw new PackageFormatException("Invalid locked package name " + name);
      }
      SemanticVersion.parse(version);
      if (!hash(repositoryIdentity) || !hash(archiveIdentity) || !hash(manifestIdentity)) {
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
