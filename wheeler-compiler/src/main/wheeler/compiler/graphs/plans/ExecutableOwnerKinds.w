//! Classifies physical executable owners without resolving their dependencies.

module wheeler.compiler.graphs.executable_owner_kinds;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.constant_declarations;
import wheeler.compiler.helper_abi;
import wheeler.compiler.module_headers;
import wheeler.compiler.module_linker;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class ExecutableOwnerKinds {
  private const long EXECUTABLE_KIND_ARENA_BYTES = 98400;

  /// Carries one validated module and its complete scalar-helper count, when applicable.
  public record ExecutableOwnerKind(
    long moduleStart,
    long moduleLength,
    long helperCount,
    boolean executable,
    boolean valid
  ) {}

  /// Returns the token after one complete bounded executable member.
  public long executableFunctionEnd(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long start,
    long closeToken
  ) {
    long cursor = start;
    while (cursor < closeToken) limit MAX_COMPILER_TOKENS {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_OPEN_BRACE)
      ) {
        long depth = 1;
        cursor += 1;
        while (cursor < closeToken) limit MAX_COMPILER_TOKENS {
          if (
            punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_OPEN_BRACE)
          ) {
            depth += 1;
          }

          if (
            punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_CLOSE_BRACE)
          ) {
            depth -= 1;
            if (depth == 0) {
              return cursor + 1;
            }
          }

          cursor += 1;
        }

        return -1;
      }

      cursor += 1;
    }

    return -1;
  }

  /// Classifies executable members without requiring imported constants or helpers.
  public ExecutableOwnerKind classifyExecutableOwner(borrow utf8 source) {
    region scratch = new region(/* bytes= */ EXECUTABLE_KIND_ARENA_BYTES, /* allocations= */ 4);
    words tokenKinds = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(scratch, MAX_COMPILER_TOKENS);
    words module = allocate(scratch, 2);
    long tokenCount = scanSemanticTokens(source, tokenKinds, tokenStarts, tokenLengths);
    ExecutableOwnerKind result = new ExecutableOwnerKind(0, 0, 0, false, false);
    if (-1 < tokenCount) {
      long body = moduleBodyStart(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        module,
        tokenCount
      );
      if (-1 < body) {
        long member = body + 4;
        long constantCount = 0;
        boolean declarationsValid = true;
        while (constantCount < MAX_CLASS_CONSTANTS) limit MAX_CLASS_CONSTANTS {
          if (constantToken(source, tokenStarts, tokenLengths, member) < 0) {
            constantCount = MAX_CLASS_CONSTANTS;
          } else {
            long next = constantDeclarationEnd(
              source,
              tokenStarts,
              tokenLengths,
              member,
              tokenCount
            );
            if (member < next) {
              member = next;
            } else {
              declarationsValid = false;
              constantCount = MAX_CLASS_CONSTANTS;
            }
          }

          constantCount += 1;
        }

        if (declarationsValid) {
          long closeToken = tokenCount - 1;
          boolean executable = member < closeToken;
          long helperCount = 0;
          boolean helperMembers = true;
          boolean scanningHelpers = member < closeToken;
          while (scanningHelpers) limit MAX_SCALAR_HELPERS {
            long helperNext = executableFunctionEnd(
              source,
              tokenKinds,
              tokenStarts,
              member,
              closeToken
            );
            if (member < helperNext) {
              member = helperNext;
              helperCount += 1;
            } else {
              helperMembers = false;
              member = closeToken;
            }

            scanningHelpers = member < closeToken;
            if (helperCount == MAX_SCALAR_HELPERS) {
              scanningHelpers = false;
            }
          }

          if (member < closeToken) {
            helperMembers = false;
            member = closeToken;
          }

          if (helperMembers == false) {
            helperCount = 0;
          }

          if (member == closeToken) {
            result = new ExecutableOwnerKind(
              module[0],
              module[1],
              helperCount,
              executable,
              true
            );
          }
        }
      }
    }

    drop(module);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(scratch);
    return result;
  }
}
