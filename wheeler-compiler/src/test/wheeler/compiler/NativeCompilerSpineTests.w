//! Compiles the physical self-hosted compiler constant spine.

module wheeler.compiler.tests.native_compiler_spine;

import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.loop_kinds;
import wheeler.compiler.opcodes;
import wheeler.compiler.proof_rules;
import wheeler.compiler.type_codes;

classical class NativeCompilerSpineTests {
  entry void main() {
    assert(true);
  }

  test void compilesPhysicalCompilerSpine() {
    long width = ENCODING_WIDTH_U16;
    assert(width == 2);
  }
}
