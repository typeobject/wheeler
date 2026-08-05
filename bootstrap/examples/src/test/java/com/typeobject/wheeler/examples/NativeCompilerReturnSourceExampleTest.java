package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeCompilerSelfSourceExampleTest.assertImportedConstantCompilerLibrary;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.core.bytecode.Program;
import org.junit.jupiter.api.Test;

/** Differential self-source tests for unresolved scalar return families. */
final class NativeCompilerReturnSourceExampleTest {
  @Test
  void compilesCanonicalNamedBooleanReturnKindsByteForByte() throws Exception {
    assertCanonicalReturnModule(
        "NamedBooleanReturnKinds.w",
        "named_boolean_return_kinds",
        "returnBooleanEqualityStatement",
        4);
  }

  @Test
  void compilesCanonicalNamedReturnArithmeticKindsByteForByte() throws Exception {
    assertCanonicalReturnModule(
        "NamedReturnArithmeticKinds.w",
        "named_return_arithmetic_kinds",
        "returnLocalBinaryStatement",
        3);
  }

  @Test
  void compilesCanonicalNamedSignedReturnKindsByteForByte() throws Exception {
    assertCanonicalReturnModule(
        "NamedSignedReturnKinds.w",
        "named_signed_return_kinds",
        "returnSignedEqualityStatement",
        4);
  }

  private static void assertCanonicalReturnModule(
      String fileName, String moduleName, String firstFunction, int functionCount)
      throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/returns/" + fileName,
        "wheeler.compiler." + moduleName,
        "compiler/ir/StatementKinds.w");
    assertEquals(
        "wheeler.compiler." + moduleName + "::" + firstFunction,
        decoded.functions().getFirst().name());
    assertEquals(functionCount, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }
}
