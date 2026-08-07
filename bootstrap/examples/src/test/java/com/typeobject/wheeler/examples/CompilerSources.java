package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.SourceModuleInspection;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest.Module;
import com.typeobject.wheeler.packageformat.PackageManifest;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;

/** Resolves canonical Wheeler compiler sources without lending the examples a private copy. */
final class CompilerSources {
  private static final Path PACKAGE = Path.of("../wheeler-compiler");
  private static final Path ROOT = PACKAGE.resolve("src/main/wheeler");
  private static final String SOURCE_PREFIX = "src/main/wheeler/";

  private CompilerSources() {}

  private static List<String> minimalPaths() throws IOException {
    return targetPaths("compiler");
  }

  private static List<String> targetPaths(String targetName) throws IOException {
    PackageManifest manifest = new PackageManifestParser().parse(
        Files.readString(PACKAGE.resolve("wheeler.package.yaml")));
    PackageManifest.Target target = manifest.targets().stream()
        .filter(candidate -> candidate.name().equals(targetName))
        .findFirst()
        .orElseThrow(() -> new IOException(
            "Compiler package has no " + targetName + " target"));
    TreeSet<String> paths = new TreeSet<>();
    for (String selector : target.sources()) {
      if (!selector.startsWith(SOURCE_PREFIX)) {
        throw new IOException("Compiler source escapes its canonical root: " + selector);
      }
      String logicalPath = selector.substring(SOURCE_PREFIX.length());
      Path selected = ROOT.resolve(logicalPath);
      if (Files.isRegularFile(selected)) {
        paths.add(logicalPath);
      } else {
        try (var files = Files.walk(selected)) {
          files.filter(Files::isRegularFile)
              .filter(path -> path.getFileName().toString().endsWith(".w"))
              .map(ROOT::relativize)
              .map(Path::toString)
              .forEach(paths::add);
        }
      }
    }
    return List.copyOf(paths);
  }

  /** Returns one canonical compiler source path. */
  static Path path(String logicalPath) {
    return ROOT.resolve(logicalPath);
  }

  /** Reads one canonical compiler source as strict host text. */
  static String read(String logicalPath) throws IOException {
    return Files.readString(path(logicalPath));
  }

  /** Returns the complete bounded self-hosting compiler module set. */
  static Map<String, String> minimalCompilerModules() throws IOException {
    Map<String, String> modules = new LinkedHashMap<>();
    for (String logicalPath : minimalPaths()) {
      modules.put(logicalPath, read(logicalPath));
    }
    return modules;
  }

  /** Returns the canonical local dependency closure rooted at one compiler module. */
  static Map<String, String> moduleClosure(String rootModule) throws IOException {
    Map<String, ModuleSource> byName = new LinkedHashMap<>();
    for (String logicalPath : targetPaths("library")) {
      String source = read(logicalPath);
      SourceModuleInspection.Header header = SourceModuleInspection.inspect(
          source.getBytes(StandardCharsets.UTF_8));
      ModuleSource previous = byName.put(header.name(), new ModuleSource(
          logicalPath, source, header.imports()));
      if (previous != null) {
        throw new IOException("Compiler library repeats module " + header.name());
      }
    }
    if (!byName.containsKey(rootModule)) {
      throw new IOException("Compiler library has no module " + rootModule);
    }

    Map<String, String> closure = new LinkedHashMap<>();
    collectModule(rootModule, byName, closure);
    return Map.copyOf(closure);
  }

  private static void collectModule(
      String name,
      Map<String, ModuleSource> byName,
      Map<String, String> closure) {
    ModuleSource module = byName.get(name);
    if (module == null || closure.containsKey(module.logicalPath())) {
      return;
    }
    for (String imported : module.imports()) {
      collectModule(imported, byName, closure);
    }
    closure.put(module.logicalPath(), module.source());
  }

  /** Derives the rooted module evidence for the physical bounded compiler closure. */
  static BootstrapModuleManifest bootstrapModuleManifest() throws Exception {
    MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
    Map<String, SourceModuleInspection.Header> headers = new LinkedHashMap<>();
    Map<String, byte[]> sources = new LinkedHashMap<>();
    for (String logicalPath : minimalPaths()) {
      byte[] source = read(logicalPath).getBytes(StandardCharsets.UTF_8);
      SourceModuleInspection.Header header = SourceModuleInspection.inspect(source);
      headers.put(logicalPath, header);
      sources.put(logicalPath, source);
    }

    TreeSet<String> localNames = new TreeSet<>();
    headers.values().forEach(header -> localNames.add(header.name()));
    TreeSet<String> externals = new TreeSet<>();
    List<Module> modules = new ArrayList<>();
    for (String logicalPath : minimalPaths()) {
      SourceModuleInspection.Header header = headers.get(logicalPath);
      header.imports().stream()
          .filter(imported -> !localNames.contains(imported))
          .forEach(externals::add);
      modules.add(new Module(
          header.name(),
          "src/main/wheeler/" + logicalPath,
          HexFormat.of().formatHex(sha256.digest(sources.get(logicalPath))),
          header.imports()));
    }
    modules.sort(Comparator.comparing(Module::name));
    return new BootstrapModuleManifest(
        "bootstrap-1",
        "wheeler.compiler.main",
        List.copyOf(externals),
        modules);
  }

  private record ModuleSource(String logicalPath, String source, List<String> imports) {}

  /** Compiles the complete bounded self-hosting compiler fixture. */
  static Program minimalCompilerProgram() throws IOException {
    Map<String, String> sources = minimalCompilerModules();
    CoreSources.addBinaryClosure(sources);
    return new WheelerCompiler().compileModuleFiles(sources, "wheeler.compiler.main");
  }

  /** Returns the importable compiler driver without its executable wrapper. */
  static Map<String, String> compilerDriverModules() throws IOException {
    Map<String, String> modules = minimalCompilerModules();
    modules.remove("MinimalCompiler.w");
    return modules;
  }
}
