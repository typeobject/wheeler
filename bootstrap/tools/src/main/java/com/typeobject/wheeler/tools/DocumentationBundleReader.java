package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageFormatException;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Strict reader for the sole semantic documentation-bundle profile. */
final class DocumentationBundleReader {
  private static final int MAX_FILES = 65_535;
  private static final int MAX_FILE_BYTES = 16 * 1024 * 1024;
  private static final Pattern ENTRY = Pattern.compile(
      "\\{\"path\":\"([A-Za-z0-9._/-]+)\",\"sha256\":\"([0-9a-f]{64})\"}");
  private static final Pattern TRAILER = Pattern.compile(
      "\\],\"manualSources\":[0-9]+,\"profile\":\"wheeler-doc-bundle-2\","
          + "\"wheelerSources\":[0-9]+}\\n");

  private DocumentationBundleReader() {}

  /** Verifies exact files and digests before returning immutable manual pages. */
  static Bundle read(Path requested) throws IOException {
    Path root = physicalDirectory(requested);
    byte[] manifestBytes = readPhysical(root.resolve("manifest.json"));
    String manifest = decode(manifestBytes, "manifest.json");
    if (!manifest.startsWith("{\"files\":[")) {
      throw new PackageFormatException("Malformed documentation bundle manifest");
    }
    int trailerStart = manifest.indexOf("],\"manualSources\":");
    if (trailerStart < 0 || !TRAILER.matcher(manifest.substring(trailerStart)).matches()) {
      throw new PackageFormatException("Unsupported documentation bundle profile or framing");
    }
    String records = manifest.substring("{\"files\":[".length(), trailerStart);
    List<ManifestEntry> entries = parseEntries(records);
    Set<String> expected = new TreeSet<>();
    expected.add("manifest.json");
    Map<String, String> pages = new LinkedHashMap<>();
    for (ManifestEntry entry : entries) {
      if (!expected.add(entry.path())) {
        throw new PackageFormatException("Duplicate documentation bundle path " + entry.path());
      }
      Path file = root.resolve(entry.path()).normalize();
      if (!file.startsWith(root)) {
        throw new PackageFormatException("Documentation bundle path escapes its root");
      }
      byte[] bytes = readPhysical(file);
      if (!sha256(bytes).equals(entry.sha256())) {
        throw new PackageFormatException(
            "Documentation bundle digest mismatch: " + entry.path());
      }
      if (entry.path().startsWith("pages/") && entry.path().endsWith(".md")) {
        pages.put(entry.path().substring("pages/".length()), decode(bytes, entry.path()));
      }
    }
    Set<String> actual = physicalFiles(root);
    if (!actual.equals(expected)) {
      throw new PackageFormatException("Documentation bundle contains unmanifested files");
    }
    if (pages.isEmpty() || !pages.containsKey("intro.md")) {
      throw new PackageFormatException("Documentation bundle requires pages/intro.md");
    }
    return new Bundle(root, sha256(manifestBytes), Map.copyOf(pages));
  }

  private static List<ManifestEntry> parseEntries(String records) {
    List<ManifestEntry> result = new ArrayList<>();
    String previous = null;
    int cursor = 0;
    while (cursor < records.length()) {
      Matcher matcher = ENTRY.matcher(records);
      matcher.region(cursor, records.length());
      if (!matcher.lookingAt()) {
        throw new PackageFormatException("Malformed documentation bundle file record");
      }
      String path = matcher.group(1);
      if (path.startsWith("/") || path.endsWith("/") || path.contains("//")) {
        throw new PackageFormatException("Invalid documentation bundle path " + path);
      }
      for (String component : path.split("/")) {
        if (component.equals(".") || component.equals("..")) {
          throw new PackageFormatException("Invalid documentation bundle path " + path);
        }
      }
      if (previous != null && previous.compareTo(path) >= 0) {
        throw new PackageFormatException(
            "Documentation bundle paths are duplicated or unordered: " + path);
      }
      previous = path;
      result.add(new ManifestEntry(path, matcher.group(2)));
      if (result.size() > MAX_FILES) {
        throw new PackageFormatException("Documentation bundle exceeds its file limit");
      }
      cursor = matcher.end();
      if (cursor < records.length()) {
        if (records.charAt(cursor) != ',') {
          throw new PackageFormatException("Malformed documentation bundle file separator");
        }
        cursor++;
      }
    }
    return List.copyOf(result);
  }

  private static Path physicalDirectory(Path requested) throws IOException {
    if (!Files.isDirectory(requested, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(requested)) {
      throw new IOException("Documentation bundle is not a physical directory: " + requested);
    }
    return requested.toRealPath(LinkOption.NOFOLLOW_LINKS);
  }

  private static Set<String> physicalFiles(Path root) throws IOException {
    Set<String> result = new TreeSet<>();
    List<Path> paths;
    try (var walk = Files.walk(root)) {
      paths = walk.sorted(Comparator.comparing(Path::toString)).toList();
    }
    for (Path path : paths) {
      if (path.equals(root)) {
        continue;
      }
      if (Files.isSymbolicLink(path)) {
        throw new IOException("Documentation bundle contains a symbolic link: " + path);
      }
      if (Files.isDirectory(path, LinkOption.NOFOLLOW_LINKS)) {
        continue;
      }
      if (!Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS)) {
        throw new IOException("Documentation bundle contains a special file: " + path);
      }
      result.add(root.relativize(path).toString().replace(
          path.getFileSystem().getSeparator(), "/"));
    }
    return Set.copyOf(result);
  }

  private static byte[] readPhysical(Path path) throws IOException {
    if (!Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(path) || Files.size(path) > MAX_FILE_BYTES) {
      throw new IOException("Documentation bundle file is not bounded and physical: " + path);
    }
    return Files.readAllBytes(path);
  }

  private static String decode(byte[] bytes, String path) throws IOException {
    try {
      return StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(bytes)).toString();
    } catch (CharacterCodingException exception) {
      throw new IOException("Documentation bundle file is not strict UTF-8: " + path, exception);
    }
  }

  static String sha256(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  record Bundle(Path root, String identity, Map<String, String> pages) {}

  private record ManifestEntry(String path, String sha256) {}
}
