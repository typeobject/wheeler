//! Selects the canonical zero-local assertion profile from shared syntax and counted globals.

module wheeler.compiler.closure.source_global_assertion_profile;

import wheeler.compiler.closure.source_global_references;
import wheeler.compiler.closure.source_global_schema;
import wheeler.compiler.closure.source_reversible_result_relations;
import wheeler.compiler.opcodes;

classical class SourceGlobalAssertionProfile {
  /// Validates every declaration coordinate before a profile can select an earlier row.
  /// The producer owns member admission. These are counted name ranges, not another parser.
  public void requireSourceGlobalDeclarationRanges(
    borrow utf8 source,
    long globalCount,
    long globalProductStart,
    borrow mut words globals
  ) {
    assert(-1 < globalCount);
    assert(globalCount < MAX_SOURCE_GLOBALS + 1);
    assert(-1 < globalProductStart);
    assert(globalProductStart < bufferLength(globals) + 1);
    if (0 < globalCount) {
      assert(SOURCE_GLOBAL_ROWS < bufferLength(globals) - globalProductStart + 1);
    }

    long global = 0;
    while (global < globalCount) limit MAX_SOURCE_GLOBALS {
      long declaration = globals[globalProductStart + SOURCE_GLOBAL_DECLARATION_ROW + global];
      long length = globals[globalProductStart + SOURCE_GLOBAL_LENGTH_ROW + global];
      assert(-1 < declaration);
      assert(0 < length);
      assert(length < bufferLength(source) + 1);
      assert(declaration < bufferLength(source) - length + 1);
      global += 1;
    }
  }

  /// Selects only named-global equality with a syntactic signed literal on the right.
  /// Final scalar binding must still reject local/global scope ambiguity.
  public long globalLiteralAssertionOrdinal(
    SourceReversibleResultRelation syntax,
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow byteview globalNames,
    long globalCount,
    long globalProductStart,
    borrow mut words globals
  ) {
    if (syntax.valid == false) {
      return -1;
    }

    if (syntax.kind != RESULT_RELATION_BINARY) {
      return -1;
    }

    if (syntax.operation != OPCODE_LOCAL_EQ) {
      return -1;
    }

    long global = sourceGlobalOrdinal(
      source,
      tokenStarts[syntax.leftToken],
      tokenLengths[syntax.leftToken],
      globalNames,
      globalCount,
      globalProductStart,
      globals
    );
    requireSourceGlobalDeclarationRanges(source, globalCount, globalProductStart, globals);
    if (global < 0) {
      return -1;
    }

    long declaration = globals[globalProductStart + SOURCE_GLOBAL_DECLARATION_ROW + global];
    if (tokenStarts[syntax.leftToken] < declaration) {
      return -1;
    }

    return global;
  }
}
