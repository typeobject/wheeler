//! Parses source type fronts while leaving nominal identity to the binding owner.

module wheeler.compiler.source_type_syntax;

import wheeler.compiler.closure.source_aggregate_syntax;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_front_windows;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class SourceTypeSyntax {
  private const long MAX_SLOT_DEPTH = 256;
  private const long MAX_SLOT_PROBES = MAX_SLOT_DEPTH + 1;
  private const long MAX_ARRAY_LENGTH = 65535;

  /// Names the base-type token window and the end of one complete type spelling.
  /// A negative baseType denotes a nominal name which still requires binding.
  public record SourceTypeFront(
    long nameStartToken,
    long nameEndToken,
    long nextToken,
    long baseType,
    boolean compound,
    boolean valid
  ) {}

  private record TypeSuffix(long nextToken, long kind, boolean valid) {}

  private SourceTypeFront invalidTypeFront() {
    return new SourceTypeFront(0, 0, 0, -1, false, false);
  }

  private long namedTypeEnd(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    long count,
    long start
  ) {
    if (kinds[start] != 1) {
      return -1;
    }

    long cursor = start + 1;
    while (cursor + 1 < count) limit MAX_COMPILER_TOKENS {
      if (punctuationAt(source, kinds, starts, cursor, PUNCTUATION_DOT) == false) {
        break;
      }

      if (kinds[cursor + 1] != 1) {
        return -1;
      }

      cursor += 2;
    }

    if (cursor + 2 < count) {
      if (punctuationAt(source, kinds, starts, cursor, PUNCTUATION_COLON)) {
        if (
          punctuationAt(source, kinds, starts, cursor + 1, PUNCTUATION_COLON) == false
        ) {
          return -1;
        }

        if (kinds[cursor + 2] != 1) {
          return -1;
        }

        return cursor + 3;
      }
    }

    if (cursor != start + 1) {
      return -1;
    }

    return cursor;
  }

  private boolean storageType(long type) {
    if (type == TYPE_REGION) {
      return true;
    }

    if (type == TYPE_WORDS) {
      return true;
    }

    if (type == TYPE_BYTES) {
      return true;
    }

    if (type == TYPE_LONG_MAP) {
      return true;
    }

    if (type == TYPE_UTF8) {
      return true;
    }

    return type == TYPE_BYTE_VIEW;
  }

  private TypeSuffix typeSuffix(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long start
  ) {
    if (start == count) {
      return new TypeSuffix(start, 0, true);
    }

    if (
      punctuationAt(source, kinds, starts, start, PUNCTUATION_OPEN_SQUARE) == false
    ) {
      return new TypeSuffix(start, 0, true);
    }

    long cursor = start + 1;
    if (count < cursor + 1) {
      return new TypeSuffix(0, 0, false);
    }

    if (punctuationAt(source, kinds, starts, cursor, PUNCTUATION_CLOSE_SQUARE)) {
      return new TypeSuffix(cursor + 1, 2, true);
    }

    if (count < cursor + 2) {
      return new TypeSuffix(0, 0, false);
    }

    if (kinds[cursor] != 2) {
      return new TypeSuffix(0, 0, false);
    }

    if (signedNumberValid(source, starts, lengths, cursor) == false) {
      return new TypeSuffix(0, 0, false);
    }

    long length = parsedSignedNumber(source, starts, lengths, cursor);
    if (length < 1) {
      return new TypeSuffix(0, 0, false);
    }

    if (MAX_ARRAY_LENGTH < length) {
      return new TypeSuffix(0, 0, false);
    }

    if (
      punctuationAt(source, kinds, starts, cursor + 1, PUNCTUATION_CLOSE_SQUARE) == false
    ) {
      return new TypeSuffix(0, 0, false);
    }

    return new TypeSuffix(cursor + 2, 1, true);
  }

  /// Parses scanner-owned primitive, nominal, array, slice, and Slot type syntax.
  /// Source syntax bounds do not widen the separate aggregate lowering profile.
  public SourceTypeFront sourceTypeFront(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long start,
    boolean allowVoid
  ) {
    if (sourceFrontWindowValid(kinds, starts, lengths, count, start) == false) {
      return invalidTypeFront();
    }

    long cursor = start;
    long depth = 0;
    boolean slot = false;
    while (cursor + 1 < count) limit MAX_SLOT_PROBES {
      long code = sourceTokenCode(source, starts, lengths, cursor);
      if (code != TOKEN_SLOT) {
        break;
      }

      if (
        punctuationAt(source, kinds, starts, cursor + 1, PUNCTUATION_LESS_THAN) == false
      ) {
        break;
      }

      if (depth == MAX_SLOT_DEPTH) {
        return invalidTypeFront();
      }

      slot = true;
      depth += 1;
      cursor += 2;
    }

    if (count < cursor + 1) {
      return invalidTypeFront();
    }

    long baseStart = cursor;
    long baseEnd = namedTypeEnd(source, kinds, starts, count, cursor);
    if (baseEnd < 0) {
      return invalidTypeFront();
    }

    long baseType = -1;
    if (baseEnd == baseStart + 1) {
      long baseCode = sourceTokenCode(source, starts, lengths, baseStart);
      baseType = primitiveType(baseCode);
      if (baseCode == TOKEN_VOID) {
        if (allowVoid == false) {
          return invalidTypeFront();
        }

        baseType = 0;
      }
    }

    if (slot) {
      boolean payload = baseType == TYPE_SIGNED;
      if (baseType == TYPE_BOOLEAN) {
        payload = true;
      }

      if (baseType == TYPE_DONE) {
        payload = true;
      }

      if (payload == false) {
        return invalidTypeFront();
      }
    }

    TypeSuffix suffix = typeSuffix(source, kinds, starts, lengths, count, baseEnd);
    if (suffix.valid == false) {
      return invalidTypeFront();
    }

    boolean compound = slot;
    if (0 < suffix.kind) {
      compound = true;
      if (storageType(baseType)) {
        return invalidTypeFront();
      }

      if (baseType == 0) {
        return invalidTypeFront();
      }
    }

    cursor = suffix.nextToken;
    while (0 < depth) limit MAX_SLOT_DEPTH {
      if (suffix.kind == 2) {
        return invalidTypeFront();
      }

      if (count < cursor + 1) {
        return invalidTypeFront();
      }

      if (
        punctuationAt(source, kinds, starts, cursor, PUNCTUATION_GREATER_THAN) == false
      ) {
        return invalidTypeFront();
      }

      cursor += 1;
      suffix = typeSuffix(source, kinds, starts, lengths, count, cursor);
      if (suffix.valid == false) {
        return invalidTypeFront();
      }

      cursor = suffix.nextToken;
      depth -= 1;
    }

    return new SourceTypeFront(baseStart, baseEnd, cursor, baseType, compound, true);
  }
}
