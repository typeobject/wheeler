package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.packageformat.BuildOutputQuarantine;
import com.typeobject.wheeler.packageformat.BuildOutputRecord;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Stream;

/** Reverified build-output reuse keyed only by complete canonical build input. */
final class BuildOutputCache {
  private static final int MAX_ARTIFACT_BYTES = 16 * 1024 * 1024;
  private static final int MAX_GC_ENTRIES = 10_000;
  private final Path cacheRoot;
  private final Path stateRoot;

  BuildOutputCache(Path artifactCache, Path stateRoot) {
    this.cacheRoot = artifactCache.resolve("build-outputs").toAbsolutePath().normalize();
    this.stateRoot = stateRoot.resolve("quarantine/build-outputs").toAbsolutePath().normalize();
  }

  byte[] load(String buildInputIdentity) throws IOException {
    requireIdentity(buildInputIdentity);
    if (!Files.exists(cacheRoot, LinkOption.NOFOLLOW_LINKS)) {
      return null;
    }
    requireExistingDirectory(cacheRoot);
    Path recordDirectory = cacheRoot.resolve("records");
    if (!Files.exists(recordDirectory, LinkOption.NOFOLLOW_LINKS)) {
      return null;
    }
    requireExistingDirectory(recordDirectory);
    Path recordPath = recordDirectory.resolve(buildInputIdentity + BuildOutputRecord.SUFFIX);
    if (!Files.exists(recordPath, LinkOption.NOFOLLOW_LINKS)) {
      return null;
    }
    if (removeInvalidRegular(recordPath, 64 * 1024)) {
      return null;
    }
    BuildOutputRecord record;
    try {
      record = BuildOutputRecord.parse(readPhysical(recordPath, 64 * 1024, false));
    } catch (PackageFormatException exception) {
      deleteRegular(recordPath);
      return null;
    }
    if (!record.buildInputIdentity().equals(buildInputIdentity)) {
      deleteRegular(recordPath);
      return null;
    }
    Path objectDirectory = cacheRoot.resolve("objects");
    if (!Files.exists(objectDirectory, LinkOption.NOFOLLOW_LINKS)) {
      deleteRegular(recordPath);
      return null;
    }
    requireExistingDirectory(objectDirectory);
    Path object = objectDirectory.resolve(record.prev() + ".wbc");
    if (!Files.exists(object, LinkOption.NOFOLLOW_LINKS)) {
      deleteRegular(recordPath);
      return null;
    }
    if (removeInvalidRegular(object, MAX_ARTIFACT_BYTES)) {
      deleteRegular(recordPath);
      return null;
    }
    try {
      byte[] bytes = readPhysical(object, MAX_ARTIFACT_BYTES, false);
      if (bytes.length != record.bytes() || !PackageProject.sha256(bytes).equals(record.prev())) {
        deleteRegular(object);
        deleteRegular(recordPath);
        return null;
      }
      requireCanonicalArtifact(bytes);
      return bytes;
    } catch (PackageFormatException | BytecodeException exception) {
      deleteRegular(object);
      deleteRegular(recordPath);
      return null;
    }
  }

