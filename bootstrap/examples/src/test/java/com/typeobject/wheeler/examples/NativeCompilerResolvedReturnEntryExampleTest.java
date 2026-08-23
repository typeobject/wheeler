package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeCompilerPhysicalEntryAssertions.assertPhysicalEntry;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Proves physical resolved return owners through native entry artifacts. */
final class NativeCompilerResolvedReturnEntryExampleTest {
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
