package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeCompilerSelfSourceExampleTest.assertImportedConstantCompilerLibrary;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.core.bytecode.Program;
import org.junit.jupiter.api.Test;

/** Differential self-source tests for bounded conditional classification modules. */
class NativeCompilerConditionalSourceExampleTest {
  @Test
  void compilesCanonicalNamedLocalConditionalKindsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/NamedLocalConditionalKinds.w",
        "wheeler.compiler.named_local_conditional_kinds",
        "compiler/ir/StatementKinds.w");
    assertEquals(
        "wheeler.compiler.named_local_conditional_kinds::namedLocalConditional",
        decoded.functions().getFirst().name());
    assertEquals(5, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalNamedLocalConditionalValuesByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/NamedLocalConditionalValues.w",
        "wheeler.compiler.named_local_conditional_values",
        "compiler/ir/StatementKinds.w");
    assertEquals(
        "wheeler.compiler.named_local_conditional_values::namedLocalConditionalValue",
        decoded.functions().getFirst().name());
    assertEquals(2, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalLiteralComparisonOperationsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/LiteralComparisonOperations.w",
        "wheeler.compiler.literal_comparison_operations",
        "compiler/ir/ResolvedStatements.w",
        "compiler/ir/StatementKinds.w");
    assertEquals(
        "wheeler.compiler.literal_comparison_operations::literalComparisonConditionalLessThan",
        decoded.functions().getFirst().name());
    assertEquals(
        "wheeler.compiler.literal_comparison_operations::literalComparisonConditionalAssignment",
        decoded.functions().get(3).name());
    assertEquals(5, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalNamedLiteralComparisonKindsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/NamedLiteralComparisonKinds.w",
        "wheeler.compiler.named_literal_comparison_kinds",
        "compiler/ir/StatementKinds.w");
    assertEquals(
        "wheeler.compiler.named_literal_comparison_kinds::namedLiteralComparisonConditional",
        decoded.functions().getFirst().name());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalResolvedLocalConditionalKindsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/ResolvedLocalConditionalKinds.w",
        "wheeler.compiler.resolved_local_conditional_kinds");
    assertEquals(
        "wheeler.compiler.resolved_local_conditional_kinds::resolvedLocalConditional",
        decoded.functions().getFirst().name());
    assertEquals(5, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalResolvedLocalConditionalOperandsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/ResolvedLocalConditionalOperands.w",
        "wheeler.compiler.resolved_local_conditional_operands");
    assertEquals(
        "wheeler.compiler.resolved_local_conditional_operands::resolvedLocalConditionalSource",
        decoded.functions().getFirst().name());
    assertEquals(28, decoded.functions().getFirst().localCount());
    assertEquals(40, decoded.functions().getFirst().forward().size());
    assertEquals(2, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalResolvedLocalConditionalSourcesByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/ResolvedLocalConditionalSources.w",
        "wheeler.compiler.resolved_local_conditional_sources");
    assertEquals(
        "wheeler.compiler.resolved_local_conditional_sources::resolvedLocalConditionalValue",
        decoded.functions().getFirst().name());
    assertEquals(
        "wheeler.compiler.resolved_local_conditional_sources::resolvedLocalConditionalXor",
        decoded.functions().get(2).name());
    assertEquals(4, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalResolvedLiteralComparisonKindsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/ResolvedLiteralComparisonKinds.w",
        "wheeler.compiler.resolved_literal_comparison_kinds");
    assertEquals(
        "wheeler.compiler.resolved_literal_comparison_kinds::resolvedLiteralComparisonConditional",
        decoded.functions().getFirst().name());
    assertEquals(
        "wheeler.compiler.resolved_literal_comparison_kinds::resolvedLiteralComparisonConditionalSource",
        decoded.functions().get(1).name());
    assertEquals(3, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }
}
