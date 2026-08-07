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
  void compilesCanonicalAssignmentCallAritiesByteForByte() throws Exception {
    Program decoded = NativeCompilerSelfSourceExampleTest.assertImportedConstantCompilerLibrary(
        "compiler/syntax/calls/assignment/AssignmentCallArities.w",
        "wheeler.compiler.assignment_call_arities",
        "compiler/syntax/calls/assignment/AssignmentCallIdentities.w");
    assertEquals(
        "wheeler.compiler.assignment_call_arities::assignmentCallArity",
        decoded.functions().getFirst().name());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalAssignmentCallColumnsByteForByte() throws Exception {
    Program decoded = NativeCompilerSelfSourceExampleTest.assertImportedConstantCompilerLibrary(
        "compiler/syntax/calls/assignment/AssignmentCallColumns.w",
        "wheeler.compiler.assignment_call_columns",
        "compiler/syntax/calls/assignment/AssignmentCallIdentities.w");
    assertEquals(
        "wheeler.compiler.assignment_call_columns::sourceKind",
        decoded.functions().getFirst().name());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void linksOneSharedLeafIntoTwoDirectConstantsByteForByte() throws Exception {
    String ids = "module example.ids; classical class Ids { public const long BASE = 20; }";
    String first = "module example.first; import example.ids; classical class First { "
        + "public const long LEFT = BASE + 1; }";
    String second = "module example.second; import example.ids; classical class Second { "
        + "public const long RIGHT = BASE + 1; }";
    String root = "module example.root; import example.first; import example.ids; "
        + "import example.second; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome = LEFT; outcome += RIGHT; assert(outcome == 42); } }";
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileModuleFiles(
            Map.of("First.w", first, "Ids.w", ids, "Root.w", root, "Second.w", second),
            "example.root"));
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] forward = NativeModuleCompilerHarness.compile(
        compiler, List.of(first, ids, second), root);
    byte[] reverse = NativeModuleCompilerHarness.compile(
        compiler, List.of(second, ids, first), root);
    assertArrayEquals(expected, forward);
    assertArrayEquals(expected, reverse);
  }

  @Test
  void compilesCanonicalAssignmentCallLocalWidthsByteForByte() throws Exception {
    Program decoded = NativeCompilerSelfSourceExampleTest.assertImportedConstantCompilerLibrary(
        "compiler/syntax/calls/assignment/AssignmentCallLocalWidths.w",
        "wheeler.compiler.assignment_call_local_widths",
        "compiler/syntax/calls/assignment/AssignmentCallArities.w",
        "compiler/syntax/calls/assignment/AssignmentCallIdentities.w");
    assertEquals(
        "wheeler.compiler.assignment_call_local_widths::assignmentCallLocalCount",
        decoded.functions().get(1).name());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalAssignmentCallInstructionWidthsByteForByte() throws Exception {
    Program decoded = NativeCompilerSelfSourceExampleTest.assertImportedConstantCompilerLibrary(
        "compiler/syntax/calls/assignment/AssignmentCallInstructionWidths.w",
        "wheeler.compiler.assignment_call_instruction_widths",
        "compiler/syntax/calls/assignment/AssignmentCallArities.w",
        "compiler/syntax/calls/assignment/AssignmentCallIdentities.w");
    assertEquals(
        "wheeler.compiler.assignment_call_instruction_widths::assignmentCallInstructionCount",
        decoded.functions().get(1).name());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalAssignmentCallCodeWidthsByteForByte() throws Exception {
    Program decoded = NativeCompilerSelfSourceExampleTest.assertImportedConstantCompilerLibrary(
        "compiler/syntax/calls/assignment/AssignmentCallCodeWidths.w",
        "wheeler.compiler.assignment_call_code_widths",
        "compiler/syntax/calls/assignment/AssignmentCallArities.w",
        "compiler/syntax/calls/assignment/AssignmentCallIdentities.w");
    assertEquals(
        "wheeler.compiler.assignment_call_code_widths::assignmentCallCodeLength",
        decoded.functions().get(1).name());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesRedundantDirectLeafGraphByteForByte() throws Exception {
    String identities = CompilerSources.read(
        "compiler/syntax/calls/assignment/AssignmentCallIdentities.w");
    String arities = CompilerSources.read(
        "compiler/syntax/calls/assignment/AssignmentCallArities.w");
    String root = """
        module example.redundant_direct_leaf;
        import wheeler.compiler.assignment_call_arities;
        import wheeler.compiler.assignment_call_identities;
        classical class RedundantDirectLeaf {
          public long arity(long opcode) {
            return assignmentCallArity(opcode);
          }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of(
                "AssignmentCallIdentities.w", identities,
                "AssignmentCallArities.w", arities,
                "RedundantDirectLeaf.w", root),
            "example.redundant_direct_leaf"));
    Program compiler = NativeModuleCompilerHarness.program();
    assertArrayEquals(
        expected,
        NativeModuleCompilerHarness.compile(compiler, List.of(arities, identities), root));
    assertArrayEquals(
        expected,
        NativeModuleCompilerHarness.compile(compiler, List.of(identities, arities), root));
  }

  @Test
  void compilesRedundantDirectConstantLeafGraphByteForByte() throws Exception {
    String leaf = """
        module example.constants;
        classical class Constants {
          public const long BASE = 40;
        }
        """;
    String dependent = """
        module example.derived;
        import example.constants;
        classical class Derived {
          public const long RESULT = BASE + 2;
        }
        """;
    String root = """
        module example.redundant_constants;
        import example.constants;
        import example.derived;
        classical class RedundantConstants {
          public long value() {
            return RESULT;
          }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("Constants.w", leaf, "Derived.w", dependent, "Root.w", root),
            "example.redundant_constants"));
    Program compiler = NativeModuleCompilerHarness.program();
    assertArrayEquals(
        expected,
        NativeModuleCompilerHarness.compile(compiler, List.of(leaf, dependent), root));
    assertArrayEquals(
        expected,
        NativeModuleCompilerHarness.compile(compiler, List.of(dependent, leaf), root));
  }

  @Test
  void compilesCanonicalAssignmentCallIdentitiesByteForByte() throws Exception {
    Program decoded = NativeCompilerSelfSourceExampleTest.assertCompilerLibrary(
        "compiler/syntax/calls/assignment/AssignmentCallIdentities.w",
        "wheeler.compiler.assignment_call_identities");
    assertEquals("$library", decoded.functions().getFirst().name());
  }

  @Test
  void compilesCanonicalVoidCallSourceFormsByteForByte() throws Exception {
    Program decoded = NativeCompilerSelfSourceExampleTest.assertImportedConstantCompilerLibrary(
        "compiler/syntax/calls/void/VoidCallSourceForms.w",
        "wheeler.compiler.void_call_source_forms",
        "compiler/syntax/calls/VoidCallKinds.w",
        "compiler/syntax/calls/VoidCallSourceKinds.w");
    assertEquals("$library", decoded.functions().getLast().name());
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
