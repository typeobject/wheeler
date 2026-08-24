//! Checks physical borrowed-intrinsic shapes through native package tests.

module wheeler.compiler.tests.native_compiler_borrowed_intrinsic_shapes;

import wheeler.compiler.borrowed_intrinsic_shapes;

classical class NativeCompilerBorrowedIntrinsicShapeTests {
  entry void main() {
    assert(true);
  }

  test void mapsResolvedLocalBufferLengthWidth() {
    long count = borrowedIntrinsicLocalCount(131073);
    assert(count == 3);
  }

  test void mapsResolvedLocalBufferLengthResult() {
    long offset = borrowedIntrinsicResultOffset(131073);
    assert(offset == 2);
  }

  test void mapsResolvedUtf8WidthCodeLength() {
    long length = borrowedIntrinsicCodeLength(131076);
    assert(length == 104);
  }

  test void mapsResolvedUtf8WidthInstructionCount() {
    long count = borrowedIntrinsicInstructionCount(131076);
    assert(count == 4);
  }
}
