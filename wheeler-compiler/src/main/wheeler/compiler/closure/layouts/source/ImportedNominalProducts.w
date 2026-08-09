//! Resolves imported nominal names from counted aggregate and string products.

module wheeler.compiler.closure.imported_nominal_products;

classical class ImportedNominalProducts {
  private const long CANDIDATE_ROWS = 8192;
  private const long CLOSURE_AGGREGATE_ROWS = 36864;
  private const long MAX_AGGREGATES = 4096;
  private const long MAX_MODULES = 512;
  private const long MAX_STRINGS = 16384;

  /// Reports one unique aggregate row or a fail-closed candidate count.
  public record ImportedNominalResolution(long aggregateRow, long candidateCount, boolean valid) {}

  private boolean exactName(
    borrow byteview source,
    long sourceStart,
    long sourceLength,
    borrow byteview artifactArchive,
    long artifactStart,
    long artifactLength
  ) {
    if (sourceLength != artifactLength) {
      return false;
    }

    long offset = 0;
    while (offset < sourceLength) limit 4096 {
      if (source[sourceStart + offset] != artifactArchive[artifactStart + offset]) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  /// Resolves one qualified rank or all direct public aggregate candidates.
  public ImportedNominalResolution resolveImportedNominalProduct(
    borrow byteview source,
    long sourceStart,
    long sourceLength,
    borrow byteview artifactArchive,
    long dependencyRank,
    long candidateCount,
    borrow mut words candidateRows,
    borrow mut words aggregateRows,
    borrow mut words moduleFirstStrings,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    long expectedKind
  ) {
    assert(-1 < sourceStart);
    assert(0 < sourceLength);
    assert(sourceStart < bufferLength(source));
    assert(sourceLength < bufferLength(source) - sourceStart + 1);
    assert(-2 < dependencyRank);
    assert(-1 < candidateCount);
    assert(candidateCount < MAX_AGGREGATES + 1);
    assert(bufferLength(candidateRows) == CANDIDATE_ROWS);
    assert(bufferLength(aggregateRows) == CLOSURE_AGGREGATE_ROWS);
    assert(bufferLength(moduleFirstStrings) == MAX_MODULES);
    assert(bufferLength(stringStarts) == MAX_STRINGS);
    assert(bufferLength(stringLengths) == MAX_STRINGS);
    boolean kindValid = expectedKind == 1;
    if (expectedKind == 2) {
      kindValid = true;
    }

    if (expectedKind == 3) {
      kindValid = true;
    }

    if (expectedKind == 4) {
      kindValid = true;
    }

    assert(kindValid);

    boolean valid = true;
    long candidate = 0;
    while (candidate < candidateCount) limit MAX_AGGREGATES {
      long rank = candidateRows[candidate];
      long aggregate = candidateRows[4096 + candidate];
      if (rank < 0) {
        valid = false;
      }

      if (63 < rank) {
        valid = false;
      }

      if (aggregate < 0) {
        valid = false;
      }

      if (MAX_AGGREGATES < aggregate + 1) {
        valid = false;
      }

      if (valid) {
        long owner = aggregateRows[4096 + aggregate];
        long localString = aggregateRows[12288 + aggregate];
        if (owner < 0) {
          valid = false;
        }

        if (MAX_MODULES < owner + 1) {
          valid = false;
        }

        if (localString < 0) {
          valid = false;
        }

        if (valid) {
          long closureString = moduleFirstStrings[owner] + localString;
          if (closureString < 0) {
            valid = false;
          }

          if (MAX_STRINGS < closureString + 1) {
            valid = false;
          }

          if (valid) {
            long artifactStart = stringStarts[closureString];
            long artifactLength = stringLengths[closureString];
            if (artifactStart < 0) {
              valid = false;
            }

            if (artifactLength < 1) {
              valid = false;
            }

            if (bufferLength(artifactArchive) < artifactStart) {
              valid = false;
            }

            if (valid) {
              if (bufferLength(artifactArchive) - artifactStart < artifactLength) {
                valid = false;
              }
            }
          }
        }
      }

      candidate += 1;
    }

    if (valid == false) {
      return new ImportedNominalResolution(-1, 0, false);
    }

    long selected = -1;
    long matches = 0;
    candidate = 0;
    while (candidate < candidateCount) limit MAX_AGGREGATES {
      long selectedRank = candidateRows[candidate];
      long selectedAggregate = candidateRows[4096 + candidate];
      boolean rankMatches = dependencyRank < 0;
      if (selectedRank == dependencyRank) {
        rankMatches = true;
      }

      if (rankMatches) {
        if (aggregateRows[selectedAggregate] == expectedKind) {
          long selectedOwner = aggregateRows[4096 + selectedAggregate];
          long selectedString = moduleFirstStrings[selectedOwner] + aggregateRows[12288
            + selectedAggregate];
          if (
            exactName(
              source,
              sourceStart,
              sourceLength,
              artifactArchive,
              stringStarts[selectedString],
              stringLengths[selectedString]
            )
          ) {
            selected = selectedAggregate;
            matches += 1;
          }
        }
      }

      candidate += 1;
    }

    if (matches == 1) {
      return new ImportedNominalResolution(selected, matches, true);
    }

    return new ImportedNominalResolution(-1, matches, false);
  }
}
