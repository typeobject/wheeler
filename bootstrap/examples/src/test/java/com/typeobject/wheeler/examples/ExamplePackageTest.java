package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifest;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;

/** Conformance tests for the checked-in example package manifest and target graph. */
class ExamplePackageTest {
  @Test
  void checkedInManifestIsCanonicalAndCoversEveryExample() throws Exception {
    Path manifestPath = Path.of("wheeler.package.yaml");
    PackageManifest manifest = new PackageManifestParser().parse(Files.readAllBytes(manifestPath));
    assertEquals(Files.readString(manifestPath), manifest.canonicalText());

    Map<String, byte[]> entries = new TreeMap<>();
    try (Stream<Path> sourceFiles = Files.walk(Path.of("src/main/wheeler"))) {
      for (Path source : sourceFiles
          .filter(path -> path.getFileName().toString().endsWith(".w"))
          .toList()) {
        entries.put(source.toString(), Files.readAllBytes(source));
      }
    }
    assertEquals(
        List.of(),
        entries.keySet().stream()
            .filter(path -> manifest.targets().stream()
                .flatMap(target -> target.sources().stream())
                .noneMatch(selector -> path.equals(selector)
                    || path.startsWith(selector + "/")))
            .toList());

    PackageArchive.DecodedPackage decoded = new PackageArchive().decode(
        new PackageArchive().encode(manifest, entries));
    assertEquals(entries.keySet(), decoded.entries().keySet());
  }
}
