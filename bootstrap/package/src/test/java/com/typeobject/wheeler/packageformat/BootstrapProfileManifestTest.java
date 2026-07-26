package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.nio.charset.StandardCharsets;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Executable schema tests for exact bootstrap features and module closure. */
final class BootstrapProfileManifestTest {
  @Test
  void featureManifestRoundTripsAndSortsConstruction() {
    BootstrapFeatureManifest manifest = new BootstrapFeatureManifest(
        "bootstrap-1",
        List.of(
            new BootstrapFeatureManifest.Feature("typed-frames", 1),
            new BootstrapFeatureManifest.Feature("bounded-loops", 2)));

    assertEquals("bounded-loops", manifest.features().getFirst().name());
    assertEquals(manifest, new BootstrapFeatureManifestParser().parse(manifest.canonicalBytes()));
    assertEquals(64, manifest.identity().length());
  }

  @Test
  void moduleManifestRoundTripsClosedGraph() {
    BootstrapModuleManifest manifest = manifest();

    assertEquals("wheeler.compiler", manifest.modules().getFirst().name());
    assertEquals(manifest, new BootstrapModuleManifestParser().parse(manifest.canonicalBytes()));
    assertEquals(64, manifest.identity().length());
  }

  @Test
  void featureDecoderRejectsUnknownAndNoncanonicalInput() {
    BootstrapFeatureManifest manifest = new BootstrapFeatureManifest(
        "bootstrap-1",
        List.of(new BootstrapFeatureManifest.Feature("typed-frames", 1)));
    byte[] unknown = manifest.canonicalText().replace(
        "profile: \"bootstrap-1\"\n", "profile: \"bootstrap-1\"\nsurprise: true\n")
        .getBytes(StandardCharsets.UTF_8);
    byte[] comment = ("# hidden decoration\n" + manifest.canonicalText())
        .getBytes(StandardCharsets.UTF_8);

    assertThrows(PackageFormatException.class,
        () -> new BootstrapFeatureManifestParser().parse(unknown));
    assertThrows(PackageFormatException.class,
        () -> new BootstrapFeatureManifestParser().parse(comment));
    assertThrows(PackageFormatException.class,
        () -> new BootstrapFeatureManifest("bootstrap-1", List.of()));
  }

  @Test
  void moduleGraphRejectsDanglingCyclesAndDeadSources() {
    BootstrapModuleManifest.Module root = module("root", "Root.w", List.of("missing"));
    assertThrows(PackageFormatException.class, () ->
        new BootstrapModuleManifest("bootstrap-1", "root", List.of(), List.of(root)));

    BootstrapModuleManifest.Module cycleA = module("a", "A.w", List.of("b"));
    BootstrapModuleManifest.Module cycleB = module("b", "B.w", List.of("a"));
    assertThrows(PackageFormatException.class, () ->
        new BootstrapModuleManifest(
            "bootstrap-1", "a", List.of(), List.of(cycleA, cycleB)));

    BootstrapModuleManifest.Module live = module("live", "Live.w", List.of());
    BootstrapModuleManifest.Module dead = module("dead", "Dead.w", List.of());
    assertThrows(PackageFormatException.class, () ->
        new BootstrapModuleManifest(
            "bootstrap-1", "live", List.of(), List.of(live, dead)));
  }

  @Test
  void moduleDecoderRejectsChangedOrderAndUnknownFields() {
    BootstrapModuleManifest manifest = manifest();
    String noncanonical = manifest.canonicalText().replace(
        "  - name: \"wheeler.compiler.backend\"",
        "  - name: \"wheeler.compiler.backend\"\n    surprise: false");
    assertThrows(PackageFormatException.class, () ->
        new BootstrapModuleManifestParser().parse(noncanonical.getBytes(StandardCharsets.UTF_8)));

    assertThrows(PackageFormatException.class, () ->
        new BootstrapModuleManifest(
            "bootstrap-1",
            "wheeler.compiler",
            List.of("wheeler.core"),
            List.of(
                module("wheeler.compiler", "Same.w", List.of("wheeler.compiler.backend")),
                module("wheeler.compiler.backend", "Same.w", List.of("wheeler.core")))));
  }

  private static BootstrapModuleManifest manifest() {
    return new BootstrapModuleManifest(
        "bootstrap-1",
        "wheeler.compiler",
        List.of("wheeler.core"),
        List.of(
            module(
                "wheeler.compiler",
                "src/main/wheeler/MinimalCompiler.w",
                List.of("wheeler.compiler.backend", "wheeler.core")),
            module(
                "wheeler.compiler.backend",
                "src/main/wheeler/compiler/backend/Codegen.w",
                List.of("wheeler.core"))));
  }

  private static BootstrapModuleManifest.Module module(
      String name, String source, List<String> imports) {
    return new BootstrapModuleManifest.Module(name, source, "00".repeat(32), imports);
  }
}
