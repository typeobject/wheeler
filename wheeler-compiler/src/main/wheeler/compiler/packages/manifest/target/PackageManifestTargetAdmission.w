//! Admits complete package-manifest targets without aggregate parser state.

module wheeler.compiler.packages.manifest_target_admission;

import wheeler.compiler.packages.manifest_target_coordinates;
import wheeler.compiler.packages.manifest_target_head;
import wheeler.compiler.packages.manifest_target_module;
import wheeler.compiler.packages.manifest_target_module_head;
import wheeler.compiler.packages.manifest_target_source_collection;
import wheeler.compiler.packages.manifest_target_tail;

classical class PackageManifestTargetAdmission {
  /// Returns the validated test-key token, or minus one without a count commit.
  /// Token columns come from the scanner. Admitted source rows remain on rejection.
  /// The caller owns target capacity, adjacent ordering, and target-row publication.
  public long manifestTargetAdmissionProduct(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor,
    borrow mut words sourceRows,
    long sourceOffset
  ) {
    boolean bounded = targetInputValid(
      kinds, starts, lengths, count, cursor, sourceRows, sourceOffset
    );
    if (bounded == false) {
      return -1;
    }

    long kind = manifestTargetHeadKind(source, kinds, starts, lengths, count, cursor);
    if (kind == 0) {
      return -1;
    }

    long sourceEnd = optionalSourceCollection(
      source, kinds, starts, lengths, count, cursor, sourceRows, sourceOffset
    );
    if (sourceEnd < 0) {
      return -1;
    }

    long sourceCount = sourceEnd - sourceOffset;
    long tail = manifestTargetTailToken(cursor, sourceCount);
    long test = manifestTargetTestValue(source, kinds, starts, lengths, count, kind, tail);
    if (test < 0) {
      return -1;
    }

    return tail;
  }

  private boolean targetInputValid(
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor,
    borrow mut words sourceRows,
    long sourceOffset
  ) {
    if (cursor < 0) {
      return false;
    }
    if (count < 0) {
      return false;
    }
    long kindCapacity = bufferLength(kinds);
    if (kindCapacity < count) {
      return false;
    }
    long startCapacity = bufferLength(starts);
    if (startCapacity < count) {
      return false;
    }
    long lengthCapacity = bufferLength(lengths);
    if (lengthCapacity < count) {
      return false;
    }
    long remaining = count - cursor;
    if (remaining < 13) {
      return false;
    }
    if (sourceOffset < 0) {
      return false;
    }
    long slots = bufferLength(sourceRows);
    long rows = slots / 2;
    if (rows < sourceOffset) {
      return false;
    }
    return true;
  }

  private long optionalSourceCollection(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor,
    borrow mut words sourceRows,
    long sourceOffset
  ) {
    long moduleKey = manifestTargetModuleKeyToken(cursor);
    boolean modular = manifestTargetModulePresent(source, kinds, starts, lengths, count, moduleKey);
    if (modular == false) {
      return sourceOffset;
    }

    long moduleToken = manifestTargetModuleToken(cursor);
    long sourcesKey = manifestTargetSourcesKeyToken(cursor);
    boolean valid = manifestTargetModuleHeadValid(
      source, kinds, starts, lengths, count, moduleToken, sourcesKey
    );
    if (valid == false) {
      return -1;
    }

    long next = manifestTargetSourceCollectionProduct(
      source, kinds, starts, lengths, count, cursor, sourceRows, sourceOffset
    );
    return next;
  }
}
