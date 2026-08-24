//! Rewrites exact helper-member prefixes during bounded graph linking.

module wheeler.compiler.graphs.helper_members;

import wheeler.compiler.class_constants;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.module_headers;
import wheeler.compiler.module_linker;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class GraphHelperMembers {
  private const long HELPER_MEMBER_ARENA_BYTES = 98400;
  private const long MAX_GRAPH_NODES = 7;
  private const long MAX_HELPERS = 23;

  private long functionEnd(
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

  private long helperBoundary(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long memberStart,
    long helperCount,
    long closeToken
  ) {
    long cursor = memberStart;
    long helper = 0;
    while (helper < helperCount) limit MAX_HELPERS {
      long next = functionEnd(source, tokenKinds, tokenStarts, cursor, closeToken);
      if (cursor < next) {} else {
        return -1;
      }

      cursor = next;
      helper += 1;
    }

    return cursor;
  }

  private long memberStart(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words module,
    long tokenCount
  ) {
    long body = moduleBodyStart(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      module,
      tokenCount
    );
    if (-1 < body) {} else {
      return -1;
    }

    return classMemberStart(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      body + 4,
      tokenCount
    );
  }

  /// Copies only helper-owner groups selected by one exact identity filter.
  public utf8 filterHelperOwners(
    borrow utf8 source,
    long node,
    borrow mut words slotOwnerCounts,
    borrow mut words slotOwnerNodes,
    borrow mut words helperCounts,
    borrow mut words ownerKeep,
    borrow mut region outputArena
  ) {
    region scratch = new region(/* bytes= */ HELPER_MEMBER_ARENA_BYTES, /* allocations= */ 4);
    words tokenKinds = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(scratch, MAX_COMPILER_TOKENS);
    words module = allocate(scratch, 2);
    long tokenCount = scanSemanticTokens(source, tokenKinds, tokenStarts, tokenLengths);
    assert(0 < tokenCount);
    long member = memberStart(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      module,
      tokenCount
    );
    assert(-1 < member);
    long tokenCursor = member;
    long removedBytes = 0;
    long owner = 0;
    long ownerNode = 0;
    long next = 0;
    while (owner < slotOwnerCounts[node]) limit MAX_GRAPH_NODES {
      ownerNode = slotOwnerNodes[node * MAX_GRAPH_NODES + owner];
      next = helperBoundary(
        source,
        tokenKinds,
        tokenStarts,
        tokenCursor,
        helperCounts[ownerNode],
        tokenCount - 1
      );
      assert(tokenCursor < next);
      if (ownerKeep[owner] == 0) {
        removedBytes += tokenStarts[next] - tokenStarts[tokenCursor];
      }

      tokenCursor = next;
      owner += 1;
    }

    bytes output = allocateBytes(outputArena, bufferLength(source) - removedBytes);
    long memberByte = tokenStarts[member];
    long outputCursor = copyLinkedAscii(source, 0, memberByte, output, 0);
    tokenCursor = member;
    owner = 0;
    while (owner < slotOwnerCounts[node]) limit MAX_GRAPH_NODES {
      ownerNode = slotOwnerNodes[node * MAX_GRAPH_NODES + owner];
      next = helperBoundary(
        source,
        tokenKinds,
        tokenStarts,
        tokenCursor,
        helperCounts[ownerNode],
        tokenCount - 1
      );
      if (ownerKeep[owner] == 1) {
        outputCursor = copyLinkedAscii(
          source,
          tokenStarts[tokenCursor],
          tokenStarts[next] - tokenStarts[tokenCursor],
          output,
          outputCursor
        );
      }

      tokenCursor = next;
      owner += 1;
    }

    outputCursor = copyLinkedAscii(
      source,
      tokenStarts[tokenCursor],
      bufferLength(source) - tokenStarts[tokenCursor],
      output,
      outputCursor
    );
    assert(outputCursor == bufferLength(output));
    utf8 result = freezeUtf8(output);
    drop(module);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(scratch);
    return result;
  }

  /// Moves one prepended helper group behind every existing imported helper.
  public utf8 appendPrependedHelpers(
    borrow utf8 source,
    long prependedHelperCount,
    long existingHelperCount,
    borrow mut region outputArena
  ) {
    assert(0 < prependedHelperCount);
    assert(0 < existingHelperCount);
    region scratch = new region(/* bytes= */ HELPER_MEMBER_ARENA_BYTES, /* allocations= */ 4);
    words tokenKinds = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(scratch, MAX_COMPILER_TOKENS);
    words module = allocate(scratch, 2);
    long tokenCount = scanSemanticTokens(source, tokenKinds, tokenStarts, tokenLengths);
    assert(0 < tokenCount);
    long member = memberStart(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      module,
      tokenCount
    );
    assert(-1 < member);
    long prependedEnd = helperBoundary(
      source,
      tokenKinds,
      tokenStarts,
      member,
      prependedHelperCount,
      tokenCount - 1
    );
    assert(member < prependedEnd);
    long existingEnd = helperBoundary(
      source,
      tokenKinds,
      tokenStarts,
      prependedEnd,
      existingHelperCount,
      tokenCount - 1
    );
    assert(prependedEnd < existingEnd);
    long memberByte = tokenStarts[member];
    long prependedEndByte = tokenStarts[prependedEnd];
    long existingEndByte = tokenStarts[existingEnd];
    bytes output = allocateBytes(outputArena, bufferLength(source));
    long cursor = copyLinkedAscii(source, 0, memberByte, output, 0);
    cursor = copyLinkedAscii(
      source,
      prependedEndByte,
      existingEndByte - prependedEndByte,
      output,
      cursor
    );
    cursor = copyLinkedAscii(source, memberByte, prependedEndByte - memberByte, output, cursor);
    cursor = copyLinkedAscii(
      source,
      existingEndByte,
      bufferLength(source) - existingEndByte,
      output,
      cursor
    );
    assert(cursor == bufferLength(output));
    utf8 result = freezeUtf8(output);
    drop(module);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(scratch);
    return result;
  }
}
