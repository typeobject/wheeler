//! Packs direct public scalar products for bounded expression lookup.

module wheeler.compiler.closure.imported_constant_values;

import wheeler.compiler.constant_declarations;
import wheeler.compiler.constant_product_schema;

classical class ImportedConstantValues {
  private const long MAX_LOCAL_MODULES = 512;
  private const long MAX_DIRECT_IMPORTS = 64;
  /// Appends one selected module's own scalar products in declaration order.
  public long appendDirectLocalValues(
    long moduleOwner,
    long importedCount,
    borrow mut words moduleFirstSymbols,
    borrow mut words moduleSymbolCounts,
    borrow mut words moduleNameStarts,
    borrow mut words moduleNameLengths,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolTypes,
    borrow mut words symbolValues,
    borrow mut words symbolResolved,
    borrow mut words importedRows
  ) {
    assert(-1 < moduleOwner);
    assert(moduleOwner < MAX_LOCAL_MODULES);
    assert(-1 < importedCount);
    assert(importedCount < MAX_CONSTANT_PRODUCTS + 1);
    assert(bufferLength(importedRows) == CONSTANT_PRODUCT_ROWS);
    long first = moduleFirstSymbols[moduleOwner];
    long count = moduleSymbolCounts[moduleOwner];
    assert(-1 < first);
    assert(-1 < count);
    assert(count < MAX_CLASS_CONSTANTS + 1);
    long offset = 0;
    while (offset < count) limit MAX_CLASS_CONSTANTS {
      assert(importedCount < MAX_CONSTANT_PRODUCTS);
      long symbol = first + offset;
      long base = CONSTANT_PRODUCT_HEADER_ROWS + importedCount * CONSTANT_PRODUCT_COLUMNS;
      set(importedRows, base + CONSTANT_NAME_START, symbolStarts[symbol]);
      set(importedRows, base + CONSTANT_NAME_LENGTH, symbolLengths[symbol]);
      set(importedRows, base + CONSTANT_TYPE, symbolTypes[symbol]);
      set(importedRows, base + CONSTANT_VALUE, symbolValues[symbol]);
      set(importedRows, base + CONSTANT_RESOLVED, symbolResolved[symbol]);
      set(importedRows, base + CONSTANT_MODULE_START, moduleNameStarts[moduleOwner]);
      set(importedRows, base + CONSTANT_MODULE_LENGTH, moduleNameLengths[moduleOwner]);
      importedCount += 1;
      offset += 1;
    }

    set(importedRows, 0, importedCount);
    return importedCount;
  }

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
    assert(bufferLength(importedRows) == CONSTANT_PRODUCT_ROWS);
    long importedCount = 0;
    long rank = 0;
    while (rank < directImportCount) limit MAX_DIRECT_IMPORTS {
      long dependency = edgeTargets[firstImport + rank];
      if (-1 < dependency) {
        long first = moduleFirstSymbols[dependency];
        long count = moduleSymbolCounts[dependency];
        long offset = 0;
        while (offset < count) limit MAX_CLASS_CONSTANTS {
          long symbol = first + offset;
          if (symbolVisibilities[symbol] == 1) {
            assert(importedCount < MAX_CONSTANT_PRODUCTS);
            long base = CONSTANT_PRODUCT_HEADER_ROWS + importedCount * CONSTANT_PRODUCT_COLUMNS;
            set(importedRows, base + CONSTANT_NAME_START, symbolStarts[symbol]);
            set(importedRows, base + CONSTANT_NAME_LENGTH, symbolLengths[symbol]);
            set(importedRows, base + CONSTANT_TYPE, symbolTypes[symbol]);
            set(importedRows, base + CONSTANT_VALUE, symbolValues[symbol]);
            set(importedRows, base + CONSTANT_RESOLVED, symbolResolved[symbol]);
            set(importedRows, base + CONSTANT_MODULE_START, moduleNameStarts[dependency]);
            set(importedRows, base + CONSTANT_MODULE_LENGTH, moduleNameLengths[dependency]);
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
