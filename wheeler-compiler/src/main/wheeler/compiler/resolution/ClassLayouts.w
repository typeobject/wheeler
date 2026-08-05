//! Resolves the bounded class constant, state, helper, and entry layout.

module wheeler.compiler.class_layouts;

import wheeler.compiler.class_constants;
import wheeler.compiler.constant_declarations;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class ClassLayouts {
  private record StateInitialValue(long value, boolean valid) {}

  /// Carries one validated class prefix into entry and helper parsing.
  public record ClassLayout(
    long memberStart,
    long globalNameToken,
    long initialValue,
    long globalCount,
    boolean valid
  ) {}

  private ClassLayout invalidLayout() {
    return new ClassLayout(0, 0, 0, 0, false);
  }

  private long classBodyStart(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    if (tokenHash(source, tokenStarts, tokenLengths, 0) == TOKEN_CLASSICAL) {
      if (tokenHash(source, tokenStarts, tokenLengths, 1) == TOKEN_CLASS) {
        if (tokenKinds[2] == 1) {
          if (tokenLengths[2] < 257) {
            if (
              punctuationAt(source, tokenKinds, tokenStarts, 3, PUNCTUATION_OPEN_BRACE)
            ) {
              return 4;
            }
          }
        }
      }
    }

    return -1;
  }

  private long stateEnd(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long stateStart,
    long tokenCount
  ) {
    if (stateStart + 5 < tokenCount) {} else {
      return -1;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, stateStart) == TOKEN_STATE) {} else {
      return -1;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, stateStart + 1) == TOKEN_LONG) {} else {
      return -1;
    }

    if (tokenKinds[stateStart + 2] == 1) {
      if (tokenLengths[stateStart + 2] < 257) {} else {
        return -1;
      }
    } else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, stateStart + 3, PUNCTUATION_ASSIGN) == false
    ) {
      return -1;
    }

    long initializer = stateStart + 4;
    long width = signedNumberWidth(source, tokenKinds, tokenStarts, initializer);
    if (width < 1) {
      if (tokenKinds[initializer] == 1) {
        width = 1;
      } else {
        return -1;
      }
    }

    long semicolon = initializer + width;
    if (semicolon < tokenCount) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, semicolon, PUNCTUATION_SEMICOLON)
    ) {
      return semicolon + 1;
    }

    return -1;
  }

  private StateInitialValue stateInitialValue(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long stateStart
  ) {
    long initializer = stateStart + 4;
    long width = signedNumberWidth(source, tokenKinds, tokenStarts, initializer);
    if (0 < width) {
      if (signedNumberValid(source, tokenStarts, tokenLengths, initializer)) {
        return new StateInitialValue(
          parsedSignedNumber(source, tokenStarts, tokenLengths, initializer),
          true
        );
      }

      return new StateInitialValue(0, false);
    }

    ConstantResolution constant = resolveClassConstant(
      source,
      tokenStarts,
      tokenLengths,
      initializer,
      true
    );
    return new StateInitialValue(constant.value, constant.valid);
  }

  private ClassLayout finishStateLayout(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long stateStart,
    long memberStart
  ) {
    long name = stateStart + 2;
    if (classConstantNameExists(source, tokenStarts, tokenLengths, name)) {
      return invalidLayout();
    }

    StateInitialValue initial = stateInitialValue(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      stateStart
    );
    if (initial.valid == false) {
      return invalidLayout();
    }

    set(tokenKinds, COMPILER_GLOBAL_NAME_TOKEN, tokenKinds[name]);
    set(tokenStarts, COMPILER_GLOBAL_NAME_TOKEN, tokenStarts[name]);
    set(tokenLengths, COMPILER_GLOBAL_NAME_TOKEN, tokenLengths[name]);
    return new ClassLayout(memberStart, name, initial.value, 1, true);
  }

  /// Resolves constants before or after one optional signed state declaration.
  public ClassLayout resolveClassLayout(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long tokenCount
  ) {
    set(tokenKinds, COMPILER_GLOBAL_NAME_TOKEN, 0);
    set(tokenStarts, COMPILER_GLOBAL_NAME_TOKEN, 0);
    set(tokenLengths, COMPILER_GLOBAL_NAME_TOKEN, 0);
    long bodyStart = classBodyStart(source, tokenKinds, tokenStarts, tokenLengths);
    if (bodyStart < 0) {
      return invalidLayout();
    }

    if (tokenHash(source, tokenStarts, tokenLengths, bodyStart) == TOKEN_STATE) {
      long stateFirstEnd = stateEnd(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        bodyStart,
        tokenCount
      );
      if (stateFirstEnd < 0) {
        return invalidLayout();
      }

      long stateFirstMember = classMemberStart(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        stateFirstEnd,
        tokenCount
      );
      if (stateFirstMember < 0) {
        return invalidLayout();
      }

      return finishStateLayout(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        bodyStart,
        stateFirstMember
      );
    }

    long constantFirstMember = classMemberStart(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      bodyStart,
      tokenCount
    );
    if (constantFirstMember < 0) {
      return invalidLayout();
    }

    if (
      tokenHash(source, tokenStarts, tokenLengths, constantFirstMember) == TOKEN_STATE
    ) {
      long constantFirstEnd = stateEnd(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        constantFirstMember,
        tokenCount
      );
      if (constantFirstEnd < 0) {
        return invalidLayout();
      }

      if (constantToken(source, tokenStarts, tokenLengths, constantFirstEnd) < 0) {} else {
        return invalidLayout();
      }

      return finishStateLayout(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        constantFirstMember,
        constantFirstEnd
      );
    }

    return new ClassLayout(constantFirstMember, 0, 0, 0, true);
  }
}
