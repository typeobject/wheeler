package com.typeobject.wheeler.examples;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.Map;

/** Resolves canonical Wheeler compiler sources without lending the examples a private copy. */
final class CompilerSources {
  private static final Path ROOT = Path.of("../wheeler-compiler/src/main/wheeler");

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
    String[] logicalPaths = {
      "MinimalCompiler.w",
      "compiler/Driver.w",
      "compiler/backend/Codegen.w",
      "compiler/backend/Encoding.w",
      "compiler/backend/StringTable.w",
      "compiler/frontend/BodyParser.w",
      "compiler/frontend/HelperParser.w",
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
      "lexer/Scanner.w"
    };
    Map<String, String> modules = new LinkedHashMap<>();
    for (String logicalPath : logicalPaths) {
      modules.put(Path.of(logicalPath).getFileName().toString(), read(logicalPath));
    }
    return modules;
  }

  /** Returns the importable compiler driver without its executable wrapper. */
  static Map<String, String> compilerDriverModules() throws IOException {
    Map<String, String> modules = minimalCompilerModules();
    modules.remove("MinimalCompiler.w");
    return modules;
  }
}