  GcResult gc() throws IOException {
    if (!Files.exists(cacheRoot, LinkOption.NOFOLLOW_LINKS)) {
      return new GcResult(0, 0);
    }
    if (!Files.isDirectory(cacheRoot, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(cacheRoot)) {
      throw new IOException("Build output cache root is not a physical directory: " + cacheRoot);
    }
    int[] visits = {0};
    Path records = cacheRoot.resolve("records");
    Path objects = cacheRoot.resolve("objects");
    List<Path> initialRecords = regularEntries(records, visits);
    List<Path> initialObjects = regularEntries(objects, visits);
    int initial = initialRecords.size() + initialObjects.size();
    Set<String> referenced = new HashSet<>();
    for (Path record : initialRecords) {
      String name = record.getFileName().toString();
      if (!name.endsWith(BuildOutputRecord.SUFFIX)) {
        Files.delete(record);
        continue;
      }
      String input = name.substring(0, name.length() - BuildOutputRecord.SUFFIX.length());
      if (!input.matches("[0-9a-f]{64}")) {
        Files.delete(record);
        continue;
      }
      byte[] bytes = load(input);
      if (bytes != null) {
        referenced.add(PackageProject.sha256(bytes));
      }
    }
    List<Path> currentObjects = regularEntries(objects, visits);
    for (Path object : currentObjects) {
      String name = object.getFileName().toString();
      String prev = name.endsWith(".wbc") ? name.substring(0, name.length() - 4) : "";
      if (!prev.matches("[0-9a-f]{64}") || !referenced.contains(prev)) {
        Files.delete(object);
        continue;
      }
      try {
        byte[] bytes = readPhysical(object, MAX_ARTIFACT_BYTES, false);
        if (!PackageProject.sha256(bytes).equals(prev)) {
          Files.delete(object);
        } else {
          requireCanonicalArtifact(bytes);
        }
      } catch (PackageFormatException | BytecodeException exception) {
        Files.deleteIfExists(object);
      }
    }
    for (Path record : initialRecords) {
      if (Files.exists(record, LinkOption.NOFOLLOW_LINKS)) {
        String name = record.getFileName().toString();
        String input = name.substring(0, name.length() - BuildOutputRecord.SUFFIX.length());
        load(input);
      }
    }
    int retained = regularEntries(records, visits).size() + regularEntries(objects, visits).size();
    return new GcResult(retained, initial - retained);
  }

  void store(String buildInputIdentity, byte[] bytes) throws IOException {
    requireIdentity(buildInputIdentity);
    bytes = bytes.clone();
    requireCanonicalArtifact(bytes);
    String prev = PackageProject.sha256(bytes);
    BuildOutputRecord observed = new BuildOutputRecord(buildInputIdentity, prev, bytes.length);
    Path objects = physicalDirectory(cacheRoot.resolve("objects"));
    Path records = physicalDirectory(cacheRoot.resolve("records"));
    Path object = objects.resolve(prev + ".wbc");
    writeCacheObject(object, bytes);

    Path recordPath = records.resolve(buildInputIdentity + BuildOutputRecord.SUFFIX);
    if (Files.exists(recordPath, LinkOption.NOFOLLOW_LINKS)) {
      if (removeInvalidRegular(recordPath, 64 * 1024)) {
        PackageProject.writeAtomically(recordPath, observed.canonicalBytes());
        return;
      }
      BuildOutputRecord expected;
      try {
        expected = BuildOutputRecord.parse(readPhysical(recordPath, 64 * 1024, false));
      } catch (PackageFormatException exception) {
        deleteRegular(recordPath);
        PackageProject.writeAtomically(recordPath, observed.canonicalBytes());
        return;
      }
      if (!expected.buildInputIdentity().equals(buildInputIdentity)) {
        deleteRegular(recordPath);
        PackageProject.writeAtomically(recordPath, observed.canonicalBytes());
        return;
      }
      if (!expected.prev().equals(prev) || expected.bytes() != bytes.length) {
        quarantine(expected, observed, bytes);
        throw new PackageFormatException(
            "Build output diverged for input " + buildInputIdentity
                + ": expected " + expected.prev() + ", observed " + prev);
      }
      return;
    }
    PackageProject.writeAtomically(recordPath, observed.canonicalBytes());
  }

  private void quarantine(
      BuildOutputRecord expected, BuildOutputRecord observed, byte[] bytes) throws IOException {
    Path input = physicalDirectory(stateRoot.resolve(expected.buildInputIdentity()));
    Path revision = physicalDirectory(input.resolve(observed.prev()));
    writeImmutable(revision.resolve("observed.wbc"), bytes, "quarantined build output");
    BuildOutputQuarantine record = new BuildOutputQuarantine(
        expected.buildInputIdentity(), expected.prev(), observed.prev(), observed.bytes());
    writeImmutable(
        revision.resolve(BuildOutputQuarantine.FILE_NAME),
        record.canonicalBytes(),
        "build output quarantine record");
  }

  private static void requireCanonicalArtifact(byte[] bytes) {
    byte[] canonical = new BytecodeWriter().write(new BytecodeReader().read(bytes));
    if (!Arrays.equals(bytes, canonical)) {
      throw new PackageFormatException("Build output cache object is not canonical bytecode");
    }
  }

  private static byte[] readPhysical(Path path, long maximum, boolean allowEmpty)
      throws IOException {
    if (!Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS) || Files.isSymbolicLink(path)) {
      throw new IOException("Build output cache path is not a physical file: " + path);
    }
    BasicFileAttributes before = Files.readAttributes(
        path, BasicFileAttributes.class, LinkOption.NOFOLLOW_LINKS);
    if (before.size() > maximum || (!allowEmpty && before.size() == 0)) {
      throw new IOException("Build output cache file is empty or oversized: " + path);
    }
    byte[] bytes = Files.readAllBytes(path);
    BasicFileAttributes after = Files.readAttributes(
        path, BasicFileAttributes.class, LinkOption.NOFOLLOW_LINKS);
    if (!after.isRegularFile()
        || bytes.length != before.size()
        || bytes.length != after.size()
        || before.fileKey() != null && after.fileKey() != null
            && !Objects.equals(before.fileKey(), after.fileKey())
        || !before.lastModifiedTime().equals(after.lastModifiedTime())) {
      throw new IOException("Build output cache file changed while being read: " + path);
    }
    return bytes;
  }

