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

class PackageFormatTest {
  private static final String MANIFEST = """
      package "wheeler.compiler" version "0.1.0" profile "bootstrap-1";
      capability "build.write" path "out/**";
      target tool "compiler" root "src/compiler.w";
      dependency build "wheeler.bytecode" version "^0.1.0";
      capability "build.read" path "src/**";
      """;

  @Test
  void manifestCanonicalizationIgnoresDeclarationOrder() {
    PackageManifestParser parser = new PackageManifestParser();
    PackageManifest first = parser.parse(MANIFEST);
    PackageManifest second = parser.parse("""
        package "wheeler.compiler" version "0.1.0" profile "bootstrap-1";
        capability "build.read" path "src/**";
        dependency build "wheeler.bytecode" version "^0.1.0";
        target tool "compiler" root "src/compiler.w";
        capability "build.write" path "out/**";
        """);

    assertEquals(first, second);
    assertEquals(first.identity(), second.identity());
    assertEquals(first, parser.parse(first.canonicalText()));
    assertTrue(first.canonicalText().indexOf("build.read")
        < first.canonicalText().indexOf("build.write"));
  }

  @Test
  void malformedManifestFailsClosedWithLocation() {
    PackageManifestParser parser = new PackageManifestParser();
    PackageFormatException unknown = assertThrows(
        PackageFormatException.class,
        () -> parser.parse(MANIFEST.replace("target tool", "plugin tool")));
    PackageFormatException duplicate = assertThrows(
        PackageFormatException.class,
        () -> parser.parse(MANIFEST +
            "dependency normal \"wheeler.bytecode\" version \"=0.1.0\";\n"));
    byte[] malformedUtf8 = {(byte) 0xc3, (byte) 0x28};

    assertTrue(unknown.getMessage().contains("line 3"));
    assertTrue(duplicate.getMessage().contains("Duplicate dependency"));
    assertThrows(PackageFormatException.class, () -> parser.parse(malformedUtf8));
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
  void moduleTargetCanonicalizesAndRequiresItsExactSourceSet() {
    PackageManifestParser parser = new PackageManifestParser();
    PackageManifest manifest = parser.parse("""
        package "wheeler.modules" version "0.1.0" profile "bootstrap-1";
        target tool "compiler" root "src/Main.w" module "compiler.main"
            source "src/Main.w" source "src/Lexer.w";
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
