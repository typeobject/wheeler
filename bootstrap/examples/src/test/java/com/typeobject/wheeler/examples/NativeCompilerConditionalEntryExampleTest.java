package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeCompilerPhysicalEntryAssertions.assertPhysicalEntry;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Proves physical conditional classifier and operand owners through native entry artifacts. */
final class NativeCompilerConditionalEntryExampleTest {
  @Test
  void compilesPhysicalNamedLiteralComparisonKindsIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/StatementKinds.w");
    String kinds = CompilerSources.read(
        "compiler/syntax/conditionals/NamedLiteralComparisonKinds.w");
    String root = """
        module example.named_literal_comparison_kinds_entry;
        import wheeler.compiler.named_literal_comparison_kinds;
        classical class NamedLiteralComparisonKindsEntry {
          entry void main() {
            boolean present = namedLiteralComparisonConditional(825);
            assert(present);
          }
        }
        """;
    assertPhysicalEntry(
        List.of(opcodes, kinds),
        Map.of("Opcodes.w", opcodes, "Kinds.w", kinds, "Entry.w", root),
        root,
        "example.named_literal_comparison_kinds_entry");
  }

  @Test
  void compilesPhysicalNamedLocalConditionalValuesIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/StatementKinds.w");
    String values = CompilerSources.read(
        "compiler/syntax/conditionals/NamedLocalConditionalValues.w");
    String root = """
        module example.named_local_conditional_values_entry;
        import wheeler.compiler.named_local_conditional_values;
        classical class NamedLocalConditionalValuesEntry {
          entry void main() {
            boolean present = namedLocalConditionalValue(814);
            assert(present);
          }
        }
        """;
    assertPhysicalEntry(
        List.of(opcodes, values),
        Map.of("Opcodes.w", opcodes, "Values.w", values, "Entry.w", root),
        root,
        "example.named_local_conditional_values_entry");
  }

  @Test
  void compilesPhysicalResolvedLocalConditionalOperandsIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/ResolvedStatements.w");
    String operands = CompilerSources.read(
        "compiler/syntax/conditionals/ResolvedLocalConditionalOperands.w");
    String root = """
        module example.resolved_local_conditional_operands_entry;
        import wheeler.compiler.resolved_local_conditional_operands;
        classical class ResolvedLocalConditionalOperandsEntry {
          entry void main() {
            long source = resolvedLocalConditionalSource(11775);
            assert(source == 255);
          }
        }
        """;
    assertPhysicalEntry(
        List.of(opcodes, operands),
        Map.of("Opcodes.w", opcodes, "Operands.w", operands, "Entry.w", root),
        root,
        "example.resolved_local_conditional_operands_entry");
  }
}
