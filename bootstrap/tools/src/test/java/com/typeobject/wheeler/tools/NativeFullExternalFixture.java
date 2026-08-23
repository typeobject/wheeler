package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifest;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

/** Two complete archives filling the eight-source native compiler plan. */
final class NativeFullExternalFixture {
  private NativeFullExternalFixture() {}

  static Fixture create(Path project) throws Exception {
    Files.createDirectories(project.resolve("src"));
    String manifestText = """
        schema: 1
        package:
          name: "demo.native.external.full"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "laws"
            root: "src/Main.w"
            module: "demo.native.external.full.tests"
            sources:
              - "src/Main.w"
            test: true
        dependencies:
          - kind: "normal"
            name: "demo.a"
            version: "=1.0.0"
          - kind: "normal"
            name: "demo.b"
            version: "=1.0.0"
        capabilities: []
        """;
    Files.writeString(project.resolve("wheeler.package.yaml"), manifestText);
    Files.writeString(project.resolve("src/Main.w"), """
        module demo.native.external.full.tests;
        import demo.a.m0;
        import demo.a.m1;
        import demo.a.m2;
        import demo.a.m3;
        import demo.b.m0;
        import demo.b.m1;
        import demo.b.m2;
        classical class NativeFullExternalImportTests {
          test void readsSevenLockedConstants() {
            long valueA0 = VALUE_A0;
            assert(valueA0 == 40);
            long valueA1 = VALUE_A1;
            assert(valueA1 == 41);
            long valueA2 = VALUE_A2;
            assert(valueA2 == 42);
            long valueA3 = VALUE_A3;
            assert(valueA3 == 43);
            long valueB0 = VALUE_B0;
            assert(valueB0 == 44);
            long valueB1 = VALUE_B1;
            assert(valueB1 == 45);
            long valueB2 = VALUE_B2;
            assert(valueB2 == 46);
          }
        }
        """);
    PackageArchive codec = new PackageArchive();
    LockedArchive first = archive(codec, "demo.a", "A", 4, 40);
    LockedArchive second = archive(codec, "demo.b", "B", 3, 44);
    String rootIdentity = new PackageManifestParser().parse(manifestText).identity();
    String lock = ("""
        schema: 3
        root: "%s"
        packages:
          - name: "demo.a"
            version: "1.0.0"
            repository: "%s"
            snapshot: "%s"
            archive: "%s"
            manifest: "%s"
            dependencies: []
          - name: "demo.b"
            version: "1.0.0"
            repository: "%s"
            snapshot: "%s"
            archive: "%s"
            manifest: "%s"
            dependencies: []
        """).formatted(
            rootIdentity,
            "1".repeat(64),
            "2".repeat(64),
            first.identity(),
            first.manifest().identity(),
            "1".repeat(64),
            "2".repeat(64),
            second.identity(),
            second.manifest().identity());
    Files.writeString(project.resolve("wheeler.package.lock.yaml"), lock);
    Path vendor = project.resolve("vendor");
    Files.createDirectory(vendor);
    Files.writeString(vendor.resolve("wheeler.package.lock.yaml"), lock);
    writeArchive(vendor, first);
    writeArchive(vendor, second);
    return new Fixture(project, PackageProject.load(project));
  }

  private static LockedArchive archive(
      PackageArchive codec,
      String packageName,
      String label,
      int count,
      int firstValue) {
    StringBuilder sources = new StringBuilder();
    Map<String, byte[]> entries = new LinkedHashMap<>();
    for (int index = 0; index < count; index++) {
      String path = "src/M" + index + ".w";
      sources.append("      - \"").append(path).append("\"\n");
      String text = """
          module %s.m%d;
          classical class Constants%s%d {
            public const long VALUE_%s%d = %d;
          }
          """.formatted(
              packageName,
              index,
              label,
              index,
              label,
              index,
              firstValue + index);
      entries.put(path, text.getBytes(StandardCharsets.UTF_8));
    }
    String manifestText = """
        schema: 1
        package:
          name: "%s"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "library"
            name: "library"
            root: "src/M0.w"
            module: "%s.m0"
            sources:
        %s    test: false
        dependencies: []
        capabilities: []
        """.formatted(packageName, packageName, sources);
    PackageManifest manifest = new PackageManifestParser().parse(manifestText);
    byte[] bytes = codec.encode(manifest, entries);
    return new LockedArchive(packageName, manifest, codec.identity(bytes), bytes);
  }

  private static void writeArchive(Path vendor, LockedArchive archive) throws Exception {
    Files.write(vendor.resolve(
        archive.name() + "-1.0.0-" + archive.identity() + ".wpk"), archive.bytes());
  }

  private record LockedArchive(
      String name,
      PackageManifest manifest,
      String identity,
      byte[] bytes) {}

  record Fixture(Path root, PackageProject project) {
    Set<String> modules() {
      Set<String> result = new TreeSet<>();
      for (int index = 0; index < 4; index++) {
        result.add("demo.a.m" + index);
      }
      for (int index = 0; index < 3; index++) {
        result.add("demo.b.m" + index);
      }
      return Set.copyOf(result);
    }
  }
}
