//! Classifies resolved scalar-helper tail result statements.

module wheeler.compiler.helper_result_kinds;

import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.named_comparison_kinds;
import wheeler.compiler.named_return_arithmetic_kinds;
import wheeler.compiler.owned_storage_forms;
import wheeler.compiler.resolved_local_returns;
import wheeler.compiler.resolved_return_call_kinds;
import wheeler.compiler.statement_kinds;

classical class HelperResultKinds {
  /// Checks whether one statement returns a signed helper result.
  public boolean signedHelperResult(long opcode) {
    if (opcode == STATEMENT_RETURN_LONG) {
      return true;
    }

    if (resolvedSignedLocalReturn(opcode)) {
      return true;
    }

    if (returnLocalBinaryStatement(opcode)) {
      return true;
    }

    if (resolvedReturnHelperCall(opcode)) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BUFFER_LENGTH) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BUFFER_GET) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_UTF8_SCALAR) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_UTF8_WIDTH) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_MAP_GET) {
      return true;
    }

    return returnLocalPairStatement(opcode);
  }

  /// Checks whether one statement returns an owned UTF-8 helper result.
  public boolean utf8HelperResult(long opcode) {
    if (opcode == STATEMENT_RETURN_FREEZE_UTF8_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_FREEZE_MOVED_UTF8) {
      return true;
    }

    return resolvedReturnHelperCall(opcode);
  }

  /// Checks whether one statement returns a Boolean helper result.
  public boolean booleanHelperResult(long opcode) {
    if (opcode == STATEMENT_RETURN_BOOLEAN) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
      return true;
    }

    if (returnComparisonStatement(opcode)) {
      return true;
    }

    if (resolvedReturnHelperCall(opcode)) {
      return true;
    }

    if (resolvedLocalReturn(opcode)) {
      return resolvedSignedLocalReturn(opcode) == false;
    }

    return opcode == STATEMENT_RETURN_MAP_HAS;
  }
}
