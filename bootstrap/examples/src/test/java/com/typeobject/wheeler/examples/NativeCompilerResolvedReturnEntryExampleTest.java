package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeCompilerPhysicalEntryAssertions.assertPhysicalEntry;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Proves physical resolved return owners through native entry artifacts. */
final class NativeCompilerResolvedReturnEntryExampleTest {
  @Test
  void compilesPhysicalNamedReturnArithmeticKindsIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/StatementKinds.w");
    String kinds = CompilerSources.read(
        "compiler/syntax/returns/NamedReturnArithmeticKinds.w");
    String root = """
        module example.named_return_arithmetic_kinds_entry;
        import wheeler.compiler.named_return_arithmetic_kinds;
        classical class NamedReturnArithmeticKindsEntry {
          entry void main() {
            boolean local = returnLocalBinaryStatement(860);
            boolean pair = returnLocalPairStatement(861);
            assert(local);
            assert(pair);
          }
        }
        """;
    assertPhysicalEntry(
        List.of(opcodes, kinds),
        Map.of("Opcodes.w", opcodes, "Kinds.w", kinds, "Entry.w", root),
        root,
        "example.named_return_arithmetic_kinds_entry");
  }

  @Test
  void compilesPhysicalNamedBooleanReturnKindsIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/StatementKinds.w");
    String kinds = CompilerSources.read("compiler/syntax/returns/NamedBooleanReturnKinds.w");
    String root = """
        module example.named_boolean_return_kinds_entry;
        import wheeler.compiler.named_boolean_return_kinds;
        classical class NamedBooleanReturnKindsEntry {
          entry void main() {
            boolean equality = returnBooleanEqualityStatement(857);
            boolean inequality = returnBooleanInequalityStatement(865);
            boolean comparison = returnBooleanComparisonStatement(865);
            assert(equality);
            assert(inequality);
            assert(comparison);
          }
        }
        """;
    assertPhysicalEntry(
        List.of(opcodes, kinds),
        Map.of("Opcodes.w", opcodes, "Kinds.w", kinds, "Entry.w", root),
        root,
        "example.named_boolean_return_kinds_entry");
  }

  @Test
  void compilesPhysicalNamedSignedReturnKindsIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/StatementKinds.w");
    String kinds = CompilerSources.read("compiler/syntax/returns/NamedSignedReturnKinds.w");
    String root = """
        module example.named_signed_return_kinds_entry;
        import wheeler.compiler.named_signed_return_kinds;
        classical class NamedSignedReturnKindsEntry {
          entry void main() {
            boolean equality = returnSignedEqualityStatement(873);
            boolean inequality = returnSignedInequalityStatement(875);
            boolean lessThan = returnSignedLessThanStatement(877);
            assert(equality);
            assert(inequality);
            assert(lessThan);
          }
        }
        """;
    assertPhysicalEntry(
        List.of(opcodes, kinds),
        Map.of("Opcodes.w", opcodes, "Kinds.w", kinds, "Entry.w", root),
        root,
        "example.named_signed_return_kinds_entry");
  }

  @Test
  void compilesPhysicalNamedReturnComparisonOperandsIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/StatementKinds.w");
    String operands = CompilerSources.read(
        "compiler/syntax/returns/NamedReturnComparisonOperands.w");
    String root = """
        module example.named_return_comparison_operands_entry;
        import wheeler.compiler.named_return_comparison_operands;
        classical class NamedReturnComparisonOperandsEntry {
          entry void main() {
            boolean local = returnComparisonLocalRight(877);
            assert(local);
          }
        }
        """;
    assertPhysicalEntry(
        List.of(opcodes, operands),
        Map.of("Opcodes.w", opcodes, "Operands.w", operands, "Entry.w", root),
        root,
        "example.named_return_comparison_operands_entry");
  }

  @Test
  void compilesPhysicalEarlyReturnSourcesIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/ResolvedStatements.w");
    String sources = CompilerSources.read("compiler/syntax/returns/EarlyReturnSources.w");
    String root = """
        module example.early_return_sources_entry;
        import wheeler.compiler.early_return_sources;
        classical class EarlyReturnSourcesEntry {
          entry void main() {
            long helper = earlyHelperReturnSource(28671);
            long comparison = earlyComparisonReturnSource(32255);
            assert(helper == 255);
            assert(comparison == 255);
          }
        }
        """;
    assertPhysicalEntry(
        List.of(opcodes, sources),
        Map.of("Opcodes.w", opcodes, "Sources.w", sources, "Entry.w", root),
        root,
        "example.early_return_sources_entry");
  }

  @Test
  void compilesPhysicalResolvedEarlyResultKindsIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/ResolvedStatements.w");
    String kinds = CompilerSources.read(
        "compiler/syntax/returns/ResolvedEarlyResultKinds.w");
    String root = """
        module example.resolved_early_result_kinds_entry;
        import wheeler.compiler.resolved_early_result_kinds;
        classical class ResolvedEarlyResultKindsEntry {
          entry void main() {
            boolean forwarding = resolvedEarlyHelperForwardingReturn(28671);
            boolean helper = resolvedEarlyHelperReturn(28671);
            boolean signed = resolvedEarlySignedReturn(32255);
            boolean local = resolvedEarlyLocalReturn(29439);
            boolean computed = resolvedEarlyComputedReturn(32255);
            boolean addition = resolvedEarlyAdditionReturn(32255);
            boolean remainder = resolvedEarlyRemainderReturn(28415);
            boolean division = resolvedEarlyDivisionReturn(28927);
            assert(forwarding);
            assert(helper);
            assert(signed);
            assert(local);
            assert(computed);
            assert(addition);
            assert(remainder);
            assert(division);
          }
        }
        """;
    assertPhysicalEntry(
        List.of(opcodes, kinds),
        Map.of("Opcodes.w", opcodes, "Kinds.w", kinds, "Entry.w", root),
        root,
        "example.resolved_early_result_kinds_entry");
  }

  @Test
  void compilesPhysicalResolvedReturnCallKindsIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/ResolvedStatements.w");
    String kinds = CompilerSources.read(
        "compiler/syntax/returns/ResolvedReturnCallKinds.w");
    String root = """
        module example.resolved_return_call_kinds_entry;
        import wheeler.compiler.resolved_return_call_kinds;
        classical class ResolvedReturnCallKindsEntry {
          entry void main() {
            boolean present = resolvedReturnHelperCall(29952);
            long arity = returnHelperCallArity(29952);
            long first = returnHelperCallFirstSource(4328521727);
            long second = returnHelperCallSecondSource(4328521727);
            long third = returnHelperCallThirdSource(4328521727);
            long fourth = returnHelperCallFourthSource(4328521727);
            assert(present);
            assert(arity == 7);
            assert(first == 255);
            assert(second == 255);
            assert(third == 255);
            assert(fourth == 255);
          }
        }
        """;
    assertPhysicalEntry(
        List.of(opcodes, kinds),
        Map.of("Opcodes.w", opcodes, "Kinds.w", kinds, "Entry.w", root),
        root,
        "example.resolved_return_call_kinds_entry");
  }

  @Test
  void compilesPhysicalResolvedEarlyComparisonKindsIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/ResolvedStatements.w");
    String kinds = CompilerSources.read(
        "compiler/syntax/returns/ResolvedEarlyComparisonKinds.w");
    String root = """
        module example.resolved_early_comparison_kinds_entry;
        import wheeler.compiler.resolved_early_comparison_kinds;
        classical class ResolvedEarlyComparisonKindsEntry {
          entry void main() {
            boolean equality = resolvedEarlyEqualityReturn(29183);
            boolean lessThan = resolvedEarlyLessReturn(32255);
            assert(equality);
            assert(lessThan);
          }
        }
        """;
    assertPhysicalEntry(
        List.of(opcodes, kinds),
        Map.of("Opcodes.w", opcodes, "Kinds.w", kinds, "Entry.w", root),
        root,
        "example.resolved_early_comparison_kinds_entry");
  }
}
