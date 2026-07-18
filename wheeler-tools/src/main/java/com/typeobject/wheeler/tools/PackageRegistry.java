package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageArchive.DecodedPackage;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.SemanticVersion;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Immutable content-addressed local registry transport with idempotent publication. */
final class PackageRegistry {
  private static final Pattern RELEASE = Pattern.compile(
      "release 1 package \"([^\"]+)\" version \"([^\"]+)\""
          + " archive \"([0-9a-f]{64})\" manifest \"([0-9a-f]{64})\";\\n");

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

  DecodedPackage publish(byte[] bytes) throws IOException {
    DecodedPackage decoded = codec.decode(bytes);
    Path archives = physicalDirectory("archives");
    Path releases = physicalDirectory("releases");
    Path packageDirectory = physicalDirectory(releases, decoded.manifest().name());
    Path archive = archives.resolve(decoded.identity() + ".wpk");
    writeImmutable(archive, bytes, "archive");

    byte[] release = canonicalRelease(decoded).getBytes(StandardCharsets.UTF_8);
    Path mapping = packageDirectory.resolve(decoded.manifest().version() + ".release");
    if (Files.exists(mapping, LinkOption.NOFOLLOW_LINKS)) {
      requirePhysicalFile(mapping, "release mapping");
      if (!Arrays.equals(Files.readAllBytes(mapping), release)) {
        throw new PackageFormatException(
            "Registry version already identifies different content: "
                + decoded.manifest().name() + " " + decoded.manifest().version());
      }
    } else {
      PackageProject.writeAtomically(mapping, release);
    }
    verifyRelease(mapping, decoded.manifest().name(), decoded.manifest().version());
    return decoded;
  }

  byte[] fetch(String name, String version) throws IOException {
    requirePackageName(name);
    SemanticVersion.parse(version);
    Path mapping = descend("releases", name, version + ".release");
    Release release = verifyRelease(mapping, name, version);
    Path archive = descend("archives", release.archiveIdentity() + ".wpk");
    byte[] bytes = Files.readAllBytes(archive);
    DecodedPackage decoded = codec.decode(bytes);
    if (!decoded.identity().equals(release.archiveIdentity())
        || !decoded.manifest().identity().equals(release.manifestIdentity())
        || !decoded.manifest().name().equals(name)
        || !decoded.manifest().version().equals(version)) {
      throw new PackageFormatException("Registry release content does not match its mapping");
    }
    return bytes;
  }

  private Release verifyRelease(Path mapping, String name, String version) throws IOException {
    requirePhysicalFile(mapping, "release mapping");
    String text = new String(Files.readAllBytes(mapping), StandardCharsets.UTF_8);
    Matcher matcher = RELEASE.matcher(text);
    if (!matcher.matches()
        || !matcher.group(1).equals(name)
        || !matcher.group(2).equals(version)) {
      throw new PackageFormatException("Malformed or mismatched registry release mapping");
    }
    requirePackageName(name);
    SemanticVersion.parse(version);
    Release result = new Release(matcher.group(3), matcher.group(4));
    String canonical = canonicalRelease(name, version, result);
    if (!canonical.equals(text)) {
      throw new PackageFormatException("Registry release mapping is not canonical");
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

  private static String canonicalRelease(DecodedPackage decoded) {
    return canonicalRelease(
        decoded.manifest().name(),
        decoded.manifest().version(),
        new Release(decoded.identity(), decoded.manifest().identity()));
  }

  private static String canonicalRelease(String name, String version, Release release) {
    return "release 1 package \"" + name + "\" version \"" + version
        + "\" archive \"" + release.archiveIdentity() + "\" manifest \""
        + release.manifestIdentity() + "\";\n";
  }

  private static void requirePackageName(String name) {
    if (name == null || !name.matches("[a-z][a-z0-9]*(?:\\.[a-z][a-z0-9]*)*")) {
      throw new PackageFormatException("Invalid registry package name " + name);
    }
  }

  private record Release(String archiveIdentity, String manifestIdentity) {}
}
