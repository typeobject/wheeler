package com.typeobject.wheeler.packageformat;

import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Strict canonical decoder for generated {@code wheeler.package.lock}. */
public final class PackageLockParser {
  private static final int MAX_BYTES = 4 * 1024 * 1024;
  private static final Pattern HEADER = Pattern.compile("lock ([0-9]+) root \"([0-9a-f]{64})\";");
  private static final Pattern PACKAGE = Pattern.compile(
      "package \"([^\"]+)\" version \"([^\"]+)\" archive \"([0-9a-f]{64})\""
          + " manifest \"([0-9a-f]{64})\";");
  private static final Pattern EDGE = Pattern.compile("edge \"([^\"]+)\" \"([^\"]+)\";");

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
      return parseCanonical(source);
    } catch (CharacterCodingException exception) {
      throw new PackageFormatException("Lockfile is not strict UTF-8", exception);
    }
  }

  public PackageLock parse(String source) {
    return parse(source.getBytes(StandardCharsets.UTF_8));
  }

  private static PackageLock parseCanonical(String source) {
    String[] lines = source.split("\\n", -1);
    if (lines.length < 2 || !lines[lines.length - 1].isEmpty()) {
      throw new PackageFormatException("Lockfile must end with one newline");
    }
    Matcher header = HEADER.matcher(lines[0]);
    if (!header.matches()) {
      throw new PackageFormatException("Malformed lockfile header");
    }
    int schema;
    try {
      schema = Integer.parseInt(header.group(1));
    } catch (NumberFormatException exception) {
      throw new PackageFormatException("Invalid lockfile schema", exception);
    }
    Map<String, RawEntry> entries = new HashMap<>();
    List<Edge> edges = new ArrayList<>();
    boolean sawEdge = false;
    for (int line = 1; line < lines.length - 1; line++) {
      Matcher packageLine = PACKAGE.matcher(lines[line]);
      Matcher edgeLine = EDGE.matcher(lines[line]);
      if (packageLine.matches() && !sawEdge) {
        RawEntry entry = new RawEntry(
            packageLine.group(1),
            packageLine.group(2),
            packageLine.group(3),
            packageLine.group(4));
        if (entries.put(entry.name(), entry) != null) {
          throw new PackageFormatException("Duplicate lockfile package " + entry.name());
        }
      } else if (edgeLine.matches()) {
        sawEdge = true;
        edges.add(new Edge(edgeLine.group(1), edgeLine.group(2)));
      } else {
        throw new PackageFormatException("Malformed or unordered lockfile line " + (line + 1));
      }
    }
    Map<String, List<String>> dependencies = new HashMap<>();
    for (Edge edge : edges) {
      if (!entries.containsKey(edge.source()) || !entries.containsKey(edge.target())) {
        throw new PackageFormatException("Lockfile edge references an unknown package");
      }
      dependencies.computeIfAbsent(edge.source(), ignored -> new ArrayList<>()).add(edge.target());
    }
    List<PackageLock.Entry> locked = entries.values().stream()
        .map(entry -> new PackageLock.Entry(
            entry.name(),
            entry.version(),
            entry.archive(),
            entry.manifest(),
            dependencies.getOrDefault(entry.name(), List.of())))
        .toList();
    PackageLock result = new PackageLock(schema, header.group(2), locked);
    if (!result.canonicalText().equals(source)) {
      throw new PackageFormatException("Lockfile is not canonical");
    }
    return result;
  }

  private record RawEntry(String name, String version, String archive, String manifest) {}

  private record Edge(String source, String target) {}
}
