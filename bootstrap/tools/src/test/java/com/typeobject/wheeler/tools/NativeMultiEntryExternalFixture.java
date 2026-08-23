package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.Set;

/** Physical four-entry dependency archive for the bounded native package profile. */
final class NativeMultiEntryExternalFixture {
  private NativeMultiEntryExternalFixture() {}

  static Fixture create(Path project) throws Exception {
    Files.createDirectories(project.resolve("src"));
    String manifestText = """
        schema: 1
        package:
          name: "demo.native.external.four"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "laws"
            root: "src/Main.w"
            module: "demo.native.external.four.tests"
            sources:
              - "src/Main.w"
            test: true
        dependencies:
          - kind: "normal"
            name: "demo.dep"
            version: "=1.0.0"
        capabilities: []
        """;
    Files.writeString(project.resolve("wheeler.package.yaml"), manifestText);
    Files.writeString(project.resolve("src/Main.w"), """
        module demo.native.external.four.tests;
        import demo.dep.a;
        import demo.dep.b;
        import demo.dep.c;
        import demo.dep.d;
        classical class NativeFourEntryImportTests {
          test void readsFourLockedConstants() {
            long answerA = ANSWER_A;
            assert(answerA == 40);
            long answerB = ANSWER_B;
            assert(answerB == 41);
            long answerC = ANSWER_C;
            assert(answerC == 42);
            long answerD = ANSWER_D;
            assert(answerD == 43);
          }
        }
        """);
    String dependencyManifestText = """
        schema: 1
        package:
          name: "demo.dep"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "library"
            name: "library"
            root: "src/A.w"
            module: "demo.dep.a"
            sources:
              - "src/A.w"
              - "src/B.w"
              - "src/C.w"
              - "src/D.w"
            test: false
        dependencies: []
        capabilities: []
        """;
    var dependencyManifest = new PackageManifestParser().parse(dependencyManifestText);
    Map<String, byte[]> entries = Map.of(
        "src/A.w", source("demo.dep.a", "ConstantsA", "ANSWER_A", 40),
        "src/B.w", source("demo.dep.b", "ConstantsB", "ANSWER_B", 41),
        "src/C.w", source("demo.dep.c", "ConstantsC", "ANSWER_C", 42),
        "src/D.w", source("demo.dep.d", "ConstantsD", "ANSWER_D", 43));
    PackageArchive codec = new PackageArchive();
    byte[] archive = codec.encode(dependencyManifest, entries);
    String archiveIdentity = codec.identity(archive);
    String rootIdentity = new PackageManifestParser().parse(manifestText).identity();
    String lock = ("""
        schema: 3
        root: "%s"
        packages:
          - name: "demo.dep"
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
            archiveIdentity,
            dependencyManifest.identity());
    Files.writeString(project.resolve("wheeler.package.lock.yaml"), lock);
    Path vendor = project.resolve("vendor");
    Files.createDirectory(vendor);
    Files.writeString(vendor.resolve("wheeler.package.lock.yaml"), lock);
    Files.write(vendor.resolve(
        "demo.dep-1.0.0-" + archiveIdentity + ".wpk"), archive);
    return new Fixture(project, PackageProject.load(project));
  }

  private static byte[] source(String module, String owner, String name, int value) {
    return ("""
        module %s;
        classical class %s {
          public const long %s = %d;
        }
        """).formatted(module, owner, name, value).getBytes(StandardCharsets.UTF_8);
  }

  record Fixture(Path root, PackageProject project) {
    Set<String> modules() {
      return Set.of("demo.dep.a", "demo.dep.b", "demo.dep.c", "demo.dep.d");
    }
  }
}
