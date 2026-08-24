package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeCompilerSelfSourceExampleTest.assertCompilerLibrary;
import static com.typeobject.wheeler.examples.NativeCompilerSelfSourceExampleTest.assertImportedConstantCompilerLibrary;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.core.bytecode.Program;
import org.junit.jupiter.api.Test;

/** Differential self-source tests for bounded local opcode families. */
class NativeCompilerLocalSourceExampleTest {
  @Test
  void compilesCanonicalNamedLocalAssignmentKindsByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/assignments/NamedLocalAssignmentKinds.w",
        "named_local_assignment_kinds",
        "localAssignmentSourceStatement",
        2,
        "compiler/ir/StatementKinds.w");
  }

  @Test
  void compilesCanonicalNamedLongOperationsByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/locals/NamedLongOperations.w",
        "named_long_operations",
        "namedLongLiteralBase",
        6,
        "compiler/ir/ResolvedStatements.w",
        "compiler/ir/StatementKinds.w");
  }

  @Test
  void compilesCanonicalNamedLocalUpdateKindsByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/updates/NamedLocalUpdateKinds.w",
        "named_local_update_kinds",
        "localUpdateSourceStatement",
        2,
        "compiler/ir/StatementKinds.w");
  }

  @Test
  void compilesCanonicalResolvedLocalAssignmentsByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/assignments/ResolvedLocalAssignments.w",
        "resolved_local_assignments",
        "resolvedLocalAssignment",
        5);
  }

  @Test
  void compilesCanonicalResolvedLocalLoopFormsByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/loops/ResolvedLocalLoopForms.w",
        "resolved_local_loop_forms",
        "localWhileConditionBit",
        5,
        "compiler/syntax/LoopKinds.w");
  }

  @Test
  void compilesCanonicalResolvedLocalLoopKindsByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/loops/ResolvedLocalLoopKinds.w",
        "resolved_local_loop_kinds",
        "resolvedLocalWhile",
        2,
        "compiler/syntax/LoopKinds.w",
        "compiler/ir/ResolvedStatements.w");
  }

  @Test
  void compilesCanonicalResolvedLocalLoopOperandsByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/loops/ResolvedLocalLoopOperands.w",
        "resolved_local_loop_operands",
        "resolvedLocalWhileTarget",
        3,
        "compiler/syntax/LoopKinds.w",
        "compiler/ir/ResolvedStatements.w");
  }

  @Test
  void compilesCanonicalResolvedLocalUpdatesByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/updates/ResolvedLocalUpdates.w",
        "resolved_local_updates",
        "resolvedLocalUpdate",
        4);
  }

  @Test
  void compilesCanonicalResolvedBooleanLiteralAssertionsByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/assertions/ResolvedBooleanLiteralAssertions.w",
        "resolved_boolean_literal_assertions",
        "resolvedBooleanLiteralAssertion",
        3);
  }

  @Test
  void compilesCanonicalResolvedBooleanLiteralComparisonsByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/booleans/ResolvedBooleanLiteralComparisons.w",
        "resolved_boolean_literal_comparisons",
        "resolvedBooleanLiteralEquality",
        5);
  }

  @Test
  void compilesCanonicalResolvedLocalCopyKindsByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/locals/ResolvedLocalCopyKinds.w",
        "resolved_local_copy_kinds",
        "resolvedLocalLongAssertion",
        5);
  }

  @Test
  void compilesCanonicalResolvedLocalEqualityKindsByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/locals/ResolvedLocalEqualityKinds.w",
        "resolved_local_equality_kinds",
        "resolvedLocalEquality",
        4);
  }

  @Test
  void compilesCanonicalResolvedLocalInequalityKindsByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/locals/ResolvedLocalInequalityKinds.w",
        "resolved_local_inequality_kinds",
        "resolvedLocalInequality",
        4);
  }

  @Test
  void compilesCanonicalResolvedLocalLessThanKindsByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/locals/ResolvedLocalLessThanKinds.w",
        "resolved_local_less_than_kinds",
        "resolvedLocalLongLessThan",
        2);
  }

  @Test
  void compilesCanonicalResolvedLocalLiteralComparisonSourcesByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/locals/ResolvedLocalLiteralComparisonSources.w",
        "resolved_local_literal_comparison_sources",
        "resolvedLocalLiteralComparisonSource",
        2);
  }

  @Test
  void compilesCanonicalResolvedLocalLiteralComparisonsByteForByte() throws Exception {
    assertCanonicalLocalModule(
        "syntax/locals/ResolvedLocalLiteralComparisons.w",
        "resolved_local_literal_comparisons",
        "resolvedLocalLiteralEquality",
        5);
  }

  @Test
  void compilesCanonicalResolvedLongOperationsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/locals/ResolvedLongOperations.w",
        "wheeler.compiler.resolved_long_operations");
    assertEquals(
        "wheeler.compiler.resolved_long_operations::resolvedLocalLongBinary",
        decoded.functions().getFirst().name());
    assertEquals(5, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalResolvedLessThanAssertionsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/assertions/ResolvedLessThanAssertions.w",
        "wheeler.compiler.resolved_less_than_assertions");
    assertEquals(
        "wheeler.compiler.resolved_less_than_assertions::resolvedLocalLessThanAssertion",
        decoded.functions().getFirst().name());
    assertEquals(4, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalResolvedLocalPairAssertionsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/assertions/ResolvedLocalPairAssertions.w",
        "wheeler.compiler.resolved_local_pair_assertions");
    assertEquals(
        "wheeler.compiler.resolved_local_pair_assertions::resolvedLocalPairAssertion",
        decoded.functions().getFirst().name());
    assertEquals(4, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalResolvedLocalReturnsByteForByte() throws Exception {
    Program decoded = assertCompilerLibrary(
        "compiler/syntax/returns/ResolvedLocalReturns.w",
        "wheeler.compiler.resolved_local_returns");
    assertEquals(
        "wheeler.compiler.resolved_local_returns::resolvedLocalReturn",
        decoded.functions().getFirst().name());
    assertEquals(4, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  private static void assertCanonicalLocalModule(
      String logicalPath,
      String moduleName,
      String firstFunction,
      int functionCount,
      String... dependencyPaths)
      throws Exception {
    if (dependencyPaths.length == 0) {
      dependencyPaths = new String[] {"compiler/ir/ResolvedStatements.w"};
    }
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/" + logicalPath,
        "wheeler.compiler." + moduleName,
        dependencyPaths);
    assertEquals(
        "wheeler.compiler." + moduleName + "::" + firstFunction,
        decoded.functions().getFirst().name());
    assertEquals(functionCount, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }
}
