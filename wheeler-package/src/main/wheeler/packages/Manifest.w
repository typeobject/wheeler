//! Parses bounded canonical package manifests.

module wheeler.packages.manifest;

import wheeler.lexer.scanner;
import wheeler.packages.names;
import wheeler.packages.paths;
import wheeler.packages.semver;
import wheeler.packages.tokens;

classical class Manifest {
  /// Defines immutable `QuotedRange` values for this module.
  public record QuotedRange(long start, long length) {}

  /// Defines immutable `ManifestHeader` values for this module.
  public record ManifestHeader(
    QuotedRange name,
    QuotedRange version,
    QuotedRange profile,
    QuotedRange targetName,
    QuotedRange targetRoot,
    QuotedRange targetModule,
    QuotedRange targetSource,
    QuotedRange targetSecondSource,
    QuotedRange targetThirdSource,
    QuotedRange targetFourthSource,
    long targetSourceCount,
    long targetTest,
    QuotedRange secondTargetName,
    QuotedRange secondTargetRoot,
    long secondTargetTest,
    long targetCount,
    QuotedRange dependencyName,
    QuotedRange dependencyVersion,
    QuotedRange secondDependencyName,
    QuotedRange secondDependencyVersion,
    long dependencyCount,
    QuotedRange capabilityName,
    QuotedRange capabilityPath,
    QuotedRange secondCapabilityName,
    QuotedRange secondCapabilityPath,
    long capabilityCount
  ) {}

  /// Describes one bounded target record after its optional test selector is classified.
  public record TargetShape(long sourceCount, long tokenCount, boolean test) {}

  /// Defines the closed `ManifestResult` cases exported by this module.
  public variant ManifestResult {
    case Value(ManifestHeader header);
    case Error(long offset);
  }

  private QuotedRange quotedRange(borrow mut words starts, borrow mut words lengths, long token) {
    return new QuotedRange(starts[token] + 1, lengths[token] - 2);
  }

  private boolean baseHeaderValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths
  ) {
    boolean validName = validPackageName(source, starts[1] + 1, lengths[1] - 2);
    boolean validVersion = validRelease(source, starts[3] + 1, lengths[3] - 2);
    if (keywordAt(source, starts, lengths, 0, 102272152646)) {
      if (quoted(kinds, lengths, 1)) {
        if (validName) {
          if (keywordAt(source, starts, lengths, 2, 107725790424)) {
            if (quoted(kinds, lengths, 3)) {
              if (validVersion) {
                if (keywordAt(source, starts, lengths, 4, 102769789353)) {
                  if (quoted(kinds, lengths, 5)) {
                    return semicolonAt(source, kinds, starts, 6);
                  }
                }
              }
            }
          }
        }
      }
    }

    return false;
  }

  private boolean targetKindValid(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long recordStart
  ) {
    long hash = tokenHash(source, starts, lengths, recordStart + 1);
    if (hash == 2733284766595777) {
      return true;
    }

    if (hash == 98950456507) {
      return true;
    }

    return hash == 3565976;
  }

  private boolean dependencyKindValid(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long recordStart
  ) {
    long hash = tokenHash(source, starts, lengths, recordStart + 1);
    if (hash == 3255221479) {
      return true;
    }

    if (hash == 84736749587766587) {
      return true;
    }

    return hash == 94094958;
  }

  private boolean targetKindTestable(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long recordStart
  ) {
    long hash = tokenHash(source, starts, lengths, recordStart + 1);
    if (hash == 2733284766595777) {
      return true;
    }

    return hash == 3565976;
  }

  private TargetShape targetShape(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long recordStart
  ) {
    TargetShape invalid = new TargetShape(-1, 0, false);
    if (count < recordStart + 5) {
      return invalid;
    }

    if (count == recordStart + 5) {
      return invalid;
    }

    if (semicolonAt(source, kinds, starts, recordStart + 5)) {
      return new TargetShape(0, 6, false);
    }

    if (keywordAt(source, starts, lengths, recordStart + 5, 3556498)) {
      if (targetKindTestable(source, starts, lengths, recordStart)) {
        if (recordStart + 6 < count) {
          if (semicolonAt(source, kinds, starts, recordStart + 6)) {
            return new TargetShape(0, 7, true);
          }
        }
      }

      return invalid;
    }

    if (keywordAt(source, starts, lengths, recordStart + 5, 3226183276)) {
      if (quoted(kinds, lengths, recordStart + 6)) {
        long sourceCount = 0;
        long cursor = recordStart + 7;
        boolean scanning = true;
        while (scanning) limit 5 {
          if (cursor + 1 < count) {
            if (keywordAt(source, starts, lengths, cursor, 3398461467)) {
              if (quoted(kinds, lengths, cursor + 1)) {
                sourceCount += 1;
                cursor += 2;
              } else {
                scanning = false;
              }
            } else {
              scanning = false;
            }
          } else {
            scanning = false;
          }
        }

        if (0 < sourceCount) {
          if (cursor < count) {
            if (semicolonAt(source, kinds, starts, cursor)) {
              return new TargetShape(sourceCount, cursor - recordStart + 1, false);
            }

            if (keywordAt(source, starts, lengths, cursor, 3556498)) {
              if (targetKindTestable(source, starts, lengths, recordStart)) {
                if (cursor + 1 < count) {
                  if (semicolonAt(source, kinds, starts, cursor + 1)) {
                    return new TargetShape(sourceCount, cursor - recordStart + 2, true);
                  }
                }
              }
            }
          }
        }
      }
    }

    return invalid;
  }

  private boolean targetValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    TargetShape shape,
    long recordStart
  ) {
    boolean validRoot = validLogicalPath(
      source,
      starts[recordStart + 4] + 1,
      lengths[recordStart + 4] - 2
    );
    boolean baseValid = false;
    if (keywordAt(source, starts, lengths, recordStart, 3414061457)) {
      if (targetKindValid(source, starts, lengths, recordStart)) {
        if (quoted(kinds, lengths, recordStart + 2)) {
          if (keywordAt(source, starts, lengths, recordStart + 3, 3506402)) {
            if (quoted(kinds, lengths, recordStart + 4)) {
              baseValid = validRoot;
            }
          }
        }
      }
    }

    if (baseValid) {
      if (shape.sourceCount == 0) {
        return true;
      }

      boolean validModule = validModuleName(
        source,
        starts[recordStart + 6] + 1,
        lengths[recordStart + 6] - 2
      );
      if (keywordAt(source, starts, lengths, recordStart + 5, 3226183276)) {
        if (quoted(kinds, lengths, recordStart + 6)) {
          if (validModule) {
            long sourceNumber = 0;
            long sourceToken = recordStart + 8;
            long previousToken = -1;
            boolean sourcesValid = true;
            boolean sourceIncludesRoot = false;
            while (sourceNumber < shape.sourceCount) limit 4 {
              boolean validSource = validLogicalPath(
                source,
                starts[sourceToken] + 1,
                lengths[sourceToken] - 2
              );
              if (validSource) {
                if (
                  sameTokenText(source, starts, lengths, recordStart + 4, sourceToken)
                ) {
                  sourceIncludesRoot = true;
                }

                if (-1 < previousToken) {
                  long sourceOrder = compareTokenText(
                    source,
                    starts,
                    lengths,
                    previousToken,
                    sourceToken
                  );
                  if (sourceOrder == 0) {
                    sourcesValid = false;
                  }

                  if (0 < sourceOrder) {
                    sourcesValid = false;
                  }
                }
              } else {
                sourcesValid = false;
              }

              previousToken = sourceToken;
              sourceToken += 2;
              sourceNumber += 1;
            }

            if (sourcesValid) {
              if (sourceIncludesRoot) {
                return true;
              }
            }
          }
        }
      }
    }

    return false;
  }

  private boolean dependencyValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long recordStart
  ) {
    boolean validName = validPackageName(
      source,
      starts[recordStart + 2] + 1,
      lengths[recordStart + 2] - 2
    );
    boolean validVersion = validConstraint(
      source,
      starts[recordStart + 4] + 1,
      lengths[recordStart + 4] - 2
    );
    if (keywordAt(source, starts, lengths, recordStart, 2733278506177355)) {
      if (dependencyKindValid(source, starts, lengths, recordStart)) {
        if (quoted(kinds, lengths, recordStart + 2)) {
          if (validName) {
            if (keywordAt(source, starts, lengths, recordStart + 3, 107725790424)) {
              if (quoted(kinds, lengths, recordStart + 4)) {
                if (validVersion) {
                  return semicolonAt(source, kinds, starts, recordStart + 5);
                }
              }
            }
          }
        }
      }
    }

    return false;
  }

  private boolean capabilityValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long recordStart
  ) {
    boolean validPath = validLogicalPath(
      source,
      starts[recordStart + 3] + 1,
      lengths[recordStart + 3] - 2
    );
    if (keywordAt(source, starts, lengths, recordStart, 2703423431124248)) {
      if (quoted(kinds, lengths, recordStart + 1)) {
        if (keywordAt(source, starts, lengths, recordStart + 2, 3433509)) {
          if (quoted(kinds, lengths, recordStart + 3)) {
            if (validPath) {
              return semicolonAt(source, kinds, starts, recordStart + 4);
            }
          }
        }
      }
    }

    return false;
  }

  private ManifestHeader header(
    borrow mut words starts,
    borrow mut words lengths,
    long targetCount,
    long dependencyCount,
    long capabilityCount,
    TargetShape firstShape,
    TargetShape secondShape
  ) {
    QuotedRange empty = new QuotedRange(0, 0);
    QuotedRange targetName = empty;
    QuotedRange targetRoot = empty;
    QuotedRange targetModule = empty;
    QuotedRange targetSource = empty;
    QuotedRange targetSecondSource = empty;
    QuotedRange targetThirdSource = empty;
    QuotedRange targetFourthSource = empty;
    long targetSourceCount = 0;
    QuotedRange secondTargetName = empty;
    QuotedRange secondTargetRoot = empty;
    QuotedRange dependencyName = empty;
    QuotedRange dependencyVersion = empty;
    QuotedRange secondDependencyName = empty;
    QuotedRange secondDependencyVersion = empty;
    QuotedRange capabilityName = empty;
    QuotedRange capabilityPath = empty;
    QuotedRange secondCapabilityName = empty;
    QuotedRange secondCapabilityPath = empty;
    if (0 < targetCount) {
      targetName = quotedRange(starts, lengths, 9);
      targetRoot = quotedRange(starts, lengths, 11);
    }

    if (0 < firstShape.sourceCount) {
      targetModule = quotedRange(starts, lengths, 13);
      targetSource = quotedRange(starts, lengths, 15);
      targetSourceCount = firstShape.sourceCount;
    }

    if (1 < firstShape.sourceCount) {
      targetSecondSource = quotedRange(starts, lengths, 17);
    }

    if (2 < firstShape.sourceCount) {
      targetThirdSource = quotedRange(starts, lengths, 19);
    }

    if (3 < firstShape.sourceCount) {
      targetFourthSource = quotedRange(starts, lengths, 21);
    }

    long secondTargetStart = 7 + firstShape.tokenCount;
    if (1 < targetCount) {
      secondTargetName = quotedRange(starts, lengths, secondTargetStart + 2);
      secondTargetRoot = quotedRange(starts, lengths, secondTargetStart + 4);
    }

    long dependencyStart = secondTargetStart;
    if (1 < targetCount) {
      dependencyStart += secondShape.tokenCount;
    }

    if (0 < dependencyCount) {
      dependencyName = quotedRange(starts, lengths, dependencyStart + 2);
      dependencyVersion = quotedRange(starts, lengths, dependencyStart + 4);
    }

    if (1 < dependencyCount) {
      secondDependencyName = quotedRange(starts, lengths, dependencyStart + 8);
      secondDependencyVersion = quotedRange(starts, lengths, dependencyStart + 10);
    }

    long capabilityStart = dependencyStart + dependencyCount * 6;
    if (0 < capabilityCount) {
      capabilityName = quotedRange(starts, lengths, capabilityStart + 1);
      capabilityPath = quotedRange(starts, lengths, capabilityStart + 3);
    }

    if (1 < capabilityCount) {
      secondCapabilityName = quotedRange(starts, lengths, capabilityStart + 6);
      secondCapabilityPath = quotedRange(starts, lengths, capabilityStart + 8);
    }

    long targetTest = 0;
    if (firstShape.test) {
      targetTest = 1;
    }

    long secondTargetTest = 0;
    if (secondShape.test) {
      secondTargetTest = 1;
    }

    return new ManifestHeader(
      quotedRange(starts, lengths, 1),
      quotedRange(starts, lengths, 3),
      quotedRange(starts, lengths, 5),
      targetName,
      targetRoot,
      targetModule,
      targetSource,
      targetSecondSource,
      targetThirdSource,
      targetFourthSource,
      targetSourceCount,
      targetTest,
      secondTargetName,
      secondTargetRoot,
      secondTargetTest,
      targetCount,
      dependencyName,
      dependencyVersion,
      secondDependencyName,
      secondDependencyVersion,
      dependencyCount,
      capabilityName,
      capabilityPath,
      secondCapabilityName,
      secondCapabilityPath,
      capabilityCount
    );
  }

  private ManifestResult parseRecords(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    TargetShape firstShape
  ) {
    if (targetValid(source, kinds, starts, lengths, firstShape, 7)) {
      long cursor = 7 + firstShape.tokenCount;
      long targetCount = 1;
      boolean targetsSorted = true;
      TargetShape secondShape = targetShape(source, kinds, starts, lengths, count, cursor);
      if (secondShape.sourceCount == 0) {
        if (targetValid(source, kinds, starts, lengths, secondShape, cursor)) {
          long targetOrder = compareTokenText(source, starts, lengths, 9, cursor + 2);
          if (targetOrder < 0) {
            targetCount = 2;
            cursor += secondShape.tokenCount;
          } else {
            targetsSorted = false;
          }
        }
      }

      long dependencyCount = 0;
      boolean dependenciesSorted = targetsSorted;
      if (dependencyValid(source, kinds, starts, lengths, cursor)) {
        dependencyCount = 1;
        cursor += 6;
        if (dependencyValid(source, kinds, starts, lengths, cursor)) {
          long dependencyOrder = compareTokenText(
            source,
            starts,
            lengths,
            cursor - 4,
            cursor + 2
          );
          if (dependencyOrder < 0) {
            dependencyCount = 2;
            cursor += 6;
          } else {
            dependenciesSorted = false;
          }
        }
      }

      if (dependenciesSorted) {
        long capabilityCount = 0;
        boolean capabilitiesSorted = true;
        if (capabilityValid(source, kinds, starts, lengths, cursor)) {
          capabilityCount = 1;
          cursor += 5;
          if (capabilityValid(source, kinds, starts, lengths, cursor)) {
            long capabilityNameOrder = compareTokenText(
              source,
              starts,
              lengths,
              cursor - 4,
              cursor + 1
            );
            long capabilityPathOrder = compareTokenText(
              source,
              starts,
              lengths,
              cursor - 2,
              cursor + 3
            );
            if (capabilityNameOrder < 0) {
              capabilityCount = 2;
              cursor += 5;
            } else {
              if (capabilityNameOrder == 0) {
                if (capabilityPathOrder < 0) {
                  capabilityCount = 2;
                  cursor += 5;
                } else {
                  capabilitiesSorted = false;
                }
              } else {
                capabilitiesSorted = false;
              }
            }
          }
        }

        if (capabilitiesSorted) {
          if (count == cursor) {
            return new ManifestResult.Value(
              header(
                starts,
                lengths,
                targetCount,
                dependencyCount,
                capabilityCount,
                firstShape,
                secondShape
              )
            );
          }
        }
      }
    }

    return new ManifestResult.Error(0);
  }

  /// Parses and validates one canonical package-manifest header.
  public ManifestResult parseHeader(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    if (baseHeaderValid(source, kinds, starts, lengths)) {
      TargetShape empty = new TargetShape(0, 0, false);
      if (count == 7) {
        return new ManifestResult.Value(header(starts, lengths, 0, 0, 0, empty, empty));
      }

      TargetShape firstShape = targetShape(source, kinds, starts, lengths, count, 7);
      if (-1 < firstShape.sourceCount) {
        return parseRecords(source, kinds, starts, lengths, count, firstShape);
      }
    }

    return new ManifestResult.Error(0);
  }
}
