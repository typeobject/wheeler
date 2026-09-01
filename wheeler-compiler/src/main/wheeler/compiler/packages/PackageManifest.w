//! Parses bounded canonical-YAML package manifests.

module wheeler.compiler.packages.manifest;

import wheeler.compiler.packages.manifest_brackets;
import wheeler.compiler.packages.manifest_capability_prefix;
import wheeler.compiler.packages.manifest_dependency_name;
import wheeler.compiler.packages.manifest_dependency_prefix;
import wheeler.compiler.packages.manifest_dependency_version;
import wheeler.compiler.packages.manifest_header;
import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_kinds;
import wheeler.compiler.packages.manifest_ranges;
import wheeler.compiler.packages.manifest_rows;
import wheeler.compiler.packages.manifest_selectors;
import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.names;
import wheeler.compiler.packages.paths;
import wheeler.compiler.packages.semver;

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
    long start = manifestQuotedStart(starts, token);
    long length = manifestQuotedLength(lengths, token);
    return new QuotedRange(start, length);
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
        if (
          manifestKeyAt(source, kinds, starts, lengths, count, cursor + 1, 3292052)
        ) {
          long kind = manifestTargetKind(source, kinds, starts, lengths, cursor + 3);
          if (0 < kind) {
            if (
              manifestKeyAt(source, kinds, starts, lengths, count, cursor + 4, 3373707)
            ) {
              if (quoted(kinds, lengths, cursor + 6)) {
                boolean validName = validWorkspaceName(
                  source,
                  starts[cursor + 6] + 1,
                  lengths[cursor + 6] - 2
                );
                if (validName) {
                  if (
                    manifestKeyAt(source, kinds, starts, lengths, count, cursor + 7, 3506402)
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
                          manifestKeyAt(
                            source,
                            kinds,
                            starts,
                            lengths,
                            count,
                            next,
                            3226183276
                          )
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
                              manifestKeyAt(
                                source,
                                kinds,
                                starts,
                                lengths,
                                count,
                                next,
                                105352305592
                              ) == false
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
                                      manifestSourceRowCapacity(
                                        sourceRows,
                                        sourceOffset + sourceCount
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

                                    long selectorToken = next + 1;
                                    long rootToken = cursor + 9;
                                    long selectorTokenStart = starts[selectorToken];
                                    long selectorTokenLength = lengths[selectorToken];
                                    long rootTokenStart = starts[rootToken];
                                    long rootTokenLength = lengths[rootToken];
                                    long selectorStart = selectorTokenStart + 1;
                                    long selectorLength = selectorTokenLength - 2;
                                    long rootStart = rootTokenStart + 1;
                                    long rootLength = rootTokenLength - 2;
                                    boolean covers = manifestSelectorRangeCoversRoot(
                                      source,
                                      selectorStart,
                                      selectorLength,
                                      rootStart,
                                      rootLength
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
                          manifestKeyAt(source, kinds, starts, lengths, count, next, 3556498)
                        ) {
                          long test = manifestBooleanToken(source, starts, lengths, next + 2);
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
    long kind = manifestDependencyPrefix(source, kinds, starts, lengths, count, cursor);
    if (kind < 1) {
      return invalid;
    }

    boolean validName = manifestDependencyNameValid(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (validName == false) {
      return invalid;
    }

    boolean validVersion = manifestDependencyVersionValid(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (validVersion == false) {
      return invalid;
    }

    return new DependencyParse(true, cursor + 10, kind, cursor + 6, cursor + 9);
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
    boolean validPrefix = manifestCapabilityPrefixValid(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (validPrefix == false) {
      return invalid;
    }

    if (manifestKeyAt(source, kinds, starts, lengths, count, cursor + 4, 3433509)) {
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

    return invalid;
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
    if (manifestHeaderValid(source, kinds, starts, lengths, count) == false) {
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
          if (manifestTargetRowCapacity(targetRows, targetCount) == false) {
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
      manifestKeyAt(source, kinds, starts, lengths, count, cursor, 2626680644436426025) == false
    ) {
      return new ManifestResult.Error(starts[cursor]);
    }

    cursor += 2;
    long dependencyCount = 0;
    if (cursor == count) {
      return new ManifestResult.Error(0);
    }

    boolean emptyDependencies = false;
    if (cursor < count) {
      if (manifestOpenBracketAt(source, kinds, starts, cursor)) {
        long dependencyCloseToken = cursor + 1;
        if (dependencyCloseToken < count) {
          if (manifestCloseBracketAt(source, kinds, starts, dependencyCloseToken)) {
            cursor += 2;
            emptyDependencies = true;
          } else {
            return new ManifestResult.Error(starts[cursor]);
          }
        } else {
          return new ManifestResult.Error(starts[cursor]);
        }
      }
    }

    if (emptyDependencies == false) {
      long previousDependencyToken = -1;
      boolean parsingDependencies = true;
      while (parsingDependencies) limit 512 {
        if (cursor < count) {
          if (dashAt(source, kinds, starts, cursor)) {
            if (manifestDependencyRowCapacity(dependencyRows, dependencyCount) == false) {
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
      manifestKeyAt(source, kinds, starts, lengths, count, cursor, 2597989917310390198) == false
    ) {
      return new ManifestResult.Error(starts[cursor]);
    }

    cursor += 2;
    long capabilityCount = 0;
    if (cursor == count) {
      return new ManifestResult.Error(0);
    }

    boolean emptyCapabilities = false;
    if (cursor < count) {
      if (manifestOpenBracketAt(source, kinds, starts, cursor)) {
        long capabilityCloseToken = cursor + 1;
        if (capabilityCloseToken < count) {
          if (manifestCloseBracketAt(source, kinds, starts, capabilityCloseToken)) {
            cursor += 2;
            emptyCapabilities = true;
          } else {
            return new ManifestResult.Error(starts[cursor]);
          }
        } else {
          return new ManifestResult.Error(starts[cursor]);
        }
      }
    }

    if (emptyCapabilities == false) {
      long previousCapabilityName = -1;
      long previousCapabilityPath = -1;
      while (cursor < count) limit 512 {
        if (manifestCapabilityRowCapacity(capabilityRows, capabilityCount) == false) {
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
