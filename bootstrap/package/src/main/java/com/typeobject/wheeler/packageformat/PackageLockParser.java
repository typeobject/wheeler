package com.typeobject.wheeler.packageformat;

import com.typeobject.wheeler.packageformat.CanonicalYaml.Mapping;
import com.typeobject.wheeler.packageformat.CanonicalYaml.Sequence;
import com.typeobject.wheeler.packageformat.CanonicalYaml.Value;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/** Strict schema decoder for generated {@code wheeler.package.lock.yaml}. */
public final class PackageLockParser {
  private static final int MAX_BYTES = 4 * 1024 * 1024;
  private static final Set<String> ROOT_FIELDS = Set.of("schema", "root", "packages");
  private static final Set<String> PACKAGE_FIELDS = Set.of(
      "name", "version", "archive", "manifest", "dependencies");

  public PackageLock parse(byte[] utf8) {
    if (utf8.length > MAX_BYTES) {
      throw new PackageFormatException("Lockfile exceeds " + MAX_BYTES + " bytes");
    }
    try {
      String source = StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(utf8))
          .toString();
      return parseDecoded(source);
    } catch (CharacterCodingException exception) {
      throw new PackageFormatException("Lockfile is not strict UTF-8", exception);
    }
  }

  public PackageLock parse(String source) {
    return parse(source.getBytes(StandardCharsets.UTF_8));
  }

  private static PackageLock parseDecoded(String source) {
    Mapping root = CanonicalYaml.mapping(CanonicalYaml.parse(source, "package lock"), "lock");
    CanonicalYaml.fields(root, ROOT_FIELDS, "lock");
    int schema = CanonicalYaml.integer(
        CanonicalYaml.required(root, "schema", "lock"), "lock.schema");
    String rootIdentity = CanonicalYaml.string(
        CanonicalYaml.required(root, "root", "lock"), "lock.root");
    Sequence packages = CanonicalYaml.sequence(
        CanonicalYaml.required(root, "packages", "lock"), "lock.packages");
    List<PackageLock.Entry> entries = new ArrayList<>();
    for (Value value : packages.values()) {
      Mapping entry = CanonicalYaml.mapping(value, "locked package");
      CanonicalYaml.fields(entry, PACKAGE_FIELDS, "locked package");
      entries.add(new PackageLock.Entry(
          requiredString(entry, "name"),
          requiredString(entry, "version"),
          requiredString(entry, "archive"),
          requiredString(entry, "manifest"),
          stringList(CanonicalYaml.sequence(
              CanonicalYaml.required(entry, "dependencies", "locked package"),
              "locked package dependencies"))));
    }
    return new PackageLock(schema, rootIdentity, entries);
  }

  private static String requiredString(Mapping mapping, String key) {
    return CanonicalYaml.string(
        CanonicalYaml.required(mapping, key, "locked package"), "locked package." + key);
  }

  private static List<String> stringList(Sequence sequence) {
    List<String> result = new ArrayList<>();
    for (Value value : sequence.values()) {
      result.add(CanonicalYaml.string(value, "locked dependency"));
    }
    return List.copyOf(result);
  }
}