  private static void requireExistingDirectory(Path directory) throws IOException {
    if (!Files.isDirectory(directory, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(directory)) {
      throw new IOException("Build output cache path is not a physical directory: " + directory);
    }
  }

  private static Path physicalDirectory(Path directory) throws IOException {
    RepositoryPolicyStore.createPhysicalDirectories(directory);
    if (!Files.isDirectory(directory, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(directory)) {
      throw new IOException("Build output cache path is not a physical directory: " + directory);
    }
    return directory.toRealPath(LinkOption.NOFOLLOW_LINKS);
  }

  private static void writeCacheObject(Path path, byte[] bytes) throws IOException {
    if (Files.exists(path, LinkOption.NOFOLLOW_LINKS)) {
      if (removeInvalidRegular(path, MAX_ARTIFACT_BYTES)) {
        PackageProject.writeAtomically(path, bytes);
        return;
      }
      byte[] existing = readPhysical(path, MAX_ARTIFACT_BYTES, false);
      if (Arrays.equals(existing, bytes)) {
        return;
      }
      Files.delete(path);
    }
    PackageProject.writeAtomically(path, bytes);
  }

  private static void writeImmutable(Path path, byte[] bytes, String description)
      throws IOException {
    if (Files.exists(path, LinkOption.NOFOLLOW_LINKS)) {
      byte[] existing = readPhysical(path, MAX_ARTIFACT_BYTES, false);
      if (!Arrays.equals(existing, bytes)) {
        throw new IOException("Conflicting " + description + " at " + path);
      }
      return;
    }
    PackageProject.writeAtomically(path, bytes);
  }

  private static List<Path> regularEntries(Path directory, int[] visits) throws IOException {
    if (!Files.exists(directory, LinkOption.NOFOLLOW_LINKS)) {
      return List.of();
    }
    if (!Files.isDirectory(directory, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(directory)) {
      throw new IOException("Build output cache contains a nonphysical directory: " + directory);
    }
    List<Path> entries;
    try (Stream<Path> listed = Files.list(directory)) {
      entries = listed.sorted(Comparator.comparing(path -> path.getFileName().toString())).toList();
    }
    List<Path> regular = new ArrayList<>();
    for (Path entry : entries) {
      visits[0]++;
      if (visits[0] > MAX_GC_ENTRIES) {
        throw new IOException("Build output cache GC exceeds " + MAX_GC_ENTRIES + " entries");
      }
      if (Files.isSymbolicLink(entry)
          || !Files.isRegularFile(entry, LinkOption.NOFOLLOW_LINKS)) {
        throw new IOException("Build output cache contains a special entry: " + entry);
      }
      regular.add(entry);
    }
    return List.copyOf(regular);
  }

  private static boolean removeInvalidRegular(Path path, long maximum) throws IOException {
    if (Files.isSymbolicLink(path)) {
      throw new IOException("Build output cache contains a symbolic link: " + path);
    }
    if (!Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS)) {
      throw new IOException("Build output cache contains a special file: " + path);
    }
    long size = Files.size(path);
    if (size == 0 || size > maximum) {
      Files.delete(path);
      return true;
    }
    return false;
  }

  private static void deleteRegular(Path path) throws IOException {
    if (Files.isSymbolicLink(path)) {
      throw new IOException("Build output cache contains a symbolic link: " + path);
    }
    if (Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS)) {
      Files.delete(path);
    } else if (Files.exists(path, LinkOption.NOFOLLOW_LINKS)) {
      throw new IOException("Build output cache contains a special file: " + path);
    }
  }

  record GcResult(int retained, int removed) {}

  private static void requireIdentity(String identity) {
    if (identity == null || !identity.matches("[0-9a-f]{64}")) {
      throw new PackageFormatException("Invalid build input identity");
    }
  }
}
