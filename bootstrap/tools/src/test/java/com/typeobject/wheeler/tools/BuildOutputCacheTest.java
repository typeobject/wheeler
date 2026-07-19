package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Complete-input build-output cache and quarantine tests. */
final class BuildOutputCacheTest {
  @TempDir
  Path temporary;

  @Test
  void reusesOnlyReverifiedCanonicalOutputAndQuarantinesDivergence() throws Exception {
    Path root = temporary.toRealPath();
    Path artifacts = root.resolve("cache/artifacts");
    Path state = root.resolve("state");
    BuildOutputCache cache = new BuildOutputCache(artifacts, state);
    String input = "a".repeat(64);
    byte[] expected = artifact("Expected");
    byte[] observed = artifact("Observed");

    cache.store(input, expected);
    assertArrayEquals(expected, cache.load(input));
    cache.store(input, expected);

    PackageFormatException divergence = assertThrows(
        PackageFormatException.class, () -> cache.store(input, observed));
    assertTrue(divergence.getMessage().contains("Build output diverged"));
    String observedPrev = PackageProject.sha256(observed);
    Path quarantine = state.resolve("quarantine/build-outputs")
        .resolve(input).resolve(observedPrev);
    assertArrayEquals(observed, Files.readAllBytes(quarantine.resolve("observed.wbc")));
    assertTrue(Files.readString(quarantine.resolve("quarantine.yaml"))
        .contains("expected-prev"));
    BuildOutputCache.GcResult gc = cache.gc();
    assertTrue(0 < gc.removed());
    assertArrayEquals(expected, cache.load(input));
  }

  @Test
  void cacheDirectoryLinksFailClosed() throws Exception {
    Path root = temporary.toRealPath();
    Path buildCache = root.resolve("cache/artifacts/build-outputs");
    Path external = Files.createDirectory(root.resolve("external"));
    Files.createDirectories(buildCache);
    Files.createSymbolicLink(buildCache.resolve("records"), external);
    BuildOutputCache cache = new BuildOutputCache(
        root.resolve("cache/artifacts"), root.resolve("state"));

    assertThrows(java.io.IOException.class, () -> cache.load("c".repeat(64)));
  }

  @Test
  void corruptRegularObjectsBecomeMissesAndNeverAuthority() throws Exception {
    Path root = temporary.toRealPath();
    Path artifacts = root.resolve("cache/artifacts");
    BuildOutputCache cache = new BuildOutputCache(artifacts, root.resolve("state"));
    String input = "b".repeat(64);
    byte[] artifact = artifact("Cached");
    cache.store(input, artifact);
    Path object = artifacts.resolve("build-outputs/objects")
        .resolve(PackageProject.sha256(artifact) + ".wbc");
    Files.write(object, new byte[] {0});

    assertNull(cache.load(input));
    assertTrue(Files.notExists(object));
    assertThrows(RuntimeException.class, () -> cache.store(input, new byte[] {0}));
  }

  private static byte[] artifact(String name) {
    return new BytecodeWriter().write(new WheelerCompiler().compile(
        "classical class " + name + " { entry void main() { } }"));
  }
}
