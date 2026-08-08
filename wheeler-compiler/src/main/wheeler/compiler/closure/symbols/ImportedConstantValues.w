//! Packs direct public scalar products for bounded expression lookup.

module wheeler.compiler.closure.imported_constant_values;

import wheeler.compiler.constant_declarations;

classical class ImportedConstantValues {
  /// Names the complete packed direct-import lookup table size.
  public const long IMPORTED_CONSTANT_ROWS = 114689;
  private const long IMPORTED_CONSTANT_LIMIT = 16384;
  private const long IMPORTED_CONSTANT_ROW_WIDTH = 7;

  /// Writes one dependent's direct public products in header and declaration order.
  public long writeDirectImportedValues(
    long firstImport,
    long directImportCount,
    borrow mut words edgeTargets,
    borrow mut words moduleFirstSymbols,
    borrow mut words moduleSymbolCounts,
    borrow mut words moduleNameStarts,
    borrow mut words moduleNameLengths,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolVisibilities,
    borrow mut words symbolTypes,
    borrow mut words symbolValues,
    borrow mut words symbolResolved,
    borrow mut words importedRows
  ) {
    assert(bufferLength(importedRows) == IMPORTED_CONSTANT_ROWS);
    long importedCount = 0;
    long rank = 0;
    while (rank < directImportCount) limit 64 {
      long dependency = edgeTargets[firstImport + rank];
      if (-1 < dependency) {
        long first = moduleFirstSymbols[dependency];
        long count = moduleSymbolCounts[dependency];
        long offset = 0;
        while (offset < count) limit MAX_CLASS_CONSTANTS {
          long symbol = first + offset;
          if (symbolVisibilities[symbol] == 1) {
            assert(importedCount < IMPORTED_CONSTANT_LIMIT);
            long base = 1 + importedCount * IMPORTED_CONSTANT_ROW_WIDTH;
            set(importedRows, base, symbolStarts[symbol]);
            set(importedRows, base + 1, symbolLengths[symbol]);
            set(importedRows, base + 2, symbolTypes[symbol]);
            set(importedRows, base + 3, symbolValues[symbol]);
            set(importedRows, base + 4, symbolResolved[symbol]);
            set(importedRows, base + 5, moduleNameStarts[dependency]);
            set(importedRows, base + 6, moduleNameLengths[dependency]);
            importedCount += 1;
          }

          offset += 1;
        }
      }

      rank += 1;
    }

    set(importedRows, 0, importedCount);
    return importedCount;
  }
}
