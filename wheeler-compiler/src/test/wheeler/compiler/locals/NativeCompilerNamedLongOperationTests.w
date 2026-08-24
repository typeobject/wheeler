//! Checks physical unresolved signed-operation mapping through native package tests.

module wheeler.compiler.tests.native_compiler_named_long_operations;

import wheeler.compiler.named_long_operations;

classical class NativeCompilerNamedLongOperationTests {
  entry void main() {
    assert(true);
  }

  test void mapsFinalNamedLongLiteralBase() {
    long base = namedLongLiteralBase(858);
    assert(base == 14848);
  }

  test void mapsFinalNamedLongPairBase() {
    long base = namedLongPairBase(859);
    assert(base == 15104);
  }

  test void classifiesFinalNamedLongBinary() {
    boolean binary = namedLongBinary(858);
    assert(binary);
  }

  test void classifiesFinalNamedLongPair() {
    boolean pair = namedLongPair(859);
    assert(pair);
  }

  test void classifiesFinalNamedGlobalUpdate() {
    boolean update = namedGlobalUpdate(808);
    assert(update);
  }
}
