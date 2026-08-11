package com.typeobject.wheeler.examples;

import org.junit.jupiter.api.Test;

/** Focused source evidence for local type-table encoding without a callable import. */
final class NativeCompilerLocalTypeEncodingSourceExampleTest {
  @Test
  void compilesCanonicalLocalTypeEncodingByteForByte() throws Exception {
    NativeCompilerSelfSourceExampleTest.assertImportedConstantCompilerLibrary(
        "compiler/backend/types/LocalTypeEncoding.w",
        "wheeler.compiler.local_type_encoding",
        "compiler/ir/TypeCodes.w");
  }
}
