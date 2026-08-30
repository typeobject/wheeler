//! Checks fixed-width output coordinates for package manifests.

module wheeler.compiler.packages.manifest_rows;

classical class PackageManifestRows {
  /// Checks one complete ten-column target row.
  public boolean manifestTargetRowCapacity(borrow mut words rows, long row) {
    long rowStart = row * 10;
    long finalColumn = rowStart + 9;
    long capacity = bufferLength(rows);
    return finalColumn < capacity;
  }

  /// Checks one complete two-column target-source row.
  public boolean manifestSourceRowCapacity(borrow mut words rows, long row) {
    long rowStart = row * 2;
    long finalColumn = rowStart + 1;
    long capacity = bufferLength(rows);
    return finalColumn < capacity;
  }

  /// Checks one complete five-column dependency row.
  public boolean manifestDependencyRowCapacity(borrow mut words rows, long row) {
    long rowStart = row * 5;
    long finalColumn = rowStart + 4;
    long capacity = bufferLength(rows);
    return finalColumn < capacity;
  }

  /// Checks one complete four-column capability row.
  public boolean manifestCapabilityRowCapacity(borrow mut words rows, long row) {
    long rowStart = row * 4;
    long finalColumn = rowStart + 3;
    long capacity = bufferLength(rows);
    return finalColumn < capacity;
  }
}
