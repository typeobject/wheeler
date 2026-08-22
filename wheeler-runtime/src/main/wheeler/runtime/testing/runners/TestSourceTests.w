//! Discovers bounded test cases in a validated root source.

module wheeler.runtime.testing.runners.test_source_tests;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;
import wheeler.runtime.testing.runners.test_discovered_descriptors;
import wheeler.runtime.testing.runners.test_source_metadata;
import wheeler.runtime.testing.runners.test_source_plan;

classical class TestSourceTests {
  private const long MAX_CASES = 64;
  private const long TOKEN_CASES = 94432067;
  private const long TOKEN_FALSE = 97196323;
  private const long TOKEN_TEST = 3556498;
  private const long TOKEN_TRUE = 3569038;

  /// Reports the discovered case count and complete descriptor match.
  public record SourceTestDiscovery(long count, boolean matched) {}

  private record SourceTestRows(long count, boolean supported, long nextToken) {}

  private long readUnsigned32LittleEndian(borrow byteview input, long offset) {
    return input[offset] + input[offset + 1] * 256 + input[offset + 2] * 65536 + input[offset + 3]
      * 16777216;
  }

  private boolean discoveredNameMatches(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long nameToken,
    borrow byteview descriptor,
    long descriptorStart,
    long descriptorLength,
    borrow byteview targetName,
    long caseIndex
  ) {
    long targetLength = bufferLength(targetName);
    long nameLength = tokenLengths[nameToken];
    long suffixLength = 0;
    if (-1 < caseIndex) {
      suffixLength = 3;
      if (9 < caseIndex) {
        suffixLength = 4;
      }
    }

    if (descriptorLength != targetLength + nameLength + suffixLength + 2) {
      return false;
    }

    long offset = 0;
    while (offset < targetLength) limit 255 {
      if (descriptor[descriptorStart + offset] != targetName[offset]) {
        return false;
      }

      offset += 1;
    }

    if (descriptor[descriptorStart + targetLength] != 58) {
      return false;
    }

    if (descriptor[descriptorStart + targetLength + 1] != 58) {
      return false;
    }

    long nameStart = tokenStarts[nameToken];
    offset = 0;
    while (offset < nameLength) limit 255 {
      if (
        descriptor[descriptorStart + targetLength + 2 + offset] != utf8Scalar(
          source,
          nameStart + offset
        )
      ) {
        return false;
      }

      offset += 1;
    }

    if (-1 < caseIndex) {
      long suffixStart = descriptorStart + targetLength + 2 + nameLength;
      if (descriptor[suffixStart] != 91) {
        return false;
      }

      if (caseIndex < 10) {
        if (descriptor[suffixStart + 1] != 48 + caseIndex) {
          return false;
        }
      } else {
        if (descriptor[suffixStart + 1] != 48 + caseIndex / 10) {
          return false;
        }

        if (descriptor[suffixStart + 2] != 48 + caseIndex % 10) {
          return false;
        }
      }

      if (descriptor[descriptorStart + descriptorLength - 1] != 93) {
        return false;
      }
    }

    return true;
  }

  private long matchingDescriptor(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long nameToken,
    borrow byteview descriptors,
    long descriptorStart,
    long caseCount,
    borrow byteview targetName,
    long caseIndex
  ) {
    long cursor = descriptorStart;
    long selected = -1;
    long testcase = 0;
    while (testcase < caseCount) limit MAX_CASES {
      long nameLength = descriptors[cursor];
      long nameStart = cursor + 1;
      if (
        discoveredNameMatches(
          source,
          tokenStarts,
          tokenLengths,
          nameToken,
          descriptors,
          nameStart,
          nameLength,
          targetName,
          caseIndex
        )
      ) {
        assert(selected < 0);
        selected = testcase;
      }

      long artifactLengthOffset = nameStart + nameLength;
      long artifactLength = readUnsigned32LittleEndian(descriptors, artifactLengthOffset);
      cursor = artifactLengthOffset + 4 + artifactLength;
      testcase += 1;
    }

    return selected;
  }

  private SourceTestRows parameterRows(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long tokenCount,
    long declaration,
    borrow mut words rowValues
  ) {
    if (tokenCount < declaration + 10) {
      return new SourceTestRows(0, false, 0);
    }

    long typeHash = tokenHash(source, tokenStarts, tokenLengths, declaration + 4);
    boolean longRows = typeHash == TOKEN_LONG;
    if (longRows == false) {
      if (typeHash != TOKEN_BOOLEAN) {
        return new SourceTestRows(0, false, 0);
      }
    }

    if (tokenKinds[declaration + 5] != 1) {
      return new SourceTestRows(0, false, 0);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, declaration + 6, PUNCTUATION_CLOSE_PAREN)
        == false
    ) {
      return new SourceTestRows(0, false, 0);
    }

    if (tokenHash(source, tokenStarts, tokenLengths, declaration + 7) != TOKEN_CASES) {
      return new SourceTestRows(0, false, 0);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, declaration + 8, PUNCTUATION_OPEN_PAREN)
        == false
    ) {
      return new SourceTestRows(0, false, 0);
    }

    long cursor = declaration + 9;
    long rowCount = 0;
    while (rowCount < MAX_CASES) limit MAX_CASES {
      if (cursor < tokenCount) {} else {
        return new SourceTestRows(rowCount, false, 0);
      }

      long value = 0;
      if (longRows) {
        long width = signedNumberWidth(source, tokenKinds, tokenStarts, cursor);
        if (width < 1) {
          return new SourceTestRows(rowCount, false, 0);
        }

        if (signedNumberValid(source, tokenStarts, tokenLengths, cursor) == false) {
          return new SourceTestRows(rowCount, false, 0);
        }

        value = parsedSignedNumber(source, tokenStarts, tokenLengths, cursor);
        cursor += width;
      } else {
        long valueHash = tokenHash(source, tokenStarts, tokenLengths, cursor);
        if (valueHash == TOKEN_TRUE) {
          value = 1;
        } else {
          if (valueHash != TOKEN_FALSE) {
            return new SourceTestRows(rowCount, false, 0);
          }
        }

        cursor += 1;
      }

      long prior = 0;
      while (prior < rowCount) limit MAX_CASES {
        if (rowValues[prior] == value) {
          return new SourceTestRows(rowCount, false, 0);
        }

        prior += 1;
      }

      set(rowValues, rowCount, value);
      rowCount += 1;
      if (cursor < tokenCount) {} else {
        return new SourceTestRows(rowCount, false, 0);
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_CLOSE_PAREN)
      ) {
        return new SourceTestRows(rowCount, true, cursor + 1);
      }

      if (punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_COMMA)) {
        cursor += 1;
      } else {
        return new SourceTestRows(rowCount, false, 0);
      }
    }

    return new SourceTestRows(rowCount, false, 0);
  }

  private boolean uniqueTestName(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long nameToken
  ) {
    long prior = 0;
    while (prior + 2 < nameToken) limit MAX_COMPILER_TOKENS {
      if (tokenHash(source, tokenStarts, tokenLengths, prior) == TOKEN_TEST) {
        if (tokenHash(source, tokenStarts, tokenLengths, prior + 1) == TOKEN_VOID) {
          if (sameTokenText(source, tokenStarts, tokenLengths, prior + 2, nameToken)) {
            return false;
          }
        }
      }

      prior += 1;
    }

    return true;
  }

  /// Discovers and binds the bounded root-test profile.
  public SourceTestDiscovery discoverRootTests(
    borrow byteview input,
    long planStart,
    long planLength,
    long rootOrdinal,
    long descriptorStart,
    long caseCount,
    borrow byteview targetName,
    long selectionStart,
    long selectionCount,
    boolean constructDescriptors,
    boolean qualifyModule,
    boolean allowSelectedTagAbsence,
    long rootModuleStart,
    long rootModuleLength,
    borrow mut bytes constructedNames,
    borrow mut words constructedNameLengths,
    borrow mut words caseKinds,
    borrow mut words caseValues,
    borrow mut words caseStepLimits
  ) {
    assert(bufferLength(constructedNames) == MAX_CASES * 255);
    assert(bufferLength(constructedNameLengths) == MAX_CASES);
    assert(bufferLength(caseKinds) == MAX_CASES);
    assert(bufferLength(caseValues) == MAX_CASES);
    assert(bufferLength(caseStepLimits) == MAX_CASES);
    long sourceLength = validatedSourceLength(input, planStart, planLength, rootOrdinal);
    region arena = new region(/* bytes= */ 109056, /* allocations= */ 9);
    bytes sourceBytes = allocateBytes(arena, sourceLength);
    copyValidatedSource(input, planStart, planLength, rootOrdinal, sourceBytes);
    utf8 source = freezeUtf8(sourceBytes);
    words tokenKinds = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(arena, MAX_COMPILER_TOKENS);
    words rowValues = allocate(arena, MAX_CASES);
    words knownTags = allocate(arena, MAX_CASES);
    words declarationMatches = allocate(arena, MAX_CASES);
    words metadataTagStarts = allocate(arena, MAX_CASES);
    words metadataTagEnds = allocate(arena, MAX_CASES);
    long tokenCount = 0;
    ScanResult scanned = scan(source, tokenKinds, tokenStarts, tokenLengths);
    match (scanned) {
      case ScanResult.Value(long count) {
        tokenCount = count;
      }
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        assert(diagnostic.offset < 0);
      }
    }

    long discovered = 0;
    long matchedDeclarations = 0;
    boolean supported = true;
    long token = 0;
    while (token + 4 < tokenCount) limit MAX_COMPILER_TOKENS {
      if (tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_TEST) {
        if (tokenHash(source, tokenStarts, tokenLengths, token + 1) == TOKEN_VOID) {
          if (uniqueTestName(source, tokenStarts, tokenLengths, token + 2) == false) {
            supported = false;
          }

          boolean parameterless = punctuationAt(
            source,
            tokenKinds,
            tokenStarts,
            token + 3,
            PUNCTUATION_OPEN_PAREN
          );
          if (parameterless) {
            parameterless = punctuationAt(
              source,
              tokenKinds,
              tokenStarts,
              token + 4,
              PUNCTUATION_CLOSE_PAREN
            );
          }

          if (parameterless) {
            SourceTestMetadata parameterlessMetadata = validatedTestMetadata(
              source,
              tokenKinds,
              tokenStarts,
              tokenLengths,
              tokenCount,
              token + 5,
              input,
              selectionStart,
              selectionCount,
              knownTags,
              declarationMatches,
              metadataTagStarts,
              metadataTagEnds
            );
            if (parameterlessMetadata.supported == false) {
              supported = false;
            }

            if (parameterlessMetadata.selected) {
              long matchedCase = -1;
              if (constructDescriptors) {
                matchedCase = discovered;
                writeDiscoveredCaseName(
                  source,
                  tokenStarts,
                  tokenLengths,
                  token + 2,
                  targetName,
                  input,
                  rootModuleStart,
                  rootModuleLength,
                  qualifyModule,
                  /* row= */ -1,
                  discovered,
                  constructedNames,
                  constructedNameLengths
                );
              } else {
                matchedCase = matchingDescriptor(
                  source,
                  tokenStarts,
                  tokenLengths,
                  token + 2,
                  input,
                  descriptorStart,
                  caseCount,
                  targetName,
                  -1
                );
              }

              if (-1 < matchedCase) {
                set(caseKinds, matchedCase, /* parameterless= */ 1);
                set(caseValues, matchedCase, 0);
                set(caseStepLimits, matchedCase, parameterlessMetadata.stepLimit);
                matchedDeclarations += 1;
              }

              discovered += 1;
            }
          } else {
            SourceTestRows rows = parameterRows(
              source,
              tokenKinds,
              tokenStarts,
              tokenLengths,
              tokenCount,
              token,
              rowValues
            );
            SourceTestMetadata rowMetadata = validatedTestMetadata(
              source,
              tokenKinds,
              tokenStarts,
              tokenLengths,
              tokenCount,
              rows.nextToken,
              input,
              selectionStart,
              selectionCount,
              knownTags,
              declarationMatches,
              metadataTagStarts,
              metadataTagEnds
            );
            if (rows.supported == false) {
              supported = false;
            }

            if (rowMetadata.supported == false) {
              supported = false;
            }

            long caseKind = 2;
            if (
              tokenHash(source, tokenStarts, tokenLengths, token + 4) == TOKEN_BOOLEAN
            ) {
              caseKind = 3;
            }

            long row = 0;
            while (row < rows.count) limit MAX_CASES {
              long matchedRowCase = -1;
              if (rowMetadata.selected) {
                if (constructDescriptors) {
                  matchedRowCase = discovered;
                  writeDiscoveredCaseName(
                    source,
                    tokenStarts,
                    tokenLengths,
                    token + 2,
                    targetName,
                    input,
                    rootModuleStart,
                    rootModuleLength,
                    qualifyModule,
                    row,
                    discovered,
                    constructedNames,
                    constructedNameLengths
                  );
                } else {
                  matchedRowCase = matchingDescriptor(
                    source,
                    tokenStarts,
                    tokenLengths,
                    token + 2,
                    input,
                    descriptorStart,
                    caseCount,
                    targetName,
                    row
                  );
                }
              }

              if (-1 < matchedRowCase) {
                set(caseKinds, matchedRowCase, caseKind);
                set(caseValues, matchedRowCase, rowValues[row]);
                set(caseStepLimits, matchedRowCase, rowMetadata.stepLimit);
                matchedDeclarations += 1;
              }

              if (rowMetadata.selected) {
                discovered += 1;
              }

              row += 1;
            }
          }
        }
      }

      token += 1;
    }

    if (allowSelectedTagAbsence == false) {
      long selectedTag = 0;
      while (selectedTag < selectionCount) limit MAX_CASES {
        if (knownTags[selectedTag] == 0) {
          supported = false;
        }

        selectedTag += 1;
      }
    }

    boolean matched = supported;
    if (constructDescriptors == false) {
      if (discovered != caseCount) {
        matched = false;
      }
    }

    if (matchedDeclarations != discovered) {
      matched = false;
    }

    drop(metadataTagEnds);
    drop(metadataTagStarts);
    drop(declarationMatches);
    drop(knownTags);
    drop(rowValues);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(source);
    drop(arena);
    return new SourceTestDiscovery(discovered, matched);
  }
}
