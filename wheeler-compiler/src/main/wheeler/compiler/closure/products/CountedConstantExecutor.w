//! Compiles one executable root from counted scalar module products.

module wheeler.compiler.closure.counted_constant_executor;

import wheeler.compiler.closure.imported_constant_values;
import wheeler.compiler.closure.product_root_source;
import wheeler.compiler.compiler_core;

classical class CountedConstantExecutors {
  private const long IMPORTED_CONSTANT_ARENA_BYTES = 917512;
  private const long MAX_IMPORTS = 3072;
  private const long MAX_LINKED_SOURCE_BYTES = 32768;

  /// Reports whether scalar products admitted compilation and the exact artifact length.
  public record CountedConstantExecution(boolean attempted, long length) {}

  /// Compiles an executable root after replacing direct references from completed products.
  ///
  /// This path copies no dependency source. Unsupported roots return without touching output.
  public CountedConstantExecution compileCountedConstantRoot(
    borrow byteview archive,
    long rootModule,
    long rootExecutable,
    borrow mut words sourceStarts,
    borrow mut words sourceLengths,
    borrow mut words firstImports,
    borrow mut words directImportCounts,
    borrow mut words edgeTargets,
    borrow mut words edgeSymbolCounts,
    borrow mut words moduleFirstSymbols,
    borrow mut words moduleSymbolCounts,
    borrow mut words moduleProductNameStarts,
    borrow mut words moduleProductNameLengths,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolVisibilities,
    borrow mut words symbolTypes,
    borrow mut words symbolValues,
    borrow mut words symbolResolved,
    borrow mut bytes output
  ) {
    if (rootExecutable == 1) {} else {
      return new CountedConstantExecution(false, 0);
    }

    long importCount = directImportCounts[rootModule];
    if (0 < importCount) {} else {
      return new CountedConstantExecution(false, 0);
    }

    long firstImport = firstImports[rootModule];
    long checked = 0;
    while (checked < importCount) limit MAX_IMPORTS {
      long edge = firstImport + checked;
      if (-1 < edgeTargets[edge]) {} else {
        return new CountedConstantExecution(false, 0);
      }

      if (0 < edgeSymbolCounts[edge]) {} else {
        return new CountedConstantExecution(false, 0);
      }

      checked += 1;
    }

    region importedArena = new region(
      /* bytes= */ IMPORTED_CONSTANT_ARENA_BYTES,
      /* allocations= */ 1
    );
    words importedRows = allocate(importedArena, IMPORTED_CONSTANT_ROWS);
    long importedCount = writeDirectImportedValues(
      firstImport,
      importCount,
      edgeTargets,
      moduleFirstSymbols,
      moduleSymbolCounts,
      moduleProductNameStarts,
      moduleProductNameLengths,
      symbolStarts,
      symbolLengths,
      symbolVisibilities,
      symbolTypes,
      symbolValues,
      symbolResolved,
      importedRows
    );
    if (0 < importedCount) {} else {
      drop(importedRows);
      drop(importedArena);
      return new CountedConstantExecution(false, 0);
    }

    region sourceArena = new region(/* bytes= */ 65536, /* allocations= */ 2);
    bytes scratch = allocateBytes(sourceArena, MAX_LINKED_SOURCE_BYTES);
    long sourceLength = writeProductRootSource(
      archive,
      sourceStarts[rootModule],
      sourceLengths[rootModule],
      moduleFirstSymbols[rootModule],
      moduleSymbolCounts[rootModule],
      symbolStarts,
      symbolLengths,
      importedRows,
      scratch
    );
    if (0 < sourceLength) {} else {
      drop(scratch);
      drop(sourceArena);
      drop(importedRows);
      drop(importedArena);
      return new CountedConstantExecution(false, 0);
    }

    bytes normalizedBytes = allocateBytes(sourceArena, sourceLength);
    long copied = 0;
    while (copied < sourceLength) limit MAX_LINKED_SOURCE_BYTES {
      setByte(normalizedBytes, copied, scratch[copied]);
      copied += 1;
    }

    utf8 normalizedSource = freezeUtf8(normalizedBytes);
    CoreCompilation compiled = compileMinimalCore(normalizedSource, output);
    CountedConstantExecution result = new CountedConstantExecution(true, compiled.length);
    drop(normalizedSource);
    drop(scratch);
    drop(sourceArena);
    drop(importedRows);
    drop(importedArena);
    return result;
  }
}
