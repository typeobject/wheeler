package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageLock;
import com.typeobject.wheeler.packageformat.PackageManifest;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** End-to-end checks for package-scoped source visibility across an exact lock graph. */
class PackageVisibilityTest {
  @TempDir
  Path temporary;

  @Test
  void rootCannotImportADepsPrivateTransitiveDependency() throws Exception {
    Fixture fixture = createFixture();

    CompilerException failure = assertThrows(
        CompilerException.class,
        () -> PackageProject.load(fixture.root()).check());
    assertTrue(
        failure.getMessage().contains(
            "imports an undeclared package dependency module: demo.leaf.api"),
        failure.getMessage());

    Files.writeString(fixture.root().resolve("src/Main.w"), """
        module demo.root.main;
        import demo.middle.api;
        classical class Main {
          state long value = 0;
          entry void main() { value = middle(value); assert(value == 2); }
        }
        """);
    assertDoesNotThrow(() -> PackageProject.load(fixture.root()).check());
  }

  private Fixture createFixture() throws Exception {
    PackageManifest leaf = manifest("""
        package "demo.leaf" version "1.0.0" profile "bootstrap-1";
        target library "main" root "src/Leaf.w" module "demo.leaf.api"
            source "src/Leaf.w";
        """);
    PackageManifest middle = manifest("""
        package "demo.middle" version "1.0.0" profile "bootstrap-1";
        target library "main" root "src/Middle.w" module "demo.middle.api"
            source "src/Middle.w";
        dependency normal "demo.leaf" version "=1.0.0";
        """);
    byte[] leafArchive = archive(leaf, "src/Leaf.w", """
        module demo.leaf.api;
        classical class Leaf {
          public long leaf(long value) { return value + 1; }
        }
        """);
    byte[] middleArchive = archive(middle, "src/Middle.w", """
        module demo.middle.api;
        import demo.leaf.api;
        classical class Middle {
          public long middle(long value) { return leaf(value) + 1; }
        }
        """);

    Path root = temporary.resolve("root");
    Path vendor = root.resolve("vendor");
    Files.createDirectories(root.resolve("src"));
    Files.createDirectories(vendor);
    PackageManifest rootManifest = manifest("""
        package "demo.root" version "1.0.0" profile "bootstrap-1";
        target deployable "main" root "src/Main.w" module "demo.root.main"
            source "src/Main.w";
        dependency normal "demo.middle" version "=1.0.0";
        """);
    Files.writeString(root.resolve("wheeler.package"), rootManifest.canonicalText());
    Files.writeString(root.resolve("src/Main.w"), """
        module demo.root.main;
        import demo.leaf.api;
        classical class Main {
          state long value = 0;
          entry void main() { value = leaf(value); assert(value == 1); }
        }
        """);

    PackageArchive codec = new PackageArchive();
    String leafIdentity = codec.decode(leafArchive).identity();
    String middleIdentity = codec.decode(middleArchive).identity();
    writeArchive(vendor, leaf, leafIdentity, leafArchive);
    writeArchive(vendor, middle, middleIdentity, middleArchive);
    PackageLock lock = new PackageLock(PackageLock.SCHEMA_VERSION, rootManifest.identity(), List.of(
        new PackageLock.Entry(
            leaf.name(), leaf.version(), leafIdentity, leaf.identity(), List.of()),
        new PackageLock.Entry(
            middle.name(), middle.version(), middleIdentity, middle.identity(),
            List.of(leaf.name()))));
    Files.writeString(vendor.resolve("wheeler.lock"), lock.canonicalText());
    return new Fixture(root);
  }

  private static PackageManifest manifest(String text) {
    return new PackageManifestParser().parse(text.getBytes(StandardCharsets.UTF_8));
  }

  private static byte[] archive(PackageManifest manifest, String path, String source) {
    return new PackageArchive().encode(
        manifest, Map.of(path, source.getBytes(StandardCharsets.UTF_8)));
  }

  private static void writeArchive(
      Path vendor,
      PackageManifest manifest,
      String identity,
      byte[] bytes) throws Exception {
    Files.write(
        vendor.resolve(manifest.name() + "-" + manifest.version() + "-" + identity + ".wpk"),
        bytes);
  }

  private record Fixture(Path root) {}
}
