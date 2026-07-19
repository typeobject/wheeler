package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageArchive.DecodedPackage;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.PackageRelease;
import com.typeobject.wheeler.packageformat.RepositoryRelease;
import com.typeobject.wheeler.packageformat.SemanticVersion;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Stream;

/** Immutable content-addressed local registry transport with idempotent publication. */
final class PackageRegistry {
  private static final int MAX_RELEASES = 10_000;
  private final Path root;
  private final PackageArchive codec = new PackageArchive();

  private PackageRegistry(Path root) {
    this.root = root;
  }

  static PackageRegistry open(Path requestedRoot) throws IOException {
    Path root = requestedRoot.toRealPath(LinkOption.NOFOLLOW_LINKS);
    if (!Files.isDirectory(root, LinkOption.NOFOLLOW_LINKS) || Files.isSymbolicLink(root)) {
      throw new IOException("Registry is not a physical directory: " + requestedRoot);
    }
    return new PackageRegistry(root);
  }

  static PackageRegistry openOrCreate(Path requestedRoot) throws IOException {
    if (!Files.exists(requestedRoot, LinkOption.NOFOLLOW_LINKS)) {
      RepositoryPolicyStore.createPhysicalDirectories(requestedRoot.toAbsolutePath().normalize());
    }
    return open(requestedRoot);
  }

  DecodedPackage publish(byte[] bytes) throws IOException {
    DecodedPackage decoded = codec.decode(bytes);
    Path archives = physicalDirectory("archives");
    Path releases = physicalDirectory("releases");
    Path packageDirectory = physicalDirectory(releases, decoded.manifest().name());
    Path archive = archives.resolve(decoded.identity() + ".wpk");
    writeImmutable(archive, bytes, "archive");

    RepositoryRelease release = release(decoded);
    byte[] releaseBytes = release.canonicalText().getBytes(StandardCharsets.UTF_8);
    Path mapping = packageDirectory.resolve(decoded.manifest().version() + RepositoryRelease.SUFFIX);
    if (Files.exists(mapping, LinkOption.NOFOLLOW_LINKS)) {
      requirePhysicalFile(mapping, "release mapping");
      if (!Arrays.equals(Files.readAllBytes(mapping), releaseBytes)) {
        throw new PackageFormatException(
            "Registry version already identifies different content: "
                + decoded.manifest().name() + " " + decoded.manifest().version());
      }
    } else {
      PackageProject.writeAtomically(mapping, releaseBytes);
    }
    verifyRelease(mapping, decoded.manifest().name(), decoded.manifest().version());
    return decoded;
  }

  byte[] fetch(String name, String version) throws IOException {
    byte[] bytes = fetchIfPresent(name, version);
    if (bytes == null) {
      throw new IOException("Registry has no release " + name + " " + version);
    }
    return bytes;
  }

  byte[] fetchIfPresent(String name, String version) throws IOException {
    RepositoryRelease release = releaseIfPresent(name, version);
    return release == null ? null : fetch(release);
  }

