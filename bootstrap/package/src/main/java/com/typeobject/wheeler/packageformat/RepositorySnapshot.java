package com.typeobject.wheeler.packageformat;

import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Set;

/** Immutable canonical coordinate view for one repository snapshot. */
public record RepositorySnapshot(List<Entry> releases) {
  public static final int SCHEMA_VERSION = 1;
  public static final String SUFFIX = ".snapshot.yaml";
  public static final String EMPTY_IDENTITY = new RepositorySnapshot(List.of()).identity();
  private static final int MAX_RELEASES = 10_000;
  private static final int MAX_BYTES = 16 * 1024 * 1024;
  private static final Set<String> ROOT_FIELDS = Set.of("schema", "releases");
  private static final Set<String> RELEASE_FIELDS = Set.of(
      "package", "version", "archive", "manifest");

  public RepositorySnapshot {
    if (releases.size() > MAX_RELEASES) {
      throw new PackageFormatException("Repository snapshot exceeds release limit");
    }
    List<Entry> ordered = new ArrayList<>(List.copyOf(releases));
    ordered.sort(Comparator.comparing(Entry::name)
        .thenComparing(entry -> SemanticVersion.parse(entry.version()))
        .thenComparing(Entry::archiveIdentity));
    Set<String> coordinates = new HashSet<>();
    for (Entry entry : ordered) {
      if (!coordinates.add(entry.name() + "\u0000" + entry.version())) {
        throw new PackageFormatException(
            "Duplicate repository snapshot coordinate " + entry.name() + " " + entry.version());
      }
    }
    releases = List.copyOf(ordered);
  }

  public static RepositorySnapshot fromPackageReleases(
      Collection<PackageRelease> releases) {
    return new RepositorySnapshot(releases.stream().map(release -> new Entry(
        release.manifest().name(),
        release.manifest().version(),
        release.archiveIdentity(),
        release.manifest().identity())).toList());
  }

  public static RepositorySnapshot fromMappings(Collection<RepositoryRelease> releases) {
    return new RepositorySnapshot(releases.stream().map(release -> new Entry(
        release.name(),
        release.version(),
        release.archiveIdentity(),
        release.manifestIdentity())).toList());
  }

  public String canonicalText() {
    StringBuilder text = new StringBuilder("schema: 1\n");
    if (releases.isEmpty()) {
      return text.append("releases: []\n").toString();
    }
    text.append("releases:\n");
    for (Entry release : releases) {
      text.append("  - package: ").append(CanonicalYaml.quote(release.name())).append('\n')
          .append("    version: ").append(CanonicalYaml.quote(release.version())).append('\n')
          .append("    archive: ").append(CanonicalYaml.quote(release.archiveIdentity())).append('\n')
          .append("    manifest: ").append(CanonicalYaml.quote(release.manifestIdentity())).append('\n');
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

  public static RepositorySnapshot parse(byte[] utf8) {
    if (utf8.length > MAX_BYTES) {
      throw new PackageFormatException("Repository snapshot exceeds " + MAX_BYTES + " bytes");
    }
    try {
      String source = StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(utf8))
          .toString();
      CanonicalYaml.Mapping root = CanonicalYaml.mapping(
          CanonicalYaml.parse(source, "repository snapshot"), "repository snapshot");
      CanonicalYaml.fields(root, ROOT_FIELDS, "repository snapshot");
      int schema = CanonicalYaml.integer(
          CanonicalYaml.required(root, "schema", "repository snapshot"), "snapshot.schema");
      if (schema != SCHEMA_VERSION) {
        throw new PackageFormatException("Unsupported repository snapshot schema " + schema);
      }
      CanonicalYaml.Sequence rows = CanonicalYaml.sequence(
          CanonicalYaml.required(root, "releases", "repository snapshot"), "snapshot.releases");
      List<Entry> entries = new ArrayList<>();
      for (CanonicalYaml.Value row : rows.values()) {
        CanonicalYaml.Mapping mapping = CanonicalYaml.mapping(row, "snapshot release");
        CanonicalYaml.fields(mapping, RELEASE_FIELDS, "snapshot release");
        entries.add(new Entry(
            string(mapping, "package"),
            string(mapping, "version"),
            string(mapping, "archive"),
            string(mapping, "manifest")));
      }
      RepositorySnapshot snapshot = new RepositorySnapshot(entries);
      if (!snapshot.canonicalText().equals(source)) {
        throw new PackageFormatException("Repository snapshot is not canonical");
      }
      return snapshot;
    } catch (CharacterCodingException exception) {
      throw new PackageFormatException("Repository snapshot is not strict UTF-8", exception);
    }
  }

  private static String string(CanonicalYaml.Mapping mapping, String key) {
    return CanonicalYaml.string(
        CanonicalYaml.required(mapping, key, "snapshot release"), "snapshot." + key);
  }

  /** One exact coordinate mapping in a snapshot. */
  public record Entry(
      String name,
      String version,
      String archiveIdentity,
      String manifestIdentity) {
    public Entry {
      RepositoryRelease validated = new RepositoryRelease(
          RepositoryRelease.SCHEMA_VERSION,
          name,
          version,
          archiveIdentity,
          manifestIdentity);
      name = validated.name();
      version = validated.version();
      archiveIdentity = validated.archiveIdentity();
      manifestIdentity = validated.manifestIdentity();
    }
  }
}
