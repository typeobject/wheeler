package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.packageformat.BootstrapCompilerLimits;
import com.typeobject.wheeler.packageformat.BootstrapCompilerOptions;
import com.typeobject.wheeler.packageformat.BootstrapManifest;
import com.typeobject.wheeler.packageformat.BootstrapManifestParser;
import com.typeobject.wheeler.packageformat.BootstrapToolchain;
import com.typeobject.wheeler.packageformat.BootstrapToolchain.Kind;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageLock;
import com.typeobject.wheeler.packageformat.PackageManifest;
import com.typeobject.wheeler.packageformat.PackageManifest.Target;
import com.typeobject.wheeler.packageformat.PackageManifest.TargetKind;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** End-to-end fixed-point and diverse-bootstrap evidence tests. */
final class BootstrapManifestCommandTest {
  @TempDir
  Path temporary;

  @Test
  void comparesBytesBeforeWritingCanonicalEvidence() throws Exception {
    Fixture fixture = fixture();
    ByteArrayOutputStream output = new ByteArrayOutputStream();

    int status = Wheeler.execute(
        fixture.arguments(), new PrintStream(output), System.err);

    assertEquals(0, status);
    BootstrapManifest manifest = new BootstrapManifestParser().parse(
        Files.readAllBytes(fixture.manifest()));
    assertEquals(manifest.ordinary().stage1(), manifest.ordinary().stage2());
    assertEquals(manifest.ordinary().stage1(), manifest.diverse().output());
    assertEquals(manifest.ordinary().diagnostics(), manifest.diverse().diagnostics());
    assertNotEquals(manifest.ordinary().toolchain(), manifest.diverse().toolchain());
    assertNotEquals(manifest.ordinary().compiler(), manifest.diverse().compiler());
    assertTrue(output.toString(StandardCharsets.UTF_8).contains(manifest.identity()));
    assertEquals(manifest.canonicalText(), Files.readString(fixture.manifest()));
  }

  @Test
  void refusesAFalseFixedPointWithoutPublishing() throws Exception {
    Fixture fixture = fixture();
    Files.write(fixture.stage2(), new BytecodeWriter().write(new WheelerCompiler().compile(
        "classical class Different { entry void main() { } }")));

    IOException failure = assertThrows(IOException.class, () ->
        BootstrapManifestCommand.execute(fixture.arguments(), System.out, System.err));

    assertTrue(failure.getMessage().contains("Stage 1 and stage 2 differ"));
    assertFalse(Files.exists(fixture.manifest()));
  }

  @Test
  void refusesStaleAcceptanceEvidence() throws Exception {
    Fixture fixture = fixture();
    Files.write(fixture.acceptance().resolve("extra.wbc"), Files.readAllBytes(fixture.stage1()));

    IOException failure = assertThrows(IOException.class, () ->
        BootstrapManifestCommand.execute(fixture.arguments(), System.out, System.err));

    assertTrue(failure.getMessage().contains("does not match the closed tree"));
    assertFalse(Files.exists(fixture.manifest()));
  }

