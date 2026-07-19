package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Conformance tests for canonical YAML manifests, source sets, and package archives. */
class PackageFormatTest {
  private static final String MANIFEST = """
      schema: 1
      package:
        name: "wheeler.compiler"
        version: "0.1.0"
        profile: "bootstrap-1"
      targets:
        - kind: "tool"
          name: "compiler"
          root: "src/compiler.w"
          test: false
      dependencies:
        - kind: "build"
          name: "wheeler.bytecode"
          version: "^0.1.0"
      capabilities:
        - name: "build.write"
          path: "build/**"
        - name: "build.read"
          path: "src/**"
      """;

  @Test
  void manifestCanonicalizationIgnoresMappingAndDeclarationOrder() {
    PackageManifestParser parser = new PackageManifestParser();
    PackageManifest first = parser.parse(MANIFEST);
    PackageManifest second = parser.parse("""
        capabilities:
          - path: "src/**"
            name: "build.read"
          - path: "build/**"
            name: "build.write"
        dependencies:
          - version: "^0.1.0"
            name: "wheeler.bytecode"
            kind: "build"
        targets:
          - test: false
            root: "src/compiler.w"
            name: "compiler"
            kind: "tool"
        package:
          profile: "bootstrap-1"
          version: "0.1.0"
          name: "wheeler.compiler"
        schema: 1
        """);

    assertEquals(first, second);
    assertArrayEquals(
        new PackageManifest.TargetKind[] {
            PackageManifest.TargetKind.DEPLOYABLE,
            PackageManifest.TargetKind.LIBRARY,
            PackageManifest.TargetKind.TOOL
        },
        PackageManifest.TargetKind.values());
    assertEquals(first.identity(), second.identity());
    assertEquals(first, parser.parse(first.canonicalText()));
    assertTrue(first.canonicalText().indexOf("build.read")
        < first.canonicalText().indexOf("build.write"));
    PackageManifest testTarget = parser.parse(MANIFEST.replace("test: false", "test: true"));
    assertTrue(testTarget.targets().getFirst().test());
    assertTrue(parser.parse(testTarget.canonicalText().replace(
        "kind: \"tool\"", "kind: \"deployable\"")).targets().getFirst().test());
    assertEquals(testTarget, parser.parse(testTarget.canonicalText()));
  }

  @Test
  void malformedManifestFailsClosed() {
    PackageManifestParser parser = new PackageManifestParser();
    PackageFormatException unknown = assertThrows(
        PackageFormatException.class,
        () -> parser.parse(MANIFEST.replace("kind: \"tool\"", "plugin: \"tool\"")));
    PackageFormatException duplicate = assertThrows(
        PackageFormatException.class,
        () -> parser.parse(MANIFEST.replace(
            "    version: \"^0.1.0\"",
            "    version: \"^0.1.0\"\n"
                + "  - kind: \"normal\"\n"
                + "    name: \"wheeler.bytecode\"\n"
                + "    version: \"=0.1.0\"")));
    byte[] malformedUtf8 = {(byte) 0xc3, (byte) 0x28};

    assertTrue(unknown.getMessage().contains("plugin"));
    assertTrue(duplicate.getMessage().contains("Duplicate dependency"));
    assertThrows(PackageFormatException.class, () -> parser.parse(malformedUtf8));
    PackageFormatException targetName = assertThrows(
        PackageFormatException.class,
        () -> parser.parse(MANIFEST.replace("name: \"compiler\"", "name: \"../compiler\"")));
    assertTrue(targetName.getMessage().contains("Invalid target name"));
    assertThrows(
        PackageFormatException.class,
        () -> parser.parse(MANIFEST
            .replace("kind: \"tool\"", "kind: \"library\"")
            .replace("test: false", "test: true")));
    assertThrows(
        PackageFormatException.class,
        () -> parser.parse(MANIFEST.replace("kind: \"tool\"", "kind: \"example\"")));
    assertThrows(
        PackageFormatException.class,
        () -> parser.parse(MANIFEST.replace(
            "test: false", "test: false\n    test: false")));
  }

