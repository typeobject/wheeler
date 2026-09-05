package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.SourceModuleInspection;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.TreeSet;

/** Resolves canonical Wheeler package sources without cloning them into the example portfolio. */
final class PackageSources {
  private static final Path ROOT = Path.of("../wheeler-package/src/main/wheeler");

  private PackageSources() {}

  /** Adds the shared metadata matcher and its current compiler dependency closure. */
  static Map<String, String> withMetadataTokens(Map<String, String> local) throws IOException {
    Map<String, String> modules = new LinkedHashMap<>(local);
    String path = "packages/metadata/MetadataTokens.w";
    modules.put(path, read(path));
    var names = new HashSet<String>();
    var imports = new TreeSet<String>();
    for (String source : modules.values()) {
      var header = SourceModuleInspection.inspect(source.getBytes(StandardCharsets.UTF_8));
      if (!names.add(header.name())) {
        throw new IOException("Metadata fixture repeats module " + header.name());
      }
      imports.addAll(header.imports());
    }
    for (String imported : imports) {
      if (imported.startsWith("wheeler.compiler.") && !names.contains(imported)) {
        for (var entry : CompilerSources.moduleClosure(imported).entrySet()) {
          var header = SourceModuleInspection.inspect(
              entry.getValue().getBytes(StandardCharsets.UTF_8));
          if (names.add(header.name())) {
            modules.put(entry.getKey(), entry.getValue());
          }
        }
      }
    }
    return Map.copyOf(modules);
  }

  /** Returns one canonical package source path. */
  static Path path(String logicalPath) {
    return ROOT.resolve(logicalPath);
  }

  /** Reads one canonical package source as strict host text. */
  static String read(String logicalPath) throws IOException {
    return Files.readString(path(logicalPath));
  }
}
