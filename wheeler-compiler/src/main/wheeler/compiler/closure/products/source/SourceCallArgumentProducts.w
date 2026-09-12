//! Binds source-call arguments to typed defining value products.

module wheeler.compiler.closure.source_call_argument_products;

import wheeler.compiler.closure.direct_statement_coordinates;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.source_call_argument_layouts;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.module_linker;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class SourceCallArgumentProducts {
  private const long CALL_COUNT_LIMIT = SOURCE_CALL_COUNT_LIMIT;
  private const long STAGING_BYTES = MAX_COMPILER_TOKENS * 24 + CALL_COUNT_LIMIT * 16
    + SOURCE_CALL_ARGUMENT_ROWS * 16;
  private const long CALL_ROWS = 1024;
  private const long MAX_STATEMENTS = 4096;
  private const long MAX_VALUES = 1024;
  private const long STATEMENT_ROWS = 28672;
  private const long VALUE_ROWS = 7168;

  /// Reports one complete source-call argument product.
  public record SourceCallArgumentPlan(long callCount, long argumentCount, boolean valid) {}

  private boolean sameRange(
    borrow utf8 source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    if (leftLength != rightLength) {
      return false;
    }

    long offset = 0;
    while (offset < leftLength) limit 256 {
      if (
        utf8Scalar(source, leftStart + offset) != utf8Scalar(source, rightStart + offset)
      ) {
        return false;
      }

      offset += utf8Width(source, leftStart + offset);
    }

    return offset == leftLength;
  }

  private long tokenAtRange(
    long start,
    long length,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long selected = -1;
    long matches = 0;
    long token = 0;
    while (token < tokenCount) limit MAX_COMPILER_TOKENS {
      if (tokenKinds[token] == 1) {
        if (tokenStarts[token] == start) {
          if (tokenLengths[token] == length) {
            selected = token;
            matches += 1;
          }
        }
      }

      token += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private long visibleValue(
    borrow utf8 source,
    long owner,
    long argumentStart,
    long argumentLength,
    long valueCount,
    borrow mut words valueRows
  ) {
    long selected = -1;
    long selectedStart = -1;
    long matches = 0;
    long value = 0;
    while (value < valueCount) limit MAX_VALUES {
      if (valueRows[value] == owner) {
        long declarationStart = valueRows[5120 + value];
        if (declarationStart < argumentStart) {
          if (
            sameRange(
              source,
              argumentStart,
              argumentLength,
              valueRows[1024 + value],
              valueRows[2048 + value]
            )
          ) {
            if (selectedStart < declarationStart) {
              selected = value;
              selectedStart = declarationStart;
              matches = 1;
            } else {
              if (selectedStart == declarationStart) {
                matches += 1;
              }
            }
          }
        }
      }

      value += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private boolean completeCallTokenWindow(
    long first,
    long last,
    long end,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths
  ) {
    long previousEnd = starts[first];
    long token = first;
    while (token < last + 1) limit MAX_COMPILER_TOKENS {
      long start = starts[token];
      long length = lengths[token];
      if (start < previousEnd) {
        return false;
      }

      if (end < start) {
        return false;
      }

      if (length < 1) {
        return false;
      }

      if (end - start < length) {
        return false;
      }

      if (kinds[token] == 3) {
        if (length != 1) {
          return false;
        }
      }

      previousEnd = start + length;
      token += 1;
    }

    return previousEnd == end;
  }

  private boolean callPrefixValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    long first,
    long name
  ) {
    if (first == name) {
      return true;
    }

    if (name - first < 3) {
      return false;
    }

    long cursor = first;
    while (cursor < name - 2) limit MAX_COMPILER_TOKENS {
      if (kinds[cursor] != 1) {
        return false;
      }

      cursor += 1;
      if (cursor < name - 2) {
        if (punctuationAt(source, kinds, starts, cursor, PUNCTUATION_DOT) == false) {
          return false;
        }

        cursor += 1;
        if (name - 2 < cursor + 1) {
          return false;
        }
      }
    }

    if (cursor != name - 2) {
      return false;
    }

    if (punctuationAt(source, kinds, starts, cursor, PUNCTUATION_COLON) == false) {
      return false;
    }

    return punctuationAt(source, kinds, starts, cursor + 1, PUNCTUATION_COLON);
  }

  /// Selects a call prefix without binding its callee or destination.
  public long sourceCallHeadTokens(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long first
  ) {
    if (count < 1) {
      return -1;
    }

    if (MAX_COMPILER_TOKENS < count) {
      return -1;
    }

    if (bufferLength(kinds) != MAX_COMPILER_TOKENS) {
      return -1;
    }

    if (bufferLength(starts) != MAX_COMPILER_TOKENS) {
      return -1;
    }

    if (bufferLength(lengths) != MAX_COMPILER_TOKENS) {
      return -1;
    }

    if (first < 0) {
      return -1;
    }

    if (count - 1 < first) {
      return -1;
    }

    long checked = first;
    while (checked < first + 2) limit 2 {
      if (checked < count) {
        long start = starts[checked];
        long length = lengths[checked];
        if (start < 0) {
          return -1;
        }

        if (bufferLength(source) < start) {
          return -1;
        }

        if (length < 1) {
          return -1;
        }

        if (bufferLength(source) - start < length) {
          return -1;
        }
      }

      checked += 1;
    }

    long word = sourceTokenCode(source, starts, lengths, first);
    if (word == TOKEN_RETURN) {
      return 1;
    }

    if (word == TOKEN_LONG) {
      return 3;
    }

    if (word == TOKEN_BOOLEAN) {
      return 3;
    }

    if (first + 1 < count) {
      if (punctuationAt(source, kinds, starts, first + 1, PUNCTUATION_ASSIGN)) {
        return 2;
      }
    }

    return 0;
  }

  /// Checks a complete call statement against its retained call-name and arity rows.
  ///
  /// Heads contain zero tokens for a call, one for a return, two for a store, or three for a declaration.
  /// Scanner columns own token spelling and trivia. Target and value binding remain separate.
  public boolean sourceCallStatementValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long first,
    long statementLength,
    long callStart,
    long callLength,
    long arity,
    long headTokens
  ) {
    boolean headValid = headTokens == 0;
    if (headTokens == 1) {
      headValid = true;
    }

    if (headTokens == 2) {
      headValid = true;
    }

    if (headTokens == 3) {
      headValid = true;
    }

    if (headValid == false) {
      return false;
    }

    if (bufferLength(kinds) != MAX_COMPILER_TOKENS) {
      return false;
    }

    if (bufferLength(starts) != MAX_COMPILER_TOKENS) {
      return false;
    }

    if (bufferLength(lengths) != MAX_COMPILER_TOKENS) {
      return false;
    }

    if (count < 1) {
      return false;
    }

    if (MAX_COMPILER_TOKENS < count) {
      return false;
    }

    if (first < 0) {
      return false;
    }

    if (count - 1 < first) {
      return false;
    }

    if (arity < 0) {
      return false;
    }

    if (SOURCE_CALL_ARITY_LIMIT < arity) {
      return false;
    }

    long start = starts[first];
    if (start < 0) {
      return false;
    }

    if (bufferLength(source) < start) {
      return false;
    }

    if (statementLength < 1) {
      return false;
    }

    if (bufferLength(source) - start < statementLength) {
      return false;
    }

    long end = start + statementLength;
    if (callStart < start) {
      return false;
    }

    if (end < callStart) {
      return false;
    }

    if (callLength < 1) {
      return false;
    }

    if (end - callStart < callLength) {
      return false;
    }

    long name = tokenAtRange(callStart, callLength, count, kinds, starts, lengths);
    if (name < first + headTokens) {
      return false;
    }

    long close = name + 2;
    if (0 < arity) {
      close = name + 1 + arity * 2;
    }

    long last = close + 1;
    if (count - 1 < last) {
      return false;
    }

    if (last + 1 < count) {
      if (starts[last + 1] < end) {
        return false;
      }
    }

    if (completeCallTokenWindow(first, last, end, kinds, starts, lengths) == false) {
      return false;
    }

    if (kinds[first] != 1) {
      return false;
    }

    if (headTokens == 1) {
      if (sourceTokenCode(source, starts, lengths, first) != TOKEN_RETURN) {
        return false;
      }
    }

    if (headTokens == 2) {
      if (
        punctuationAt(source, kinds, starts, first + 1, PUNCTUATION_ASSIGN) == false
      ) {
        return false;
      }
    }

    if (headTokens == 3) {
      long word = sourceTokenCode(source, starts, lengths, first);
      boolean scalar = word == TOKEN_LONG;
      if (word == TOKEN_BOOLEAN) {
        scalar = true;
      }

      if (scalar == false) {
        return false;
      }

      if (kinds[first + 1] != 1) {
        return false;
      }

      if (
        punctuationAt(source, kinds, starts, first + 2, PUNCTUATION_ASSIGN) == false
      ) {
        return false;
      }
    }

    if (callPrefixValid(source, kinds, starts, first + headTokens, name) == false) {
      return false;
    }

    if (
      punctuationAt(source, kinds, starts, name + 1, PUNCTUATION_OPEN_PAREN) == false
    ) {
      return false;
    }

    if (
      punctuationAt(source, kinds, starts, close, PUNCTUATION_CLOSE_PAREN) == false
    ) {
      return false;
    }

    if (punctuationAt(source, kinds, starts, last, PUNCTUATION_SEMICOLON) == false) {
      return false;
    }

    long argument = 0;
    while (argument < arity) limit SOURCE_CALL_ARITY_LIMIT {
      long token = name + 2 + argument * 2;
      if (kinds[token] != 1) {
        return false;
      }

      argument += 1;
      if (argument < arity) {
        if (
          punctuationAt(source, kinds, starts, token + 1, PUNCTUATION_COMMA) == false
        ) {
          return false;
        }
      }
    }

    return true;
  }

  private long argumentType(
    borrow utf8 source,
    long owner,
    long local,
    long valueCount,
    borrow mut words valueRows,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long sourceType = loopBodyValueType(
      source,
      owner,
      local,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (sourceType == TOKEN_LONG) {
      return TYPE_SIGNED;
    }

    if (sourceType == TOKEN_BOOLEAN) {
      return TYPE_BOOLEAN;
    }

    boolean storageLoan = sourceType == TOKEN_REGION;
    if (sourceType == TOKEN_LONGMAP) {
      storageLoan = true;
    }

    if (storageLoan) {
      boolean borrowed = borrowedLoopBodyLocal(
        source,
        owner,
        local,
        valueCount,
        valueRows,
        tokenCount,
        tokenStarts,
        tokenLengths
      );
      if (borrowed == false) {
        return -1;
      }

      if (sourceType == TOKEN_REGION) {
        return TYPE_REGION_BORROW;
      }

      return TYPE_LONG_MAP_BORROW;
    }

    return directBufferLocalType(
      source,
      owner,
      local,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
  }

  /// Publishes ordered identifier arguments, exact types, and defining values atomically.
  public SourceCallArgumentPlan materializeSourceCallArgumentProducts(
    borrow utf8 source,
    long callSourceBase,
    long callCount,
    borrow mut words callRows,
    borrow mut words callStatements,
    long statementCount,
    borrow mut words statementRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words callArgumentStarts,
    borrow mut words callArgumentCounts,
    borrow mut words argumentRows,
    borrow mut words argumentValueProducts
  ) {
    assert(-1 < callSourceBase);
    assert(-1 < callCount);
    assert(callCount < CALL_COUNT_LIMIT + 1);
    assert(bufferLength(callRows) == CALL_ROWS);
    assert(bufferLength(callStatements) == CALL_COUNT_LIMIT);
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == STATEMENT_ROWS);
    assert(-1 < valueCount);
    assert(valueCount < MAX_VALUES + 1);
    assert(bufferLength(valueRows) == VALUE_ROWS);
    assert(bufferLength(callArgumentStarts) == CALL_COUNT_LIMIT);
    assert(bufferLength(callArgumentCounts) == CALL_COUNT_LIMIT);
    assert(bufferLength(argumentRows) == SOURCE_CALL_ARGUMENT_ROWS);
    assert(bufferLength(argumentValueProducts) == SOURCE_CALL_ARGUMENT_ROWS);

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 7);
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words stagedStarts = allocate(staging, CALL_COUNT_LIMIT);
    words stagedCounts = allocate(staging, CALL_COUNT_LIMIT);
    words stagedArguments = allocate(staging, SOURCE_CALL_ARGUMENT_ROWS);
    words stagedValues = allocate(staging, SOURCE_CALL_ARGUMENT_ROWS);
    long tokenCount = scanSemanticTokens(source, tokenKinds, tokenStarts, tokenLengths);
    boolean valid = -1 < tokenCount;
    long argumentCount = 0;
    long call = 0;
    while (call < callCount) limit CALL_COUNT_LIMIT {
      long statement = callStatements[call];
      if (statement < 0) {
        valid = false;
      }

      if (statementCount - 1 < statement) {
        valid = false;
      }

      long arity = callRows[512 + call];
      if (arity < 0) {
        valid = false;
      }

      if (SOURCE_CALL_ARITY_LIMIT < arity) {
        valid = false;
      }

      if (SOURCE_CALL_ARGUMENT_LIMIT - argumentCount < arity) {
        valid = false;
      }

      set(stagedStarts, call, argumentCount);
      set(stagedCounts, call, arity);
      if (valid) {
        long callStart = callSourceBase + callRows[call];
        long nameToken = tokenAtRange(
          callStart,
          callRows[256 + call],
          tokenCount,
          tokenKinds,
          tokenStarts,
          tokenLengths
        );
        if (nameToken < 0) {
          valid = false;
        } else {
          long open = nameToken + 1;
          if (tokenCount - 1 < open) {
            valid = false;
          } else {
            if (
              punctuationAt(source, tokenKinds, tokenStarts, open, PUNCTUATION_OPEN_PAREN) == false
            ) {
              valid = false;
            }
          }

          long argument = 0;
          long token = open + 1;
          while (argument < arity) limit SOURCE_CALL_ARITY_LIMIT {
            if (tokenCount - 1 < token) {
              valid = false;
            }

            if (valid) {
              if (tokenKinds[token] != 1) {
                valid = false;
              } else {
                long owner = statementRows[statement];
                long selectedValue = visibleValue(
                  source,
                  owner,
                  tokenStarts[token],
                  tokenLengths[token],
                  valueCount,
                  valueRows
                );
                if (selectedValue < 0) {
                  valid = false;
                } else {
                  long type = argumentType(
                    source,
                    owner,
                    valueRows[3072 + selectedValue],
                    valueCount,
                    valueRows,
                    tokenCount,
                    tokenStarts,
                    tokenLengths
                  );
                  if (type < 0) {
                    valid = false;
                  }

                  set(stagedArguments, argumentCount, valueRows[3072 + selectedValue]);
                  set(stagedArguments, SOURCE_CALL_ARGUMENT_TYPE_ROW + argumentCount, type);
                  set(stagedValues, argumentCount, selectedValue);
                  set(stagedValues, SOURCE_CALL_ARGUMENT_TYPE_ROW + argumentCount, 0);
                }
              }
            }

            argumentCount += 1;
            argument += 1;
            token += 1;
            if (argument < arity) {
              if (
                punctuationAt(source, tokenKinds, tokenStarts, token, PUNCTUATION_COMMA) == false
              ) {
                valid = false;
              }

              token += 1;
            }
          }

          if (
            punctuationAt(source, tokenKinds, tokenStarts, token, PUNCTUATION_CLOSE_PAREN) == false
          ) {
            valid = false;
          }
        }
      }

      call += 1;
    }

    if (valid) {
      call = 0;
      while (call < callCount) limit CALL_COUNT_LIMIT {
        set(callArgumentStarts, call, stagedStarts[call]);
        set(callArgumentCounts, call, stagedCounts[call]);
        call += 1;
      }

      long publishedArgument = 0;
      while (publishedArgument < argumentCount) limit SOURCE_CALL_ARGUMENT_LIMIT {
        set(argumentRows, publishedArgument, stagedArguments[publishedArgument]);
        set(
          argumentRows,
          SOURCE_CALL_ARGUMENT_TYPE_ROW + publishedArgument,
          stagedArguments[SOURCE_CALL_ARGUMENT_TYPE_ROW + publishedArgument]
        );
        set(argumentValueProducts, publishedArgument, stagedValues[publishedArgument]);
        set(
          argumentValueProducts,
          SOURCE_CALL_ARGUMENT_TYPE_ROW + publishedArgument,
          stagedValues[SOURCE_CALL_ARGUMENT_TYPE_ROW + publishedArgument]
        );
        publishedArgument += 1;
      }
    }

    drop(stagedValues);
    drop(stagedArguments);
    drop(stagedCounts);
    drop(stagedStarts);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(staging);
    if (valid == false) {
      return new SourceCallArgumentPlan(0, 0, false);
    }

    return new SourceCallArgumentPlan(callCount, argumentCount, true);
  }
}
