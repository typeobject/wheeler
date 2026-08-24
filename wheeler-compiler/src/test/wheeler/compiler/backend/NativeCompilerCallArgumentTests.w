//! Checks physical call-argument opcode selection through native package tests.

module wheeler.compiler.tests.native_compiler_call_arguments;

import wheeler.compiler.call_arguments;

classical class NativeCompilerCallArgumentTests {
  entry void main() {
    assert(true);
  }

  test void mapsCallArgumentOpcodes() {
    long utf8Borrow = callArgumentOpcode(8);
    assert(utf8Borrow == 1364);
    long longMapBorrow = callArgumentOpcode(9);
    assert(longMapBorrow == 1365);
    long regionBorrow = callArgumentOpcode(12);
    assert(regionBorrow == 1367);
    long wordsBorrow = callArgumentOpcode(10);
    assert(wordsBorrow == 1366);
    long bytesBorrow = callArgumentOpcode(11);
    assert(bytesBorrow == 1366);
    long byteViewBorrow = callArgumentOpcode(13);
    assert(byteViewBorrow == 1366);
    long scalarMove = callArgumentOpcode(1);
    assert(scalarMove == 1027);
  }
}
