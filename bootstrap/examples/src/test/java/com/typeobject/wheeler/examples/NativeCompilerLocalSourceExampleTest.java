package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeCompilerSelfSourceExampleTest.assertCompilerLibrary;
import static com.typeobject.wheeler.examples.NativeCompilerSelfSourceExampleTest.assertImportedConstantCompilerLibrary;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.core.bytecode.Program;
import org.junit.jupiter.api.Test;

/** Differential self-source tests for bounded local opcode families. */
class NativeCompilerLocalSourceExampleTest {
  @Test
  void compilesCanonicalNamedLongOperationsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/locals/NamedLongOperations.w",
        "wheeler.compiler.named_long_operations",
        "compiler/ir/StatementKinds.w");
    assertEquals(
        "wheeler.compiler.named_long_operations::namedLongBinary",
        decoded.functions().getFirst().name());
    assertEquals(4, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
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
}
