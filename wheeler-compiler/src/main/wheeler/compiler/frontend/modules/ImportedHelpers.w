//! Plans one bounded imported scalar-helper table before canonical lowering.

module wheeler.compiler.imported_helpers;

import wheeler.compiler.class_constants;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.helper_abi;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.module_headers;
import wheeler.compiler.module_linker;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class ImportedHelpers {
  private record HelperFacts(
    long count,
    long exportedCount,
    boolean privateNamesHidden,
    boolean valid
  ) {}

  private HelperFacts invalidFacts() {
    return new HelperFacts(0, 0, false, false);
  }

  private boolean rootContainsName(
    borrow utf8 importedSource,
    borrow mut words importedStarts,
    borrow mut words importedLengths,
    long name,
    borrow utf8 rootSource,
    borrow mut words rootKinds,
    borrow mut words rootStarts,
    borrow mut words rootLengths,
    long rootBody,
    long rootCount
  ) {
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
          return true;
        }
      }

      rootToken += 1;
    }

    return false;
  }

  private long functionEnd(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long declaration,
    long closeToken
  ) {
    long cursor = declaration + 3;
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

  private HelperFacts helperFacts(
    borrow utf8 importedSource,
    borrow mut words importedKinds,
    borrow mut words importedStarts,
    borrow mut words importedLengths,
    long memberStart,
    long closeToken,
    borrow utf8 rootSource,
    borrow mut words rootKinds,
    borrow mut words rootStarts,
    borrow mut words rootLengths,
    long rootBody,
    long rootCount
  ) {
    long cursor = memberStart;
    long count = 0;
    long exported = 0;
    while (cursor < closeToken) limit MAX_IMPORTED_SCALAR_HELPERS {
      long visibility = tokenHash(importedSource, importedStarts, importedLengths, cursor);
      if (visibility == TOKEN_PUBLIC) {
        exported += 1;
      } else {
        if (visibility == TOKEN_PRIVATE) {} else {
          return invalidFacts();
        }
      }

      long name = cursor + 2;
      if (name < closeToken) {} else {
        return invalidFacts();
      }

      if (importedKinds[name] == 1) {} else {
        return invalidFacts();
      }

      if (visibility == TOKEN_PRIVATE) {
        if (
          rootContainsName(
            importedSource,
            importedStarts,
            importedLengths,
            name,
            rootSource,
            rootKinds,
            rootStarts,
            rootLengths,
            rootBody,
            rootCount
          )
        ) {
          return invalidFacts();
        }
      }

      long next = functionEnd(
        importedSource,
        importedKinds,
        importedStarts,
        cursor,
        closeToken
      );
      if (cursor < next) {} else {
        return invalidFacts();
      }

      cursor = next;
      count += 1;
    }

    if (cursor == closeToken) {
      if (0 < count) {
        return new HelperFacts(count, exported, true, true);
      }
    }

    return invalidFacts();
  }

  /// Plans one resolved dependency containing constants followed by scalar helpers.
  public LinkPlan planResolvedHelperImport(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    long expectedImportCount
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
    LinkPlan result = new LinkPlan(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, false);
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
              ImportRange selected = selectedImportRange(
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
              if (selected.valid) {
                long firstDeclaration = importedBody + 4;
                long memberStart = classMemberStart(
                  importedSource,
                  importedKinds,
                  importedStarts,
                  importedLengths,
                  firstDeclaration,
                  importedCount
                );
                long closeToken = importedCount - 1;
                if (firstDeclaration < memberStart + 1) {
                  if (memberStart < closeToken) {
                    if (
                      punctuationAt(
                        importedSource,
                        importedKinds,
                        importedStarts,
                        closeToken,
                        PUNCTUATION_CLOSE_BRACE
                      )
                    ) {
                      long constantExports = 0;
                      if (firstDeclaration < memberStart) {
                        constantExports = exportedConstantCount(
                          importedSource,
                          importedKinds,
                          importedStarts,
                          importedLengths,
                          firstDeclaration,
                          memberStart
                        );
                      }

                      if (-1 < constantExports) {
                        boolean constantsHidden = privateConstantNamesHidden(
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
                        if (constantsHidden) {
                          HelperFacts helpers = helperFacts(
                            importedSource,
                            importedKinds,
                            importedStarts,
                            importedLengths,
                            memberStart,
                            closeToken,
                            rootSource,
                            rootKinds,
                            rootStarts,
                            rootLengths,
                            rootBody,
                            rootCount
                          );
                          if (helpers.valid) {
                            long qualifications = qualificationCount(
                              importedSource,
                              importedModule[0],
                              importedModule[1],
                              rootSource
                            );
                            if (-1 < qualifications) {
                              long importedStart = importedStarts[firstDeclaration];
                              long importedLength = importedStarts[closeToken] - importedStart;
                              long rootInsertion = rootStarts[rootBody + 3] + 1;
                              long removed = qualifications * (
                                importedModule[1] + QUALIFICATION_SEPARATOR_BYTES
                              );
                              long exported = constantExports + helpers.exportedCount;
                              long linkedLength = bufferLength(rootSource) + importedLength
                                - removed + exported;
                              if (linkedLength < MAX_LINKED_SOURCE_BYTES + 1) {
                                result = new LinkPlan(
                                  importedStart,
                                  importedLength,
                                  importedModule[0],
                                  importedModule[1],
                                  selected.start,
                                  selected.length,
                                  helpers.count,
                                  rootInsertion,
                                  linkedLength,
                                  qualifications,
                                  exported,
                                  true,
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
}
