package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeCompilerPhysicalEntryAssertions.assertCompilerEntry;

import org.junit.jupiter.api.Test;

/** Proves physical resolved return owners through native entry artifacts. */
final class NativeCompilerResolvedReturnEntryExampleTest {
  @Test
  void compilesPhysicalNamedReturnArithmeticKindsIntoEntryByteForByte() throws Exception {
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
    assertCompilerEntry(root);
  }

  @Test
  void compilesPhysicalNamedBooleanReturnKindsIntoEntryByteForByte() throws Exception {
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
    assertCompilerEntry(root);
  }

  @Test
  void compilesPhysicalNamedSignedReturnKindsIntoEntryByteForByte() throws Exception {
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
    assertCompilerEntry(root);
  }

  @Test
  void compilesPhysicalNamedReturnComparisonOperandsIntoEntryByteForByte() throws Exception {
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
    assertCompilerEntry(root);
  }

  @Test
  void compilesPhysicalEarlyReturnSourcesIntoEntryByteForByte() throws Exception {
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
    assertCompilerEntry(root);
  }

  @Test
  void compilesPhysicalResolvedEarlyResultKindsIntoEntryByteForByte() throws Exception {
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
    assertCompilerEntry(root);
  }

  @Test
  void compilesPhysicalResolvedReturnCallKindsIntoEntryByteForByte() throws Exception {
    String root = """
        module example.resolved_return_call_kinds_entry;
        import wheeler.compiler.forwarded_helper_result_kinds;
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
    assertCompilerEntry(root);
  }

  @Test
  void compilesPhysicalResolvedEarlyComparisonKindsIntoEntryByteForByte() throws Exception {
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
    assertCompilerEntry(root);
  }
}
