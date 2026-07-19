//! Parses bounded canonical-YAML package manifests.

module wheeler.packages.manifest;

import wheeler.packages.names;
import wheeler.packages.paths;
import wheeler.packages.semver;
import wheeler.packages.tokens;

classical class Manifest {
  /// Number of words in one target row.
  public const long TARGET_ROW_WIDTH = 10;
  /// Target-kind column.
  public const long TARGET_KIND = 0;
  /// Target-name start column.
  public const long TARGET_NAME_START = 1;
  /// Target-name length column.
  public const long TARGET_NAME_LENGTH = 2;
  /// Target-root start column.
  public const long TARGET_ROOT_START = 3;
  /// Target-root length column.
  public const long TARGET_ROOT_LENGTH = 4;
  /// Target-module start column, or zero for a nonmodular target.
  public const long TARGET_MODULE_START = 5;
  /// Target-module length column, or zero for a nonmodular target.
  public const long TARGET_MODULE_LENGTH = 6;
  /// First source-selector row column.
  public const long TARGET_SOURCE_OFFSET = 7;
  /// Source-selector count column.
  public const long TARGET_SOURCE_COUNT = 8;
  /// Test-selection Boolean column.
  public const long TARGET_TEST = 9;

  /// Number of words in one source-selector row.
  public const long SOURCE_ROW_WIDTH = 2;
  /// Number of words in one dependency row.
  public const long DEPENDENCY_ROW_WIDTH = 5;
  /// Number of words in one capability row.
  public const long CAPABILITY_ROW_WIDTH = 4;

  /// Defines one quoted source range without copying its bytes.
  public record QuotedRange(long start, long length) {}

  /// Carries scalar ranges and collection counts for one validated manifest.
  public record ManifestModel(
    QuotedRange name,
    QuotedRange version,
    QuotedRange profile,
    long targetCount,
    long sourceCount,
    long dependencyCount,
    long capabilityCount
  ) {}

  /// Defines the closed parse result; malformed YAML never returns a model.
  public variant ManifestResult {
    case Value(ManifestModel manifest);
    case Error(long offset);
  }

  private record TargetParse(
    boolean valid,
    long next,
    long kind,
    long nameToken,
    long rootToken,
    long moduleToken,
    long sourceOffset,
    long sourceCount,
    long test
  ) {}

  private record DependencyParse(
    boolean valid,
    long next,
    long kind,
    long nameToken,
    long versionToken
  ) {}

  private record CapabilityParse(boolean valid, long next, long nameToken, long pathToken) {}

  private QuotedRange range(borrow mut words starts, borrow mut words lengths, long token) {
    return new QuotedRange(starts[token] + 1, lengths[token] - 2);
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

  private long booleanToken(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    long hash = tokenHash(source, starts, lengths, token);
    if (hash == 3569038) {
      return 1;
    }

    if (hash == 97196323) {
      return 0;
    }

    return -1;
  }

  private long targetKind(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    if (quoted(kinds, lengths, token)) {
      long hash = quotedHash(source, starts, lengths, token);
      if (hash == 2733284766595777) {
        return 1;
      }

      if (hash == 98950456507) {
        return 2;
      }

      if (hash == 3565976) {
        return 3;
      }
    }

    return 0;
  }

  private long dependencyKind(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    if (quoted(kinds, lengths, token)) {
      long hash = quotedHash(source, starts, lengths, token);
      if (hash == 3255221479) {
        return 1;
      }

      if (hash == 84736749587766587) {
        return 2;
      }

      if (hash == 94094958) {
        return 3;
      }
    }

    return 0;
  }

  private boolean rowCapacity(borrow mut words rows, long row, long width) {
    long finalColumn = row * width + width - 1;
    return finalColumn < bufferLength(rows);
  }

  private boolean selectorCoversRoot(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long selectorToken,
    long rootToken
  ) {
    long selectorStart = starts[selectorToken] + 1;
    long selectorLength = lengths[selectorToken] - 2;
    long rootStart = starts[rootToken] + 1;
    long rootLength = lengths[rootToken] - 2;
    if (selectorLength < rootLength) {
      long offset = 0;
      while (offset < selectorLength) limit 4096 {
        if (
          utf8Scalar(source, selectorStart + offset) == utf8Scalar(source, rootStart + offset)
        ) {
          offset += 1;
        } else {
          return false;
        }
      }

      return utf8Scalar(source, rootStart + selectorLength) == 47;
    }

    if (selectorLength == rootLength) {
      long equalOffset = 0;
      while (equalOffset < selectorLength) limit 4096 {
        if (
          utf8Scalar(source, selectorStart + equalOffset) == utf8Scalar(
            source,
            rootStart + equalOffset
          )
        ) {
          equalOffset += 1;
        } else {
          return false;
        }
      }

      return true;
    }

    return false;
  }

  private TargetParse parseTarget(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor,
    borrow mut words sourceRows,
    long sourceOffset
  ) {
    TargetParse invalid = new TargetParse(false, cursor, 0, 0, 0, 0, sourceOffset, 0, 0);
    if (cursor + 12 < count) {
      if (dashAt(source, kinds, starts, cursor)) {
        if (key(source, kinds, starts, lengths, count, cursor + 1, 3292052)) {
          long kind = targetKind(source, kinds, starts, lengths, cursor + 3);
          if (0 < kind) {
            if (key(source, kinds, starts, lengths, count, cursor + 4, 3373707)) {
              if (quoted(kinds, lengths, cursor + 6)) {
                boolean validName = validWorkspaceName(
                  source,
                  starts[cursor + 6] + 1,
                  lengths[cursor + 6] - 2
                );
                if (validName) {
                  if (
                    key(source, kinds, starts, lengths, count, cursor + 7, 3506402)
                  ) {
                    if (quoted(kinds, lengths, cursor + 9)) {
                      boolean validRoot = validLogicalPath(
                        source,
                        starts[cursor + 9] + 1,
                        lengths[cursor + 9] - 2
                      );
                      if (validRoot) {
                        long moduleToken = -1;
                        long sourceCount = 0;
                        long next = cursor + 10;
                        if (
                          key(source, kinds, starts, lengths, count, next, 3226183276)
                        ) {
                          if (quoted(kinds, lengths, next + 2)) {
                            boolean validModule = validModuleName(
                              source,
                              starts[next + 2] + 1,
                              lengths[next + 2] - 2
                            );
                            if (validModule == false) {
                              return invalid;
                            }

                            moduleToken = next + 2;
                            next += 3;
                            if (
                              key(source, kinds, starts, lengths, count, next, 105352305592)
                                == false
                            ) {
                              return invalid;
                            }

                            next += 2;
                            long previousSourceToken = -1;
                            boolean rootCovered = false;
                            boolean scanning = true;
                            while (scanning) limit 1024 {
                              if (next + 1 < count) {
                                if (dashAt(source, kinds, starts, next)) {
                                  if (quoted(kinds, lengths, next + 1)) {
                                    boolean validSource = validLogicalPath(
                                      source,
                                      starts[next + 1] + 1,
                                      lengths[next + 1] - 2
                                    );
                                    if (validSource == false) {
                                      return invalid;
                                    }

                                    if (
                                      rowCapacity(
                                        sourceRows,
                                        sourceOffset + sourceCount,
                                        SOURCE_ROW_WIDTH
                                      ) == false
                                    ) {
                                      return invalid;
                                    }

                                    if (-1 < previousSourceToken) {
                                      long sourceOrder = compareTokenText(
                                        source,
                                        starts,
                                        lengths,
                                        previousSourceToken,
                                        next + 1
                                      );
                                      boolean sourcesOrdered = sourceOrder < 0;
                                      if (sourcesOrdered == false) {
                                        return invalid;
                                      }
                                    }

                                    boolean covers = selectorCoversRoot(
                                      source,
                                      starts,
                                      lengths,
                                      next + 1,
                                      cursor + 9
                                    );
                                    if (covers) {
                                      rootCovered = true;
                                    }

                                    long sourceBase = (sourceOffset + sourceCount)
                                      * SOURCE_ROW_WIDTH;
                                    set(sourceRows, sourceBase, starts[next + 1] + 1);
                                    set(sourceRows, sourceBase + 1, lengths[next + 1] - 2);
                                    sourceCount += 1;
                                    previousSourceToken = next + 1;
                                    next += 2;
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

                            if (sourceCount == 0) {
                              return invalid;
                            }

                            if (rootCovered == false) {
                              return invalid;
                            }
                          } else {
                            return invalid;
                          }
                        }

                        if (
                          key(source, kinds, starts, lengths, count, next, 3556498)
                        ) {
                          long test = booleanToken(source, starts, lengths, next + 2);
                          if (-1 < test) {
                            if (kind == 2) {
                              if (test == 1) {
                                return invalid;
                              }
                            }

                            return new TargetParse(
                              true,
                              next + 3,
                              kind,
                              cursor + 6,
                              cursor + 9,
                              moduleToken,
                              sourceOffset,
                              sourceCount,
                              test
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

    return invalid;
  }

  private DependencyParse parseDependency(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    DependencyParse invalid = new DependencyParse(false, cursor, 0, 0, 0);
    if (cursor + 9 < count) {
      if (dashAt(source, kinds, starts, cursor)) {
        if (key(source, kinds, starts, lengths, count, cursor + 1, 3292052)) {
          long kind = dependencyKind(source, kinds, starts, lengths, cursor + 3);
          if (0 < kind) {
            if (key(source, kinds, starts, lengths, count, cursor + 4, 3373707)) {
              if (quoted(kinds, lengths, cursor + 6)) {
                boolean validName = validPackageName(
                  source,
                  starts[cursor + 6] + 1,
                  lengths[cursor + 6] - 2
                );
                if (validName) {
                  if (
                    key(source, kinds, starts, lengths, count, cursor + 7, 107725790424)
                  ) {
                    if (quoted(kinds, lengths, cursor + 9)) {
                      boolean validVersion = validConstraint(
                        source,
                        starts[cursor + 9] + 1,
                        lengths[cursor + 9] - 2
                      );
                      if (validVersion) {
                        return new DependencyParse(
                          true,
                          cursor + 10,
                          kind,
                          cursor + 6,
                          cursor + 9
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

    return invalid;
  }

  private CapabilityParse parseCapability(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    CapabilityParse invalid = new CapabilityParse(false, cursor, 0, 0);
    if (cursor + 6 < count) {
      if (dashAt(source, kinds, starts, cursor)) {
        if (key(source, kinds, starts, lengths, count, cursor + 1, 3373707)) {
          if (quoted(kinds, lengths, cursor + 3)) {
            if (key(source, kinds, starts, lengths, count, cursor + 4, 3433509)) {
              if (quoted(kinds, lengths, cursor + 6)) {
                boolean validPath = validLogicalPath(
                  source,
                  starts[cursor + 6] + 1,
                  lengths[cursor + 6] - 2
                );
                if (validPath) {
                  return new CapabilityParse(true, cursor + 7, cursor + 3, cursor + 6);
                }
              }
            }
          }
        }
      }
    }

    return invalid;
  }

  private boolean validHeader(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    if (count < 35) {
      return false;
    }

    boolean valid = key(source, kinds, starts, lengths, count, 0, 3386979745);
    if (valid) {
      valid = tokenHash(source, starts, lengths, 2) == 49;
    }

    if (valid) {
      valid = key(source, kinds, starts, lengths, count, 3, 102272152646);
    }

    if (valid) {
      valid = key(source, kinds, starts, lengths, count, 5, 3373707);
    }

    if (valid) {
      valid = quoted(kinds, lengths, 7);
    }

    if (valid) {
      valid = validPackageName(source, starts[7] + 1, lengths[7] - 2);
    }

    if (valid) {
      valid = key(source, kinds, starts, lengths, count, 8, 107725790424);
    }

    if (valid) {
      valid = quoted(kinds, lengths, 10);
    }

    if (valid) {
      valid = validRelease(source, starts[10] + 1, lengths[10] - 2);
    }

    if (valid) {
      valid = key(source, kinds, starts, lengths, count, 11, 102769789353);
    }

    if (valid) {
      valid = quoted(kinds, lengths, 13);
    }

    if (valid) {
      valid = key(source, kinds, starts, lengths, count, 14, 105835905282);
    }

    return valid;
  }

  /// Parses every canonical collection row that fits the caller-owned tables.
  public ManifestResult parseManifest(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    borrow mut words targetRows,
    borrow mut words sourceRows,
    borrow mut words dependencyRows,
    borrow mut words capabilityRows
  ) {
    if (validHeader(source, kinds, starts, lengths, count) == false) {
      return new ManifestResult.Error(0);
    }

    long cursor = 16;
    long targetCount = 0;
    long sourceCount = 0;
    long previousTargetToken = -1;
    boolean parsingTargets = true;
    while (parsingTargets) limit 512 {
      if (cursor < count) {
        if (dashAt(source, kinds, starts, cursor)) {
          if (rowCapacity(targetRows, targetCount, TARGET_ROW_WIDTH) == false) {
            return new ManifestResult.Error(starts[cursor]);
          }

          TargetParse target = parseTarget(
            source,
            kinds,
            starts,
            lengths,
            count,
            cursor,
            sourceRows,
            sourceCount
          );
          if (target.valid == false) {
            return new ManifestResult.Error(starts[cursor]);
          }

          if (-1 < previousTargetToken) {
            long targetOrder = compareTokenText(
              source,
              starts,
              lengths,
              previousTargetToken,
              target.nameToken
            );
            boolean targetsOrdered = targetOrder < 0;
            if (targetsOrdered == false) {
              return new ManifestResult.Error(starts[target.nameToken]);
            }
          }

          long targetBase = targetCount * TARGET_ROW_WIDTH;
          set(targetRows, targetBase + TARGET_KIND, target.kind);
          set(targetRows, targetBase + TARGET_NAME_START, starts[target.nameToken] + 1);
          set(targetRows, targetBase + TARGET_NAME_LENGTH, lengths[target.nameToken] - 2);
          set(targetRows, targetBase + TARGET_ROOT_START, starts[target.rootToken] + 1);
          set(targetRows, targetBase + TARGET_ROOT_LENGTH, lengths[target.rootToken] - 2);
          if (-1 < target.moduleToken) {
            set(targetRows, targetBase + TARGET_MODULE_START, starts[target.moduleToken] + 1);
            set(targetRows, targetBase + TARGET_MODULE_LENGTH, lengths[target.moduleToken] - 2);
          } else {
            set(targetRows, targetBase + TARGET_MODULE_START, 0);
            set(targetRows, targetBase + TARGET_MODULE_LENGTH, 0);
          }

          set(targetRows, targetBase + TARGET_SOURCE_OFFSET, target.sourceOffset);
          set(targetRows, targetBase + TARGET_SOURCE_COUNT, target.sourceCount);
          set(targetRows, targetBase + TARGET_TEST, target.test);
          targetCount += 1;
          sourceCount += target.sourceCount;
          previousTargetToken = target.nameToken;
          cursor = target.next;
        } else {
          parsingTargets = false;
        }
      } else {
        parsingTargets = false;
      }
    }

    if (targetCount == 0) {
      return new ManifestResult.Error(0);
    }

    if (
      key(source, kinds, starts, lengths, count, cursor, 2626680644436426025) == false
    ) {
      return new ManifestResult.Error(starts[cursor]);
    }

    cursor += 2;
    long dependencyCount = 0;
    if (punctuation(source, kinds, starts, count, cursor, 91)) {
      if (punctuation(source, kinds, starts, count, cursor + 1, 93)) {
        cursor += 2;
      } else {
        return new ManifestResult.Error(starts[cursor]);
      }
    } else {
      long previousDependencyToken = -1;
      boolean parsingDependencies = true;
      while (parsingDependencies) limit 512 {
        if (cursor < count) {
          if (dashAt(source, kinds, starts, cursor)) {
            if (
              rowCapacity(dependencyRows, dependencyCount, DEPENDENCY_ROW_WIDTH) == false
            ) {
              return new ManifestResult.Error(starts[cursor]);
            }

            DependencyParse dependency = parseDependency(
              source,
              kinds,
              starts,
              lengths,
              count,
              cursor
            );
            if (dependency.valid == false) {
              return new ManifestResult.Error(starts[cursor]);
            }

            if (-1 < previousDependencyToken) {
              long dependencyOrder = compareTokenText(
                source,
                starts,
                lengths,
                previousDependencyToken,
                dependency.nameToken
              );
              boolean dependenciesOrdered = dependencyOrder < 0;
              if (dependenciesOrdered == false) {
                return new ManifestResult.Error(starts[dependency.nameToken]);
              }
            }

            long dependencyBase = dependencyCount * DEPENDENCY_ROW_WIDTH;
            set(dependencyRows, dependencyBase, dependency.kind);
            set(dependencyRows, dependencyBase + 1, starts[dependency.nameToken] + 1);
            set(dependencyRows, dependencyBase + 2, lengths[dependency.nameToken] - 2);
            set(dependencyRows, dependencyBase + 3, starts[dependency.versionToken] + 1);
            set(dependencyRows, dependencyBase + 4, lengths[dependency.versionToken] - 2);
            dependencyCount += 1;
            previousDependencyToken = dependency.nameToken;
            cursor = dependency.next;
          } else {
            parsingDependencies = false;
          }
        } else {
          parsingDependencies = false;
        }
      }

      if (dependencyCount == 0) {
        return new ManifestResult.Error(0);
      }
    }

    if (
      key(source, kinds, starts, lengths, count, cursor, 2597989917310390198) == false
    ) {
      return new ManifestResult.Error(starts[cursor]);
    }

    cursor += 2;
    long capabilityCount = 0;
    if (punctuation(source, kinds, starts, count, cursor, 91)) {
      if (punctuation(source, kinds, starts, count, cursor + 1, 93)) {
        cursor += 2;
      } else {
        return new ManifestResult.Error(starts[cursor]);
      }
    } else {
      long previousCapabilityName = -1;
      long previousCapabilityPath = -1;
      while (cursor < count) limit 512 {
        if (
          rowCapacity(capabilityRows, capabilityCount, CAPABILITY_ROW_WIDTH) == false
        ) {
          return new ManifestResult.Error(starts[cursor]);
        }

        CapabilityParse capability = parseCapability(
          source,
          kinds,
          starts,
          lengths,
          count,
          cursor
        );
        if (capability.valid == false) {
          return new ManifestResult.Error(starts[cursor]);
        }

        if (-1 < previousCapabilityName) {
          long capabilityOrder = compareTokenText(
            source,
            starts,
            lengths,
            previousCapabilityName,
            capability.nameToken
          );
          if (capabilityOrder == 0) {
            capabilityOrder = compareTokenText(
              source,
              starts,
              lengths,
              previousCapabilityPath,
              capability.pathToken
            );
          }

          boolean capabilitiesOrdered = capabilityOrder < 0;
          if (capabilitiesOrdered == false) {
            return new ManifestResult.Error(starts[capability.nameToken]);
          }
        }

        long capabilityBase = capabilityCount * CAPABILITY_ROW_WIDTH;
        set(capabilityRows, capabilityBase, starts[capability.nameToken] + 1);
        set(capabilityRows, capabilityBase + 1, lengths[capability.nameToken] - 2);
        set(capabilityRows, capabilityBase + 2, starts[capability.pathToken] + 1);
        set(capabilityRows, capabilityBase + 3, lengths[capability.pathToken] - 2);
        capabilityCount += 1;
        previousCapabilityName = capability.nameToken;
        previousCapabilityPath = capability.pathToken;
        cursor = capability.next;
      }

      if (capabilityCount == 0) {
        return new ManifestResult.Error(0);
      }
    }

    if (cursor < count) {
      return new ManifestResult.Error(starts[cursor]);
    }

    ManifestModel manifest = new ManifestModel(
      range(starts, lengths, 7),
      range(starts, lengths, 10),
      range(starts, lengths, 13),
      targetCount,
      sourceCount,
      dependencyCount,
      capabilityCount
    );
    return new ManifestResult.Value(manifest);
  }
}
