//! Separates source member visibility and callable effects from the following type.

module wheeler.compiler.source_member_modifiers;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.tokens;

classical class SourceMemberModifiers {
  /// Marks the program entry method.
  public const long MEMBER_ENTRY = 1;
  /// Marks a reversible classical method.
  public const long MEMBER_REV = MEMBER_ENTRY * 2;
  /// Marks the coherent facet of a reversible method.
  public const long MEMBER_COHERENT = MEMBER_REV * 2;
  /// Marks a test method rather than an ordinary callable.
  public const long MEMBER_TEST = MEMBER_COHERENT * 2;
  /// Marks a unitary circuit declaration.
  public const long MEMBER_UNITARY = MEMBER_TEST * 2;
  /// Marks a dynamic circuit declaration.
  public const long MEMBER_DYNAMIC = MEMBER_UNITARY * 2;

  /// Reports one admitted modifier prefix, not admission of the following member.
  public record MemberModifiers(long nextToken, long effects, boolean exported, boolean valid) {}

  private boolean modifierWindowValid(
    borrow mut words starts,
    borrow mut words lengths,
    long start,
    long end
  ) {
    if (start < 0) {
      return false;
    }

    if (end < start) {
      return false;
    }

    if (MAX_COMPILER_TOKENS < end - start) {
      return false;
    }

    if (bufferLength(starts) < end) {
      return false;
    }

    if (bufferLength(lengths) < end) {
      return false;
    }

    return true;
  }

  /// Consumes visibility words in source order. Any public occurrence exports the member.
  public MemberModifiers sourceVisibilityModifiers(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long start,
    long end
  ) {
    if (modifierWindowValid(starts, lengths, start, end) == false) {
      return new MemberModifiers(0, 0, false, false);
    }

    long cursor = start;
    boolean exported = false;
    while (cursor < end) limit MAX_COMPILER_TOKENS {
      long code = sourceTokenCode(source, starts, lengths, cursor);
      if (code == TOKEN_PUBLIC) {
        exported = true;
      } else {
        if (code == TOKEN_PRIVATE) {} else {
          if (code == TOKEN_PROTECTED) {} else {
            break;
          }
        }
      }

      cursor += 1;
    }

    return new MemberModifiers(cursor, 0, exported, true);
  }

  private long modifierEffect(long code) {
    if (code == TOKEN_STATIC) {
      return 0;
    }

    if (code == TOKEN_ENTRY) {
      return MEMBER_ENTRY;
    }

    if (code == TOKEN_REV) {
      return MEMBER_REV;
    }

    if (code == TOKEN_COHERENT) {
      return MEMBER_COHERENT;
    }

    if (code == TOKEN_TEST) {
      return MEMBER_TEST;
    }

    if (code == TOKEN_UNITARY) {
      return MEMBER_UNITARY;
    }

    if (code == TOKEN_DYNAMIC) {
      return MEMBER_DYNAMIC;
    }

    return -1;
  }

  private boolean callableEffectsValid(long effects) {
    long reversible = effects / MEMBER_REV % 2;
    long coherent = effects / MEMBER_COHERENT % 2;
    if (coherent == 1) {
      if (reversible == 0) {
        return false;
      }
    }

    long kinds = effects % 2 + reversible + effects / MEMBER_TEST % 2 + effects / MEMBER_UNITARY % 2
      + effects / MEMBER_DYNAMIC % 2;
    return kinds < 2;
  }

  /// Consumes visibility and callable modifiers without changing scanner columns.
  /// Duplicate modifiers are idempotent. Distinct method kinds remain mutually exclusive.
  public MemberModifiers sourceCallableModifiers(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long start,
    long end
  ) {
    MemberModifiers visibility = sourceVisibilityModifiers(source, starts, lengths, start, end);
    if (visibility.valid == false) {
      return visibility;
    }

    long cursor = visibility.nextToken;
    long effects = 0;
    while (cursor < end) limit MAX_COMPILER_TOKENS {
      long code = sourceTokenCode(source, starts, lengths, cursor);
      long effect = modifierEffect(code);
      if (effect < 0) {
        break;
      }

      if (0 < effect) {
        long present = effects / effect % 2;
        if (present == 0) {
          effects += effect;
        }
      }

      cursor += 1;
    }

    boolean valid = callableEffectsValid(effects);
    return new MemberModifiers(cursor, effects, visibility.exported, valid);
  }
}
