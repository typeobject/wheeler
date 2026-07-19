//! Parses a bounded canonical-YAML dependency lock.

module wheeler.packages.lock;

import wheeler.packages.names;
import wheeler.packages.semver;
import wheeler.packages.tokens;

classical class Lock {
  /// Carries scalar ranges and collection counts for one validated lock.
  public record LockModel(long rootStart, long rootLength, long packageCount, long edgeCount) {}

  /// Defines the closed package-lock parse result.
  public variant LockResult {
    case Value(LockModel lock);
    case Error(long offset);
  }

  private boolean key(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long token,
    long hash
  ) {
    if (token + 1 < count) {
      if (keywordAt(source, starts, lengths, token, hash)) {
        return colonAt(source, kinds, starts, token + 1);
      }
    }

    return false;
  }

  private boolean punctuation(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    long count,
    long token,
    long scalar
  ) {
    if (token < count) {
      if (kinds[token] == 3) {
        return utf8Scalar(source, starts[token]) == scalar;
      }
    }

    return false;
  }

  private boolean hexDigest(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    if (quoted(kinds, lengths, token)) {
      if (lengths[token] == 66) {
        long cursor = starts[token] + 1;
        long end = cursor + 64;
        while (cursor < end) limit 64 {
          long scalar = utf8Scalar(source, cursor);
          boolean valid = false;
          if (47 < scalar) {
            if (scalar < 58) {
              valid = true;
            }
          }

          if (96 < scalar) {
            if (scalar < 103) {
              valid = true;
            }
          }

          if (valid) {
            cursor += 1;
          } else {
            return false;
          }
        }

        return true;
      }
    }

    return false;
  }

  private boolean packageFieldsValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    if (cursor + 17 < count) {
      if (dashAt(source, kinds, starts, cursor)) {
        if (key(source, kinds, starts, lengths, count, cursor + 1, 3373707)) {
          if (quoted(kinds, lengths, cursor + 3)) {
            boolean validName = validPackageName(
              source,
              starts[cursor + 3] + 1,
              lengths[cursor + 3] - 2
            );
            if (validName) {
              if (
                key(source, kinds, starts, lengths, count, cursor + 4, 107725790424)
              ) {
                if (quoted(kinds, lengths, cursor + 6)) {
                  boolean validVersion = validRelease(
                    source,
                    starts[cursor + 6] + 1,
                    lengths[cursor + 6] - 2
                  );
                  if (validVersion) {
                    if (
                      key(
                        source,
                        kinds,
                        starts,
                        lengths,
                        count,
                        cursor + 7,
                        3103442239675210
                      )
                    ) {
                      if (hexDigest(source, kinds, starts, lengths, cursor + 9)) {
                        if (
                          key(
                            source,
                            kinds,
                            starts,
                            lengths,
                            count,
                            cursor + 10,
                            89446211778
                          )
                        ) {
                          if (hexDigest(source, kinds, starts, lengths, cursor + 12)) {
                            if (
                              key(
                                source,
                                kinds,
                                starts,
                                lengths,
                                count,
                                cursor + 13,
                                3088212110895
                              )
                            ) {
                              if (
                                hexDigest(source, kinds, starts, lengths, cursor + 15)
                              ) {
                                return key(
                                  source,
                                  kinds,
                                  starts,
                                  lengths,
                                  count,
                                  cursor + 16,
                                  2626680644436426025
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

    return false;
  }

  private boolean sameRange(
    borrow utf8 source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    if (leftLength == rightLength) {
      long offset = 0;
      while (offset < leftLength) limit 4096 {
        if (
          utf8Scalar(source, leftStart + offset) == utf8Scalar(source, rightStart + offset)
        ) {
          offset += 1;
        } else {
          return false;
        }
      }

      return true;
    }

    return false;
  }

  private boolean packageCapacity(
    borrow mut words packageNameStarts,
    borrow mut words packageNameLengths,
    borrow mut words versionStarts,
    borrow mut words versionLengths,
    borrow mut words repositoryStarts,
    borrow mut words archiveStarts,
    borrow mut words manifestStarts,
    borrow mut words dependencyOffsets,
    borrow mut words dependencyCounts,
    long packageCount
  ) {
    if (packageCount < bufferLength(packageNameStarts)) {
      if (packageCount < bufferLength(packageNameLengths)) {
        if (packageCount < bufferLength(versionStarts)) {
          if (packageCount < bufferLength(versionLengths)) {
            if (packageCount < bufferLength(repositoryStarts)) {
              if (packageCount < bufferLength(archiveStarts)) {
                if (packageCount < bufferLength(manifestStarts)) {
                  if (packageCount < bufferLength(dependencyOffsets)) {
                    return packageCount < bufferLength(dependencyCounts);
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

  private boolean edgeCapacity(
    borrow mut words edgeTargetStarts,
    borrow mut words edgeTargetLengths,
    long edgeCount
  ) {
    if (edgeCount < bufferLength(edgeTargetStarts)) {
      return edgeCount < bufferLength(edgeTargetLengths);
    }

    return false;
  }

  private boolean allEdgesResolve(
    borrow utf8 source,
    borrow mut words packageNameStarts,
    borrow mut words packageNameLengths,
    long packageCount,
    borrow mut words edgeTargetStarts,
    borrow mut words edgeTargetLengths,
    long edgeCount
  ) {
    long edge = 0;
    while (edge < edgeCount) limit 1024 {
      boolean found = false;
      long package = 0;
      while (package < packageCount) limit 512 {
        boolean same = sameRange(
          source,
          edgeTargetStarts[edge],
          edgeTargetLengths[edge],
          packageNameStarts[package],
          packageNameLengths[package]
        );
        if (same) {
          found = true;
        }

        package += 1;
      }

      if (found == false) {
        return false;
      }

      edge += 1;
    }

    return true;
  }

  /// Parses every package and edge that fits the caller-provided bounded tables.
  public LockResult parse(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    borrow mut words packageNameStarts,
    borrow mut words packageNameLengths,
    borrow mut words versionStarts,
    borrow mut words versionLengths,
    borrow mut words repositoryStarts,
    borrow mut words archiveStarts,
    borrow mut words manifestStarts,
    borrow mut words dependencyOffsets,
    borrow mut words dependencyCounts,
    borrow mut words edgeTargetStarts,
    borrow mut words edgeTargetLengths
  ) {
    if (count < 10) {
      return new LockResult.Error(0);
    }

    if (key(source, kinds, starts, lengths, count, 0, 3386979745) == false) {
      return new LockResult.Error(0);
    }

    boolean schemaTwo = tokenHash(source, starts, lengths, 2) == 50;
    if (schemaTwo == false) {
      return new LockResult.Error(starts[2]);
    }

    if (key(source, kinds, starts, lengths, count, 3, 3506402) == false) {
      return new LockResult.Error(starts[3]);
    }

    if (hexDigest(source, kinds, starts, lengths, 5) == false) {
      return new LockResult.Error(starts[5]);
    }

    if (key(source, kinds, starts, lengths, count, 6, 3170436732141) == false) {
      return new LockResult.Error(starts[6]);
    }

    long cursor = 8;
    if (punctuation(source, kinds, starts, count, cursor, 91)) {
      if (punctuation(source, kinds, starts, count, cursor + 1, 93)) {
        if (count == cursor + 2) {
          LockModel empty = new LockModel(starts[5] + 1, 64, 0, 0);
          return new LockResult.Value(empty);
        }
      }

      return new LockResult.Error(starts[cursor]);
    }

    long packageCount = 0;
    long edgeCount = 0;
    long previousNameToken = -1;
    while (cursor < count) limit 512 {
      if (
        packageFieldsValid(source, kinds, starts, lengths, count, cursor) == false
      ) {
        return new LockResult.Error(starts[cursor]);
      }

      if (
        packageCapacity(
          packageNameStarts,
          packageNameLengths,
          versionStarts,
          versionLengths,
          repositoryStarts,
          archiveStarts,
          manifestStarts,
          dependencyOffsets,
          dependencyCounts,
          packageCount
        ) == false
      ) {
        return new LockResult.Error(starts[cursor]);
      }

      if (-1 < previousNameToken) {
        long order = compareTokenText(source, starts, lengths, previousNameToken, cursor + 3);
        boolean ordered = order < 0;
        if (ordered == false) {
          return new LockResult.Error(starts[cursor + 3]);
        }
      }

      set(packageNameStarts, packageCount, starts[cursor + 3] + 1);
      set(packageNameLengths, packageCount, lengths[cursor + 3] - 2);
      set(versionStarts, packageCount, starts[cursor + 6] + 1);
      set(versionLengths, packageCount, lengths[cursor + 6] - 2);
      set(repositoryStarts, packageCount, starts[cursor + 9] + 1);
      set(archiveStarts, packageCount, starts[cursor + 12] + 1);
      set(manifestStarts, packageCount, starts[cursor + 15] + 1);
      set(dependencyOffsets, packageCount, edgeCount);

      long dependencyCursor = cursor + 18;
      long dependencyCount = 0;
      long previousDependencyToken = -1;
      if (punctuation(source, kinds, starts, count, dependencyCursor, 91)) {
        if (punctuation(source, kinds, starts, count, dependencyCursor + 1, 93)) {
          dependencyCursor += 2;
        } else {
          return new LockResult.Error(starts[dependencyCursor]);
        }
      } else {
        boolean scanning = true;
        while (scanning) limit 1024 {
          if (dependencyCursor + 1 < count) {
            if (dashAt(source, kinds, starts, dependencyCursor)) {
              if (quoted(kinds, lengths, dependencyCursor + 1)) {
                boolean validDependency = validPackageName(
                  source,
                  starts[dependencyCursor + 1] + 1,
                  lengths[dependencyCursor + 1] - 2
                );
                if (validDependency == false) {
                  return new LockResult.Error(starts[dependencyCursor + 1]);
                }

                if (
                  edgeCapacity(edgeTargetStarts, edgeTargetLengths, edgeCount) == false
                ) {
                  return new LockResult.Error(starts[dependencyCursor]);
                }

                if (-1 < previousDependencyToken) {
                  long dependencyOrder = compareTokenText(
                    source,
                    starts,
                    lengths,
                    previousDependencyToken,
                    dependencyCursor + 1
                  );
                  boolean dependenciesOrdered = dependencyOrder < 0;
                  if (dependenciesOrdered == false) {
                    return new LockResult.Error(starts[dependencyCursor + 1]);
                  }
                }

                set(edgeTargetStarts, edgeCount, starts[dependencyCursor + 1] + 1);
                set(edgeTargetLengths, edgeCount, lengths[dependencyCursor + 1] - 2);
                edgeCount += 1;
                dependencyCount += 1;
                previousDependencyToken = dependencyCursor + 1;
                dependencyCursor += 2;
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

        if (dependencyCount == 0) {
          return new LockResult.Error(0);
        }
      }

      set(dependencyCounts, packageCount, dependencyCount);
      packageCount += 1;
      previousNameToken = cursor + 3;
      cursor = dependencyCursor;
    }

    boolean edgesResolve = allEdgesResolve(
      source,
      packageNameStarts,
      packageNameLengths,
      packageCount,
      edgeTargetStarts,
      edgeTargetLengths,
      edgeCount
    );
    if (edgesResolve == false) {
      return new LockResult.Error(0);
    }

    LockModel lock = new LockModel(starts[5] + 1, 64, packageCount, edgeCount);
    return new LockResult.Value(lock);
  }
}
