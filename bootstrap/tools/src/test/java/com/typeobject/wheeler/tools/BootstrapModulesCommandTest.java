package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifestParser;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifest;
import com.typeobject.wheeler.packageformat.PackageManifest.Target;
import com.typeobject.wheeler.packageformat.PackageManifest.TargetKind;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** End-to-end derivation tests for canonical bootstrap module graphs. */
final class BootstrapModulesCommandTest {
  @TempDir
  Path temporary;

  @Test
  void derivesExactCompilerTargetClosure() throws Exception {
    Path archive = archive(Map.of(
        "src/Driver.w", source(
            "wheeler.compiler", List.of("wheeler.compiler.backend", "wheeler.core")),
        "src/Backend.w", source("wheeler.compiler.backend", List.of("wheeler.core")),
        "src/Library.w", source("wheeler.compiler.library", List.of("wheeler.core"))));
    Path output = temporary.resolve(BootstrapModuleManifest.FILE_NAME);
    ByteArrayOutputStream message = new ByteArrayOutputStream();

    int status = Wheeler.execute(
        new String[] {
            "bootstrap-modules", "--source-archive", archive.toString(),
            "--output", output.toString()
        },
        new PrintStream(message),
        System.err);

    assertEquals(0, status);
    BootstrapModuleManifest manifest = new BootstrapModuleManifestParser().parse(
        Files.readAllBytes(output));
    assertEquals("wheeler.compiler", manifest.root());
    assertEquals(List.of("wheeler.core"), manifest.externals());
    assertEquals(2, manifest.modules().size());
    assertFalse(manifest.modules().stream()
        .anyMatch(module -> module.name().equals("wheeler.compiler.library")));
    assertTrue(message.toString(StandardCharsets.UTF_8).contains(manifest.identity()));
  }

  @Test
  void rejectsCyclicCompilerSourcesWithoutPublishing() throws Exception {
    Path archive = archive(Map.of(
        "src/Driver.w", source("wheeler.compiler", List.of("wheeler.compiler.backend")),
        "src/Backend.w", source("wheeler.compiler.backend", List.of("wheeler.compiler")),
        "src/Library.w", source("wheeler.compiler.library", List.of())));
    Path output = temporary.resolve(BootstrapModuleManifest.FILE_NAME);

    assertThrows(IOException.class, () -> BootstrapModulesCommand.execute(
        new String[] {
            "bootstrap-modules", "--source-archive", archive.toString(),
            "--output", output.toString()
        },
        System.out,
        System.err));
    assertFalse(Files.exists(output));
  }

  private Path archive(Map<String, byte[]> entries) throws IOException {
    PackageManifest manifest = new PackageManifest(
        "wheeler.compiler",
        "0.1.0",
        "bootstrap-1",
        List.of(
            new Target(
                TargetKind.TOOL,
                "compiler",
                "src/Driver.w",
                "wheeler.compiler",
                List.of("src/Driver.w", "src/Backend.w")),
            new Target(
                TargetKind.LIBRARY,
                "library",
                "src/Library.w",
                "wheeler.compiler.library",
                List.of("src/Library.w"))),
        List.of(),
        List.of());
    return Files.write(
        temporary.resolve("wheeler.compiler.wpk"), new PackageArchive().encode(manifest, entries));
  }

  private static byte[] source(String module, List<String> imports) {
    StringBuilder source = new StringBuilder("//! fixture module.\nmodule ")
        .append(module).append(";\n");
    for (String imported : imports) {
      source.append("import ").append(imported).append(";\n");
    }
    return source.append("\nclassical class Fixture { }\n")
        .toString().getBytes(StandardCharsets.UTF_8);
  }
}
