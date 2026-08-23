//! Collects bounded scalar call names and statement rows from one parsed body.

module wheeler.compiler.helper_call_sites;

import wheeler.compiler.assignment_call_kinds;
import wheeler.compiler.call_forms;
import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.early_utf8_call_forms;
import wheeler.compiler.helper_abi;
import wheeler.compiler.ir;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.void_call_source_forms;

classical class HelperCallSites {
  /// Carries source ranges and statement rows for one bounded call set.
  public record CallSites(
    long[64] targetStarts,
    long[64] targetLengths,
    long[64] statements,
    long count,
    boolean valid
  ) {}

  /// Collects every scalar, assignment, forwarding, and void call in a body.
  public CallSites collectCallSites(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    long statementCount
  ) {
    region arena = new region(/* bytes= */ 1536, /* allocations= */ 3);
    words targetStartWork = allocate(arena, MAX_SCALAR_HELPER_CALLS);
    words targetLengthWork = allocate(arena, MAX_SCALAR_HELPER_CALLS);
    words statementWork = allocate(arena, MAX_SCALAR_HELPER_CALLS);
    long callCount = 0;
    long sourceStatement = 0;
    while (sourceStatement < statementCount) limit MAX_MINIMAL_STATEMENTS {
      long statementStart = statementStarts[sourceStatement];
      long sourceOpcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
      boolean helperCall = sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_TRUE_NAMED;
      if (sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_FALSE_NAMED) {
        helperCall = true;
      }

      if (sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_LONG_NAMED) {
        helperCall = true;
      }

      boolean forwardingGuard = sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_HELPER_CALL_NAMED;
      if (forwardingGuard) {
        helperCall = true;
      }

      long targetToken = statementStart + 2;
      if (anyVoidCallSourceStatement(sourceOpcode)) {
        helperCall = true;
        targetToken = statementStart;
      }

      if (sourceOpcode == STATEMENT_RETURN_HELPER_CALL_NAMED) {
        helperCall = true;
        targetToken = statementStart + 1;
      }

      if (sourceOpcode == STATEMENT_IF_EQ_RETURN_UTF8_CALL_NAMED) {
        helperCall = true;
        targetToken = earlyUtf8CallTargetToken(statementStart);
      }

      if (scalarResultCallStatement(sourceOpcode)) {
        helperCall = true;
        targetToken = statementStart + 3;
      }

      if (assignmentCallSourceStatement(sourceOpcode)) {
        helperCall = true;
        targetToken = statementStart + 2;
      }

      if (helperCall) {
        if (callCount < MAX_SCALAR_HELPER_CALLS) {
          set(targetStartWork, callCount, tokenStarts[targetToken]);
          set(targetLengthWork, callCount, tokenLengths[targetToken]);
          set(statementWork, callCount, sourceStatement);
        }

        callCount += 1;
      }

      if (forwardingGuard) {
        long returnTargetToken = statementStart + 9;
        if (callCount < MAX_SCALAR_HELPER_CALLS) {
          set(targetStartWork, callCount, tokenStarts[returnTargetToken]);
          set(targetLengthWork, callCount, tokenLengths[returnTargetToken]);
          set(statementWork, callCount, sourceStatement);
        }

        callCount += 1;
      }

      sourceStatement += 1;
    }

    boolean valid = callCount < MAX_SCALAR_HELPER_CALLS + 1;
    long[64] targetStarts = freezeHelperCallColumn(targetStartWork);
    long[64] targetLengths = freezeHelperCallColumn(targetLengthWork);
    long[64] statements = freezeHelperCallColumn(statementWork);
    drop(statementWork);
    drop(targetLengthWork);
    drop(targetStartWork);
    drop(arena);
    return new CallSites(targetStarts, targetLengths, statements, callCount, valid);
  }
}