  @Test
  void yamlProfileRejectsTheFeaturesGeneralYamlMadeFamous() {
    PackageManifestParser parser = new PackageManifestParser();
    PackageManifest canonical = parser.parse(MANIFEST);

    assertEquals(canonical, parser.parse("# Review comments do not alter identity.\n" + MANIFEST));
    assertThrows(PackageFormatException.class,
        () -> parser.parse(MANIFEST.replace("schema: 1", "schema:\t1")));
    assertThrows(PackageFormatException.class,
        () -> parser.parse(MANIFEST.replace("name: \"wheeler.compiler\"", "name: compiler")));
    assertThrows(PackageFormatException.class,
        () -> parser.parse(MANIFEST.replace("name: \"wheeler.compiler\"", "name: *compiler")));
    assertThrows(PackageFormatException.class,
        () -> parser.parse(MANIFEST.replace("schema: 1", "schema: 01")));
    assertThrows(PackageFormatException.class,
        () -> parser.parse(MANIFEST.replace("capabilities:", "features: []\ncapabilities:")));
    assertThrows(PackageFormatException.class,
        () -> parser.parse(MANIFEST.replace("\n", "\r\n")));
  }

  @Test
  void archiveIsCanonicalContentAddressedAndIntegrityChecked() {
    PackageManifest manifest = new PackageManifestParser().parse(MANIFEST);
    Map<String, byte[]> ascending = new LinkedHashMap<>();
    ascending.put("README.md", "compiler".getBytes(StandardCharsets.UTF_8));
    ascending.put("src/compiler.w", "classical class Compiler {}".getBytes(StandardCharsets.UTF_8));
    Map<String, byte[]> descending = new LinkedHashMap<>();
    descending.put("src/compiler.w", ascending.get("src/compiler.w"));
    descending.put("README.md", ascending.get("README.md"));
    PackageArchive codec = new PackageArchive();

    byte[] first = codec.encode(manifest, ascending);
    byte[] second = codec.encode(manifest, descending);
    PackageArchive.DecodedPackage decoded = codec.decode(first);

    assertArrayEquals(first, second);
    assertEquals(manifest, decoded.manifest());
    assertEquals(codec.identity(first), decoded.identity());
    assertArrayEquals(ascending.get("src/compiler.w"), decoded.entries().get("src/compiler.w"));
    assertNotEquals(manifest.identity(), decoded.identity());

    byte[] corrupted = first.clone();
    corrupted[corrupted.length / 2] ^= 1;
    assertThrows(PackageFormatException.class, () -> codec.decode(corrupted));
    assertThrows(
        PackageFormatException.class,
        () -> codec.encode(manifest, Map.of("../compiler.w", new byte[0])));
  }

  @Test
  void moduleTargetCanonicalizesAndRequiresItsSourceSelectors() {
    PackageManifestParser parser = new PackageManifestParser();
    PackageManifest manifest = parser.parse("""
        schema: 1
        package:
          name: "wheeler.modules"
          version: "0.1.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "compiler"
            root: "src/Main.w"
            module: "compiler.main"
            sources:
              - "src/Lexer.w"
              - "src/Main.w"
            test: false
        dependencies: []
        capabilities: []
        """);

    assertEquals(List.of("src/Lexer.w", "src/Main.w"),
        manifest.targets().getFirst().sources());
    assertEquals(manifest, parser.parse(manifest.canonicalText()));
    assertThrows(
        PackageFormatException.class,
        () -> new PackageArchive().encode(
            manifest, Map.of("src/Main.w", new byte[0])));
  }

  @Test
  void archiveRequiresEveryDeclaredTargetRoot() {
    PackageManifest manifest = new PackageManifestParser().parse(MANIFEST);

    PackageFormatException exception = assertThrows(
        PackageFormatException.class,
        () -> new PackageArchive().encode(manifest, Map.of("README.md", new byte[0])));

    assertTrue(exception.getMessage().contains("src/compiler.w"));
  }
}
