package com.typeobject.wheeler.packageformat;

import com.typeobject.wheeler.packageformat.CanonicalYaml.Mapping;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.Set;

/** Canonical immutable name/version mapping stored by one file repository. */
public record RepositoryRelease(
    int schemaVersion,
    String name,
    String version,
    String archiveIdentity,
    String manifestIdentity) {
  public static final int SCHEMA_VERSION = 1;
  public static final String SUFFIX = ".release.yaml";
  private static final int MAX_BYTES = 64 * 1024;
  private static final Set<String> FIELDS = Set.of(
      "schema", "package", "version", "archive", "manifest");

  public RepositoryRelease {
    if (schemaVersion != SCHEMA_VERSION) {
      throw new PackageFormatException("Unsupported repository release schema " + schemaVersion);
    }
    if (name == null || !name.matches("[a-z][a-z0-9]*(?:\\.[a-z][a-z0-9]*)*")) {
      throw new PackageFormatException("Invalid repository package name " + name);
    }
    SemanticVersion.parse(version);
    if (!hash(archiveIdentity) || !hash(manifestIdentity)) {
      throw new PackageFormatException("Invalid repository release identity");
    }
  }

  public String canonicalText() {
    return "schema: 1\n"
        + "package: " + CanonicalYaml.quote(name) + "\n"
        + "version: " + CanonicalYaml.quote(version) + "\n"
        + "archive: " + CanonicalYaml.quote(archiveIdentity) + "\n"
        + "manifest: " + CanonicalYaml.quote(manifestIdentity) + "\n";
  }

  public static RepositoryRelease parse(byte[] utf8) {
    if (utf8.length > MAX_BYTES) {
      throw new PackageFormatException("Repository release exceeds " + MAX_BYTES + " bytes");
    }
    try {
      String source = StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(utf8))
          .toString();
      Mapping mapping = CanonicalYaml.mapping(
          CanonicalYaml.parse(source, "repository release"), "repository release");
      CanonicalYaml.fields(mapping, FIELDS, "repository release");
      RepositoryRelease release = new RepositoryRelease(
          CanonicalYaml.integer(
              CanonicalYaml.required(mapping, "schema", "repository release"), "release.schema"),
          string(mapping, "package"),
          string(mapping, "version"),
          string(mapping, "archive"),
          string(mapping, "manifest"));
      if (!release.canonicalText().equals(source)) {
        throw new PackageFormatException("Repository release mapping is not canonical");
      }
      return release;
    } catch (CharacterCodingException exception) {
      throw new PackageFormatException("Repository release is not strict UTF-8", exception);
    }
  }

  private static String string(Mapping mapping, String key) {
    return CanonicalYaml.string(
        CanonicalYaml.required(mapping, key, "repository release"), "release." + key);
  }

  private static boolean hash(String value) {
    return value != null && value.matches("[0-9a-f]{64}");
  }
}
