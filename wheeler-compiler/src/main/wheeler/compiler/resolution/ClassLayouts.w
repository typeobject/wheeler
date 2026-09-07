//! Resolves the bounded class constant, state, helper, and entry layout.

module wheeler.compiler.class_layouts;

import wheeler.compiler.class_constants;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.constant_declarations;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class ClassLayouts {
  private record StateInitialValue(long value, boolean valid) {}

  /// Separates constant ranges from the optional state before executable members.
  public record ClassPrelude(
    long constantStart,
    long constantEnd,
    long memberStart,
    long stateStart,
    long stateEnd,
    boolean valid
  ) {}

  /// Carries one validated class prefix into entry and helper parsing.
  public record ClassLayout(
    long memberStart,
    long globalNameToken,
    long initialValue,
    long globalCount,
    boolean valid
  ) {}

  /// Matches the retained class-state name without treating an absent slot as source offset zero.
  public boolean namesClassState(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long name
  ) {
    if (bufferLength(tokenStarts) < COMPILER_GLOBAL_NAME_TOKEN + 1) {
      return false;
    }

    if (bufferLength(tokenLengths) < COMPILER_GLOBAL_NAME_TOKEN + 1) {
      return false;
    }

    if (tokenLengths[COMPILER_GLOBAL_NAME_TOKEN] < 1) {
      return false;
    }

    return sameTokenText(source, tokenStarts, tokenLengths, COMPILER_GLOBAL_NAME_TOKEN, name);
  }

  /// Checks one name against admitted class constants and the retained class state.
  public boolean classValueNameExists(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long name
  ) {
    if (classConstantNameExists(source, tokenStarts, tokenLengths, name)) {
      return true;
    }

    return namesClassState(source, tokenStarts, tokenLengths, name);
  }

  private ClassLayout invalidLayout() {
    return new ClassLayout(0, 0, 0, 0, false);
  }

  private ClassPrelude invalidPrelude() {
    return new ClassPrelude(0, 0, 0, -1, -1, false);
  }

  private long classBodyStart(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    if (sourceTokenCode(source, tokenStarts, tokenLengths, 0) == TOKEN_CLASSICAL) {
      if (sourceTokenCode(source, tokenStarts, tokenLengths, 1) == TOKEN_CLASS) {
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

    if (sourceTokenCode(source, tokenStarts, tokenLengths, stateStart) == TOKEN_STATE) {} else {
      return -1;
    }

    if (
      sourceTokenCode(source, tokenStarts, tokenLengths, stateStart + 1) == TOKEN_LONG
    ) {} else {
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

    return scalarInitializerEnd(source, tokenStarts, tokenLengths, stateStart + 4, tokenCount);
  }

  private long singleStateValueEnd(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long stateStart
  ) {
    long initializer = stateStart + 4;
    long width = signedNumberWidth(source, tokenKinds, tokenStarts, initializer);
    if (width < 1) {
      if (tokenKinds[initializer] == 1) {
        width = 1;
      } else {
        return -1;
      }
    }

    return initializer + width + 1;
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

  /// Locates one bounded constant/state envelope without binding names or values.
  /// Final linked class validation owns duplicate names, values, and global metadata.
  public ClassPrelude resolveClassPrelude(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long tokenCount
  ) {
    if (tokenCount < 1) {
      return invalidPrelude();
    }

    if (MAX_COMPILER_TOKENS < tokenCount) {
      return invalidPrelude();
    }

    if (firstDeclaration < 0) {
      return invalidPrelude();
    }

    if (firstDeclaration < tokenCount) {} else {
      return invalidPrelude();
    }

    if (bufferLength(tokenKinds) < MAX_COMPILER_TOKENS) {
      return invalidPrelude();
    }

    if (bufferLength(tokenStarts) < MAX_COMPILER_TOKENS) {
      return invalidPrelude();
    }

    if (bufferLength(tokenLengths) < MAX_COMPILER_TOKENS) {
      return invalidPrelude();
    }

    if (
      sourceTokenCode(source, tokenStarts, tokenLengths, firstDeclaration) == TOKEN_STATE
    ) {
      long stateFirstEnd = stateEnd(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        firstDeclaration,
        tokenCount
      );
      if (stateFirstEnd < 0) {
        return invalidPrelude();
      }

      long stateFirstMember = constantPrefixEnd(
        source,
        tokenStarts,
        tokenLengths,
        stateFirstEnd,
        tokenCount
      );
      if (stateFirstMember < 0) {
        return invalidPrelude();
      }

      if (stateFirstMember < tokenCount) {} else {
        return invalidPrelude();
      }

      if (
        sourceTokenCode(source, tokenStarts, tokenLengths, stateFirstMember) == TOKEN_STATE
      ) {
        return invalidPrelude();
      }

      return new ClassPrelude(
        stateFirstEnd,
        stateFirstMember,
        stateFirstMember,
        firstDeclaration,
        stateFirstEnd,
        true
      );
    }

    long constantFirstMember = constantPrefixEnd(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      tokenCount
    );
    if (constantFirstMember < 0) {
      return invalidPrelude();
    }

    if (constantFirstMember < tokenCount) {} else {
      return invalidPrelude();
    }

    if (
      sourceTokenCode(source, tokenStarts, tokenLengths, constantFirstMember) == TOKEN_STATE
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
        return invalidPrelude();
      }

      if (constantFirstEnd < tokenCount) {} else {
        return invalidPrelude();
      }

      if (constantToken(source, tokenStarts, tokenLengths, constantFirstEnd) < 0) {} else {
        return invalidPrelude();
      }

      if (
        sourceTokenCode(source, tokenStarts, tokenLengths, constantFirstEnd) == TOKEN_STATE
      ) {
        return invalidPrelude();
      }

      return new ClassPrelude(
        firstDeclaration,
        constantFirstMember,
        constantFirstEnd,
        constantFirstMember,
        constantFirstEnd,
        true
      );
    }

    return new ClassPrelude(
      firstDeclaration,
      constantFirstMember,
      constantFirstMember,
      -1,
      -1,
      true
    );
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
    ClassPrelude prelude = resolveClassPrelude(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      bodyStart,
      tokenCount
    );
    if (prelude.valid == false) {
      return invalidLayout();
    }

    if (-1 < prelude.stateStart) {
      long valueEnd = singleStateValueEnd(source, tokenKinds, tokenStarts, prelude.stateStart);
      if (valueEnd == prelude.stateEnd) {} else {
        return invalidLayout();
      }
    }

    long constantEnd = classMemberStart(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      prelude.constantStart,
      tokenCount
    );
    if (constantEnd == prelude.constantEnd) {} else {
      return invalidLayout();
    }

    if (-1 < prelude.stateStart) {
      return finishStateLayout(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        prelude.stateStart,
        prelude.memberStart
      );
    }

    return new ClassLayout(prelude.memberStart, 0, 0, 0, true);
  }
}
