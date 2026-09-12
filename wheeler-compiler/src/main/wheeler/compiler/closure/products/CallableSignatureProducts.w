//! Parses canonical callable result, effect, parameter-type, and loan products.

module wheeler.compiler.closure.callable_signature_products;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.source_member_modifiers;
import wheeler.compiler.source_member_names;
import wheeler.compiler.source_parameter_modes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.source_type_syntax;
import wheeler.compiler.tokens;

classical class CallableSignatureProducts {
  /// Caps one callable signature at sixty-four parameters.
  public const long MAX_CALLABLE_PARAMETERS = 64;
  /// Caps all parameter products in one closure.
  public const long MAX_CLOSURE_PARAMETERS = 16384;

  /// Counts parameters in one structurally validated callable header.
  public long parameterCount(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long open,
    long close
  ) {
    if (open + 1 == close) {
      return 0;
    }

    long count = 1;
    long depth = 1;
    long cursor = open + 1;
    while (cursor < close) limit MAX_COMPILER_TOKENS {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_OPEN_PAREN)
      ) {
        depth += 1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_CLOSE_PAREN)
      ) {
        depth -= 1;
      }

      if (depth == 1) {
        if (
          punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_COMMA)
        ) {
          count += 1;
        }
      }

      cursor += 1;
    }

    if (count < MAX_CALLABLE_PARAMETERS + 1) {
      return count;
    }

    return -1;
  }

  /// Identifies one result type and its canonical effect mask.
  public record CallableHeader(
    long resultTypeToken,
    long effects,
    boolean exported,
    boolean valid
  ) {}

  /// Separates visibility and effect modifiers from a callable result type.
  public CallableHeader callableHeader(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declarationStart,
    long nameToken
  ) {
    if (nameToken < bufferLength(tokenStarts)) {} else {
      return new CallableHeader(0, 0, false, false);
    }

    if (nameToken < bufferLength(tokenLengths)) {} else {
      return new CallableHeader(0, 0, false, false);
    }

    MemberModifiers modifiers = sourceCallableModifiers(
      source,
      tokenStarts,
      tokenLengths,
      declarationStart,
      nameToken
    );
    if (modifiers.valid) {
      if (modifiers.nextToken < nameToken) {
        return new CallableHeader(
          modifiers.nextToken,
          modifiers.effects,
          modifiers.exported,
          true
        );
      }
    }

    return new CallableHeader(0, 0, false, false);
  }

  /// Publishes canonical parameter type ranges and owner or loan modes.
  public long writeParameterProducts(
    borrow utf8 source,
    long archiveSourceStart,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long open,
    long close,
    long expectedCount,
    long firstParameter,
    borrow mut words parameterTypeStarts,
    borrow mut words parameterTypeLengths,
    borrow mut words parameterModes
  ) {
    long cursor = open + 1;
    long written = 0;
    while (cursor < close) limit MAX_CALLABLE_PARAMETERS {
      long segmentStart = cursor;
      while (cursor < close) limit MAX_COMPILER_TOKENS {
        if (
          punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_COMMA)
        ) {
          break;
        }

        cursor += 1;
      }

      long nameToken = cursor - 1;
      if (segmentStart < nameToken) {} else {
        return -1;
      }

      if (
        sourceValueNameValid(source, tokenKinds, tokenStarts, tokenLengths, nameToken) == false
      ) {
        return -1;
      }

      ParameterPrefix prefix = sourceParameterPrefix(
        source,
        tokenStarts,
        tokenLengths,
        segmentStart,
        nameToken
      );
      if (prefix.valid == false) {
        return -1;
      }

      long typeToken = prefix.typeToken;
      long mode = prefix.mode;
      SourceTypeFront type = sourceTypeFront(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        nameToken,
        typeToken,
        false
      );
      if (type.valid == false) {
        return -1;
      }

      if (type.nextToken != nameToken) {
        return -1;
      }

      if (sourceParameterModeValid(type.baseType, type.compound, mode) == false) {
        return -1;
      }

      long parameter = firstParameter + written;
      if (parameter < MAX_CLOSURE_PARAMETERS) {} else {
        return -1;
      }

      long finalTypeToken = nameToken - 1;
      long typeStart = tokenStarts[typeToken];
      long typeEnd = tokenStarts[finalTypeToken] + tokenLengths[finalTypeToken];
      set(parameterTypeStarts, parameter, archiveSourceStart + typeStart);
      set(parameterTypeLengths, parameter, typeEnd - typeStart);
      set(parameterModes, parameter, mode);
      written += 1;
      cursor += 1;
    }

    if (written == expectedCount) {
      return firstParameter + written;
    }

    return -1;
  }

}
