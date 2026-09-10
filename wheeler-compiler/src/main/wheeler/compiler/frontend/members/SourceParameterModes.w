//! Separates parameter loan prefixes from source type syntax.

module wheeler.compiler.source_parameter_modes;

import wheeler.compiler.keyword_tokens;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class SourceParameterModes {
  /// Names the first type token and its explicit value or loan mode.
  public record ParameterPrefix(long typeToken, long mode, boolean valid) {}

  /// Reads an optional borrow prefix before a nonempty type/name window.
  public ParameterPrefix sourceParameterPrefix(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long start,
    long end
  ) {
    if (start < 0) {
      return new ParameterPrefix(0, 0, false);
    }

    if (end < 1) {
      return new ParameterPrefix(0, 0, false);
    }

    if (end - 1 < start) {
      return new ParameterPrefix(0, 0, false);
    }

    if (bufferLength(starts) < end) {
      return new ParameterPrefix(0, 0, false);
    }

    if (bufferLength(lengths) < end) {
      return new ParameterPrefix(0, 0, false);
    }

    long cursor = start;
    long mode = 0;
    if (sourceTokenCode(source, starts, lengths, cursor) == TOKEN_BORROW) {
      mode = 1;
      cursor += 1;
      if (cursor < end) {
        if (sourceTokenCode(source, starts, lengths, cursor) == TOKEN_MUT) {
          mode = 2;
          cursor += 1;
        }
      }
    }

    return new ParameterPrefix(cursor, mode, cursor < end);
  }

  /// Checks the source parameter mode after primitive or nominal type classification.
  /// Nominal names still require binding. A compound type is never a storage loan.
  public boolean sourceParameterModeValid(long baseType, boolean compound, long mode) {
    if (mode == 0) {
      if (compound) {
        return true;
      }

      return baseType != TYPE_BYTE_VIEW;
    }

    if (compound) {
      return false;
    }

    if (mode == 1) {
      if (baseType == TYPE_UTF8) {
        return true;
      }

      if (baseType == TYPE_BYTES) {
        return true;
      }

      return baseType == TYPE_BYTE_VIEW;
    }

    if (mode == 2) {
      if (baseType == TYPE_REGION) {
        return true;
      }

      if (baseType == TYPE_WORDS) {
        return true;
      }

      if (baseType == TYPE_BYTES) {
        return true;
      }

      return baseType == TYPE_LONG_MAP;
    }

    return false;
  }
}
