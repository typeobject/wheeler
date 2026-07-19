//! Parses and re-emits a canonical package manifest in Wheeler.

module examples.packages.main;

import wheeler.lexer.scanner;
import wheeler.packages.emitter;
import wheeler.packages.manifest;

classical class NativeManifest {
  state long nameLength = 0;
  state long nameStart = 0;
  state long profileLength = 0;
  state long versionLength = 0;
  state long targetCount = 0;
  state long targetSourceCount = 0;
  state long dependencyCount = 0;
  state long capabilityCount = 0;
  state long firstTargetNameLength = 0;
  state long lastTargetNameLength = 0;
  state long lastDependencyNameLength = 0;
  state long lastCapabilityNameLength = 0;
  state long emittedLength = 0;
  state long finalCursor = 0;

  /// Runs the bounded `NativeManifest` fixture.
  ///
  /// - Effects: Mutates declared state and caller-owned byte output.
  entry void main(borrow utf8 source, borrow mut bytes canonical) {
    region arena = new region(15360, 7);
    words kinds = allocate(arena, 512);
    words starts = allocate(arena, 512);
    words lengths = allocate(arena, 512);
    words targetRows = allocate(arena, 80);
    words sourceRows = allocate(arena, 64);
    words dependencyRows = allocate(arena, 40);
    words capabilityRows = allocate(arena, 32);
    long count = 0;
    ScanResult scanned = scan(source, kinds, starts, lengths);
    match (scanned) {
      case ScanResult.Value(long tokenCount) {
        count = tokenCount;
      }
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        assert(finalCursor == 1);
      }
    }

    ManifestResult parsed = parseManifest(
      source,
      kinds,
      starts,
      lengths,
      count,
      targetRows,
      sourceRows,
      dependencyRows,
      capabilityRows
    );
    match (parsed) {
      case ManifestResult.Value(ManifestModel manifest) {
        nameStart = manifest.name.start;
        nameLength = manifest.name.length;
        versionLength = manifest.version.length;
        profileLength = manifest.profile.length;
        targetCount = manifest.targetCount;
        targetSourceCount = manifest.sourceCount;
        dependencyCount = manifest.dependencyCount;
        capabilityCount = manifest.capabilityCount;
        firstTargetNameLength = targetRows[TARGET_NAME_LENGTH];
        lastTargetNameLength = targetRows[(targetCount - 1) * TARGET_ROW_WIDTH
          + TARGET_NAME_LENGTH];
        if (0 < dependencyCount) {
          lastDependencyNameLength = dependencyRows[(dependencyCount - 1) * DEPENDENCY_ROW_WIDTH
            + 2];
        }

        if (0 < capabilityCount) {
          lastCapabilityNameLength = capabilityRows[(capabilityCount - 1) * CAPABILITY_ROW_WIDTH
            + 1];
        }

        emittedLength = emitCanonical(source, starts, lengths, count, canonical);
      }
      case ManifestResult.Error(long parseOffset) {
        assert(finalCursor == 1);
      }
    }

    finalCursor = bufferLength(source);
    assert(nameLength == 11);
    assert(versionLength == 10);
    assert(profileLength == 11);
    setOutputLength(canonical, emittedLength);

    drop(capabilityRows);
    drop(dependencyRows);
    drop(sourceRows);
    drop(targetRows);
    drop(lengths);
    drop(starts);
    drop(kinds);
    drop(arena);
  }
}
