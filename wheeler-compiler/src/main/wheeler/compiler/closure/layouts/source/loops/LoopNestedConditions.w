//! Resolves one-arm nested loop guards without emitting branch instructions.

module wheeler.compiler.closure.loop_nested_conditions;

import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class LoopNestedConditions {
  /// Reports one Boolean, equality-literal, or less-than-literal guard.
  public record LoopNestedCondition(
    long kind,
    long local,
    long literal,
    long localCount,
    boolean valid
  ) {}

  /// Resolves a nested `if` condition against owner-scoped callable values.
  public LoopNestedCondition resolveLoopNestedCondition(
    borrow utf8 source,
    long owner,
    long ordinal,
    long controlToken,
    long valueCount,
    borrow mut words valueRows,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    boolean valid = punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      controlToken + 1,
      PUNCTUATION_OPEN_PAREN
    );
    LoopBodyValue condition = resolveLoopBodyValue(
      source,
      tokenStarts[controlToken + 2],
      tokenLengths[controlToken + 2],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    if (condition.valid == false) {
      valid = false;
    }

    long kind = 0;
    long literal = 0;
    long localCount = 3;
    long closeToken = controlToken + 3;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, closeToken, PUNCTUATION_CLOSE_PAREN)
    ) {
      kind = 3;
      localCount = 1;
      if (
        booleanLoopBodyLocal(
          source,
          owner,
          condition.local,
          valueCount,
          valueRows,
          tokenCount,
          tokenStarts,
          tokenLengths
        ) == false
      ) {
        valid = false;
      }
    } else {
      long literalToken = controlToken + 4;
      if (
        punctuationAt(source, tokenKinds, tokenStarts, controlToken + 3, PUNCTUATION_LESS_THAN)
      ) {
        kind = 2;
      } else {
        if (
          punctuationAt(source, tokenKinds, tokenStarts, controlToken + 3, PUNCTUATION_ASSIGN)
        ) {
          if (
            punctuationAt(
              source,
              tokenKinds,
              tokenStarts,
              controlToken + 4,
              PUNCTUATION_ASSIGN
            )
          ) {
            kind = 1;
            literalToken += 1;
          }
        }
      }

      if (kind == 0) {
        valid = false;
      }

      if (
        signedLoopBodyLocal(
          source,
          owner,
          condition.local,
          valueCount,
          valueRows,
          tokenCount,
          tokenStarts,
          tokenLengths
        ) == false
      ) {
        valid = false;
      }

      if (signedNumberWidth(source, tokenKinds, tokenStarts, literalToken) != 1) {
        valid = false;
      } else {
        if (signedNumberValid(source, tokenStarts, tokenLengths, literalToken)) {
          literal = parsedSignedNumber(source, tokenStarts, tokenLengths, literalToken);
        } else {
          valid = false;
        }
      }

      closeToken = literalToken + 1;
      if (
        punctuationAt(source, tokenKinds, tokenStarts, closeToken, PUNCTUATION_CLOSE_PAREN) == false
      ) {
        valid = false;
      }
    }

    return new LoopNestedCondition(kind, condition.local, literal, localCount, valid);
  }
}
