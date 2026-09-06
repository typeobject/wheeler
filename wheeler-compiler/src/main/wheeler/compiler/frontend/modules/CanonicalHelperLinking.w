//! Keeps linked helper declarations ahead of every executable member.

module wheeler.compiler.canonical_helper_linking;

import wheeler.compiler.class_constants;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.constant_declarations;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.module_headers;
import wheeler.compiler.module_linker;
import wheeler.compiler.shared_declarations;
import wheeler.compiler.tokens;

classical class CanonicalHelperLinking {
  private const long HELPER_LINK_SCRATCH_BYTES = 196640;
  private const long PRIVATE_VISIBILITY_BYTES = 7;

  private record ImportedRangeCopy(long cursor, long privatized, boolean valid) {}

  private ImportedRangeCopy copyImportedRange(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long tokenCount,
    long start,
    long length,
    boolean privatize,
    borrow mut bytes output,
    long outputStart
  ) {
    if (privatize) {} else {
      long copied = copyLinkedAscii(source, start, length, output, outputStart);
      return new ImportedRangeCopy(copied, 0, -1 < copied);
    }

    long sourceCursor = start;
    long sourceEnd = start + length;
    long outputCursor = outputStart;
    long tokenCursor = 0;
    long privatized = 0;
    while (tokenCursor < tokenCount) limit MAX_COMPILER_TOKENS {
      long tokenStart = tokenStarts[tokenCursor];
      if (start < tokenStart + 1) {
        if (tokenStart < sourceEnd) {
          if (
            sourceTokenCode(source, tokenStarts, tokenLengths, tokenCursor) == TOKEN_PUBLIC
          ) {
            outputCursor = copyLinkedAscii(
              source,
              sourceCursor,
              tokenStart - sourceCursor,
              output,
              outputCursor
            );
            if (-1 < outputCursor) {} else {
              return new ImportedRangeCopy(-1, privatized, false);
            }

            writeAscii(output, outputCursor, "private");
            outputCursor += PRIVATE_VISIBILITY_BYTES;
            sourceCursor = tokenStart + tokenLengths[tokenCursor];
            privatized += 1;
          }
        }
      }

      tokenCursor += 1;
    }

    outputCursor = copyLinkedAscii(
      source,
      sourceCursor,
      sourceEnd - sourceCursor,
      output,
      outputCursor
    );
    return new ImportedRangeCopy(outputCursor, privatized, -1 < outputCursor);
  }

  private ImportedRangeCopy copyConstantRange(
    borrow utf8 importedSource,
    borrow mut words importedKinds,
    borrow mut words importedStarts,
    borrow mut words importedLengths,
    long importedFirst,
    long importedMember,
    borrow utf8 rootSource,
    borrow mut words rootKinds,
    borrow mut words rootStarts,
    borrow mut words rootLengths,
    long rootFirst,
    long rootMember,
    LinkPlan plan,
    borrow mut bytes output,
    long outputStart
  ) {
    long cursor = outputStart;
    long sourceCursor = plan.importedStart;
    long privatized = 0;
    long declaration = importedFirst;
    while (declaration < importedMember) limit MAX_CLASS_CONSTANTS {
      long next = constantDeclarationEnd(
        importedSource,
        importedStarts,
        importedLengths,
        declaration,
        importedMember
      );
      if (declaration < next) {} else {
        return new ImportedRangeCopy(-1, privatized, false);
      }

      long declarationStart = importedStarts[declaration];
      if (plan.importedStart < declarationStart + 1) {
        long declarationEnd = importedStarts[next - 1] + importedLengths[next - 1];
        cursor = copyLinkedAscii(
          importedSource,
          sourceCursor,
          declarationStart - sourceCursor,
          output,
          cursor
        );
        if (-1 < cursor) {} else {
          return new ImportedRangeCopy(-1, privatized, false);
        }

        boolean shared = sharedPrivateDeclaration(
          importedSource,
          importedKinds,
          importedStarts,
          importedLengths,
          declaration,
          next,
          rootSource,
          rootKinds,
          rootStarts,
          rootLengths,
          rootFirst,
          rootMember
        );
        if (shared == false) {
          if (plan.privatizeExports) {
            if (
              sourceTokenCode(importedSource, importedStarts, importedLengths, declaration)
                == TOKEN_PUBLIC
            ) {
              writeAscii(output, cursor, "private");
              cursor += PRIVATE_VISIBILITY_BYTES;
              declarationStart += importedLengths[declaration];
              privatized += 1;
            }
          }

          cursor = copyLinkedAscii(
            importedSource,
            declarationStart,
            declarationEnd - declarationStart,
            output,
            cursor
          );
          if (-1 < cursor) {} else {
            return new ImportedRangeCopy(-1, privatized, false);
          }
        }

        sourceCursor = declarationEnd;
      }

      declaration = next;
    }

    cursor = copyLinkedAscii(
      importedSource,
      sourceCursor,
      importedStarts[importedMember] - sourceCursor,
      output,
      cursor
    );
    return new ImportedRangeCopy(cursor, privatized, -1 < cursor);
  }

  /// Writes one helper import with all constants before all executable members.
  public long writeCanonicalHelperImport(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    LinkPlan plan,
    borrow mut bytes output
  ) {
    if (plan.valid) {} else {
      return -1;
    }

    if (0 < plan.importedHelperCount) {} else {
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

    region scratch = new region(/* bytes= */ HELPER_LINK_SCRATCH_BYTES, /* allocations= */ 8);
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
    long result = -1;
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
            long importedFirst = importedBody + 4;
            long rootFirst = rootBody + 4;
            long importedMember = classMemberStart(
              importedSource,
              importedKinds,
              importedStarts,
              importedLengths,
              importedFirst,
              importedCount
            );
            long rootMember = classMemberStart(
              rootSource,
              rootKinds,
              rootStarts,
              rootLengths,
              rootFirst,
              rootCount
            );
            if (importedFirst < importedMember + 1) {
              if (importedMember < importedCount - 1) {
                if (rootFirst < rootMember + 1) {
                  if (rootMember < rootCount) {
                    long importedMemberStart = importedStarts[importedMember];
                    long rootMemberStart = rootStarts[rootMember];
                    long importedEnd = plan.importedStart + plan.importedLength;
                    long cursor = copyLinkedRootAscii(
                      importedSource,
                      plan.importedModuleStart,
                      plan.importedModuleLength,
                      rootSource,
                      0,
                      plan.rootInsertion,
                      output,
                      0
                    );
                    ImportedRangeCopy constants = copyConstantRange(
                      importedSource,
                      importedKinds,
                      importedStarts,
                      importedLengths,
                      importedFirst,
                      importedMember,
                      rootSource,
                      rootKinds,
                      rootStarts,
                      rootLengths,
                      rootFirst,
                      rootMember,
                      plan,
                      output,
                      cursor
                    );
                    cursor = constants.cursor;
                    cursor = copyLinkedRootAscii(
                      importedSource,
                      plan.importedModuleStart,
                      plan.importedModuleLength,
                      rootSource,
                      plan.rootInsertion,
                      rootMemberStart - plan.rootInsertion,
                      output,
                      cursor
                    );
                    ImportedRangeCopy members = copyImportedRange(
                      importedSource,
                      importedStarts,
                      importedLengths,
                      importedCount,
                      importedMemberStart,
                      importedEnd - importedMemberStart,
                      plan.privatizeExports,
                      output,
                      cursor
                    );
                    cursor = members.cursor;
                    cursor = copyLinkedRootAscii(
                      importedSource,
                      plan.importedModuleStart,
                      plan.importedModuleLength,
                      rootSource,
                      rootMemberStart,
                      bufferLength(rootSource) - rootMemberStart,
                      output,
                      cursor
                    );
                    long privatized = constants.privatized + members.privatized;
                    boolean copied = constants.valid;
                    if (members.valid) {} else {
                      copied = false;
                    }

                    if (privatized == plan.exportedCount) {} else {
                      copied = false;
                    }

                    if (cursor == plan.linkedLength) {} else {
                      copied = false;
                    }

                    if (copied) {
                      result = cursor;
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