  RepositoryRelease releaseIfPresent(String name, String version) throws IOException {
    requirePackageName(name);
    SemanticVersion.parse(version);
    Path releaseRoot = root.resolve("releases");
    if (!Files.exists(releaseRoot, LinkOption.NOFOLLOW_LINKS)) {
      return null;
    }
    if (!Files.isDirectory(releaseRoot, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(releaseRoot)) {
      throw new IOException("Registry releases path is not a physical directory");
    }
    Path packageRoot = releaseRoot.resolve(name);
    if (!Files.exists(packageRoot, LinkOption.NOFOLLOW_LINKS)) {
      return null;
    }
    if (!Files.isDirectory(packageRoot, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(packageRoot)) {
      throw new IOException("Registry package path is not a physical directory: " + packageRoot);
    }
    Path mapping = packageRoot.resolve(version + RepositoryRelease.SUFFIX);
    if (!Files.exists(mapping, LinkOption.NOFOLLOW_LINKS)) {
      return null;
    }
    requirePhysicalFile(mapping, "release mapping");
    return verifyRelease(mapping, name, version);
  }

  byte[] fetch(RepositoryRelease release) throws IOException {
    Path archive = descend("archives", release.archiveIdentity() + ".wpk");
    byte[] bytes = Files.readAllBytes(archive);
    DecodedPackage decoded = codec.decode(bytes);
    if (!decoded.identity().equals(release.archiveIdentity())
        || !decoded.manifest().identity().equals(release.manifestIdentity())
        || !decoded.manifest().name().equals(release.name())
        || !decoded.manifest().version().equals(release.version())) {
      throw new PackageFormatException("Registry release content does not match its mapping");
    }
    return bytes;
  }

  List<PackageRelease> releases() throws IOException {
    Path releaseRoot = root.resolve("releases");
    if (!Files.exists(releaseRoot, LinkOption.NOFOLLOW_LINKS)) {
      return List.of();
    }
    if (!Files.isDirectory(releaseRoot, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(releaseRoot)) {
      throw new IOException("Repository releases path is not a physical directory");
    }
    List<Path> packages;
    try (Stream<Path> entries = Files.list(releaseRoot)) {
      packages = entries.sorted(Comparator.comparing(path -> path.getFileName().toString()))
          .toList();
    }
    List<PackageRelease> result = new ArrayList<>();
    for (Path packageDirectory : packages) {
      if (!Files.isDirectory(packageDirectory, LinkOption.NOFOLLOW_LINKS)
          || Files.isSymbolicLink(packageDirectory)) {
        throw new IOException(
            "Repository release entry is not a physical directory: " + packageDirectory);
      }
      String name = packageDirectory.getFileName().toString();
      requirePackageName(name);
      List<Path> mappings;
      try (Stream<Path> entries = Files.list(packageDirectory)) {
        mappings = entries.sorted(Comparator.comparing(path -> path.getFileName().toString()))
            .toList();
      }
      for (Path mapping : mappings) {
        String fileName = mapping.getFileName().toString();
        if (!fileName.endsWith(RepositoryRelease.SUFFIX)) {
          throw new IOException("Unknown repository release entry: " + mapping);
        }
        String version = fileName.substring(
            0, fileName.length() - RepositoryRelease.SUFFIX.length());
        byte[] bytes = fetch(name, version);
        DecodedPackage decoded = codec.decode(bytes);
        result.add(new PackageRelease(decoded.manifest(), decoded.identity()));
        if (result.size() > MAX_RELEASES) {
          throw new IOException("Repository exceeds " + MAX_RELEASES + " releases");
        }
      }
    }
    return List.copyOf(result);
  }

  private RepositoryRelease verifyRelease(Path mapping, String name, String version)
      throws IOException {
    requirePhysicalFile(mapping, "release mapping");
    RepositoryRelease result = RepositoryRelease.parse(Files.readAllBytes(mapping));
    if (!result.name().equals(name) || !result.version().equals(version)) {
      throw new PackageFormatException("Mismatched repository release mapping");
    }
    return result;
  }

  private Path physicalDirectory(String logical) throws IOException {
    return physicalDirectory(root, logical);
  }

  private static Path physicalDirectory(Path parent, String logical) throws IOException {
    Path directory = parent.resolve(logical);
    if (!Files.exists(directory, LinkOption.NOFOLLOW_LINKS)) {
      Files.createDirectory(directory);
    }
    if (!Files.isDirectory(directory, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(directory)) {
      throw new IOException("Registry path is not a physical directory: " + directory);
    }
    return directory;
  }

  private Path descend(String... components) throws IOException {
    Path current = root;
    for (int index = 0; index < components.length; index++) {
      current = current.resolve(components[index]);
      if (index + 1 < components.length) {
        if (!Files.isDirectory(current, LinkOption.NOFOLLOW_LINKS)
            || Files.isSymbolicLink(current)) {
          throw new IOException("Registry path is not a physical directory: " + current);
        }
      }
    }
    requirePhysicalFile(current, "registry content");
    return current;
  }

  private static void writeImmutable(Path path, byte[] bytes, String description)
      throws IOException {
    if (Files.exists(path, LinkOption.NOFOLLOW_LINKS)) {
      requirePhysicalFile(path, description);
      if (!Arrays.equals(Files.readAllBytes(path), bytes)) {
        throw new PackageFormatException("Registry " + description + " content collision");
      }
      return;
    }
    PackageProject.writeAtomically(path, bytes);
  }

  private static void requirePhysicalFile(Path path, String description) throws IOException {
    if (!Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS) || Files.isSymbolicLink(path)) {
      throw new IOException("Missing physical " + description + ": " + path);
    }
  }

  private static RepositoryRelease release(DecodedPackage decoded) {
    return new RepositoryRelease(
        RepositoryRelease.SCHEMA_VERSION,
        decoded.manifest().name(),
        decoded.manifest().version(),
        decoded.identity(),
        decoded.manifest().identity());
  }

  private static void requirePackageName(String name) {
    if (name == null || !name.matches("[a-z][a-z0-9]*(?:\\.[a-z][a-z0-9]*)*")) {
      throw new PackageFormatException("Invalid registry package name " + name);
    }
  }

}
