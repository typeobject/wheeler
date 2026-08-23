package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeCompilerPhysicalEntryAssertions.assertPhysicalEntry;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Proves physical resolved return owners through native entry artifacts. */
final class NativeCompilerResolvedReturnEntryExampleTest {
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
