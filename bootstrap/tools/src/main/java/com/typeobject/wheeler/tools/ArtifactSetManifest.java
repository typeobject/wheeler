package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.attribute.BasicFileAttributes;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;

/** Canonical verified identity manifest for one closed tree of Wheeler artifacts. */
final class ArtifactSetManifest {
  static final String FILE_NAME = "artifact-set.json";
  private static final String PROFILE = "wheeler.artifact-set/1";
  private static final int MAX_ARTIFACTS = 65_535;
  private static final long MAX_ARTIFACT_BYTES = 16L * 1024 * 1024;
  private static final long MAX_SET_BYTES = 1024L * 1024 * 1024;

  private ArtifactSetManifest() {}

  /** Verifies a closed artifact directory and atomically writes its canonical manifest. */
  static int execute(String[] args, PrintStream out, PrintStream error) throws IOException {
    if (args.length != 2) {
      error.println("Usage: wheeler manifest-artifacts <artifact-directory>");
      return 2;
    }
    Path root = physicalDirectory(Path.of(args[1]));
    List<Entry> entries = collect(root);
    String identity = identity(entries);
    String manifest = canonicalJson(entries, identity);
    PackageProject.writeAtomically(
        root.resolve(FILE_NAME), manifest.getBytes(StandardCharsets.UTF_8));
    out.println("manifested " + entries.size() + " artifacts (" + identity + ")");
    return 0;
  }

  private static Path physicalDirectory(Path requested) throws IOException {
    if (!Files.isDirectory(requested, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(requested)) {
      throw new IOException("Artifact set is not a physical directory: " + requested);
    }
    return requested.toRealPath(LinkOption.NOFOLLOW_LINKS);
  }

  private static List<Entry> collect(Path root) throws IOException {
    List<Path> paths;
    try (var walk = Files.walk(root)) {
      paths = walk.sorted(Comparator.comparing(Path::toString)).toList();
    }
    List<Entry> entries = new ArrayList<>();
    long totalBytes = 0;
    for (Path path : paths) {
      if (path.equals(root)) {
        continue;
      }
      if (Files.isSymbolicLink(path)) {
        throw new IOException("Artifact set contains a symbolic link: " + path);
      }
      if (Files.isDirectory(path, LinkOption.NOFOLLOW_LINKS)) {
        continue;
      }
      if (!Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS)) {
        throw new IOException("Artifact set contains a nonregular file: " + path);
      }
      String logical = root.relativize(path).toString().replace(
          path.getFileSystem().getSeparator(), "/");
      if (logical.equals(FILE_NAME)) {
        continue;
      }
      if (!logical.endsWith(".wbc")) {
        throw new IOException("Artifact set contains an undeclared file: " + logical);
      }
      BasicFileAttributes before = Files.readAttributes(
          path, BasicFileAttributes.class, LinkOption.NOFOLLOW_LINKS);
      long length = before.size();
      if (!before.isRegularFile() || length <= 0 || length > MAX_ARTIFACT_BYTES) {
        throw new IOException("Artifact exceeds the 16 MiB limit: " + logical);
      }
      totalBytes = Math.addExact(totalBytes, length);
      if (totalBytes > MAX_SET_BYTES || entries.size() == MAX_ARTIFACTS) {
        throw new IOException("Artifact set exceeds its count or byte limit");
      }
      byte[] bytes = Files.readAllBytes(path);
      BasicFileAttributes after = Files.readAttributes(
          path, BasicFileAttributes.class, LinkOption.NOFOLLOW_LINKS);
      if (!after.isRegularFile() || bytes.length != length || after.size() != length
          || before.fileKey() != null && after.fileKey() != null
              && !Objects.equals(before.fileKey(), after.fileKey())
          || !before.lastModifiedTime().equals(after.lastModifiedTime())) {
        throw new IOException("Artifact changed while it was read: " + logical);
      }
      new BytecodeReader().read(bytes);
      entries.add(new Entry(logical, sha256(bytes), bytes.length));
    }
    if (entries.isEmpty()) {
      throw new IOException("Artifact set contains no .wbc files");
    }
    return List.copyOf(entries);
  }

  private static String canonicalJson(List<Entry> entries, String identity) {
    StringBuilder json = new StringBuilder("{\"artifacts\":[");
    for (int index = 0; index < entries.size(); index++) {
      if (index > 0) {
        json.append(',');
      }
      Entry entry = entries.get(index);
      json.append("{\"bytes\":").append(entry.bytes())
          .append(",\"path\":").append(quote(entry.path()))
          .append(",\"sha256\":\"").append(entry.sha256()).append("\"}");
    }
    return json.append("],\"identity\":\"").append(identity)
        .append("\",\"profile\":\"").append(PROFILE).append("\"}\n")
        .toString();
  }

  private static String quote(String value) {
    StringBuilder result = new StringBuilder("\"");
    value.codePoints().forEach(codePoint -> {
      if (codePoint == '"' || codePoint == '\\') {
        result.append('\\').appendCodePoint(codePoint);
      } else if (codePoint < 0x20) {
        result.append(String.format(java.util.Locale.ROOT, "\\u%04x", codePoint));
      } else {
        result.appendCodePoint(codePoint);
      }
    });
    return result.append('"').toString();
  }

  private static String identity(List<Entry> entries) {
    ByteArrayOutputStream canonical = new ByteArrayOutputStream();
    field(canonical, PROFILE);
    for (Entry entry : entries) {
      field(canonical, entry.path());
      field(canonical, entry.sha256());
      field(canonical, Long.toString(entry.bytes()));
    }
    return sha256(canonical.toByteArray());
  }

  private static void field(ByteArrayOutputStream output, String value) {
    byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
    output.write(bytes.length);
    output.write(bytes.length >>> 8);
    output.write(bytes.length >>> 16);
    output.write(bytes.length >>> 24);
    output.writeBytes(bytes);
  }

  private static String sha256(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private record Entry(String path, String sha256, long bytes) {}
}
