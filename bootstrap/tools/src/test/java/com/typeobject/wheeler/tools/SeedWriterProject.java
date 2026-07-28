package com.typeobject.wheeler.tools;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

/** Builds the Wheeler-native compiler fixture used by command integration tests. */
final class SeedWriterProject {
  private static final Path COMPILER_ROOT = Path.of("wheeler-compiler/src/main/wheeler");
  private static final Path BINARY_SOURCE =
      Path.of("wheeler-core/src/main/wheeler/encoding/Binary.w");
  private static final List<String> COMPILER_SOURCES = List.of(
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
      "compiler/resolution/HelperCalls.w",
      "compiler/resolution/Operands.w",
      "compiler/verification/AggregateVerifier.w",
      "compiler/verification/FunctionVerifier.w",
      "compiler/verification/InstructionVerifier.w",
      "compiler/verification/ProofVerifier.w",
      "compiler/verification/StorageVerifier.w",
      "compiler/verification/Verifier.w",
      "lexer/Scanner.w");

  private SeedWriterProject() {}

  /** Copies the canonical bounded compiler closure and writes its standalone test manifest. */
  static Path create(Path temporary) throws IOException {
    Path project = temporary.resolve("seed-writer");
    for (String source : COMPILER_SOURCES) {
      Path destination = project.resolve("src").resolve(source);
      Files.createDirectories(destination.getParent());
      Files.copy(COMPILER_ROOT.resolve(source), destination);
    }
    Path binaryDestination = project.resolve("src/packages/Binary.w");
    Files.createDirectories(binaryDestination.getParent());
    Files.copy(BINARY_SOURCE, binaryDestination);
    Files.writeString(project.resolve("wheeler.package.yaml"), manifest());
    return project;
  }

  private static String manifest() {
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
    for (String source : COMPILER_SOURCES) {
      manifest.append("      - \"src/").append(source).append("\"\n");
    }
    manifest.append("""
              - "src/packages/Binary.w"
            test: false
        dependencies: []
        capabilities: []
        """);
    return manifest.toString();
  }
}
