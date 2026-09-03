//! Parses bounded canonical-YAML package manifests.

module wheeler.compiler.packages.manifest;

import wheeler.compiler.packages.manifest_capability_coordinates;
import wheeler.compiler.packages.manifest_capability_path;
import wheeler.compiler.packages.manifest_capability_prefix;
import wheeler.compiler.packages.manifest_dependency_coordinates;
import wheeler.compiler.packages.manifest_dependency_name;
import wheeler.compiler.packages.manifest_dependency_prefix;
import wheeler.compiler.packages.manifest_dependency_version;
import wheeler.compiler.packages.manifest_empty_section;
import wheeler.compiler.packages.manifest_header;
import wheeler.compiler.packages.manifest_kinds;
import wheeler.compiler.packages.manifest_ranges;
import wheeler.compiler.packages.manifest_rows;
import wheeler.compiler.packages.manifest_sections;
import wheeler.compiler.packages.manifest_target_coordinates;
import wheeler.compiler.packages.manifest_target_module;
import wheeler.compiler.packages.manifest_target_name;
import wheeler.compiler.packages.manifest_target_prefix;
import wheeler.compiler.packages.manifest_target_root;
import wheeler.compiler.packages.manifest_target_source;
import wheeler.compiler.packages.manifest_target_source_coordinates;
import wheeler.compiler.packages.manifest_target_test;
import wheeler.compiler.packages.manifest_tokens;
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
    long kind = manifestTargetPrefixKind(source, kinds, starts, lengths, count, cursor);
    long nameToken = manifestTargetNameToken(cursor);
    long rootToken = manifestTargetRootToken(cursor);
    if (0 < kind) {
      boolean validName = manifestTargetNameValid(
        source,
        kinds,
        starts,
        lengths,
        count,
        cursor
      );
      if (validName) {
        boolean validRoot = manifestTargetRootValid(
          source,
          kinds,
          starts,
          lengths,
          count,
          cursor
        );
        if (validRoot) {
          long moduleToken = -1;
          long sourceCount = 0;
          long moduleKeyToken = manifestTargetModuleKeyToken(cursor);
          long next = moduleKeyToken;
          if (
            manifestTargetModulePresent(
              source,
              kinds,
              starts,
              lengths,
              count,
              moduleKeyToken
            )
          ) {
            moduleToken = manifestTargetModuleToken(cursor);
            boolean validModule = manifestTargetModuleValid(
              source,
              kinds,
              starts,
              lengths,
              moduleToken
            );
            if (validModule) {
              long sourcesKeyToken = manifestTargetSourcesKeyToken(cursor);
              if (
                manifestTargetSourcesPresent(
                  source,
                  kinds,
                  starts,
                  lengths,
                  count,
                  sourcesKeyToken
                ) == false
              ) {
                return invalid;
              }

              next = manifestTargetFirstSourceRowToken(cursor);
              long previousSourceToken = -1;
              boolean rootCovered = false;
              boolean scanning = true;
              while (scanning) limit 1024 {
                if (next + 1 < count) {
                  if (dashAt(source, kinds, starts, next)) {
                    long selectorToken = manifestTargetSelectorToken(next);
                    boolean validSource = manifestTargetSourceValid(
                      source,
                      kinds,
                      starts,
                      lengths,
                      selectorToken
                    );
                    if (validSource) {
                      if (
                        manifestSourceRowCapacity(sourceRows, sourceOffset + sourceCount) == false
                      ) {
                        return invalid;
                      }

                      if (-1 < previousSourceToken) {
                        boolean sourcesOrdered = manifestTargetSourcesOrdered(
                          source,
                          starts,
                          lengths,
                          previousSourceToken,
                          selectorToken
                        );
                        if (sourcesOrdered == false) {
                          return invalid;
                        }
                      }

                      boolean covers = manifestTargetSourceCoversRoot(
                        source,
                        starts,
                        lengths,
                        selectorToken,
                        rootToken
                      );
                      if (covers) {
                        rootCovered = true;
                      }

                      long sourceBase = (sourceOffset + sourceCount) * SOURCE_ROW_WIDTH;
                      long selectorStart = manifestTargetSourceStart(starts, selectorToken);
                      long selectorLength = manifestTargetSourceLength(lengths, selectorToken);
                      set(sourceRows, sourceBase, selectorStart);
                      set(sourceRows, sourceBase + 1, selectorLength);
                      sourceCount += 1;
                      previousSourceToken = selectorToken;
                      next = manifestTargetNextSourceRowToken(next);
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

          if (manifestTargetTestPresent(source, kinds, starts, lengths, count, next)) {
            long testToken = manifestTargetTestToken(next);
            long test = manifestBooleanToken(source, starts, lengths, testToken);
            if (-1 < test) {
              boolean testAllowed = manifestTargetTestAllowed(kind, test);
              if (testAllowed == false) {
                return invalid;
              }

              return new TargetParse(
                true,
                manifestTargetNextToken(next),
                kind,
                nameToken,
                rootToken,
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

    long nameToken = manifestDependencyNameToken(cursor);
    long versionToken = manifestDependencyVersionToken(cursor);
    long next = manifestDependencyNextToken(cursor);
    return new DependencyParse(true, next, kind, nameToken, versionToken);
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

    boolean validPath = manifestCapabilityPathValid(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (validPath == false) {
      return invalid;
    }

    long nameToken = manifestCapabilityNameToken(cursor);
    long pathToken = manifestCapabilityPathToken(cursor);
    long next = manifestCapabilityNextToken(cursor);
    return new CapabilityParse(true, next, nameToken, pathToken);
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
            boolean targetsOrdered = manifestTargetNamesOrdered(
              source,
              starts,
              lengths,
              previousTargetToken,
              target.nameToken
            );
            if (targetsOrdered == false) {
              return new ManifestResult.Error(starts[target.nameToken]);
            }
          }

          long targetBase = targetCount * TARGET_ROW_WIDTH;
          long targetNameStart = manifestTargetValueStart(starts, target.nameToken);
          long targetNameLength = manifestTargetValueLength(lengths, target.nameToken);
          long targetRootStart = manifestTargetValueStart(starts, target.rootToken);
          long targetRootLength = manifestTargetValueLength(lengths, target.rootToken);
          set(targetRows, targetBase + TARGET_KIND, target.kind);
          set(targetRows, targetBase + TARGET_NAME_START, targetNameStart);
          set(targetRows, targetBase + TARGET_NAME_LENGTH, targetNameLength);
          set(targetRows, targetBase + TARGET_ROOT_START, targetRootStart);
          set(targetRows, targetBase + TARGET_ROOT_LENGTH, targetRootLength);
          if (-1 < target.moduleToken) {
            long targetModuleStart = manifestTargetValueStart(starts, target.moduleToken);
            long targetModuleLength = manifestTargetValueLength(lengths, target.moduleToken);
            set(targetRows, targetBase + TARGET_MODULE_START, targetModuleStart);
            set(targetRows, targetBase + TARGET_MODULE_LENGTH, targetModuleLength);
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
      manifestDependenciesPresent(source, kinds, starts, lengths, count, cursor) == false
    ) {
      return new ManifestResult.Error(starts[cursor]);
    }

    cursor += 2;
    long dependencyCount = 0;
    if (cursor == count) {
      return new ManifestResult.Error(0);
    }

    boolean emptyDependencies = false;
    long dependencySectionKind = manifestEmptySectionKind(
      source,
      kinds,
      starts,
      count,
      cursor
    );
    if (dependencySectionKind < 0) {
      return new ManifestResult.Error(starts[cursor]);
    }

    if (dependencySectionKind == 1) {
      cursor += 2;
      emptyDependencies = true;
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
              boolean dependenciesOrdered = manifestDependencyNamesOrdered(
                source,
                starts,
                lengths,
                previousDependencyToken,
                dependency.nameToken
              );
              if (dependenciesOrdered == false) {
                return new ManifestResult.Error(starts[dependency.nameToken]);
              }
            }

            long dependencyBase = dependencyCount * DEPENDENCY_ROW_WIDTH;
            set(dependencyRows, dependencyBase, dependency.kind);
            long dependencyNameStart = manifestDependencyValueStart(
              starts,
              dependency.nameToken
            );
            long dependencyNameLength = manifestDependencyValueLength(
              lengths,
              dependency.nameToken
            );
            long dependencyVersionStart = manifestDependencyValueStart(
              starts,
              dependency.versionToken
            );
            long dependencyVersionLength = manifestDependencyValueLength(
              lengths,
              dependency.versionToken
            );
            set(dependencyRows, dependencyBase + 1, dependencyNameStart);
            set(dependencyRows, dependencyBase + 2, dependencyNameLength);
            set(dependencyRows, dependencyBase + 3, dependencyVersionStart);
            set(dependencyRows, dependencyBase + 4, dependencyVersionLength);
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
      manifestCapabilitiesPresent(source, kinds, starts, lengths, count, cursor) == false
    ) {
      return new ManifestResult.Error(starts[cursor]);
    }

    cursor += 2;
    long capabilityCount = 0;
    if (cursor == count) {
      return new ManifestResult.Error(0);
    }

    boolean emptyCapabilities = false;
    long capabilitySectionKind = manifestEmptySectionKind(
      source,
      kinds,
      starts,
      count,
      cursor
    );
    if (capabilitySectionKind < 0) {
      return new ManifestResult.Error(starts[cursor]);
    }

    if (capabilitySectionKind == 1) {
      cursor += 2;
      emptyCapabilities = true;
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
          long capabilityOrder = manifestCapabilityNameOrder(
            source,
            starts,
            lengths,
            previousCapabilityName,
            capability.nameToken
          );
          if (capabilityOrder == 0) {
            boolean pathsOrdered = manifestCapabilityPathsOrdered(
              source,
              starts,
              lengths,
              previousCapabilityPath,
              capability.pathToken
            );
            if (pathsOrdered == false) {
              return new ManifestResult.Error(starts[capability.nameToken]);
            }
          }

          if (0 < capabilityOrder) {
            return new ManifestResult.Error(starts[capability.nameToken]);
          }
        }

        long capabilityBase = capabilityCount * CAPABILITY_ROW_WIDTH;
        long capabilityNameStart = manifestCapabilityValueStart(
          starts,
          capability.nameToken
        );
        long capabilityNameLength = manifestCapabilityValueLength(
          lengths,
          capability.nameToken
        );
        long capabilityPathStart = manifestCapabilityValueStart(
          starts,
          capability.pathToken
        );
        long capabilityPathLength = manifestCapabilityValueLength(
          lengths,
          capability.pathToken
        );
        set(capabilityRows, capabilityBase, capabilityNameStart);
        set(capabilityRows, capabilityBase + 1, capabilityNameLength);
        set(capabilityRows, capabilityBase + 2, capabilityPathStart);
        set(capabilityRows, capabilityBase + 3, capabilityPathLength);
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
