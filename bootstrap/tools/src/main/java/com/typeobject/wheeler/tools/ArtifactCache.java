package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageArchive.DecodedPackage;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.RepositoryRelease;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Stream;

/** Disposable verified package-object cache that never contributes resolver authority. */
final class ArtifactCache {
  private static final long MAX_ARCHIVE_BYTES = 16L * 1024L * 1024L;
  private static final int MAX_OBJECTS = 10_000;
  private final Path packages;
  private final PackageArchive codec = new PackageArchive();

  ArtifactCache(Path artifactRoot) {
    if (!artifactRoot.isAbsolute()) {
      throw new PackageFormatException("Artifact cache root is not absolute: " + artifactRoot);
    }
    packages = artifactRoot.normalize().resolve("packages");
  }

  byte[] load(RepositoryRelease expected) throws IOException {
    Path path = path(expected.archiveIdentity());
    if (!Files.exists(path, LinkOption.NOFOLLOW_LINKS)) {
      return null;
    }
    if (!Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS) || Files.isSymbolicLink(path)) {
      throw new IOException("Cache object is not a physical file: " + path);
    }
    if (Files.size(path) > MAX_ARCHIVE_BYTES) {
      Files.delete(path);
      return null;
    }
    byte[] bytes = Files.readAllBytes(path);
    try {
      requireExpected(codec.decode(bytes), expected);
      return bytes;
    } catch (PackageFormatException exception) {
      Files.delete(path);
      return null;
    }
  }

  void store(RepositoryRelease expected, byte[] bytes) throws IOException {
    requireExpected(codec.decode(bytes), expected);
    RepositoryPolicyStore.createPhysicalDirectories(packages);
    Path path = path(expected.archiveIdentity());
    if (Files.exists(path, LinkOption.NOFOLLOW_LINKS)) {
      byte[] cached = load(expected);
      if (cached != null) {
        return;
      }
    }
    PackageProject.writeAtomically(path, bytes);
    byte[] verified = load(expected);
    if (verified == null) {
      throw new PackageFormatException("Cache insertion did not reproduce verified bytes");
    }
  }

  GcResult gc() throws IOException {
    if (!Files.exists(packages, LinkOption.NOFOLLOW_LINKS)) {
      return new GcResult(0, 0);
    }
    if (!Files.isDirectory(packages, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(packages)) {
      throw new IOException("Package cache is not a physical directory: " + packages);
    }
    List<Path> entries;
    try (Stream<Path> listed = Files.list(packages)) {
      entries = listed.sorted(Comparator.comparing(path -> path.getFileName().toString())).toList();
    }
    if (entries.size() > MAX_OBJECTS) {
      throw new IOException("Package cache exceeds " + MAX_OBJECTS + " objects");
    }
    int retained = 0;
    int removed = 0;
    for (Path entry : entries) {
      if (!Files.isRegularFile(entry, LinkOption.NOFOLLOW_LINKS)
          || Files.isSymbolicLink(entry)) {
        throw new IOException("Cache entry is not a physical file: " + entry);
      }
      String fileName = entry.getFileName().toString();
      boolean valid = fileName.matches("[0-9a-f]{64}\\.wpk")
          && Files.size(entry) <= MAX_ARCHIVE_BYTES;
      if (valid) {
        try {
          byte[] bytes = Files.readAllBytes(entry);
          valid = codec.identity(bytes).equals(fileName.substring(0, 64));
          if (valid) {
            codec.decode(bytes);
          }
        } catch (PackageFormatException exception) {
          valid = false;
        }
      }
      if (valid) {
        retained++;
      } else {
        Files.delete(entry);
        removed++;
      }
    }
    return new GcResult(retained, removed);
  }

  Path path(String archiveIdentity) {
    if (archiveIdentity == null || !archiveIdentity.matches("[0-9a-f]{64}")) {
      throw new PackageFormatException("Invalid cache object identity " + archiveIdentity);
    }
    return packages.resolve(archiveIdentity + ".wpk");
  }

  record GcResult(int retained, int removed) {}

  private static void requireExpected(DecodedPackage decoded, RepositoryRelease expected) {
    if (!decoded.identity().equals(expected.archiveIdentity())
        || !decoded.manifest().identity().equals(expected.manifestIdentity())
        || !decoded.manifest().name().equals(expected.name())
        || !decoded.manifest().version().equals(expected.version())) {
      throw new PackageFormatException("Cached package does not match authoritative release");
    }
  }
}
