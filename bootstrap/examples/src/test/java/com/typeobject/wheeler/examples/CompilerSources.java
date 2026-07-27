package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.SourceModuleInspection;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest.Module;
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
  private static final Path ROOT = Path.of("../wheeler-compiler/src/main/wheeler");
  private static final List<String> MINIMAL_PATHS = List.of(
      "MinimalCompiler.w",
      "compiler/Driver.w",
      "compiler/backend/Codegen.w",
      "compiler/backend/Encoding.w",
      "compiler/backend/StringTable.w",
      "compiler/frontend/BodyParser.w",
      "compiler/frontend/Conditionals.w",
      "compiler/frontend/HelperParser.w",
      "compiler/frontend/LocalOpcodes.w",
      "compiler/frontend/LocalStatements.w",
      "compiler/frontend/Parser.w",
      "compiler/frontend/Sequences.w",
      "compiler/frontend/Statements.w",
      "compiler/frontend/Structure.w",
      "compiler/frontend/Tokens.w",
      "compiler/ir/Ir.w",
      "compiler/ir/Opcodes.w",
      "compiler/ir/ProofRules.w",
      "compiler/ir/TypeCodes.w",
      "compiler/verification/AggregateVerifier.w",
      "compiler/verification/FunctionVerifier.w",
      "compiler/verification/InstructionVerifier.w",
      "compiler/verification/ProofVerifier.w",
      "compiler/verification/StorageVerifier.w",
      "compiler/verification/Verifier.w",
      "lexer/Scanner.w");

  private CompilerSources() {}

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
    for (String logicalPath : MINIMAL_PATHS) {
      modules.put(Path.of(logicalPath).getFileName().toString(), read(logicalPath));
    }
    return modules;
  }

  /** Derives the rooted module evidence for the physical bounded compiler closure. */
  static BootstrapModuleManifest bootstrapModuleManifest() throws Exception {
    MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
    Map<String, SourceModuleInspection.Header> headers = new LinkedHashMap<>();
    Map<String, byte[]> sources = new LinkedHashMap<>();
    for (String logicalPath : MINIMAL_PATHS) {
      byte[] source = read(logicalPath).getBytes(StandardCharsets.UTF_8);
      SourceModuleInspection.Header header = SourceModuleInspection.inspect(source);
      headers.put(logicalPath, header);
      sources.put(logicalPath, source);
    }

    TreeSet<String> localNames = new TreeSet<>();
    headers.values().forEach(header -> localNames.add(header.name()));
    TreeSet<String> externals = new TreeSet<>();
    List<Module> modules = new ArrayList<>();
    for (String logicalPath : MINIMAL_PATHS) {
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

  /** Compiles the complete bounded self-hosting compiler fixture. */
  static Program minimalCompilerProgram() throws IOException {
    Map<String, String> sources = minimalCompilerModules();
    sources.put("Binary.w", CoreSources.read("encoding/Binary.w"));
    return new WheelerCompiler().compileModuleFiles(sources, "wheeler.compiler.main");
  }

  /** Returns the importable compiler driver without its executable wrapper. */
  static Map<String, String> compilerDriverModules() throws IOException {
    Map<String, String> modules = minimalCompilerModules();
    modules.remove("MinimalCompiler.w");
    return modules;
  }
}
