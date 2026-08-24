package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Physical graph evidence for reversible helper owners and attached proofs. */
final class NativeCompilerReversibleOwnerExampleTest {
  private static final String ROOT = """
      module example.reversible_token_use;

      import wheeler.compiler.closure.reversible_token_coordinates;
      import wheeler.compiler.source_scalars;

      classical class ReversibleTokenUse {
        entry void main() {
          long advanced = nextSourceToken(49);
          assert(advanced == 50);
        }
      }
      """;

  @Test
  void compilesReversibleHelperAndProofByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String constants = constants();
    String dependency = dependency();
    Program decoded = assertCompilesByteForByte(compiler, constants, dependency);

    assertEquals(
        "wheeler.compiler.closure.reversible_token_coordinates::nextSourceToken",
        decoded.functions().getFirst().name());
    assertTrue(decoded.functions().getFirst().reversible());
    assertTrue(!decoded.functions().getFirst().inverse().isEmpty());
    assertEquals(
        "example.reversible_token_use::main",
        decoded.functions().get(1).name());
    assertEquals(1, decoded.proofCertificates().size());
    assertEquals(
        "wheeler.compiler.closure.reversible_token_coordinates::nextSourceTokenInverse",
        decoded.proofCertificates().getFirst().name());
  }

  @Test
  void compilesReversibleHelperWithoutOptionalProof() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String proof = "  theorem nextSourceTokenInverse proves inverse(nextSourceToken);\n";
    Program decoded = assertCompilesByteForByte(
        compiler,
        constants(),
        dependency().replace(proof, ""));

    assertTrue(decoded.functions().getFirst().reversible());
    assertEquals(0, decoded.proofCertificates().size());
  }

  @Test
  void rejectsDetachedOrMalformedHelperProofs() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String constants = constants();
    String dependency = dependency();

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(
            constants,
            dependency.replace("inverse(nextSourceToken)", "inverse(otherToken)")),
        ROOT);
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(
            constants,
            dependency.replace("public rev long nextSourceToken", "public long nextSourceToken")),
        ROOT);
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(
            constants,
            dependency.replace("inverse(nextSourceToken);", "inverse(nextSourceToken)")),
        ROOT);
  }

  private static Program assertCompilesByteForByte(
      Program compiler,
      String constants,
      String dependency) throws Exception {
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler,
        List.of(constants, dependency),
        ROOT);
    Program expected = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "compiler/closure/products/source/coordinates/ReversibleTokenCoordinates.w",
            dependency,
            "compiler/syntax/tokens/SourceScalars.w",
            constants,
            "ReversibleTokenUse.w",
            ROOT),
        "example.reversible_token_use");
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    return new BytecodeReader().read(artifact);
  }

  private static String constants() throws Exception {
    return CompilerSources.read("compiler/syntax/tokens/SourceScalars.w");
  }

  private static String dependency() throws Exception {
    return CompilerSources.read(
        "compiler/closure/products/source/coordinates/ReversibleTokenCoordinates.w");
  }
}
