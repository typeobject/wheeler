//! Binds one canonical package tool target to the selected bootstrap root.

module wheeler.compiler.closure.package_target;

import wheeler.compiler.closure.archive_sources;
import wheeler.compiler.closure.module_manifest;
import wheeler.compiler.packages.canonical;
import wheeler.compiler.packages.manifest;
import wheeler.lexer.scanner;

classical class CompilerPackageTarget {
  private const long MAX_CAPABILITIES = 512;
  private const long MAX_DEPENDENCIES = 512;
  private const long MAX_PACKAGE_MANIFEST_BYTES = 262144;
  private const long MAX_PACKAGE_SOURCES = 8192;
  private const long MAX_PACKAGE_TARGETS = 512;
  private const long MAX_PACKAGE_TOKENS = 131072;
  private const long PACKAGE_PARSE_ARENA_BYTES = 4000000;

  /// Carries immutable archive-relative ranges for the selected compiler tool target.
  public record CompilerToolTarget(
    long packageNameStart,
    long packageNameLength,
    long target,
    long rootStart,
    long rootLength,
    long moduleStart,
    long moduleLength
  ) {}

  /// Defines the closed package-target validation result.
  public variant CompilerToolTargetResult {
    case Value(CompilerToolTarget target);
    case Error(long offset);
  }

  private boolean compilerName(borrow utf8 source, long start, long length) {
    if (length == 8) {} else {
      return false;
    }

    if (utf8Scalar(source, start) == 99) {} else {
      return false;
    }

    if (utf8Scalar(source, start + 1) == 111) {} else {
      return false;
    }

    if (utf8Scalar(source, start + 2) == 109) {} else {
      return false;
    }

    if (utf8Scalar(source, start + 3) == 112) {} else {
      return false;
    }

    if (utf8Scalar(source, start + 4) == 105) {} else {
      return false;
    }

    if (utf8Scalar(source, start + 5) == 108) {} else {
      return false;
    }

    if (utf8Scalar(source, start + 6) == 101) {} else {
      return false;
    }

    return utf8Scalar(source, start + 7) == 114;
  }

  private boolean sameRange(
    borrow utf8 packageManifest,
    long packageStart,
    long packageLength,
    borrow byteview moduleManifest,
    long moduleStart,
    long moduleLength
  ) {
    if (packageLength == moduleLength) {} else {
      return false;
    }

    long cursor = 0;
    while (cursor < packageLength) limit 4096 {
      if (
        utf8Scalar(packageManifest, packageStart + cursor) == moduleManifest[moduleStart + cursor]
      ) {} else {
        return false;
      }

      cursor += 1;
    }

    return true;
  }

  /// Validates the complete package manifest before selecting one matching `compiler` tool.
  ///
  /// The selected target module and root path must name the root row already validated by the
  /// bootstrap module manifest. Returned ranges refer to the immutable archive.
  public CompilerToolTargetResult validateCompilerToolTarget(
    borrow byteview archive,
    ArchiveSourceIndex archiveIndex,
    borrow byteview moduleManifest,
    BootstrapModuleManifestPlan modulePlan,
    borrow mut words moduleStarts,
    borrow mut words moduleLengths,
    borrow mut words sourceStarts,
    borrow mut words sourceLengths
  ) {
    if (0 < archiveIndex.manifestLength) {} else {
      return new CompilerToolTargetResult.Error(archiveIndex.manifestStart);
    }

    if (archiveIndex.manifestLength < MAX_PACKAGE_MANIFEST_BYTES + 1) {} else {
      return new CompilerToolTargetResult.Error(archiveIndex.manifestStart);
    }

    region arena = new region(/* bytes= */ PACKAGE_PARSE_ARENA_BYTES, /* allocations= */ 9);
    bytes manifestBytes = allocateBytes(arena, archiveIndex.manifestLength);
    long copied = 0;
    while (copied < archiveIndex.manifestLength) limit MAX_PACKAGE_MANIFEST_BYTES {
      setByte(manifestBytes, copied, archive[archiveIndex.manifestStart + copied]);
      copied += 1;
    }

    utf8 manifest = freezeUtf8(manifestBytes);
    words kinds = allocate(arena, MAX_PACKAGE_TOKENS);
    words starts = allocate(arena, MAX_PACKAGE_TOKENS);
    words lengths = allocate(arena, MAX_PACKAGE_TOKENS);
    words targetRows = allocate(arena, MAX_PACKAGE_TARGETS * TARGET_ROW_WIDTH);
    words packageSourceRows = allocate(arena, MAX_PACKAGE_SOURCES * SOURCE_ROW_WIDTH);
    words dependencyRows = allocate(arena, MAX_DEPENDENCIES * DEPENDENCY_ROW_WIDTH);
    words capabilityRows = allocate(arena, MAX_CAPABILITIES * CAPABILITY_ROW_WIDTH);

    boolean valid = true;
    long errorOffset = archiveIndex.manifestStart;
    long tokenCount = 0;
    ScanResult scanned = scan(manifest, kinds, starts, lengths);
    match (scanned) {
      case ScanResult.Value(long count) {
        tokenCount = count;
      }
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        valid = false;
        errorOffset = archiveIndex.manifestStart + diagnostic.offset;
      }
    }

    long targetCount = 0;
    long packageNameStart = 0;
    long packageNameLength = 0;
    if (valid) {
      ManifestResult parsed = parseManifest(
        manifest,
        kinds,
        starts,
        lengths,
        tokenCount,
        targetRows,
        packageSourceRows,
        dependencyRows,
        capabilityRows
      );
      match (parsed) {
        case ManifestResult.Value(ManifestModel model) {
          targetCount = model.targetCount;
          packageNameStart = model.name.start;
          packageNameLength = model.name.length;
        }
        case ManifestResult.Error(long parseOffset) {
          valid = false;
          errorOffset = archiveIndex.manifestStart + parseOffset;
        }
      }
    }

    if (valid) {
      valid = canonicalPackageManifest(manifest, kinds, starts, lengths, tokenCount);
    }

    long selected = -1;
    long selectedRootStart = 0;
    long selectedRootLength = 0;
    long selectedModuleStart = 0;
    long selectedModuleLength = 0;
    long target = 0;
    while (target < targetCount) limit MAX_PACKAGE_TARGETS {
      long base = target * TARGET_ROW_WIDTH;
      long nameStart = targetRows[base + TARGET_NAME_START];
      long nameLength = targetRows[base + TARGET_NAME_LENGTH];
      long rootStart = targetRows[base + TARGET_ROOT_START];
      long rootLength = targetRows[base + TARGET_ROOT_LENGTH];
      long moduleStart = targetRows[base + TARGET_MODULE_START];
      long moduleLength = targetRows[base + TARGET_MODULE_LENGTH];
      boolean matching = targetRows[base + TARGET_KIND] == 3;
      if (matching) {
        matching = compilerName(manifest, nameStart, nameLength);
      }

      if (matching) {
        matching = targetRows[base + TARGET_TEST] == 0;
      }

      if (matching) {
        matching = sameRange(
          manifest,
          moduleStart,
          moduleLength,
          moduleManifest,
          moduleStarts[modulePlan.rootModule],
          moduleLengths[modulePlan.rootModule]
        );
      }

      if (matching) {
        matching = sameRange(
          manifest,
          rootStart,
          rootLength,
          moduleManifest,
          sourceStarts[modulePlan.rootModule],
          sourceLengths[modulePlan.rootModule]
        );
      }

      if (matching) {
        if (selected < 0) {
          selected = target;
          selectedRootStart = rootStart;
          selectedRootLength = rootLength;
          selectedModuleStart = moduleStart;
          selectedModuleLength = moduleLength;
        } else {
          valid = false;
        }
      }

      target += 1;
    }

    if (selected < 0) {
      valid = false;
    }

    drop(capabilityRows);
    drop(dependencyRows);
    drop(packageSourceRows);
    drop(targetRows);
    drop(lengths);
    drop(starts);
    drop(kinds);
    drop(manifest);
    drop(arena);
    if (valid) {
      CompilerToolTarget compilerTarget = new CompilerToolTarget(
        archiveIndex.manifestStart + packageNameStart,
        packageNameLength,
        selected,
        archiveIndex.manifestStart + selectedRootStart,
        selectedRootLength,
        archiveIndex.manifestStart + selectedModuleStart,
        selectedModuleLength
      );
      return new CompilerToolTargetResult.Value(compilerTarget);
    }

    return new CompilerToolTargetResult.Error(errorOffset);
  }
}
