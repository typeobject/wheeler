//! Links one bounded public-constant import into a native root source.

module wheeler.compiler.module_linker;

import wheeler.compiler.class_constants;
import wheeler.compiler.constant_declarations;
import wheeler.compiler.module_headers;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class ModuleLinker {
  /// Caps the first native linked-source slice.
  public const long MAX_LINKED_SOURCE_BYTES = 16384;

  /// Carries byte ranges for one validated synthetic linked source.
  public record LinkPlan(
    long importedStart,
    long importedLength,
    long rootInsertion,
    long linkedLength,
    boolean valid
  ) {}

  private LinkPlan invalidPlan() {
    return new LinkPlan(0, 0, 0, 0, false);
  }

  private long compactTokens(
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long count
  ) {
    long readCursor = 0;
    long writeCursor = 0;
    while (readCursor < count) limit MAX_COMPILER_TOKENS {
      long kind = tokenKinds[readCursor];
      if (kind == 4) {} else {
        if (kind == 5) {} else {
          set(tokenKinds, writeCursor, kind);
          set(tokenStarts, writeCursor, tokenStarts[readCursor]);
          set(tokenLengths, writeCursor, tokenLengths[readCursor]);
          writeCursor += 1;
        }
      }

      readCursor += 1;
    }

    return writeCursor;
  }

  private long scanSemanticTokens(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    ScanResult scanned = scan(source, tokenKinds, tokenStarts, tokenLengths);
    match (scanned) {
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        long ignoredOffset = diagnostic.offset;
        return -1;
      }
      case ScanResult.Value(long count) {
        return compactTokens(tokenKinds, tokenStarts, tokenLengths, count);
      }
    }
  }

  private boolean classPrefixValid(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long bodyStart,
    long count
  ) {
    if (bodyStart + 3 < count) {} else {
      return false;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, bodyStart) == TOKEN_CLASSICAL) {} else {
      return false;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, bodyStart + 1) == TOKEN_CLASS) {} else {
      return false;
    }

    if (tokenKinds[bodyStart + 2] == 1) {} else {
      return false;
    }

    return punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      bodyStart + 3,
      PUNCTUATION_OPEN_BRACE
    );
  }

  private boolean headerHasNoImports(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long bodyStart
  ) {
    long cursor = 0;
    while (cursor < bodyStart) limit MAX_COMPILER_TOKENS {
      if (tokenHash(source, tokenStarts, tokenLengths, cursor) == TOKEN_IMPORT) {
        return false;
      }

      cursor += 1;
    }

    return true;
  }

  private boolean directImportRange(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long bodyStart,
    borrow mut words importRange
  ) {
    long cursor = 0;
    long importCount = 0;
    while (cursor < bodyStart) limit MAX_COMPILER_TOKENS {
      if (tokenHash(source, tokenStarts, tokenLengths, cursor) == TOKEN_IMPORT) {
        importCount += 1;
        if (importCount == 1) {
          long name = cursor + 1;
          long semicolon = name;
          while (semicolon < bodyStart) limit MAX_QUALIFIED_NAME_TOKENS {
            if (
              punctuationAt(source, tokenKinds, tokenStarts, semicolon, PUNCTUATION_SEMICOLON)
            ) {
              set(importRange, 0, tokenStarts[name]);
              set(importRange, 1, tokenStarts[semicolon] - tokenStarts[name]);
              cursor = semicolon;
              break;
            }

            semicolon += 1;
          }
        }
      }

      cursor += 1;
    }

    return importCount == 1;
  }

  private boolean rangesEqual(
    borrow utf8 leftSource,
    long leftStart,
    long leftLength,
    borrow utf8 rightSource,
    long rightStart,
    long rightLength
  ) {
    if (leftLength == rightLength) {} else {
      return false;
    }

    long cursor = 0;
    while (cursor < leftLength) limit MAX_QUALIFIED_NAME_BYTES {
      if (
        utf8Scalar(leftSource, leftStart + cursor) == utf8Scalar(rightSource, rightStart + cursor)
      ) {} else {
        return false;
      }

      if (utf8Width(leftSource, leftStart + cursor) == 1) {} else {
        return false;
      }

      if (utf8Width(rightSource, rightStart + cursor) == 1) {} else {
        return false;
      }

      cursor += 1;
    }

    return true;
  }

  private boolean publicConstantBlock(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart
  ) {
    if (firstDeclaration < memberStart) {} else {
      return false;
    }

    long cursor = firstDeclaration;
    long count = 0;
    while (cursor < memberStart) limit MAX_CLASS_CONSTANTS {
      if (tokenHash(source, tokenStarts, tokenLengths, cursor) == TOKEN_PUBLIC) {} else {
        return false;
      }

      long next = constantDeclarationEnd(
        source,
        tokenStarts,
        tokenLengths,
        cursor,
        memberStart
      );
      if (cursor < next) {} else {
        return false;
      }

      cursor = next;
      count += 1;
    }

    return cursor == memberStart;
  }

  /// Plans one direct public-constant import without mutating caller output.
  public LinkPlan planSinglePublicConstantImport(
    borrow utf8 importedSource,
    borrow utf8 rootSource
  ) {
    region scratch = new region(/* bytes= */ 50000, /* allocations= */ 9);
    words importedKinds = allocate(scratch, MAX_COMPILER_TOKENS);
    words importedStarts = allocate(scratch, MAX_COMPILER_TOKENS);
    words importedLengths = allocate(scratch, MAX_COMPILER_TOKENS);
    words rootKinds = allocate(scratch, MAX_COMPILER_TOKENS);
    words rootStarts = allocate(scratch, MAX_COMPILER_TOKENS);
    words rootLengths = allocate(scratch, MAX_COMPILER_TOKENS);
    words importedModule = allocate(scratch, 2);
    words rootModule = allocate(scratch, 2);
    words rootImport = allocate(scratch, 2);
    long importedCount = scanSemanticTokens(
      importedSource,
      importedKinds,
      importedStarts,
      importedLengths
    );
    long rootCount = scanSemanticTokens(rootSource, rootKinds, rootStarts, rootLengths);
    LinkPlan result = invalidPlan();
    if (-1 < importedCount) {
      if (-1 < rootCount) {
        long importedBody = moduleBodyStart(
          importedSource,
          importedKinds,
          importedStarts,
          importedLengths,
          importedModule,
          importedCount
        );
        long rootBody = moduleBodyStart(
          rootSource,
          rootKinds,
          rootStarts,
          rootLengths,
          rootModule,
          rootCount
        );
        if (-1 < importedBody) {
          if (-1 < rootBody) {
            boolean prefixes = classPrefixValid(
              importedSource,
              importedKinds,
              importedStarts,
              importedLengths,
              importedBody,
              importedCount
            );
            if (prefixes) {
              prefixes = classPrefixValid(
                rootSource,
                rootKinds,
                rootStarts,
                rootLengths,
                rootBody,
                rootCount
              );
            }

            if (prefixes) {
              prefixes = headerHasNoImports(
                importedSource,
                importedStarts,
                importedLengths,
                importedBody
              );
            }

            if (prefixes) {
              if (0 < importedModule[1]) {
                boolean direct = directImportRange(
                  rootSource,
                  rootKinds,
                  rootStarts,
                  rootLengths,
                  rootBody,
                  rootImport
                );
                if (direct) {
                  direct = rangesEqual(
                    importedSource,
                    importedModule[0],
                    importedModule[1],
                    rootSource,
                    rootImport[0],
                    rootImport[1]
                  );
                }

                if (direct) {
                  long firstDeclaration = importedBody + 4;
                  long memberStart = classMemberStart(
                    importedSource,
                    importedKinds,
                    importedStarts,
                    importedLengths,
                    firstDeclaration,
                    importedCount
                  );
                  if (firstDeclaration < memberStart) {
                    if (
                      punctuationAt(
                        importedSource,
                        importedKinds,
                        importedStarts,
                        memberStart,
                        PUNCTUATION_CLOSE_BRACE
                      )
                    ) {
                      if (memberStart + 1 == importedCount) {
                        if (
                          publicConstantBlock(
                            importedSource,
                            importedKinds,
                            importedStarts,
                            importedLengths,
                            firstDeclaration,
                            memberStart
                          )
                        ) {
                          long importedStart = importedStarts[firstDeclaration];
                          long importedLength = importedStarts[memberStart] - importedStart;
                          long rootInsertion = rootStarts[rootBody + 3] + 1;
                          long linkedLength = bufferLength(rootSource) + importedLength;
                          if (linkedLength < MAX_LINKED_SOURCE_BYTES + 1) {
                            result = new LinkPlan(
                              importedStart,
                              importedLength,
                              rootInsertion,
                              linkedLength,
                              true
                            );
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    drop(rootImport);
    drop(rootModule);
    drop(importedModule);
    drop(rootLengths);
    drop(rootStarts);
    drop(rootKinds);
    drop(importedLengths);
    drop(importedStarts);
    drop(importedKinds);
    drop(scratch);
    return result;
  }

  private long copyAscii(
    borrow utf8 source,
    long start,
    long length,
    borrow mut bytes output,
    long outputStart
  ) {
    long cursor = 0;
    while (cursor < length) limit MAX_LINKED_SOURCE_BYTES {
      if (utf8Width(source, start + cursor) == 1) {} else {
        return -1;
      }

      setByte(output, outputStart + cursor, utf8Scalar(source, start + cursor));
      cursor += 1;
    }

    return outputStart + length;
  }

  /// Writes one previously validated synthetic source into exact caller storage.
  public long writeSinglePublicConstantImport(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    LinkPlan plan,
    borrow mut bytes output
  ) {
    if (plan.valid) {} else {
      return -1;
    }

    if (bufferLength(output) == plan.linkedLength) {} else {
      return -1;
    }

    long cursor = copyAscii(rootSource, 0, plan.rootInsertion, output, 0);
    if (cursor < 0) {
      return -1;
    }

    cursor = copyAscii(importedSource, plan.importedStart, plan.importedLength, output, cursor);
    if (cursor < 0) {
      return -1;
    }

    return copyAscii(
      rootSource,
      plan.rootInsertion,
      bufferLength(rootSource) - plan.rootInsertion,
      output,
      cursor
    );
  }
}
