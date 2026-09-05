//! Parses bounded canonical-YAML package manifests.

module wheeler.compiler.packages.manifest;

import wheeler.compiler.packages.manifest_capability;
import wheeler.compiler.packages.manifest_capability_coordinates;
import wheeler.compiler.packages.manifest_dependency;
import wheeler.compiler.packages.manifest_dependency_coordinates;
import wheeler.compiler.packages.manifest_empty_section;
import wheeler.compiler.packages.manifest_header;
import wheeler.compiler.packages.manifest_kinds;
import wheeler.compiler.packages.manifest_ranges;
import wheeler.compiler.packages.manifest_rows;
import wheeler.compiler.packages.manifest_sections;
import wheeler.compiler.packages.manifest_target_admission;
import wheeler.compiler.packages.manifest_target_coordinates;
import wheeler.compiler.packages.manifest_target_head;
import wheeler.compiler.packages.manifest_target_name;
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

  private QuotedRange range(borrow mut words starts, borrow mut words lengths, long token) {
    long start = manifestQuotedStart(starts, token);
    long length = manifestQuotedLength(lengths, token);
    return new QuotedRange(start, length);
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

          long tail = manifestTargetAdmissionProduct(
            source,
            kinds,
            starts,
            lengths,
            count,
            cursor,
            sourceRows,
            sourceCount
          );
          if (tail < 0) {
            return new ManifestResult.Error(starts[cursor]);
          }

          long nameToken = manifestTargetNameToken(cursor);
          if (-1 < previousTargetToken) {
            boolean targetsOrdered = manifestTargetNamesOrdered(
              source,
              starts,
              lengths,
              previousTargetToken,
              nameToken
            );
            if (targetsOrdered == false) {
              return new ManifestResult.Error(starts[nameToken]);
            }
          }

          long kindToken = manifestTargetKindToken(cursor);
          long kind = manifestTargetKind(source, kinds, starts, lengths, kindToken);
          long rootToken = manifestTargetRootToken(cursor);
          long targetSourceCount = manifestTargetSourceCount(cursor, tail);
          long testToken = manifestTargetTestToken(tail);
          long test = manifestBooleanToken(source, starts, lengths, testToken);
          long targetRow = manifestTargetHeadRowProduct(
            starts,
            lengths,
            targetRows,
            targetCount,
            kind,
            nameToken,
            rootToken
          );
          if (targetSourceCount != 0) {
            long moduleToken = manifestTargetModuleToken(cursor);
            targetCount = manifestModularTargetTailRowProduct(
              starts,
              lengths,
              targetRows,
              targetRow,
              moduleToken,
              sourceCount,
              targetSourceCount,
              test
            );
          } else {
            targetCount = manifestNonmodularTargetTailRowProduct(
              targetRows,
              targetRow,
              sourceCount,
              targetSourceCount,
              test
            );
          }
          sourceCount += targetSourceCount;
          previousTargetToken = nameToken;
          cursor = manifestTargetNextToken(tail);
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
      boolean parsingDependencies = true;
      while (parsingDependencies) limit 512 {
        if (cursor < count) {
          if (dashAt(source, kinds, starts, cursor)) {
            long nextDependencyRow = manifestDependencyEntryProduct(
              source,
              kinds,
              starts,
              lengths,
              count,
              cursor,
              dependencyRows,
              dependencyCount
            );
            if (nextDependencyRow < 0) {
              return new ManifestResult.Error(starts[cursor]);
            }

            if (nextDependencyRow == 0) {
              long dependencyNameToken = manifestDependencyNameToken(cursor);
              return new ManifestResult.Error(starts[dependencyNameToken]);
            }

            dependencyCount = nextDependencyRow;
            cursor = manifestDependencyNextToken(cursor);
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
      while (cursor < count) limit 512 {
        long nextCapabilityRow = manifestCapabilityEntryProduct(
          source,
          kinds,
          starts,
          lengths,
          count,
          cursor,
          capabilityRows,
          capabilityCount
        );
        if (nextCapabilityRow < 0) {
          return new ManifestResult.Error(starts[cursor]);
        }

        if (nextCapabilityRow == 0) {
          long capabilityNameToken = manifestCapabilityNameToken(cursor);
          return new ManifestResult.Error(starts[capabilityNameToken]);
        }

        capabilityCount = nextCapabilityRow;
        cursor = manifestCapabilityNextToken(cursor);
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
