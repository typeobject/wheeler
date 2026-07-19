package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.PackageLock;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.stream.Stream;

/** Materialize one exact, relocatable, idempotent vendor tree from a verified lock. */
final class PackageVendor {
  private PackageVendor() {}

  static int vendor(PackageLock lock, Path catalog, Path requestedOutput) throws IOException {
    Map<String, PackageCatalog.Entry> available = index(PackageCatalog.loadEntries(catalog));
    Map<String, byte[]> expected = new TreeMap<>();
    expected.put(PackageLock.FILE_NAME, lock.canonicalText().getBytes(StandardCharsets.UTF_8));
    for (PackageLock.Entry locked : lock.entries()) {
      PackageCatalog.Entry source = available.get(key(locked.name(), locked.version()));
      if (source == null
          || !source.decoded().identity().equals(locked.archiveIdentity())
          || !source.decoded().manifest().identity().equals(locked.manifestIdentity())) {
        throw new PackageFormatException(
            "Catalog does not contain locked package " + locked.name() + " " + locked.version());
      }
      expected.put(
          locked.name() + "-" + locked.version() + "-" + locked.archiveIdentity() + ".wpk",
          source.bytes());
    }

    Path output = requestedOutput.toAbsolutePath().normalize();
    if (Files.exists(output, LinkOption.NOFOLLOW_LINKS)) {
      verifyExisting(output, expected);
      return lock.entries().size();
    }
    Path parent = output.getParent();
    if (parent == null) {
      throw new IOException("Vendor output has no parent: " + output);
    }
    Files.createDirectories(parent);
    Path temporary = Files.createTempDirectory(parent, ".wheeler-vendor-");
    try {
      for (Map.Entry<String, byte[]> file : expected.entrySet()) {
        PackageProject.writeAtomically(temporary.resolve(file.getKey()), file.getValue());
      }
      verifyExisting(temporary, expected);
      try {
        Files.move(temporary, output, StandardCopyOption.ATOMIC_MOVE);
      } catch (java.nio.file.AtomicMoveNotSupportedException exception) {
        Files.move(temporary, output);
      }
    } finally {
      if (Files.exists(temporary, LinkOption.NOFOLLOW_LINKS)) {
        PackageProject.cleanOutput(temporary);
      }
    }
    verifyExisting(output, expected);
    return lock.entries().size();
  }

  private static Map<String, PackageCatalog.Entry> index(List<PackageCatalog.Entry> entries) {
    Map<String, PackageCatalog.Entry> result = new HashMap<>();
    for (PackageCatalog.Entry entry : entries) {
      String key = key(entry.decoded().manifest().name(), entry.decoded().manifest().version());
      if (result.put(key, entry) != null) {
        throw new PackageFormatException("Catalog has duplicate package version " + key);
      }
    }
    return Map.copyOf(result);
  }

  private static void verifyExisting(Path output, Map<String, byte[]> expected) throws IOException {
    if (!Files.isDirectory(output, LinkOption.NOFOLLOW_LINKS) || Files.isSymbolicLink(output)) {
      throw new IOException("Vendor output is not a physical directory: " + output);
    }
    List<Path> files;
    try (Stream<Path> entries = Files.list(output)) {
      files = entries.toList();
    }
    Set<String> names = new HashSet<>();
    for (Path file : files) {
      if (!Files.isRegularFile(file, LinkOption.NOFOLLOW_LINKS)
          || Files.isSymbolicLink(file)) {
        throw new IOException("Vendor tree contains a nonphysical file: " + file);
      }
      names.add(file.getFileName().toString());
    }
    if (!names.equals(expected.keySet())) {
      throw new IOException("Vendor tree contents differ from the locked package set");
    }
    for (Map.Entry<String, byte[]> file : expected.entrySet()) {
      if (!Arrays.equals(Files.readAllBytes(output.resolve(file.getKey())), file.getValue())) {
        throw new IOException("Vendor file differs from locked content: " + file.getKey());
      }
    }
  }

  private static String key(String name, String version) {
    return name + "@" + version;
  }
}
