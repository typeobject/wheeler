//! Composes package-manifest target source-collection policy.

module wheeler.compiler.packages.manifest_target_source_collection;

import wheeler.compiler.packages.manifest_rows;
import wheeler.compiler.packages.manifest_target_coordinates;
import wheeler.compiler.packages.manifest_target_source;
import wheeler.compiler.packages.manifest_target_source_coordinates;
import wheeler.compiler.packages.manifest_target_source_row;
import wheeler.compiler.packages.manifest_tokens;

classical class PackageManifestTargetSourceCollection {
  /// Publishes a nonempty, ordered, root-covering source list after a validated module head.
  /// Returns the next source-row index, or minus one without committing a count.
  /// Admitted rows remain on rejection. The caller still validates the target tail.
  public long manifestTargetSourceCollectionProduct(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long targetCursor,
    borrow mut words sourceRows,
    long sourceOffset
  ) {
    long next = manifestTargetFirstSourceRowToken(targetCursor);
    long rootToken = manifestTargetRootToken(targetCursor);
    long sourceIndex = sourceOffset;
    long sourceCount = 0;
    boolean rootCovered = false;
    boolean valid = true;
    // One terminal probe follows at most 1,024 published selectors.
    while (next < count) limit 1025 {
      long destination = sourceIndex;
      if (sourceCount == 1024) {
        // A negative row disables publication but still allows the terminal probe.
        destination = -1;
      }
      long selectorToken = manifestTargetSourceEntryProduct(
        source, kinds, starts, lengths, count, next, sourceRows, destination
      );
      boolean admitted = true;
      if (selectorToken < 1) {
        admitted = false;
        next = count;
      }
      if (selectorToken < 0) {
        valid = false;
      }
      if (admitted) {
        boolean covered = manifestTargetSourceCoverage(
          source, starts, lengths, selectorToken, rootToken, rootCovered
        );
        rootCovered = covered;
        sourceIndex += 1;
        sourceCount += 1;
        long following = manifestTargetNextSourceRowToken(next);
        next = following;
      }
    }

    long result = completedSourceCount(sourceIndex, sourceCount, rootCovered, valid);
    return result;
  }

  private long completedSourceCount(long next, long count, boolean covered, boolean valid) {
    if (valid == false) {
      return -1;
    }
    if (count == 0) {
      return -1;
    }
    if (covered == false) {
      return -1;
    }
    return next;
  }

  /// The first row follows the sources colon. Later rows follow a quoted selector.
  private long previousSelectorToken(borrow mut words kinds, long rowToken) {
    long previous = rowToken - 1;
    long kind = kinds[previous];
    if (kind == 6) {
      return previous;
    }
    return -1;
  }

  /// Accepts a first selector or checks strict order after its predecessor.
  private boolean manifestTargetSourceFollows(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long previousToken,
    long selectorToken
  ) {
    if (previousToken < 0) {
      return true;
    }

    boolean ordered = manifestTargetSourcesOrdered(
      source,
      starts,
      lengths,
      previousToken,
      selectorToken
    );
    return ordered;
  }

  /// Preserves earlier root coverage or admits current coverage.
  private boolean manifestTargetSourceRootCovered(boolean covered, boolean current) {
    if (covered == true) {
      return true;
    }
    return current;
  }

  /// Updates root coverage from one admitted selector.
  private boolean manifestTargetSourceCoverage(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long selectorToken,
    long rootToken,
    boolean covered
  ) {
    boolean current = manifestTargetSourceCoversRoot(
      source,
      starts,
      lengths,
      selectorToken,
      rootToken
    );
    boolean result = manifestTargetSourceRootCovered(covered, current);
    return result;
  }

  /// Returns a published selector, zero at a non-row tail, or minus one on rejection.
  private long manifestTargetSourceEntryProduct(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long rowToken,
    borrow mut words sourceRows,
    long sourceIndex
  ) {
    boolean rowPresent = dashAt(source, kinds, starts, rowToken);
    if (rowPresent == false) {
      return 0;
    }
    boolean valid = manifestTargetSourceRowValid(source, kinds, starts, lengths, count, rowToken);
    if (valid == false) {
      return -1;
    }
    long selectorToken = manifestTargetSelectorToken(rowToken);
    boolean capacity = manifestSourceRowCapacity(sourceRows, sourceIndex);
    if (capacity == false) {
      return -1;
    }

    long previousToken = previousSelectorToken(kinds, rowToken);
    boolean ordered = manifestTargetSourceFollows(
      source,
      starts,
      lengths,
      previousToken,
      selectorToken
    );
    if (ordered == false) {
      return -1;
    }

    long sourceBase = sourceIndex * 2;
    long nextSource = sourceBase + 1;
    long selectorStart = manifestTargetSourceStart(starts, selectorToken);
    long selectorLength = manifestTargetSourceLength(lengths, selectorToken);
    set(sourceRows, sourceBase, selectorStart);
    set(sourceRows, nextSource, selectorLength);
    return selectorToken;
  }
}