  private Fixture fixture() throws Exception {
    Path sourceArchive = temporary.resolve("wheeler.compiler.wpk");
    PackageManifest packageManifest = new PackageManifest(
        "wheeler.compiler",
        "0.1.0",
        "bootstrap-1",
        List.of(new Target(TargetKind.TOOL, "compiler", "MinimalCompiler.w")),
        List.of(),
        List.of());
    Files.write(sourceArchive, new PackageArchive().encode(
        packageManifest,
        Map.of("MinimalCompiler.w", "//! fixture\nclassical class MinimalCompiler {\n"
            .concat("  entry void main() { }\n}\n").getBytes(StandardCharsets.UTF_8))));
    Path lock = write("source.lock", new PackageLock(
        PackageLock.SCHEMA_VERSION, packageManifest.identity(), List.of()).canonicalText());
    Path options = write(
        "options.yaml", new BootstrapCompilerOptions("bootstrap-1", false).canonicalText());
    Path limits = write(
        "limits.yaml",
        new BootstrapCompilerLimits(
            16_777_216, 100_000, 256, 10_000, 10_000,
            1_000_000, 1_000, 268_435_456, 1_024, 10_000_000).canonicalText());
    Path ordinaryToolchain = write(
        "ordinary-toolchain.yaml",
        new BootstrapToolchain(
            Kind.HOST_SOURCE, id("00"), id("11"), id("22"), id("33")).canonicalText());
    Path ordinaryCompiler = write("ordinary-compiler.bin", "ordinary compiler\n");
    Path ordinaryRuntime = write("ordinary-runtime.bin", "ordinary runtime\n");
    Path ordinaryVerifier = write("ordinary-verifier.bin", "ordinary verifier\n");
    Path diverseToolchain = write(
        "diverse-toolchain.yaml",
        new BootstrapToolchain(
            Kind.INDEPENDENT_STAGE0, id("44"), id("55"), id("66"), id("77"))
            .canonicalText());
    Path diverseCompiler = write("diverse-compiler.bin", "diverse compiler\n");
    Path diverseRuntime = write("diverse-runtime.bin", "diverse runtime\n");
    Path diverseVerifier = write("diverse-verifier.bin", "diverse verifier\n");
    Path diagnostics = write("ordinary-diagnostics.txt", "");
    Path diverseDiagnostics = write("diverse-diagnostics.txt", "");
    byte[] artifact = new BytecodeWriter().write(new WheelerCompiler().compile(
        "classical class MinimalCompiler { entry void main() { } }"));
    Path stage1 = Files.write(temporary.resolve("stage1.wbc"), artifact);
    Path stage2 = Files.write(temporary.resolve("stage2.wbc"), artifact);
    Path diverseOutput = Files.write(temporary.resolve("diverse.wbc"), artifact);
    Path acceptance = Files.createDirectory(temporary.resolve("acceptance"));
    Files.write(acceptance.resolve("compiler.wbc"), artifact);
    assertEquals(0, ArtifactSetManifest.execute(
        new String[] {"manifest-artifacts", acceptance.toString()}, System.out, System.err));
    return new Fixture(
        sourceArchive, lock, options, limits,
        ordinaryToolchain, ordinaryCompiler, ordinaryRuntime, ordinaryVerifier,
        stage1, stage2, diagnostics,
        diverseToolchain, diverseCompiler, diverseRuntime, diverseVerifier,
        diverseOutput, diverseDiagnostics, acceptance,
        temporary.resolve(BootstrapManifest.FILE_NAME));
  }

  private Path write(String name, String text) throws IOException {
    return Files.writeString(temporary.resolve(name), text);
  }

  private static String id(String octet) {
    return octet.repeat(32);
  }

  private record Fixture(
      Path sourceArchive,
      Path lock,
      Path options,
      Path limits,
      Path ordinaryToolchain,
      Path ordinaryCompiler,
      Path ordinaryRuntime,
      Path ordinaryVerifier,
      Path stage1,
      Path stage2,
      Path diagnostics,
      Path diverseToolchain,
      Path diverseCompiler,
      Path diverseRuntime,
      Path diverseVerifier,
      Path diverseOutput,
      Path diverseDiagnostics,
      Path acceptance,
      Path manifest) {
    private String[] arguments() {
      List<String> arguments = new ArrayList<>(List.of("bootstrap-manifest"));
      add(arguments, "--source-archive", sourceArchive);
      add(arguments, "--source-lock", lock);
      add(arguments, "--options-manifest", options);
      add(arguments, "--limits-manifest", limits);
      add(arguments, "--ordinary-toolchain", ordinaryToolchain);
      add(arguments, "--ordinary-compiler", ordinaryCompiler);
      add(arguments, "--ordinary-runtime", ordinaryRuntime);
      add(arguments, "--ordinary-verifier", ordinaryVerifier);
      add(arguments, "--stage-1", stage1);
      add(arguments, "--stage-2", stage2);
      add(arguments, "--ordinary-diagnostics", diagnostics);
      add(arguments, "--diverse-toolchain", diverseToolchain);
      add(arguments, "--diverse-compiler", diverseCompiler);
      add(arguments, "--diverse-runtime", diverseRuntime);
      add(arguments, "--diverse-verifier", diverseVerifier);
      add(arguments, "--diverse-output", diverseOutput);
      add(arguments, "--diverse-diagnostics", diverseDiagnostics);
      add(arguments, "--acceptance-artifacts", acceptance);
      add(arguments, "--output", manifest);
      return arguments.toArray(String[]::new);
    }

    private static void add(List<String> arguments, String option, Path path) {
      arguments.add(option);
      arguments.add(path.toString());
    }
  }
}
