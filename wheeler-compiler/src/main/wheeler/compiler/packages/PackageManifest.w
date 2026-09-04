//! Parses bounded canonical-YAML package manifests.

module wheeler.compiler.packages.manifest;

import wheeler.compiler.packages.manifest_capability;
import wheeler.compiler.packages.manifest_capability_coordinates;
import wheeler.compiler.packages.manifest_capability_path;
import wheeler.compiler.packages.manifest_dependency;
import wheeler.compiler.packages.manifest_dependency_coordinates;
import wheeler.compiler.packages.manifest_dependency_name;
import wheeler.compiler.packages.manifest_empty_section;
import wheeler.compiler.packages.manifest_header;
import wheeler.compiler.packages.manifest_kinds;
import wheeler.compiler.packages.manifest_ranges;
import wheeler.compiler.packages.manifest_rows;
import wheeler.compiler.packages.manifest_sections;
import wheeler.compiler.packages.manifest_target_coordinates;
import wheeler.compiler.packages.manifest_target_head;
import wheeler.compiler.packages.manifest_target_module;
import wheeler.compiler.packages.manifest_target_module_head;
import wheeler.compiler.packages.manifest_target_name;
import wheeler.compiler.packages.manifest_target_source_collection;
import wheeler.compiler.packages.manifest_target_tail;
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
    long kind = manifestTargetHeadKind(source, kinds, starts, lengths, count, cursor);
    long nameToken = manifestTargetNameToken(cursor);
    long rootToken = manifestTargetRootToken(cursor);
    if (0 < kind) {
      long moduleToken = -1;
      long sourceCount = 0;
      boolean rootCovered = false;
      long moduleKeyToken = manifestTargetModuleKeyToken(cursor);
      long next = moduleKeyToken;
      if (manifestTargetModulePresent(source, kinds, starts, lengths, count, moduleKeyToken)) {
        moduleToken = manifestTargetModuleToken(cursor);
        long sourcesKeyToken = manifestTargetSourcesKeyToken(cursor);
        boolean validModuleHead = manifestTargetModuleHeadValid(
          source,
          kinds,
          starts,
          lengths,
          count,
          moduleToken,
          sourcesKeyToken
        );
        if (validModuleHead == false) {
          return invalid;
        }

        next = manifestTargetFirstSourceRowToken(cursor);
        long previousSourceToken = -1;
        boolean scanning = true;
        while (scanning) limit 1024 {
          long followingSource = manifestTargetSourceFollowingRow(
            source,
            kinds,
            starts,
            lengths,
            count,
            next
          );
          if (-1 < followingSource) {
            long selectorToken = manifestTargetSourceEntryProduct(
              source,
              starts,
              lengths,
              next,
              sourceRows,
              sourceOffset + sourceCount,
              previousSourceToken
            );
            if (selectorToken < 0) {
              return invalid;
            }

            rootCovered = manifestTargetSourceCoverage(
              source,
              starts,
              lengths,
              selectorToken,
              rootToken,
              rootCovered
            );

            sourceCount += 1;
            previousSourceToken = selectorToken;
            next = followingSource;
          } else {
            scanning = false;
          }
        }

      }

      boolean sourcesPresent = -1 < moduleToken;
      boolean sourceCollectionComplete = manifestTargetSourceCollectionComplete(
        sourcesPresent,
        sourceCount,
        rootCovered
      );
      long test = manifestTargetTestValue(
        source,
        kinds,
        starts,
        lengths,
        count,
        kind,
        next,
        sourceCollectionComplete
      );
      if (-1 < test) {
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
    long kind = manifestDependencyRowKind(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (kind < 1) {
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
    boolean valid = manifestCapabilityRowValid(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (valid == false) {
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

          long targetRow = manifestTargetHeadRowProduct(
            starts,
            lengths,
            targetRows,
            targetCount,
            target.kind,
            target.nameToken,
            target.rootToken
          );
          if (-1 < target.moduleToken) {
            targetCount = manifestModularTargetTailRowProduct(
              starts,
              lengths,
              targetRows,
              targetRow,
              target.moduleToken,
              target.sourceOffset,
              target.sourceCount,
              target.test
            );
          } else {
            targetCount = manifestNonmodularTargetTailRowProduct(
              targetRows,
              targetRow,
              target.sourceOffset,
              target.sourceCount,
              target.test
            );
          }
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

            dependencyCount = manifestDependencyRowProduct(
              starts,
              lengths,
              dependency.kind,
              dependency.nameToken,
              dependency.versionToken,
              dependencyRows,
              dependencyCount
            );
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

        capabilityCount = manifestCapabilityRowProduct(
          starts,
          lengths,
          capability.nameToken,
          capability.pathToken,
          capabilityRows,
          capabilityCount
        );
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
