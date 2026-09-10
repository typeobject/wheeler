//! Dispatches source class members at their declaration boundaries.

module wheeler.compiler.source_member_fronts;

import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_callable_fronts;
import wheeler.compiler.source_front_windows;
import wheeler.compiler.source_member_modifiers;
import wheeler.compiler.source_nominal_fronts;
import wheeler.compiler.source_scalar_member_fronts;
import wheeler.compiler.tokens;

classical class SourceMemberFronts {
  /// Carries one syntactic member extent. Zero kind denotes a callable.
  /// Other kinds retain their admitted declaration-word code.
  public record SourceMemberFront(
    long kind,
    long nameToken,
    long parameterClose,
    long bodyOpen,
    long nextToken,
    long effects,
    boolean valid
  ) {}

  private SourceMemberFront invalidMemberFront() {
    return new SourceMemberFront(-1, 0, 0, 0, 0, 0, false);
  }

  /// Locates a complete member front without resolving names, initializers, or method bodies.
  /// Every caller must complete the appropriate semantic products before publication.
  public SourceMemberFront sourceMemberFront(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long start
  ) {
    if (sourceFrontWindowValid(kinds, starts, lengths, count, start) == false) {
      return invalidMemberFront();
    }

    MemberModifiers visibility = sourceVisibilityModifiers(
      source,
      starts,
      lengths,
      start,
      count
    );
    if (visibility.valid == false) {
      return invalidMemberFront();
    }

    long keyword = visibility.nextToken;
    if (keyword == count) {
      return invalidMemberFront();
    }

    long code = sourceTokenCode(source, starts, lengths, keyword);
    boolean scalar = code == TOKEN_STATE;
    if (code == TOKEN_CONST) {
      scalar = true;
    }

    if (code == TOKEN_QREG) {
      scalar = true;
    }

    if (code == TOKEN_THEOREM) {
      scalar = true;
    }

    if (scalar) {
      long scalarEnd = sourceScalarMemberEnd(source, kinds, starts, lengths, count, keyword);
      if (scalarEnd < 0) {
        return invalidMemberFront();
      }

      long scalarName = keyword + 1;
      if (code == TOKEN_STATE) {
        scalarName += 1;
      }

      if (code == TOKEN_CONST) {
        scalarName += 1;
      }

      return new SourceMemberFront(code, scalarName, 0, 0, scalarEnd, 0, true);
    }

    boolean nominal = code == TOKEN_RECORD;
    if (code == TOKEN_VARIANT) {
      nominal = true;
    }

    if (code == TOKEN_ENUM) {
      nominal = true;
    }

    if (nominal) {
      long nominalEnd = sourceNominalMemberEnd(source, kinds, starts, lengths, count, keyword);
      if (nominalEnd < 0) {
        return invalidMemberFront();
      }

      return new SourceMemberFront(code, keyword + 1, 0, 0, nominalEnd, 0, true);
    }

    CallableFront callable = sourceCallableFront(source, kinds, starts, lengths, count, start);
    if (callable.valid == false) {
      return invalidMemberFront();
    }

    return new SourceMemberFront(
      0,
      callable.nameToken,
      callable.parameterClose,
      callable.bodyOpen,
      callable.nextToken,
      callable.effects,
      true
    );
  }
}
