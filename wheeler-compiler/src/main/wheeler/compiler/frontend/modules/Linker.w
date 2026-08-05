//! Links bounded public-constant dependencies into a native source.

module wheeler.compiler.module_linker;

import wheeler.compiler.class_constants;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.constant_declarations;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.module_headers;
import wheeler.compiler.shared_declarations;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class ModuleLinker {
  /// Caps the first native linked-source slice.
  public const long MAX_LINKED_SOURCE_BYTES = 32768;
  /// Caps canonical qualification rewrites in one linked root.
  public const long MAX_LINKED_QUALIFICATIONS = 64;
  /// Names the two-byte canonical module separator.
  public const long QUALIFICATION_SEPARATOR_BYTES = 2;
  /// Names the byte width of the canonical private visibility token.
  public const long PRIVATE_VISIBILITY_BYTES = 7;

  /// Carries byte ranges for one validated synthetic linked source.
  public record LinkPlan(
    long importedStart,
    long importedLength,
    long importedModuleStart,
    long importedModuleLength,
    long linkedOwnerStart,
    long linkedOwnerLength,
    long importedHelperCount,
    long rootInsertion,
    long linkedLength,
    long qualificationCount,
    long exportedCount,
    boolean privatizeExports,
    boolean valid
  ) {}

  /// Carries one selected direct-import name from the root source.
  public record ImportRange(long start, long length, boolean valid) {}

  private LinkPlan invalidPlan() {
    return new LinkPlan(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, false);
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

  /// Scans one bounded source and removes trivia in place.
  public long scanSemanticTokens(
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

  /// Checks the bounded classical-class prefix at one module body.
  public boolean classPrefixValid(
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

  /// Finds one selected import while checking the complete root import count.
  public ImportRange selectedImportRange(
    borrow utf8 importedSource,
    long moduleStart,
    long moduleLength,
    borrow utf8 rootSource,
    borrow mut words rootKinds,
    borrow mut words rootStarts,
    borrow mut words rootLengths,
    long rootBody,
    long expectedImportCount
  ) {
    long cursor = 0;
    long importCount = 0;
    long selectedCount = 0;
    long selectedStart = 0;
    long selectedLength = 0;
    while (cursor < rootBody) limit MAX_COMPILER_TOKENS {
      if (tokenHash(rootSource, rootStarts, rootLengths, cursor) == TOKEN_IMPORT) {
        importCount += 1;
        long name = cursor + 1;
        long semicolon = name;
        while (semicolon < rootBody) limit MAX_QUALIFIED_NAME_TOKENS {
          if (
            punctuationAt(rootSource, rootKinds, rootStarts, semicolon, PUNCTUATION_SEMICOLON)
          ) {
            long nameLength = rootStarts[semicolon] - rootStarts[name];
            if (
              rangesEqual(
                importedSource,
                moduleStart,
                moduleLength,
                rootSource,
                rootStarts[name],
                nameLength
              )
            ) {
              selectedCount += 1;
              selectedStart = rootStarts[name];
              selectedLength = nameLength;
            }

            cursor = semicolon;
            break;
          }

          semicolon += 1;
        }
      }

      cursor += 1;
    }

    if (importCount == expectedImportCount) {
      if (selectedCount == 1) {
        return new ImportRange(selectedStart, selectedLength, true);
      }
    }

    return new ImportRange(0, 0, false);
  }

  /// Compares two bounded ASCII source ranges.
  public boolean rangesEqual(
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

  private boolean qualificationAt(
    borrow utf8 importedSource,
    long moduleStart,
    long moduleLength,
    borrow utf8 rootSource,
    long rootStart
  ) {
    if (
      rootStart + moduleLength + QUALIFICATION_SEPARATOR_BYTES - 1 < bufferLength(rootSource)
    ) {} else {
      return false;
    }

    long cursor = 0;
    while (cursor < moduleLength) limit MAX_QUALIFIED_NAME_BYTES {
      if (utf8Width(importedSource, moduleStart + cursor) == 1) {} else {
        return false;
      }

      if (utf8Width(rootSource, rootStart + cursor) == 1) {} else {
        return false;
      }

      if (
        utf8Scalar(importedSource, moduleStart + cursor) == utf8Scalar(
          rootSource,
          rootStart + cursor
        )
      ) {} else {
        return false;
      }

      cursor += 1;
    }

    if (utf8Scalar(rootSource, rootStart + moduleLength) == PUNCTUATION_COLON) {} else {
      return false;
    }

    return utf8Scalar(rootSource, rootStart + moduleLength + QUALIFICATION_SEPARATOR_BYTES - 1)
      == PUNCTUATION_COLON;
  }

  /// Counts canonical qualifications of one imported module in a root source.
  public long qualificationCount(
    borrow utf8 importedSource,
    long moduleStart,
    long moduleLength,
    borrow utf8 rootSource
  ) {
    long rootCursor = 0;
    long count = 0;
    while (rootCursor < bufferLength(rootSource)) limit MAX_LINKED_SOURCE_BYTES {
      if (utf8Width(rootSource, rootCursor) == 1) {} else {
        return -1;
      }

      if (
        qualificationAt(importedSource, moduleStart, moduleLength, rootSource, rootCursor)
      ) {
        count += 1;
        if (MAX_LINKED_QUALIFICATIONS < count) {
          return -1;
        }

        rootCursor += moduleLength + QUALIFICATION_SEPARATOR_BYTES;
      } else {
        rootCursor += 1;
      }
    }

    return count;
  }

  /// Counts public declarations in one validated constant prefix.
  public long exportedConstantCount(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart
  ) {
    if (firstDeclaration < memberStart) {} else {
      return -1;
    }

    long cursor = firstDeclaration;
    long exportedCount = 0;
    while (cursor < memberStart) limit MAX_CLASS_CONSTANTS {
      long visibility = tokenHash(source, tokenStarts, tokenLengths, cursor);
      if (visibility == TOKEN_PUBLIC) {
        exportedCount += 1;
      } else {
        if (visibility == TOKEN_PRIVATE) {} else {
          return -1;
        }
      }

      long next = constantDeclarationEnd(
        source,
        tokenStarts,
        tokenLengths,
        cursor,
        memberStart
      );
      if (cursor < next) {} else {
        return -1;
      }

      cursor = next;
    }

    if (cursor == memberStart) {
      return exportedCount;
    }

    return -1;
  }

  /// Rejects root references to private names in one constant prefix.
  public boolean privateConstantNamesHidden(
    borrow utf8 importedSource,
    borrow mut words importedStarts,
    borrow mut words importedLengths,
    long firstDeclaration,
    long memberStart,
    borrow utf8 rootSource,
    borrow mut words rootKinds,
    borrow mut words rootStarts,
    borrow mut words rootLengths,
    long rootBody,
    long rootCount
  ) {
    long declaration = firstDeclaration;
    while (declaration < memberStart) limit MAX_CLASS_CONSTANTS {
      if (
        tokenHash(importedSource, importedStarts, importedLengths, declaration) == TOKEN_PRIVATE
      ) {
        long name = constantNameToken(
          importedSource,
          importedStarts,
          importedLengths,
          declaration
        );
        long rootToken = rootBody + 4;
        while (rootToken < rootCount) limit MAX_COMPILER_TOKENS {
          if (rootKinds[rootToken] == 1) {
            if (
              rangesEqual(
                importedSource,
                importedStarts[name],
                importedLengths[name],
                rootSource,
                rootStarts[rootToken],
                rootLengths[rootToken]
              )
            ) {
              return false;
            }
          }

          rootToken += 1;
        }
      }

      long next = constantDeclarationEnd(
        importedSource,
        importedStarts,
        importedLengths,
        declaration,
        memberStart
      );
      if (declaration < next) {} else {
        return false;
      }

      declaration = next;
    }

    return declaration == memberStart;
  }

  private LinkPlan planConstantImportMode(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    long expectedImportCount,
    boolean allowResolvedImports,
    boolean privatizeExports,
    boolean deduplicateSharedPrefix
  ) {
    region scratch = new region(/* bytes= */ 98336, /* allocations= */ 8);
    words importedKinds = allocate(scratch, MAX_COMPILER_TOKENS);
    words importedStarts = allocate(scratch, MAX_COMPILER_TOKENS);
    words importedLengths = allocate(scratch, MAX_COMPILER_TOKENS);
    words rootKinds = allocate(scratch, MAX_COMPILER_TOKENS);
    words rootStarts = allocate(scratch, MAX_COMPILER_TOKENS);
    words rootLengths = allocate(scratch, MAX_COMPILER_TOKENS);
    words importedModule = allocate(scratch, 2);
    words rootModule = allocate(scratch, 2);
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
              if (allowResolvedImports) {} else {
                prefixes = headerHasNoImports(
                  importedSource,
                  importedStarts,
                  importedLengths,
                  importedBody
                );
              }
            }

            if (prefixes) {
              if (0 < importedModule[1]) {
                ImportRange selectedImport = selectedImportRange(
                  importedSource,
                  importedModule[0],
                  importedModule[1],
                  rootSource,
                  rootKinds,
                  rootStarts,
                  rootLengths,
                  rootBody,
                  expectedImportCount
                );

                if (selectedImport.valid) {
                  long firstDeclaration = importedBody + 4;
                  long memberStart = classMemberStart(
                    importedSource,
                    importedKinds,
                    importedStarts,
                    importedLengths,
                    firstDeclaration,
                    importedCount
                  );
                  if (deduplicateSharedPrefix) {
                    long rootFirstDeclaration = rootBody + 4;
                    long rootMemberStart = rootCount - 1;
                    long sharedEnd = sharedPrivatePrefixEnd(
                      importedSource,
                      importedKinds,
                      importedStarts,
                      importedLengths,
                      firstDeclaration,
                      memberStart,
                      rootSource,
                      rootKinds,
                      rootStarts,
                      rootLengths,
                      rootFirstDeclaration,
                      rootMemberStart
                    );
                    if (-1 < sharedEnd) {
                      firstDeclaration = sharedEnd;
                    } else {
                      firstDeclaration = memberStart;
                    }
                  }

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
                        long exported = exportedConstantCount(
                          importedSource,
                          importedKinds,
                          importedStarts,
                          importedLengths,
                          firstDeclaration,
                          memberStart
                        );
                        if (0 < exported) {
                          boolean privateHidden = privateConstantNamesHidden(
                            importedSource,
                            importedStarts,
                            importedLengths,
                            firstDeclaration,
                            memberStart,
                            rootSource,
                            rootKinds,
                            rootStarts,
                            rootLengths,
                            rootBody,
                            rootCount
                          );
                          if (privateHidden) {
                            long importedStart = importedStarts[firstDeclaration];
                            long importedLength = importedStarts[memberStart] - importedStart;
                            long rootInsertion = rootStarts[rootBody + 3] + 1;
                            long qualifications = qualificationCount(
                              importedSource,
                              importedModule[0],
                              importedModule[1],
                              rootSource
                            );
                            if (-1 < qualifications) {
                              long removed = qualifications * (
                                importedModule[1] + QUALIFICATION_SEPARATOR_BYTES
                              );
                              long linkedLength = bufferLength(rootSource) + importedLength
                                - removed;
                              if (privatizeExports) {
                                linkedLength += exported;
                              }

                              if (linkedLength < MAX_LINKED_SOURCE_BYTES + 1) {
                                result = new LinkPlan(
                                  importedStart,
                                  importedLength,
                                  importedModule[0],
                                  importedModule[1],
                                  selectedImport.start,
                                  selectedImport.length,
                                  /* importedHelperCount= */ 0,
                                  rootInsertion,
                                  linkedLength,
                                  qualifications,
                                  exported,
                                  privatizeExports,
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
      }
    }

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

  /// Plans one selected direct constant import without mutating caller output.
  public LinkPlan planConstantImport(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    long expectedImportCount
  ) {
    return planConstantImportMode(
      importedSource,
      rootSource,
      expectedImportCount,
      false,
      false,
      false
    );
  }

  /// Plans one leaf dependency whose exports become private in an importing module.
  public LinkPlan planPrivateConstantImport(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    long expectedImportCount
  ) {
    return planConstantImportMode(
      importedSource,
      rootSource,
      expectedImportCount,
      false,
      true,
      false
    );
  }

  /// Plans one resolved dependency whose exports become private in its importer.
  public LinkPlan planPrivateResolvedConstantImport(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    long expectedImportCount
  ) {
    return planConstantImportMode(
      importedSource,
      rootSource,
      expectedImportCount,
      true,
      true,
      false
    );
  }

  /// Plans one shared dependency after dropping an identical private declaration prefix.
  public LinkPlan planSharedResolvedConstantImport(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    long expectedImportCount
  ) {
    return planConstantImportMode(
      importedSource,
      rootSource,
      expectedImportCount,
      true,
      true,
      true
    );
  }

  /// Plans one module after every import in its header has been resolved.
  public LinkPlan planResolvedConstantImport(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    long expectedImportCount
  ) {
    return planConstantImportMode(
      importedSource,
      rootSource,
      expectedImportCount,
      true,
      false,
      false
    );
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

  private long copyImportedDeclarations(
    borrow utf8 importedSource,
    LinkPlan plan,
    borrow mut bytes output,
    long outputStart
  ) {
    if (plan.privatizeExports) {} else {
      return copyAscii(
        importedSource,
        plan.importedStart,
        plan.importedLength,
        output,
        outputStart
      );
    }

    region scratch = new region(/* bytes= */ 49152, /* allocations= */ 3);
    words tokenKinds = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(scratch, MAX_COMPILER_TOKENS);
    long tokenCount = scanSemanticTokens(importedSource, tokenKinds, tokenStarts, tokenLengths);
    long sourceCursor = plan.importedStart;
    long importedEnd = plan.importedStart + plan.importedLength;
    long outputCursor = outputStart;
    long tokenCursor = 0;
    long privatized = 0;
    while (tokenCursor < tokenCount) limit MAX_COMPILER_TOKENS {
      long tokenStart = tokenStarts[tokenCursor];
      if (plan.importedStart < tokenStart + 1) {
        if (tokenStart < importedEnd) {
          if (
            tokenHash(importedSource, tokenStarts, tokenLengths, tokenCursor) == TOKEN_PUBLIC
          ) {
            outputCursor = copyAscii(
              importedSource,
              sourceCursor,
              tokenStart - sourceCursor,
              output,
              outputCursor
            );
            writeAscii(output, outputCursor, "private");
            outputCursor += PRIVATE_VISIBILITY_BYTES;
            sourceCursor = tokenStart + tokenLengths[tokenCursor];
            privatized += 1;
          }
        }
      }

      tokenCursor += 1;
    }

    if (privatized == plan.exportedCount) {
      outputCursor = copyAscii(
        importedSource,
        sourceCursor,
        importedEnd - sourceCursor,
        output,
        outputCursor
      );
    } else {
      outputCursor = -1;
    }

    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(scratch);
    return outputCursor;
  }

  private long copyRootAscii(
    borrow utf8 importedSource,
    long moduleStart,
    long moduleLength,
    borrow utf8 rootSource,
    long rootStart,
    long rootLength,
    borrow mut bytes output,
    long outputStart
  ) {
    long rootCursor = rootStart;
    long rootEnd = rootStart + rootLength;
    long outputCursor = outputStart;
    while (rootCursor < rootEnd) limit MAX_LINKED_SOURCE_BYTES {
      if (utf8Width(rootSource, rootCursor) == 1) {} else {
        return -1;
      }

      if (
        qualificationAt(importedSource, moduleStart, moduleLength, rootSource, rootCursor)
      ) {
        rootCursor += moduleLength + QUALIFICATION_SEPARATOR_BYTES;
      } else {
        setByte(output, outputCursor, utf8Scalar(rootSource, rootCursor));
        rootCursor += 1;
        outputCursor += 1;
      }
    }

    return outputCursor;
  }

  /// Writes one previously validated synthetic source into exact caller storage.
  public long writeConstantImport(
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

    long qualifications = qualificationCount(
      importedSource,
      plan.importedModuleStart,
      plan.importedModuleLength,
      rootSource
    );
    if (qualifications == plan.qualificationCount) {} else {
      return -1;
    }

    long cursor = copyRootAscii(
      importedSource,
      plan.importedModuleStart,
      plan.importedModuleLength,
      rootSource,
      0,
      plan.rootInsertion,
      output,
      0
    );
    if (cursor < 0) {
      return -1;
    }

    cursor = copyImportedDeclarations(importedSource, plan, output, cursor);
    if (cursor < 0) {
      return -1;
    }

    return copyRootAscii(
      importedSource,
      plan.importedModuleStart,
      plan.importedModuleLength,
      rootSource,
      plan.rootInsertion,
      bufferLength(rootSource) - plan.rootInsertion,
      output,
      cursor
    );
  }
}
