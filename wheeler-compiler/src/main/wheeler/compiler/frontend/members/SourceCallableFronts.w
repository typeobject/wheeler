//! Locates callable fronts without scanning method bodies for declaration words.

module wheeler.compiler.source_callable_fronts;

import wheeler.compiler.closure.source_aggregate_syntax;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_front_windows;
import wheeler.compiler.source_member_modifiers;
import wheeler.compiler.source_member_names;
import wheeler.compiler.source_parameter_modes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.source_type_syntax;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class SourceCallableFronts {
  /// Reports callable coordinates after syntax checks. Nominal types still require binding.
  public record CallableFront(
    long nameToken,
    long parameterClose,
    long bodyOpen,
    long nextToken,
    long effects,
    boolean valid
  ) {}

  private CallableFront invalidCallableFront() {
    return new CallableFront(0, 0, 0, 0, 0, false);
  }

  private boolean uniqueParameterName(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long open,
    long name
  ) {
    long cursor = open + 1;
    while (cursor < name) limit MAX_COMPILER_TOKENS {
      if (punctuationAt(source, kinds, starts, cursor, PUNCTUATION_COMMA)) {
        if (sameTokenText(source, starts, lengths, cursor - 1, name)) {
          return false;
        }
      }

      cursor += 1;
    }

    return true;
  }

  private long checkedParameterCount(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long open,
    long close,
    long effects
  ) {
    long cursor = open + 1;
    long parameters = 0;
    long firstMode = 0;
    long firstType = 0;
    while (cursor < close) limit MAX_COMPILER_TOKENS {
      ParameterPrefix prefix = sourceParameterPrefix(source, starts, lengths, cursor, close);
      if (prefix.valid == false) {
        return -1;
      }

      SourceTypeFront type = sourceTypeFront(
        source,
        kinds,
        starts,
        lengths,
        close,
        prefix.typeToken,
        false
      );
      if (type.valid == false) {
        return -1;
      }

      long name = type.nextToken;
      if (close - 1 < name) {
        return -1;
      }

      if (sourceValueNameValid(source, kinds, starts, lengths, name) == false) {
        return -1;
      }

      if (sourceParameterModeValid(type.baseType, type.compound, prefix.mode) == false) {
        return -1;
      }

      if (uniqueParameterName(source, kinds, starts, lengths, open, name) == false) {
        return -1;
      }

      if (effects == MEMBER_TEST) {
        if (prefix.mode != 0) {
          return -1;
        }

        if (type.compound) {
          return -1;
        }

        if (type.baseType == TYPE_SIGNED) {} else {
          if (type.baseType != TYPE_BOOLEAN) {
            return -1;
          }
        }
      }

      if (effects == MEMBER_ENTRY) {
        if (type.compound) {
          return -1;
        }

        if (parameters == 0) {
          boolean input = prefix.mode == 1;
          if (type.baseType == TYPE_UTF8) {} else {
            if (type.baseType != TYPE_BYTE_VIEW) {
              input = false;
            }
          }

          boolean output = prefix.mode == 2;
          if (type.baseType != TYPE_BYTES) {
            output = false;
          }

          if (input == false) {
            if (output == false) {
              return -1;
            }
          }
        } else {
          if (parameters != 1) {
            return -1;
          }

          if (firstMode != 1) {
            return -1;
          }

          if (firstType == TYPE_UTF8) {} else {
            if (firstType != TYPE_BYTE_VIEW) {
              return -1;
            }
          }

          if (prefix.mode != 2) {
            return -1;
          }

          if (type.baseType != TYPE_BYTES) {
            return -1;
          }
        }
      }

      if (parameters == 0) {
        firstMode = prefix.mode;
        firstType = type.baseType;
      }

      parameters += 1;
      cursor = name + 1;
      if (cursor < close) {
        if (punctuationAt(source, kinds, starts, cursor, PUNCTUATION_COMMA) == false) {
          return -1;
        }

        cursor += 1;
        if (cursor == close) {
          return -1;
        }
      }
    }

    return parameters;
  }

  private long testBodyOpen(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long start
  ) {
    long cursor = start;
    long previous = 0;
    while (cursor < count) limit 4 {
      if (punctuationAt(source, kinds, starts, cursor, PUNCTUATION_OPEN_BRACE)) {
        return cursor;
      }

      long code = sourceTokenCode(source, starts, lengths, cursor);
      long section = 0;
      if (code == TOKEN_CASES) {
        section = 1;
      }

      if (code == TOKEN_TAGS) {
        section = 2;
      }

      if (code == TOKEN_LIMITS) {
        section = 3;
      }

      if (section < previous + 1) {
        return -1;
      }

      if (count < cursor + 2) {
        return -1;
      }

      if (
        punctuationAt(source, kinds, starts, cursor + 1, PUNCTUATION_OPEN_PAREN) == false
      ) {
        return -1;
      }

      long close = closingToken(
        source,
        kinds,
        starts,
        cursor + 1,
        count,
        PUNCTUATION_OPEN_PAREN,
        PUNCTUATION_CLOSE_PAREN
      );
      if (close < 0) {
        return -1;
      }

      cursor = close + 1;
      previous = section;
    }

    return -1;
  }

  /// Checks one callable prefix, parameter sequence, metadata envelope, and balanced body extent.
  /// Test metadata values and all method statements remain with their semantic owners.
  public CallableFront sourceCallableFront(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long start
  ) {
    if (sourceFrontWindowValid(kinds, starts, lengths, count, start) == false) {
      return invalidCallableFront();
    }

    MemberModifiers modifiers = sourceCallableModifiers(source, starts, lengths, start, count);
    if (modifiers.valid == false) {
      return invalidCallableFront();
    }

    SourceTypeFront result = sourceTypeFront(
      source,
      kinds,
      starts,
      lengths,
      count,
      modifiers.nextToken,
      true
    );
    if (result.valid == false) {
      return invalidCallableFront();
    }

    long name = result.nextToken;
    if (count < name + 3) {
      return invalidCallableFront();
    }

    if (sourceValueNameValid(source, kinds, starts, lengths, name) == false) {
      return invalidCallableFront();
    }

    if (sourceTokenCode(source, starts, lengths, name) == TOKEN_SLICE) {
      return invalidCallableFront();
    }

    long open = name + 1;
    if (punctuationAt(source, kinds, starts, open, PUNCTUATION_OPEN_PAREN) == false) {
      return invalidCallableFront();
    }

    long close = closingToken(
      source,
      kinds,
      starts,
      open,
      count,
      PUNCTUATION_OPEN_PAREN,
      PUNCTUATION_CLOSE_PAREN
    );
    if (close < 0) {
      return invalidCallableFront();
    }

    long effects = modifiers.effects;
    long parameters = checkedParameterCount(
      source,
      kinds,
      starts,
      lengths,
      open,
      close,
      effects
    );
    if (parameters < 0) {
      return invalidCallableFront();
    }

    boolean voidResult = result.baseType == 0;
    if (result.compound) {
      voidResult = false;
    }

    if (effects == MEMBER_ENTRY) {
      if (voidResult == false) {
        return invalidCallableFront();
      }

      if (sourceTokenCode(source, starts, lengths, name) != TOKEN_MAIN) {
        return invalidCallableFront();
      }
    }

    if (effects == MEMBER_TEST) {
      if (voidResult == false) {
        return invalidCallableFront();
      }
    }

    boolean unparameterized = effects / MEMBER_COHERENT % 2 == 1;
    if (effects == MEMBER_UNITARY) {
      unparameterized = true;
    }

    if (effects == MEMBER_DYNAMIC) {
      unparameterized = true;
    }

    if (unparameterized) {
      if (voidResult == false) {
        return invalidCallableFront();
      }

      if (parameters != 0) {
        return invalidCallableFront();
      }
    }

    if (effects / MEMBER_REV % 2 == 1) {
      if (voidResult) {
        if (parameters != 0) {
          return invalidCallableFront();
        }
      } else {
        if (result.compound) {
          return invalidCallableFront();
        }

        if (result.baseType == TYPE_SIGNED) {} else {
          if (result.baseType != TYPE_BOOLEAN) {
            return invalidCallableFront();
          }
        }
      }
    }

    long body = close + 1;
    if (effects == MEMBER_TEST) {
      body = testBodyOpen(source, kinds, starts, lengths, count, body);
    }

    if (body < 0) {
      return invalidCallableFront();
    }

    if (count < body + 1) {
      return invalidCallableFront();
    }

    if (punctuationAt(source, kinds, starts, body, PUNCTUATION_OPEN_BRACE) == false) {
      return invalidCallableFront();
    }

    long bodyClose = closingToken(
      source,
      kinds,
      starts,
      body,
      count,
      PUNCTUATION_OPEN_BRACE,
      PUNCTUATION_CLOSE_BRACE
    );
    if (bodyClose < 0) {
      return invalidCallableFront();
    }

    return new CallableFront(name, close, body, bodyClose + 1, effects, true);
  }
}
