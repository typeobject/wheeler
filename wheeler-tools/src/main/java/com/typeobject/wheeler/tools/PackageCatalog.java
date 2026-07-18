package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageRelease;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Stream;

/** Strict local catalog loader for already content-verified {@code .wpk} archives. */
final class PackageCatalog {
  private static final int MAX_ARCHIVES = 10_000;

  private PackageCatalog() {}

  static List<PackageRelease> load(Path requestedDirectory) throws IOException {
    Path directory = requestedDirectory.toRealPath(LinkOption.NOFOLLOW_LINKS);
    if (!Files.isDirectory(directory, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(directory)) {
      throw new IOException("Catalog is not a physical directory: " + requestedDirectory);
    }
    List<Path> archives;
    try (Stream<Path> entries = Files.list(directory)) {
      archives = entries
          .filter(path -> path.getFileName().toString().endsWith(".wpk"))
          .sorted(Comparator.comparing(path -> path.getFileName().toString()))
          .toList();
    }
    if (archives.size() > MAX_ARCHIVES) {
      throw new IOException("Catalog exceeds " + MAX_ARCHIVES + " archives");
    }
    List<PackageRelease> releases = new ArrayList<>();
    PackageArchive codec = new PackageArchive();
    for (Path archive : archives) {
      if (!Files.isRegularFile(archive, LinkOption.NOFOLLOW_LINKS)
          || Files.isSymbolicLink(archive)) {
        throw new IOException("Catalog archive is not a physical file: " + archive);
      }
      byte[] bytes = Files.readAllBytes(archive);
      PackageArchive.DecodedPackage decoded = codec.decode(bytes);
      releases.add(new PackageRelease(decoded.manifest(), decoded.identity()));
    }
    return List.copyOf(releases);
  }
}
