//! Resolves signed assertion values without using a numeric value as invalidity.

module wheeler.compiler.signed_assertion_values;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.class_constants;
import wheeler.compiler.class_layouts;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.helper_abi;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.local_resolution;
import wheeler.compiler.signed_ordering_kinds;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class SignedAssertionValues {
  /// Retains a value or slot index separately from its origin and validity.
  public record SignedAssertionValue(long kind, long value, boolean valid) {}

  /// Admits a bound operand against the helper's retained parameter types.
  public boolean signedAssertionParameterValid(
    long kind,
    long value,
    long[16] parameterTypes,
    long parameterCount
  ) {
    if (parameterCount < 0) {
      return false;
    }

    if (MAX_SCALAR_HELPER_PARAMETERS < parameterCount) {
      return false;
    }

    if (signedOrderingValueValid(kind, value)) {} else {
      return false;
    }

    if (kind == ASSERTION_LOCAL) {
      if (value < parameterCount) {
        return parameterTypes[value] == TYPE_SIGNED;
      }
    }

    return true;
  }

  /// Binds a scalar token against canonical columns and prior declaration markers.
  /// Non-Boolean parameter markers require the retained helper type check before emission.
  public SignedAssertionValue resolveSignedAssertionValue(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut words previousStarts,
    long previousCount,
    long token
  ) {
    SignedAssertionValue invalid = new SignedAssertionValue(-1, 0, false);
    if (bufferLength(starts) < MAX_COMPILER_TOKENS) {
      return invalid;
    }

    if (bufferLength(lengths) < MAX_COMPILER_TOKENS) {
      return invalid;
    }

    if (token < 0) {
      return invalid;
    }

    if (token < MAX_COMPILER_TOKENS) {} else {
      return invalid;
    }

    if (starts[token] < 0) {
      return invalid;
    }

    if (lengths[token] < 1) {
      return invalid;
    }

    if (bufferLength(source) - starts[token] < lengths[token]) {
      return invalid;
    }

    long names = priorDeclarationNameCount(
      source,
      starts,
      lengths,
      previousStarts,
      previousCount,
      token
    );
    if (names < 0) {
      return invalid;
    }

    long scalar = utf8Scalar(source, starts[token]);
    boolean number = scalar == PUNCTUATION_MINUS;
    if (47 < scalar) {
      if (scalar < 58) {
        number = true;
      }
    }

    if (number) {
      if (signedNumberValid(source, starts, lengths, token)) {
        return new SignedAssertionValue(
          ASSERTION_LITERAL,
          parsedSignedNumber(source, starts, lengths, token),
          true
        );
      }

      return invalid;
    }

    // Value syntax wins here without restricting admitted declaration names.
    long wordCode = sourceTokenCode(source, starts, lengths, token);
    if (booleanTokenCode(wordCode)) {
      return invalid;
    }

    if (wordCode == TOKEN_NEW) {
      return invalid;
    }

    if (0 < names) {
      if (names == 1) {} else {
        return invalid;
      }

      long local = resolvePriorDeclaration(
        source,
        starts,
        lengths,
        previousStarts,
        previousCount,
        token,
        true
      );
      if (local < 0) {
        return invalid;
      }

      if (signedOrderingValueValid(ASSERTION_LOCAL, local)) {} else {
        return invalid;
      }

      return new SignedAssertionValue(ASSERTION_LOCAL, local, true);
    }

    if (namesClassState(source, starts, lengths, token)) {
      return new SignedAssertionValue(ASSERTION_GLOBAL, 0, true);
    }

    ConstantResolution constant = resolveClassConstant(source, starts, lengths, token, true);
    if (constant.valid) {
      return new SignedAssertionValue(ASSERTION_LITERAL, constant.value, true);
    }

    return invalid;
  }
}
