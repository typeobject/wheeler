//! Checks all physical unresolved void-call form queries through native package tests.

module wheeler.compiler.tests.native_compiler_void_call_source_forms;

import wheeler.compiler.void_call_source_forms;

classical class NativeCompilerVoidCallSourceFormTests {
  entry void main() {
    assert(true);
  }

  test void checksSevenArgumentSourceMembership() {
    boolean present = anyVoidCallSourceStatement(925);
    assert(present);
  }

  test void checksSevenArgumentSourceArity() {
    long arity = voidCallSourceArity(925);
    assert(arity == 7);
  }

  test void checksSevenArgumentSourceKind() {
    long kind = voidCallSourceKind(7);
    assert(kind == 925);
  }
}
