//! Checks physical compiler syntax and storage identities through native package tests.

module wheeler.compiler.tests.native_compiler_syntax;

import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.helper_abi;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.loop_kinds;
import wheeler.compiler.source_scalars;
import wheeler.compiler.storage_opcodes;

classical class NativeCompilerSyntaxTests {
  entry void main() {
    assert(true);
  }

  test void checksBorrowedIntrinsicKind() {
    long kind = STATEMENT_RETURN_BUFFER_LENGTH_NAMED;
    assert(kind == 893);
  }

  test void checksHelperAbi() {
    long kind = HELPER_VOID;
    assert(kind == 0);
  }

  test void checksKeywordToken() {
    long token = TOKEN_MODULE;
    assert(token == 3226183276);
  }

  test void checksLoopBodyOpcode() {
    long opcode = BODY_BOOLEAN_LITERAL;
    assert(opcode == 33280);
  }

  test void checksLoopKind() {
    long forms = STATEMENT_LOCAL_WHILE_FORM_COUNT;
    assert(forms == 24);
  }

  test void checksSourceScalar() {
    long scalar = PUNCTUATION_SEMICOLON;
    assert(scalar == 59);
  }

  test void checksStorageOpcode() {
    long opcode = OPCODE_RECORD_NEW;
    assert(opcode == 1280);
  }
}
