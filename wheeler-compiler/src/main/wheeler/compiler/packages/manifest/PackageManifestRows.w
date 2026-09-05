//! Checks fixed-width output coordinates for package manifests.

module wheeler.compiler.packages.manifest_rows;

classical class PackageManifestRows {
  /// Checks one complete ten-column target row.
  public boolean manifestTargetRowCapacity(borrow mut words rows, long row) {
    if (row < 0) {
      return false;
    }
    long capacity = bufferLength(rows);
    long completeRows = capacity / 10;
    return row < completeRows;
  }

  /// Checks one complete two-column target-source row.
  public boolean manifestSourceRowCapacity(borrow mut words rows, long row) {
    if (row < 0) {
      return false;
    }
    long capacity = bufferLength(rows);
    long completeRows = capacity / 2;
    return row < completeRows;
  }

  /// Checks one complete five-column dependency row.
  public boolean manifestDependencyRowCapacity(borrow mut words rows, long row) {
    if (row < 0) {
      return false;
    }
    long capacity = bufferLength(rows);
    long completeRows = capacity / 5;
    return row < completeRows;
  }

  /// Checks one complete four-column capability row.
  public boolean manifestCapabilityRowCapacity(borrow mut words rows, long row) {
    if (row < 0) {
      return false;
    }
    long capacity = bufferLength(rows);
    long completeRows = capacity / 4;
    return row < completeRows;
  }
}
