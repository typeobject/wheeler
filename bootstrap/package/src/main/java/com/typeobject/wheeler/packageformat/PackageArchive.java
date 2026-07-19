package com.typeobject.wheeler.packageformat;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.Collections;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;
import java.util.TreeMap;

/** Canonical content-addressed {@code .wpk} archive codec. */
public final class PackageArchive {
  private static final byte[] MAGIC = {'W', 'P', 'K', 'G', 0, 0, 0, 1};
  private static final int DIGEST_BYTES = 32;
  private static final int MAX_ARCHIVE_BYTES = 16 * 1024 * 1024;
  private static final int MAX_ENTRIES = 10_000;
  private static final int MAX_PATH_BYTES = 4096;

  public byte[] encode(PackageManifest manifest, Map<String, byte[]> sourceEntries) {
    Objects.requireNonNull(manifest, "manifest");
    Objects.requireNonNull(sourceEntries, "sourceEntries");
    if (sourceEntries.size() > MAX_ENTRIES) {
      throw new PackageFormatException("Package has too many entries");
    }
    TreeMap<String, byte[]> entries = normalizedEntries(sourceEntries);
    requireTargetSources(manifest, entries);
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    output.writeBytes(MAGIC);
    byte[] manifestBytes = manifest.canonicalBytes();
    writeInt(output, manifestBytes.length);
    writeInt(output, entries.size());
    output.writeBytes(manifestBytes);
    for (Map.Entry<String, byte[]> entry : entries.entrySet()) {
      byte[] path = entry.getKey().getBytes(StandardCharsets.UTF_8);
      byte[] data = entry.getValue();
      writeInt(output, path.length);
      writeLong(output, data.length);
      output.writeBytes(path);
      output.writeBytes(digest(data));
      output.writeBytes(data);
      if (output.size() > MAX_ARCHIVE_BYTES - DIGEST_BYTES) {
        throw new PackageFormatException("Package exceeds archive size limit");
      }
    }
    byte[] payload = output.toByteArray();
    output.writeBytes(digest(payload));
    return output.toByteArray();
  }

  public DecodedPackage decode(byte[] archive) {
    Objects.requireNonNull(archive, "archive");
    if (archive.length <= MAGIC.length + DIGEST_BYTES || archive.length > MAX_ARCHIVE_BYTES) {
      throw new PackageFormatException("Invalid package archive length");
    }
    byte[] payload = Arrays.copyOf(archive, archive.length - DIGEST_BYTES);
    byte[] expected = Arrays.copyOfRange(archive, payload.length, archive.length);
    if (!MessageDigest.isEqual(digest(payload), expected)) {
      throw new PackageFormatException("Package archive integrity check failed");
    }
    ByteBuffer input = ByteBuffer.wrap(payload).order(ByteOrder.LITTLE_ENDIAN);
    byte[] magic = new byte[MAGIC.length];
    input.get(magic);
    if (!Arrays.equals(magic, MAGIC)) {
      throw new PackageFormatException("Invalid package archive magic");
    }
    int manifestLength = bounded(input.getInt(), MAX_ARCHIVE_BYTES, "manifest length");
    int count = bounded(input.getInt(), MAX_ENTRIES, "entry count");
    require(input, manifestLength, "manifest");
    byte[] manifestBytes = new byte[manifestLength];
    input.get(manifestBytes);
    PackageManifest manifest = new PackageManifestParser().parse(manifestBytes);
    if (!Arrays.equals(manifestBytes, manifest.canonicalBytes())) {
      throw new PackageFormatException("Package manifest is not canonical");
    }
    Map<String, byte[]> entries = new LinkedHashMap<>();
    String previous = null;
    for (int index = 0; index < count; index++) {
      require(input, Integer.BYTES + Long.BYTES, "entry header");
      int pathLength = bounded(input.getInt(), MAX_PATH_BYTES, "path length");
      long dataLength = input.getLong();
      if (dataLength < 0 || dataLength > MAX_ARCHIVE_BYTES) {
        throw new PackageFormatException("Invalid package entry length");
      }
      require(input, Math.addExact(pathLength, Math.addExact(DIGEST_BYTES, Math.toIntExact(dataLength))),
          "entry payload");
      byte[] pathBytes = new byte[pathLength];
      input.get(pathBytes);
      String path = strictPath(pathBytes);
      if (previous != null && previous.compareTo(path) >= 0) {
        throw new PackageFormatException("Package entries are duplicated or unordered");
      }
      previous = path;
      byte[] entryDigest = new byte[DIGEST_BYTES];
      input.get(entryDigest);
      byte[] data = new byte[Math.toIntExact(dataLength)];
      input.get(data);
      if (!MessageDigest.isEqual(digest(data), entryDigest)) {
        throw new PackageFormatException("Package entry integrity check failed: " + path);
      }
      entries.put(path, data);
    }
    if (input.hasRemaining()) {
      throw new PackageFormatException("Trailing package archive payload");
    }
    requireTargetSources(manifest, entries);
    return new DecodedPackage(manifest, entries, identity(archive));
  }

