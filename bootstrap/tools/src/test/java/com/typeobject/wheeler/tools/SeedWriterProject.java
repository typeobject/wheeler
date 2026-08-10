package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageManifest;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.TreeSet;

/** Builds the Wheeler-native compiler fixture used by command integration tests. */
final class SeedWriterProject {
  private static final Path COMPILER_PACKAGE = Path.of("wheeler-compiler");
  private static final Path COMPILER_ROOT = COMPILER_PACKAGE.resolve("src/main/wheeler");
  private static final Path CORE_ROOT = Path.of("wheeler-core/src/main/wheeler");
  private static final List<String> CORE_SOURCES = List.of(
      "crypto/Sha256.w",
      "encoding/Binary.w",
      "encoding/FixedBinary.w");
  private static final String SOURCE_PREFIX = "src/main/wheeler/";

  private SeedWriterProject() {}

  /** Copies the canonical bounded compiler closure and writes its standalone test manifest. */
  static Path create(Path temporary) throws IOException {
    Path project = temporary.resolve("seed-writer");
    List<String> compilerSources = compilerSources();
    for (String source : compilerSources) {
      Path destination = project.resolve("src").resolve(source);
      Files.createDirectories(destination.getParent());
      Files.copy(COMPILER_ROOT.resolve(source), destination);
    }
    for (String source : CORE_SOURCES) {
      Path destination = project.resolve("src/core").resolve(source);
      Files.createDirectories(destination.getParent());
      Files.copy(CORE_ROOT.resolve(source), destination);
    }
    Files.writeString(project.resolve("wheeler.package.yaml"), manifest(compilerSources));
    return project;
  }

  private static List<String> compilerSources() throws IOException {
    PackageManifest manifest = new PackageManifestParser().parse(
        Files.readString(COMPILER_PACKAGE.resolve("wheeler.package.yaml")));
    PackageManifest.Target target = manifest.targets().stream()
        .filter(candidate -> candidate.name().equals("compiler"))
        .findFirst()
        .orElseThrow(() -> new IOException("Compiler package has no compiler target"));
    TreeSet<String> paths = new TreeSet<>();
    for (String selector : target.sources()) {
      if (!selector.startsWith(SOURCE_PREFIX)) {
        throw new IOException("Compiler source escapes its canonical root: " + selector);
      }
      String logicalPath = selector.substring(SOURCE_PREFIX.length());
      Path selected = COMPILER_ROOT.resolve(logicalPath);
      if (Files.isRegularFile(selected)) {
        paths.add(logicalPath);
      } else {
        try (var files = Files.walk(selected)) {
          files.filter(Files::isRegularFile)
              .filter(path -> path.getFileName().toString().endsWith(".w"))
              .map(COMPILER_ROOT::relativize)
              .map(Path::toString)
              .forEach(paths::add);
        }
      }
    }
    return List.copyOf(paths);
  }

  private static String manifest(List<String> compilerSources) {
    StringBuilder manifest = new StringBuilder("""
        schema: 1
        package:
          name: "demo.seedwriter"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "deployable"
            name: "compiler"
            root: "src/MinimalCompiler.w"
            module: "wheeler.compiler.main"
            sources:
        """);
    for (String source : compilerSources) {
      manifest.append("      - \"src/").append(source).append("\"\n");
    }
    manifest.append("""
              - "src/core/crypto/Sha256.w"
              - "src/core/encoding/Binary.w"
              - "src/core/encoding/FixedBinary.w"
            test: false
        dependencies: []
        capabilities: []
        """);
    return manifest.toString();
  }
}
