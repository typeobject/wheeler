//! Binds source-local signed state initializers from shared fronts and scoped constants.

module wheeler.compiler.closure.source_global_products;

import wheeler.compiler.closure.source_global_schema;
import wheeler.compiler.closure.source_string_ranges;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.constant_expressions;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.module_headers;
import wheeler.compiler.module_linker;
import wheeler.compiler.source_member_fronts;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class SourceGlobalProducts {
  private const long MODULE_RANGE_WORDS = 2;
  private const long FRONT_COLUMNS = 2;

  /// Sizes private module coordinates and two declaration-front columns.
  public const long SOURCE_GLOBAL_FRONT_ROWS = MODULE_RANGE_WORDS + MAX_SOURCE_GLOBALS
    * FRONT_COLUMNS;

  private const long WORD_BYTES = 8;
  private const long STAGING_BYTES = SOURCE_GLOBAL_ROWS * WORD_BYTES + SOURCE_GLOBAL_NAMES;
  private const long STAGING_BUFFERS = 2;
  private const long FRONT_NAME_ROW = MODULE_RANGE_WORDS;
  private const long FRONT_END_ROW = FRONT_NAME_ROW + MAX_SOURCE_GLOBALS;
  private const long CLASS_PREFIX_TOKENS = 4;
  private const long INITIALIZER_OFFSET = 2;
  private const long TERMINATOR_TOKENS = 1;
  private const long ASCII_RADIX = 128;

  /// Reports one complete declaration-ordered state window and its copied name extent.
  public record SourceGlobalPlan(long globalCount, long nameBytes, boolean valid) {}

  private void clearScratch(
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut words fronts
  ) {
    long token = 0;
    while (token < MAX_COMPILER_TOKENS) limit MAX_COMPILER_TOKENS {
      set(kinds, token, 0);
      set(starts, token, 0);
      set(lengths, token, 0);
      token += 1;
    }

    long front = 0;
    while (front < SOURCE_GLOBAL_FRONT_ROWS) limit SOURCE_GLOBAL_FRONT_ROWS {
      set(fronts, front, 0);
      front += 1;
    }
  }

  private SourceGlobalPlan bindGlobals(
    borrow utf8 source,
    borrow byteview constantNames,
    borrow mut words constants,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut words fronts,
    long globalCount,
    long nameStart,
    borrow mut bytes names,
    long productStart,
    borrow mut words products
  ) {
    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ STAGING_BUFFERS);
    words staged = allocate(staging, SOURCE_GLOBAL_ROWS);
    bytes copiedNames = allocateBytes(staging, SOURCE_GLOBAL_NAMES);
    boolean valid = true;
    long nameBytes = 0;
    long global = 0;
    while (global < globalCount) limit MAX_SOURCE_GLOBALS {
      long nameToken = fronts[FRONT_NAME_ROW + global];
      long length = lengths[nameToken];
      ExpressionValue initial = evaluateScalarExpressionWithProducts(
        source,
        starts,
        lengths,
        /* firstDeclaration= */ 0,
        /* memberStart= */ 0,
        nameToken + INITIALIZER_OFFSET,
        fronts[FRONT_END_ROW + global] - TERMINATOR_TOKENS,
        constantNames,
        constants
      );
      if (initial.valid == false) {
        valid = false;
        break;
      }

      if (initial.signed == false) {
        valid = false;
        break;
      }

      long copied = 0;
      while (copied < length) limit SOURCE_GLOBAL_NAME_BYTES {
        long scalar = utf8Scalar(source, starts[nameToken] + copied);
        if (ASCII_RADIX < scalar + 1) {
          valid = false;
          break;
        }

        setByte(copiedNames, nameBytes + copied, scalar);
        copied += 1;
      }

      long earlier = 0;
      while (earlier < global) limit MAX_SOURCE_GLOBALS {
        if (staged[SOURCE_GLOBAL_LENGTH_ROW + earlier] == length) {
          if (
            compareSourceStringRanges(
              copiedNames,
              staged[earlier],
              length,
              copiedNames,
              nameBytes,
              length
            ) == 0
          ) {
            valid = false;
            break;
          }
        }

        earlier += 1;
      }

      if (valid == false) {
        break;
      }

      set(staged, global, nameBytes);
      set(staged, SOURCE_GLOBAL_LENGTH_ROW + global, length);
      set(staged, SOURCE_GLOBAL_VALUE_ROW + global, initial.value);
      set(staged, SOURCE_GLOBAL_DECLARATION_ROW + global, starts[nameToken]);
      nameBytes += length;
      global += 1;
    }

    if (bufferLength(names) - nameStart < nameBytes) {
      valid = false;
    }

    clearScratch(kinds, starts, lengths, fronts);
    if (valid == false) {
      globalCount = 0;
      nameBytes = 0;
    }

    SourceGlobalPlan result = new SourceGlobalPlan(globalCount, nameBytes, valid);
    if (valid) {
      long nameByte = 0;
      while (nameByte < nameBytes) limit SOURCE_GLOBAL_NAMES {
        setByte(names, nameStart + nameByte, copiedNames[nameByte]);
        nameByte += 1;
      }

      long published = 0;
      while (published < globalCount) limit MAX_SOURCE_GLOBALS {
        set(products, productStart + published, nameStart + staged[published]);
        set(
          products,
          productStart + SOURCE_GLOBAL_LENGTH_ROW + published,
          staged[SOURCE_GLOBAL_LENGTH_ROW + published]
        );
        set(
          products,
          productStart + SOURCE_GLOBAL_VALUE_ROW + published,
          staged[SOURCE_GLOBAL_VALUE_ROW + published]
        );
        set(
          products,
          productStart + SOURCE_GLOBAL_DECLARATION_ROW + published,
          staged[SOURCE_GLOBAL_DECLARATION_ROW + published]
        );
        published += 1;
      }
    }

    drop(copiedNames);
    drop(staged);
    drop(staging);
    return result;
  }

  /// Binds every state front without reading dependency bodies or treating state as constant.
  /// Supplied scalar products must already include visible local and imported constants.
  /// Effects: clears private scanner scratch on return and publishes only a valid batch.
  /// Caller name prefixes, product prefixes, and unused tails survive success and rejection.
  /// A state-free source consumes no additional owned buffer or region.
  public SourceGlobalPlan materializeSourceGlobalProducts(
    borrow utf8 source,
    borrow byteview constantNames,
    borrow mut words constants,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut words fronts,
    long nameStart,
    borrow mut bytes names,
    long productStart,
    borrow mut words products
  ) {
    assert(bufferLength(kinds) == MAX_COMPILER_TOKENS);
    assert(bufferLength(starts) == MAX_COMPILER_TOKENS);
    assert(bufferLength(lengths) == MAX_COMPILER_TOKENS);
    assert(SOURCE_GLOBAL_FRONT_ROWS - 1 < bufferLength(fronts));
    assert(-1 < nameStart);
    assert(nameStart < bufferLength(names) + 1);
    assert(-1 < productStart);
    assert(productStart < bufferLength(products) + 1);
    assert(SOURCE_GLOBAL_ROWS < bufferLength(products) - productStart + 1);

    long tokenCount = scanSemanticTokens(source, kinds, starts, lengths);
    boolean valid = 0 < tokenCount;
    long body = -1;
    if (valid) {
      body = moduleBodyStart(source, kinds, starts, lengths, fronts, tokenCount);
      valid = -1 < body;
    }

    if (valid) {
      valid = classPrefixValid(source, kinds, starts, lengths, body, tokenCount);
    }

    long cursor = body + CLASS_PREFIX_TOKENS;
    long globalCount = 0;
    boolean closed = false;
    while (valid) limit MAX_COMPILER_TOKENS {
      if (cursor < tokenCount) {} else {
        valid = false;
        break;
      }

      if (punctuationAt(source, kinds, starts, cursor, PUNCTUATION_CLOSE_BRACE)) {
        closed = cursor + 1 == tokenCount;
        break;
      }

      SourceMemberFront front = sourceMemberFront(
        source,
        kinds,
        starts,
        lengths,
        tokenCount,
        cursor
      );
      if (front.valid == false) {
        valid = false;
        break;
      }

      if (front.kind == TOKEN_STATE) {
        if (MAX_SOURCE_GLOBALS < globalCount + 1) {
          valid = false;
          break;
        }

        if (SOURCE_GLOBAL_NAME_BYTES < lengths[front.nameToken]) {
          valid = false;
          break;
        }

        set(fronts, FRONT_NAME_ROW + globalCount, front.nameToken);
        set(fronts, FRONT_END_ROW + globalCount, front.nextToken);
        globalCount += 1;
      }

      cursor = front.nextToken;
    }

    if (closed == false) {
      valid = false;
    }

    if (valid == false) {
      clearScratch(kinds, starts, lengths, fronts);
      return new SourceGlobalPlan(0, 0, false);
    }

    if (globalCount == 0) {
      clearScratch(kinds, starts, lengths, fronts);
      return new SourceGlobalPlan(0, 0, true);
    }

    return bindGlobals(
      source,
      constantNames,
      constants,
      kinds,
      starts,
      lengths,
      fronts,
      globalCount,
      nameStart,
      names,
      productStart,
      products
    );
  }
}
