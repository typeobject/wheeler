//! Checks a physical compiler type decoder through native package tests.

module wheeler.compiler.tests.native_compiler_type_kinds;

import wheeler.compiler.type_codes;
import wheeler.compiler.type_kinds;

classical class NativeCompilerTypeKindTests {
  entry void main() {
    assert(true);
  }

  test void checksTypeDescriptor() {
    long descriptor = typeDescriptor(268435463);
    assert(descriptor == 7);
    long record = TYPE_RECORD;
    assert(record == 268435456);
  }
}
