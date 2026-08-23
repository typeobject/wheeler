//! Checks physical compiler call syntax identities through native package tests.

module wheeler.compiler.tests.native_compiler_call_syntax;

import wheeler.compiler.assignment_call_identities;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.void_call_source_kinds;

classical class NativeCompilerCallSyntaxTests {
  entry void main() {
    assert(true);
  }

  test void checksAssignmentCallArity() {
    boolean call = voidCallSourceStatement(900);
    assert(call);
    long arity = MAX_ASSIGNMENT_CALL_ARGUMENTS;
    assert(arity == 7);
  }

  test void checksLoopBodyRows() {
    boolean call = voidCallSourceStatement(900);
    assert(call);
    long rows = BODY_ROWS;
    assert(rows == 20480);
  }

  test void checksVoidCallSource() {
    boolean call = voidCallSourceStatement(900);
    assert(call);
    long kind = STATEMENT_CALL_VOID_ZERO_NAMED;
    assert(kind == 900);
  }
}
