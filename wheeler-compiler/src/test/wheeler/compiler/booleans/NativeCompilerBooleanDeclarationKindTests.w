//! Checks physical Boolean-declaration classification through native package tests.

module wheeler.compiler.tests.native_compiler_boolean_declaration_kinds;

import wheeler.compiler.boolean_declaration_kinds;

classical class NativeCompilerBooleanDeclarationKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalBooleanDeclaration() {
    boolean declaration = booleanDeclarationStatement(816);
    assert(declaration);
  }
}
