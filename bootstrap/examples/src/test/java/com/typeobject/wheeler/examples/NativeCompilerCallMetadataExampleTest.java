package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for compiler-owned scalar call metadata. */
final class NativeCompilerCallMetadataExampleTest {
  @Test
  void compilesEarlyDivisionReturnsByteForByte() throws Exception {
    String dependency = """
        module example.first_source_constants;
        classical class FirstSourceConstants {
          public const long FIRST_LIMIT = 1;
          public const long SECOND_LIMIT = 3;
          public const long THIRD_LIMIT = 5;
          public const long FIRST_SUBTRAHEND = 2;
          public const long FIRST_DIVISOR = 4;
          public const long SECOND_DIVISOR = 6;
        }
        """;
    String source = """
        module example.first_source;
        import example.first_source_constants;
        classical class FirstSource {
          public boolean first(long opcode) {
            return opcode == FIRST_LIMIT;
          }

          public long second(long value) {
            return value;
          }

          public long firstSource(long opcode) {
            if (opcode < FIRST_LIMIT) {
              return opcode - FIRST_SUBTRAHEND;
            }

            if (opcode < SECOND_LIMIT) {
              return opcode / FIRST_DIVISOR;
            }

            if (opcode < THIRD_LIMIT) {
              return opcode / SECOND_DIVISOR;
            }

            long packed = opcode - FIRST_LIMIT;
            return packed / 8;
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] actual = NativeModuleCompilerHarness.compile(compiler, List.of(dependency), source);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("FirstSource.w", source, "FirstSourceConstants.w", dependency),
        "example.first_source");
    assertArrayEquals(new BytecodeWriter().write(expected), actual);
  }

  @Test
  void compilesEarlyPriorLocalReturnsByteForByte() throws Exception {
    String source = """
        module example.early_local_return;
        classical class EarlyLocalReturn {
          public long select(long opcode, long fallback) {
            if (opcode == 1) {
              return fallback;
            }

            if (opcode < 3) {
              return fallback;
            }

            return opcode;
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] actual = NativeModuleCompilerHarness.compile(compiler, List.of(), source);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("EarlyLocalReturn.w", source),
        "example.early_local_return");
    assertArrayEquals(new BytecodeWriter().write(expected), actual);
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(),
        source.replace("return fallback;", "return missing;"));
  }

  @Test
  void compilesWideReturnPackingByteForByte() throws Exception {
    Program decoded = NativeCompilerSelfSourceExampleTest.assertCompilerLibrary(
        "compiler/resolution/returns/WideReturnSources.w",
        "wheeler.compiler.wide_return_sources");

    assertEquals(
        "wheeler.compiler.wide_return_sources::packWideReturnFirstSources",
        decoded.functions().getFirst().name());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalAssignmentCallIdentitiesByteForByte() throws Exception {
    Program decoded = NativeCompilerSelfSourceExampleTest.assertCompilerLibrary(
        "compiler/syntax/calls/assignment/AssignmentCallIdentities.w",
        "wheeler.compiler.assignment_call_identities");
    assertEquals("$library", decoded.functions().getFirst().name());
  }

  @Test
  void compilesResolvedReturnCallKindsByteForByte() throws Exception {
    Program decoded = NativeCompilerSelfSourceExampleTest.assertImportedConstantCompilerLibrary(
        "compiler/syntax/returns/ResolvedReturnCallKinds.w",
        "wheeler.compiler.resolved_return_call_kinds");

    assertEquals(
        "wheeler.compiler.resolved_return_call_kinds::resolvedReturnHelperCall",
        decoded.functions().getFirst().name());
    assertEquals("$library", decoded.functions().getLast().name());
  }
}
