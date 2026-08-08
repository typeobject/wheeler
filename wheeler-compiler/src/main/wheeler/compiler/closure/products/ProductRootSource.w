//! Rewrites one root source against resolved counted scalar products.

module wheeler.compiler.closure.product_root_source;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.module_headers;
import wheeler.compiler.module_linker;
import wheeler.compiler.product_constant_lookup;

classical class ProductRootSources {
  private const long MAX_CLASS_CONSTANTS = 256;
  private const long MAX_LINKED_SOURCE_BYTES = 32768;
  private const long TOKEN_ARENA_BYTES = 98320;

  private boolean localName(
    borrow byteview archive,
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token,
    long firstSymbol,
    long symbolCount,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths
  ) {
    long offset = 0;
    while (offset < symbolCount) limit MAX_CLASS_CONSTANTS {
      long symbol = firstSymbol + offset;
      if (symbolLengths[symbol] == tokenLengths[token]) {
        boolean same = true;
        long cursor = 0;
        while (cursor < symbolLengths[symbol]) limit 256 {
          if (
            archive[symbolStarts[symbol] + cursor] == utf8Scalar(
              source,
              tokenStarts[token] + cursor
            )
          ) {} else {
            same = false;
          }

          cursor += 1;
        }

        if (same) {
          return true;
        }
      }

      offset += 1;
    }

    return false;
  }

  private long copyRange(
    borrow utf8 source,
    long start,
    long end,
    borrow mut bytes output,
    long written
  ) {
    long cursor = start;
    while (cursor < end) limit MAX_LINKED_SOURCE_BYTES {
      if (written < bufferLength(output)) {} else {
        return -1;
      }

      setByte(output, written, utf8Scalar(source, cursor));
      written += 1;
      cursor += 1;
    }

    return written;
  }

  private long writeMinimumSigned(borrow mut bytes output, long written) {
    if (written + 20 < bufferLength(output) + 1) {} else {
      return -1;
    }

    writeAscii(output, written, "-9223372036854775808");
    return written + 20;
  }

  private long writeSigned(long value, borrow mut bytes output, long written) {
    if (value == 0 - 9223372036854775807 - 1) {
      return writeMinimumSigned(output, written);
    }

    long magnitude = value;
    if (value < 0) {
      if (written < bufferLength(output)) {} else {
        return -1;
      }

      setByte(output, written, 45);
      written += 1;
      magnitude = 0 - value;
    }

    long divisor = 1;
    while (divisor < magnitude / 10 + 1) limit 19 {
      if (divisor < 1000000000000000000) {
        divisor = divisor * 10;
      } else {
        break;
      }
    }

    if (magnitude < divisor) {
      divisor = divisor / 10;
    }

    if (divisor == 0) {
      divisor = 1;
    }

    boolean writing = true;
    while (writing) limit 19 {
      if (written < bufferLength(output)) {} else {
        return -1;
      }

      setByte(output, written, magnitude / divisor % 10 + 48);
      written += 1;
      if (divisor == 1) {
        writing = false;
      } else {
        divisor = divisor / 10;
      }
    }

    return written;
  }

  private long writeValue(long value, boolean signed, borrow mut bytes output, long written) {
    if (signed) {
      return writeSigned(value, output, written);
    }

    if (value == 0) {
      if (written + 5 < bufferLength(output) + 1) {} else {
        return -1;
      }

      writeAscii(output, written, "false");
      return written + 5;
    }

    if (value == 1) {
      if (written + 4 < bufferLength(output) + 1) {} else {
        return -1;
      }

      writeAscii(output, written, "true");
      return written + 4;
    }

    return -1;
  }

  /// Removes the module header and substitutes resolved direct product references.
  public long writeProductRootSource(
    borrow byteview archive,
    long sourceStart,
    long sourceLength,
    long firstLocalSymbol,
    long localSymbolCount,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words importedRows,
    borrow mut bytes output
  ) {
    if (0 < sourceLength) {} else {
      return -1;
    }

    if (sourceLength < MAX_LINKED_SOURCE_BYTES + 1) {} else {
      return -1;
    }

    if (bufferLength(output) == MAX_LINKED_SOURCE_BYTES) {} else {
      return -1;
    }

    region sourceArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes sourceBytes = allocateBytes(sourceArena, sourceLength);
    long copied = 0;
    while (copied < sourceLength) limit MAX_LINKED_SOURCE_BYTES {
      setByte(sourceBytes, copied, archive[sourceStart + copied]);
      copied += 1;
    }

    utf8 source = freezeUtf8(sourceBytes);
    region tokenArena = new region(/* bytes= */ TOKEN_ARENA_BYTES, /* allocations= */ 4);
    words tokenKinds = allocate(tokenArena, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(tokenArena, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(tokenArena, MAX_COMPILER_TOKENS);
    words moduleRange = allocate(tokenArena, 2);
    long tokenCount = scanSemanticTokens(source, tokenKinds, tokenStarts, tokenLengths);
    long body = -1;
    if (0 < tokenCount) {
      body = moduleBodyStart(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        moduleRange,
        tokenCount
      );
    }

    long written = -1;
    if (-1 < body) {
      written = 0;
      long sourceCursor = tokenStarts[body];
      long token = body;
      while (token < tokenCount) limit MAX_COMPILER_TOKENS {
        boolean local = localName(
          archive,
          source,
          tokenStarts,
          tokenLengths,
          token,
          firstLocalSymbol,
          localSymbolCount,
          symbolStarts,
          symbolLengths
        );
        ProductConstantExpression qualified = new ProductConstantExpression(
          0,
          token,
          false,
          false,
          true
        );
        ProductConstantResolution unqualified = new ProductConstantResolution(
          0,
          false,
          false,
          true
        );
        if (local == false) {
          qualified = lookupQualifiedProductConstant(
            source,
            tokenStarts,
            tokenLengths,
            token,
            tokenCount,
            archive,
            importedRows
          );
          if (qualified.found == false) {
            unqualified = lookupProductConstant(
              source,
              tokenStarts,
              tokenLengths,
              token,
              archive,
              importedRows
            );
          }
        }

        boolean replacing = qualified.found;
        long replacementValue = qualified.value;
        boolean replacementSigned = qualified.signed;
        long nextToken = qualified.next;
        boolean replacementValid = qualified.valid;
        if (unqualified.found) {
          replacing = true;
          replacementValue = unqualified.value;
          replacementSigned = unqualified.signed;
          replacementValid = unqualified.valid;
          nextToken = token + 1;
        }

        if (replacing) {
          if (replacementValid) {} else {
            written = -1;
            break;
          }

          written = copyRange(source, sourceCursor, tokenStarts[token], output, written);
          if (-1 < written) {} else {
            break;
          }

          written = writeValue(replacementValue, replacementSigned, output, written);
          if (-1 < written) {} else {
            break;
          }

          long finalToken = nextToken - 1;
          sourceCursor = tokenStarts[finalToken] + tokenLengths[finalToken];
          token = nextToken;
        } else {
          token += 1;
        }
      }

      if (-1 < written) {
        written = copyRange(source, sourceCursor, sourceLength, output, written);
      }
    }

    drop(moduleRange);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(tokenArena);
    drop(source);
    drop(sourceArena);
    return written;
  }
}
