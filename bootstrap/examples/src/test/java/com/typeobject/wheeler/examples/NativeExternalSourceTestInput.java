package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

/** Builds one complete locked external-source transport for the native test runner. */
final class NativeExternalSourceTestInput {
  private NativeExternalSourceTestInput() {}

  static Fixture create(String localManifest) {
    String manifestText = localManifest.replace(
        "dependencies: []",
        """
        dependencies:
          - kind: "normal"
            name: "demo.dep"
            version: "=1.0.0"
        """);
    var manifest = new PackageManifestParser().parse(manifestText);
    String dependencyManifestText = """
        schema: 1
        package:
          name: "demo.dep"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "library"
            name: "library"
            root: "src/Constants.w"
            module: "demo.dep.constants"
            sources:
              - "src/Constants.w"
            test: false
        dependencies: []
        capabilities: []
        """;
    var dependencyManifest = new PackageManifestParser().parse(dependencyManifestText);
    String dependencySource = """
        module demo.dep.constants;
        classical class Constants {
          public const long ANSWER = 42;
        }
        """;
    PackageArchive codec = new PackageArchive();
    byte[] archive = codec.encode(
        dependencyManifest,
        Map.of("src/Constants.w", dependencySource.getBytes(StandardCharsets.UTF_8)));
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
            manifest.identity(),
            "1".repeat(64),
            "2".repeat(64),
            codec.identity(archive),
            dependencyManifest.identity());
    String rootSource = """
        module pkg.test;
        import demo.dep.constants;
        classical class ExternalImportTests {
          test void readsLockedConstant() {
            long answer = ANSWER;
            assert(answer == 42);
          }
        }
        """;
    List<NativeTestSourcePlan.Source> sources = List.of(
        new NativeTestSourcePlan.Source(
            "dependencies/demo.dep/src/Constants.w", dependencySource),
        new NativeTestSourcePlan.Source("src/Test.w", rootSource));
    return new Fixture(
        manifest.canonicalText(),
        sources,
        lock.getBytes(StandardCharsets.UTF_8),
        "demo.dep",
        archive);
  }

  record Fixture(
      String manifest,
      List<NativeTestSourcePlan.Source> sources,
      byte[] lock,
      String packageName,
      byte[] archive) {
    Fixture {
      sources = List.copyOf(sources);
      lock = lock.clone();
      archive = archive.clone();
    }

    @Override
    public byte[] lock() {
      return lock.clone();
    }

    @Override
    public byte[] archive() {
      return archive.clone();
    }

    byte[] transport() {
      byte[] plan = NativeTestSourcePlan.write(sources);
      ByteArrayOutputStream input = new ByteArrayOutputStream();
      input.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
          .putShort((short) 0).putShort((short) 1).array());
      writeShortText(input, "pkg");
      writeShortText(input, "1.0.0");
      writeShortText(input, "test");
      writeBytes(input, manifest.getBytes(StandardCharsets.UTF_8));
      writeBytes(input, lock);
      input.write(1);
      writeShortText(input, packageName);
      writeBytes(input, archive);
      writeBytes(input, plan);
      input.write(0);
      input.write(255);
      return input.toByteArray();
    }
  }

  private static void writeShortText(ByteArrayOutputStream output, String text) {
    byte[] bytes = text.getBytes(StandardCharsets.UTF_8);
    output.write(bytes.length);
    output.writeBytes(bytes);
  }

  private static void writeBytes(ByteArrayOutputStream output, byte[] bytes) {
    output.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(bytes.length).array());
    output.writeBytes(bytes);
  }
}