  private static void requireTargetSources(
      PackageManifest manifest, Map<String, byte[]> entries) {
    for (PackageManifest.Target target : manifest.targets()) {
      if (!entries.containsKey(target.root())) {
        throw new PackageFormatException("Package is missing target root " + target.root());
      }
      for (String selector : target.sources()) {
        boolean selected = entries.containsKey(selector)
            || entries.keySet().stream().anyMatch(
                path -> path.startsWith(selector + "/") && path.endsWith(".w"));
        if (!selected) {
          throw new PackageFormatException("Package is missing source selector " + selector);
        }
      }
    }
  }

  public String identity(byte[] archive) {
    return HexFormat.of().formatHex(digest(archive));
  }

  private static TreeMap<String, byte[]> normalizedEntries(Map<String, byte[]> source) {
    TreeMap<String, byte[]> result = new TreeMap<>();
    source.forEach((path, data) -> {
      String normalized = PackageManifest.logicalPath(path);
      if (normalized.equals("wheeler.package.yaml") || result.put(normalized, data.clone()) != null) {
        throw new PackageFormatException("Reserved or duplicate package entry " + normalized);
      }
    });
    return result;
  }

  private static String strictPath(byte[] bytes) {
    String path = new String(bytes, StandardCharsets.UTF_8);
    if (!Arrays.equals(bytes, path.getBytes(StandardCharsets.UTF_8))) {
      throw new PackageFormatException("Package path is not strict UTF-8");
    }
    return PackageManifest.logicalPath(path);
  }

  private static void require(ByteBuffer input, int bytes, String description) {
    if (bytes < 0 || input.remaining() < bytes) {
      throw new PackageFormatException("Truncated package " + description);
    }
  }

  private static int bounded(int value, int maximum, String description) {
    if (value < 0 || value > maximum) {
      throw new PackageFormatException("Invalid package " + description);
    }
    return value;
  }

  private static void writeInt(ByteArrayOutputStream output, int value) {
    output.write(value);
    output.write(value >>> 8);
    output.write(value >>> 16);
    output.write(value >>> 24);
  }

  private static void writeLong(ByteArrayOutputStream output, long value) {
    for (int shift = 0; shift < Long.SIZE; shift += Byte.SIZE) {
      output.write((int) (value >>> shift));
    }
  }

  private static byte[] digest(byte[] bytes) {
    try {
      return MessageDigest.getInstance("SHA-256").digest(bytes);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  public record DecodedPackage(
      PackageManifest manifest, Map<String, byte[]> entries, String identity) {
    public DecodedPackage {
      Objects.requireNonNull(manifest, "manifest");
      Objects.requireNonNull(identity, "identity");
      Map<String, byte[]> copy = new LinkedHashMap<>();
      entries.forEach((path, data) -> copy.put(path, data.clone()));
      entries = Collections.unmodifiableMap(copy);
    }

    @Override
    public Map<String, byte[]> entries() {
      Map<String, byte[]> copy = new LinkedHashMap<>();
      entries.forEach((path, data) -> copy.put(path, data.clone()));
      return Collections.unmodifiableMap(copy);
    }
  }
}
