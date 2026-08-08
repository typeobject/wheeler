//! Classifies physical executable owners without resolving their dependencies.

module wheeler.compiler.graphs.executable_owner_kinds;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.constant_declarations;
import wheeler.compiler.module_headers;
import wheeler.compiler.module_linker;

classical class ExecutableOwnerKinds {
  private const long EXECUTABLE_KIND_ARENA_BYTES = 98400;

  /// Carries one validated physical module name and executable-member bit.
  public record ExecutableOwnerKind(
    long moduleStart,
    long moduleLength,
    boolean executable,
    boolean valid
  ) {}

  /// Classifies executable members without requiring imported constants or helpers.
  public ExecutableOwnerKind classifyExecutableOwner(borrow utf8 source) {
    region scratch = new region(/* bytes= */ EXECUTABLE_KIND_ARENA_BYTES, /* allocations= */ 4);
    words tokenKinds = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(scratch, MAX_COMPILER_TOKENS);
    words module = allocate(scratch, 2);
    long tokenCount = scanSemanticTokens(source, tokenKinds, tokenStarts, tokenLengths);
    ExecutableOwnerKind result = new ExecutableOwnerKind(0, 0, false, false);
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
          if (member < tokenCount) {
            result = new ExecutableOwnerKind(
              module[0],
              module[1],
              member < tokenCount - 1,
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
