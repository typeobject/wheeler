//! Resolves one bounded signed-local while form against prior declarations.

module wheeler.compiler.local_loop_resolution;

import wheeler.compiler.class_constants;
import wheeler.compiler.local_resolution;
import wheeler.compiler.loop_forms;
import wheeler.compiler.loop_kinds;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.tokens;

classical class LocalLoopResolution {
  /// Resolves a named while statement into one closed local-form opcode.
  public long resolveLocalWhileOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long whileTargetName = whileTargetToken(source, tokenStarts, statementStart);
    long whileTarget = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      whileTargetName,
      true
    );
    if (whileTarget < 0) {
      return -1;
    }

    long whileForm = 0;
    long whileConditionRight = whileConditionValueToken(source, tokenStarts, statementStart);
    if (whileReversed(source, tokenStarts, statementStart)) {
      whileForm += STATEMENT_LOCAL_WHILE_REVERSED_FORM;
    } else {
      if (loopOperandNamed(source, tokenStarts, whileConditionRight)) {
        long whileConditionLocal = resolvePriorDeclaration(
          source,
          tokenStarts,
          tokenLengths,
          previousStarts,
          previousCount,
          whileConditionRight,
          true
        );
        if (-1 < whileConditionLocal) {
          whileForm += STATEMENT_LOCAL_WHILE_CONDITION_NAMED;
        } else {
          ConstantResolution whileConditionConstant = resolveClassConstant(
            source,
            tokenStarts,
            tokenLengths,
            whileConditionRight,
            true
          );
          if (whileConditionConstant.valid == false) {
            return -1;
          }
        }
      }
    }

    long whileLimit = whileLimitToken(source, tokenStarts, statementStart);
    if (loopOperandNamed(source, tokenStarts, whileLimit)) {
      long whileLimitLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        whileLimit,
        true
      );
      if (-1 < whileLimitLocal) {
        whileForm += STATEMENT_LOCAL_WHILE_LIMIT_NAMED;
      } else {
        ConstantResolution whileLimitConstant = resolveClassConstant(
          source,
          tokenStarts,
          tokenLengths,
          whileLimit,
          true
        );
        if (whileLimitConstant.valid == false) {
          return -1;
        }
      }
    }

    long whileUpdateTarget = whileUpdateTargetToken(source, tokenStarts, statementStart);
    whileForm += whileUpdateForm(source, tokenStarts, whileUpdateTarget);
    return STATEMENT_LOCAL_WHILE_BASE + whileTarget * STATEMENT_LOCAL_WHILE_FORM_COUNT + whileForm;
  }
}
