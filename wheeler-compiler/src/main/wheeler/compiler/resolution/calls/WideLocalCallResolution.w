//! Resolves exact five- through seven-local helper calls.

module wheeler.compiler.wide_local_call_resolution;

import wheeler.compiler.local_resolution;
import wheeler.compiler.wide_local_calls;

classical class WideLocalCallResolution {
  private const long FIRST_PACKED_SOURCE_COUNT = 4;

  private long resolveWideLocalSource(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long argument
  ) {
    return resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      wideLocalCallArgumentToken(statementStart, argument),
      true
    );
  }

  /// Resolves one fixed wide-local statement identity.
  public long resolveWideLocalCallOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long opcode
  ) {
    if (packedWideLocalCall(opcode)) {} else {
      return opcode;
    }

    long arity = wideLocalCallArity(opcode);
    long argument = 0;
    while (argument < arity) limit MAX_WIDE_LOCAL_CALL_ARGUMENTS {
      if (
        -1 < resolveWideLocalSource(
          source,
          tokenStarts,
          tokenLengths,
          previousStarts,
          previousCount,
          statementStart,
          argument
        )
      ) {} else {
        return -1;
      }

      argument += 1;
    }

    return resolvedWideLocalCall(arity);
  }

  private long packWideLocalSources(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long first,
    long limit
  ) {
    long packed = 0;
    long scale = 1;
    long argument = first;
    while (argument < limit) limit MAX_WIDE_LOCAL_CALL_ARGUMENTS {
      long selected = resolveWideLocalSource(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart,
        argument
      );
      if (-1 < selected) {} else {
        return -1;
      }

      packed += selected * scale;
      scale = scale * WIDE_LOCAL_SOURCE_RADIX;
      argument += 1;
    }

    return packed;
  }

  /// Packs the first four sources of one validated wide-local call.
  public long resolveWideLocalFirstSources(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long opcode
  ) {
    if (packedWideLocalCall(opcode)) {} else {
      return -1;
    }

    return packWideLocalSources(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart,
      0,
      FIRST_PACKED_SOURCE_COUNT
    );
  }

  /// Packs the remaining sources of one validated wide-local call.
  public long resolveWideLocalLastSources(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long opcode
  ) {
    if (packedWideLocalCall(opcode)) {} else {
      return -1;
    }

    return packWideLocalSources(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart,
      FIRST_PACKED_SOURCE_COUNT,
      wideLocalCallArity(opcode)
    );
  }
}
