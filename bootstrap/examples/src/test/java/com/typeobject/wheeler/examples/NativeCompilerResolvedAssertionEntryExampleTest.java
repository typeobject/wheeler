package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeCompilerPhysicalEntryAssertions.assertPhysicalEntry;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Proves physical resolved assertion owners through native entry artifacts. */
final class NativeCompilerResolvedAssertionEntryExampleTest {
  @Test
  void compilesPhysicalResolvedBooleanLiteralAssertionsIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/ResolvedStatements.w");
    String assertions = CompilerSources.read(
        "compiler/syntax/assertions/ResolvedBooleanLiteralAssertions.w");
    String root = """
        module example.resolved_boolean_literal_assertions_entry;
        import wheeler.compiler.resolved_boolean_literal_assertions;
        classical class ResolvedBooleanLiteralAssertionsEntry {
          entry void main() {
            boolean present = resolvedBooleanLiteralAssertion(25855);
            long source = resolvedBooleanLiteralAssertionSource(25855);
            assert(present);
            assert(source == 255);
          }
        }
        """;
    assertPhysicalEntry(
        List.of(opcodes, assertions),
        Map.of("Opcodes.w", opcodes, "Assertions.w", assertions, "Entry.w", root),
        root,
        "example.resolved_boolean_literal_assertions_entry");
  }

  @Test
  void compilesPhysicalResolvedLessThanAssertionsIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/ResolvedStatements.w");
    String assertions = CompilerSources.read(
        "compiler/syntax/assertions/ResolvedLessThanAssertions.w");
    String root = """
        module example.resolved_less_than_assertions_entry;
        import wheeler.compiler.resolved_less_than_assertions;
        classical class ResolvedLessThanAssertionsEntry {
          entry void main() {
            boolean local = resolvedLocalLessThanAssertion(8447);
            boolean literal = resolvedLiteralLessThanAssertion(25087);
            long source = resolvedLiteralLessThanAssertionSource(25087);
            assert(local);
            assert(literal);
            assert(source == 255);
          }
        }
        """;
    assertPhysicalEntry(
        List.of(opcodes, assertions),
        Map.of("Opcodes.w", opcodes, "Assertions.w", assertions, "Entry.w", root),
        root,
        "example.resolved_less_than_assertions_entry");
  }

  @Test
  void compilesPhysicalResolvedLocalPairAssertionsIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/ResolvedStatements.w");
    String assertions = CompilerSources.read(
        "compiler/syntax/assertions/ResolvedLocalPairAssertions.w");
    String root = """
        module example.resolved_local_pair_assertions_entry;
        import wheeler.compiler.resolved_local_pair_assertions;
        classical class ResolvedLocalPairAssertionsEntry {
          entry void main() {
            boolean present = resolvedLocalPairAssertion(8191);
            boolean signed = resolvedLocalPairAssertionSigned(7935);
            long signedSource = resolvedLocalPairAssertionSource(7935);
            long booleanSource = resolvedLocalPairAssertionSource(8191);
            assert(present);
            assert(signed);
            assert(signedSource == 255);
            assert(booleanSource == 255);
          }
        }
        """;
    assertPhysicalEntry(
        List.of(opcodes, assertions),
        Map.of("Opcodes.w", opcodes, "Assertions.w", assertions, "Entry.w", root),
        root,
        "example.resolved_local_pair_assertions_entry");
  }
}
