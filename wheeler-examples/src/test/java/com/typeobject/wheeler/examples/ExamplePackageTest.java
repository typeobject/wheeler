package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifest;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.TreeMap;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;

class ExamplePackageTest {
  @Test
  void checkedInManifestIsCanonicalAndCoversEveryExample() throws Exception {
    Path manifestPath = Path.of("wheeler.package");
    PackageManifest manifest = new PackageManifestParser().parse(Files.readAllBytes(manifestPath));
    assertEquals(Files.readString(manifestPath), manifest.canonicalText());

    Map<String, byte[]> entries = new TreeMap<>();
    for (PackageManifest.Target target : manifest.targets()) {
      for (String source : target.sources()) {
        entries.put(source, Files.readAllBytes(Path.of(source)));
      }
    }
    try (Stream<Path> sourceFiles = Files.walk(Path.of("src/main/wheeler"))) {
      assertEquals(
          sourceFiles.filter(path -> path.getFileName().toString().endsWith(".w")).count(),
          entries.size());
    }

    PackageArchive.DecodedPackage decoded = new PackageArchive().decode(
        new PackageArchive().encode(manifest, entries));
    assertEquals(entries.keySet(), decoded.entries().keySet());
  }
}
