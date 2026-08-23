package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifest;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.Set;

/** Builds one exact two-package vendor closure for native external-import tests. */
final class NativeTwoPackageExternalFixture {
  private NativeTwoPackageExternalFixture() {}

  static Fixture create(Path project) throws Exception {
    Files.createDirectories(project.resolve("src"));
    String manifestText = """
        schema: 1
        package:
          name: "demo.native.external.packages"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "laws"
            root: "src/Main.w"
            module: "demo.native.external.packages.tests"
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
        module demo.native.external.packages.tests;
        import demo.a.constants;
        import demo.b.constants;
        classical class NativeExternalPackageTests {
          test void readsLockedConstants() {
            long answerA = ANSWER_A;
            assert(answerA == 41);
            long answerB = ANSWER_B;
            assert(answerB == 42);
          }
        }
        """);
    PackageManifest manifest = new PackageManifestParser().parse(manifestText);
    PackageArchive codec = new PackageArchive();
    LockedArchive first = archive(
        codec,
        "demo.a",
        "demo.a.constants",
        "ANSWER_A",
        41,
        "src/A.w");
    LockedArchive second = archive(
        codec,
        "demo.b",
        "demo.b.constants",
        "ANSWER_B",
        42,
        "src/B.w");
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
            manifest.identity(),
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
      String moduleName,
      String constantName,
      int value,
      String path) {
    String manifestText = ("""
        schema: 1
        package:
          name: "%s"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "library"
            name: "library"
            root: "%s"
            module: "%s"
            sources:
              - "%s"
            test: false
        dependencies: []
        capabilities: []
        """).formatted(packageName, path, moduleName, path);
    PackageManifest manifest = new PackageManifestParser().parse(manifestText);
    String source = ("""
        module %s;
        classical class Constants {
          public const long %s = %d;
        }
        """).formatted(moduleName, constantName, value);
    byte[] bytes = codec.encode(
        manifest, Map.of(path, source.getBytes(StandardCharsets.UTF_8)));
    return new LockedArchive(packageName, manifest, codec.identity(bytes), bytes);
  }

  private static void writeArchive(Path vendor, LockedArchive archive) throws Exception {
    Files.write(
        vendor.resolve(
            archive.packageName() + "-1.0.0-" + archive.identity() + ".wpk"),
        archive.bytes());
  }

  record Fixture(Path root, PackageProject project) {
    Set<String> modules() {
      return Set.of("demo.a.constants", "demo.b.constants");
    }
  }

  private record LockedArchive(
      String packageName, PackageManifest manifest, String identity, byte[] bytes) {}
}
