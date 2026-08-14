//! Publishes source-ordered callable local, instruction, code, and type coordinates.

module wheeler.compiler.closure.callable_coordinate_products;

classical class CallableCoordinateProducts {
  private const long CALLABLE_CODE_LENGTH_ROW = 192;
  private const long CALLABLE_CODE_START_ROW = 128;
  private const long CALLABLE_INSTRUCTION_COUNT_ROW = 64;
  private const long CALLABLE_ROWS = 320;
  private const long CALLABLE_TYPE_START_ROW = 256;
  private const long MAX_CALLABLES = 64;
  private const long MAX_CODE_BYTES = 262144;
  private const long MAX_INSTRUCTIONS = 32768;
  private const long MAX_LOCALS = 256;
  private const long MAX_LOCAL_TYPES = 4096;
  private const long MAX_PRODUCTS = 4096;
  private const long PRODUCT_CODE_LENGTH_ROW = 32768;
  private const long PRODUCT_INSTRUCTION_COUNT_ROW = 28672;
  private const long PRODUCT_KIND_ROW = 36864;
  private const long PRODUCT_LOGICAL_START_ROW = 16384;
  private const long PRODUCT_LOGICAL_WIDTH_ROW = 20480;
  private const long PRODUCT_PARENT_ROW = 12288;
  private const long PRODUCT_PHYSICAL_WIDTH_ROW = 24576;
  private const long PRODUCT_ROWS = 40960;
  private const long PRODUCT_SOURCE_END_ROW = 8192;
  private const long PRODUCT_SOURCE_START_ROW = 4096;
  private const long RESULT_CODE_LENGTH_ROW = 24576;
  private const long RESULT_CODE_START_ROW = 20480;
  private const long RESULT_INSTRUCTION_COUNT_ROW = 16384;
  private const long RESULT_INSTRUCTION_START_ROW = 12288;
  private const long RESULT_LOCAL_COUNT_ROW = 4096;
  private const long RESULT_LOCAL_END_ROW = 8192;
  private const long RESULT_ROWS = 36864;
  private const long RESULT_TYPE_COUNT_ROW = 32768;
  private const long RESULT_TYPE_START_ROW = 28672;

  /// Reports one complete callable coordinate extent.
  public record CallableCoordinatePlan(
    long productCount,
    long localTypeCount,
    long instructionCount,
    long codeLength,
    boolean valid
  ) {}

  private long nextProduct(
    long owner,
    long priorStart,
    long productCount,
    borrow mut words productRows
  ) {
    long selected = productCount;
    long selectedStart = 32769;
    long product = 0;
    while (product < productCount) limit MAX_PRODUCTS {
      if (productRows[product] == owner) {
        long start = productRows[PRODUCT_SOURCE_START_ROW + product];
        if (priorStart < start) {
          if (start < selectedStart) {
            selected = product;
            selectedStart = start;
          }
        }
      }

      product += 1;
    }

    return selected;
  }

  private boolean ancestorOf(long ancestor, long product, borrow mut words productRows) {
    long cursor = productRows[PRODUCT_PARENT_ROW + product];
    long depth = 0;
    while (cursor != - 1) limit MAX_PRODUCTS {
      depth += 1;
      if (4 < depth) {
        return false;
      }

      if (cursor == ancestor) {
        return true;
      }

      cursor = productRows[PRODUCT_PARENT_ROW + cursor];
    }

    return false;
  }

  private boolean validDepth(long product, borrow mut words productRows) {
    long cursor = productRows[PRODUCT_PARENT_ROW + product];
    long depth = 0;
    while (cursor != - 1) limit MAX_PRODUCTS {
      depth += 1;
      if (4 < depth) {
        return false;
      }

      cursor = productRows[PRODUCT_PARENT_ROW + cursor];
    }

    return true;
  }

  private boolean validSourceRelations(
    long product,
    long productCount,
    borrow mut words productRows
  ) {
    long start = productRows[PRODUCT_SOURCE_START_ROW + product];
    long end = productRows[PRODUCT_SOURCE_END_ROW + product];
    long candidate = 0;
    while (candidate < productCount) limit MAX_PRODUCTS {
      if (candidate != product) {
        if (productRows[candidate] == productRows[product]) {
          long candidateStart = productRows[PRODUCT_SOURCE_START_ROW + candidate];
          long candidateEnd = productRows[PRODUCT_SOURCE_END_ROW + candidate];
          if (candidateStart == start) {
            return false;
          }

          if (start < candidateEnd) {
            if (candidateStart < end) {
              boolean related = ancestorOf(product, candidate, productRows);
              if (related == false) {
                related = ancestorOf(candidate, product, productRows);
              }

              if (related == false) {
                return false;
              }
            }
          }
        }
      }

      candidate += 1;
    }

    return true;
  }

  private boolean validParent(long product, long productCount, borrow mut words productRows) {
    long parent = productRows[PRODUCT_PARENT_ROW + product];
    if (parent == -1) {
      return true;
    }

    if (parent < 0) {
      return false;
    }

    if (productCount - 1 < parent) {
      return false;
    }

    if (productRows[parent] != productRows[product]) {
      return false;
    }

    long parentStart = productRows[PRODUCT_SOURCE_START_ROW + parent];
    long parentEnd = productRows[PRODUCT_SOURCE_END_ROW + parent];
    long start = productRows[PRODUCT_SOURCE_START_ROW + product];
    long end = productRows[PRODUCT_SOURCE_END_ROW + product];
    if (start < parentStart + 1) {
      return false;
    }

    return end < parentEnd + 1;
  }

  /// Plans every product by source coordinate without depending on product storage order.
  public CallableCoordinatePlan materializeCallableCoordinateProducts(
    long callableCount,
    borrow mut words signatureLocalCounts,
    long productCount,
    borrow mut words productRows,
    borrow mut words callableRows,
    borrow mut words coordinateRows
  ) {
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(signatureLocalCounts) == MAX_CALLABLES);
    assert(-1 < productCount);
    assert(productCount < MAX_PRODUCTS + 1);
    assert(bufferLength(productRows) == PRODUCT_ROWS);
    assert(bufferLength(callableRows) == CALLABLE_ROWS);
    assert(bufferLength(coordinateRows) == RESULT_ROWS);

    boolean valid = true;
    long product = 0;
    while (product < productCount) limit MAX_PRODUCTS {
      long owner = productRows[product];
      long sourceStart = productRows[PRODUCT_SOURCE_START_ROW + product];
      long sourceEnd = productRows[PRODUCT_SOURCE_END_ROW + product];
      long logicalStart = productRows[PRODUCT_LOGICAL_START_ROW + product];
      long logicalWidth = productRows[PRODUCT_LOGICAL_WIDTH_ROW + product];
      long physicalWidth = productRows[PRODUCT_PHYSICAL_WIDTH_ROW + product];
      long instructionCount = productRows[PRODUCT_INSTRUCTION_COUNT_ROW + product];
      long codeLength = productRows[PRODUCT_CODE_LENGTH_ROW + product];
      long kind = productRows[PRODUCT_KIND_ROW + product];
      if (owner < 0) {
        valid = false;
      }

      if (callableCount - 1 < owner) {
        valid = false;
      }

      if (sourceStart < 0) {
        valid = false;
      }

      if (32767 < sourceStart) {
        valid = false;
      }

      if (sourceEnd < sourceStart + 1) {
        valid = false;
      }

      if (32768 < sourceEnd) {
        valid = false;
      }

      if (logicalStart < 0) {
        valid = false;
      }

      if (MAX_LOCALS < logicalStart) {
        valid = false;
      }

      if (logicalWidth < 0) {
        valid = false;
      }

      if (MAX_LOCALS < logicalWidth) {
        valid = false;
      }

      if (physicalWidth < 0) {
        valid = false;
      }

      if (MAX_LOCALS < physicalWidth) {
        valid = false;
      }

      if (instructionCount < 0) {
        valid = false;
      }

      if (MAX_INSTRUCTIONS < instructionCount) {
        valid = false;
      }

      if (codeLength < 0) {
        valid = false;
      }

      if (MAX_CODE_BYTES < codeLength) {
        valid = false;
      }

      if (kind < 1) {
        valid = false;
      }

      if (8 < kind) {
        valid = false;
      }

      if (validParent(product, productCount, productRows) == false) {
        valid = false;
      }

      product += 1;
    }

    if (valid) {
      product = 0;
      while (product < productCount) limit MAX_PRODUCTS {
        if (validDepth(product, productRows) == false) {
          valid = false;
        }

        if (validSourceRelations(product, productCount, productRows) == false) {
          valid = false;
        }

        product += 1;
      }
    }

    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long validatedSignatureCount = signatureLocalCounts[callable];
      if (validatedSignatureCount < 0) {
        valid = false;
      }

      if (MAX_LOCALS < validatedSignatureCount) {
        valid = false;
      }

      callable += 1;
    }

    if (valid == false) {
      return new CallableCoordinatePlan(0, 0, 0, 0, false);
    }

    region staging = new region(/* bytes= */ 297472, /* allocations= */ 2);
    words stagedCallables = allocate(staging, CALLABLE_ROWS);
    words stagedCoordinates = allocate(staging, RESULT_ROWS);
    long totalInstructions = 0;
    long codeCursor = 0;
    long typeCursor = 0;
    long processedProducts = 0;
    callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long signatureCount = signatureLocalCounts[callable];
      long logicalCursor = signatureCount;
      long physicalCursor = signatureCount;
      long callableInstructionCursor = 0;
      long callableCodeStart = codeCursor;
      long callableTypeStart = typeCursor;
      typeCursor += signatureCount;
      long priorStart = -1;
      boolean selecting = true;
      while (selecting) limit MAX_PRODUCTS {
        long selected = nextProduct(callable, priorStart, productCount, productRows);
        if (selected == productCount) {
          selecting = false;
        } else {
          long selectedStart = productRows[PRODUCT_SOURCE_START_ROW + selected];
          long emittedLogicalStart = productRows[PRODUCT_LOGICAL_START_ROW + selected];
          long emittedLogicalWidth = productRows[PRODUCT_LOGICAL_WIDTH_ROW + selected];
          long emittedPhysicalWidth = productRows[PRODUCT_PHYSICAL_WIDTH_ROW + selected];
          long emittedInstructionCount = productRows[PRODUCT_INSTRUCTION_COUNT_ROW + selected];
          long emittedCodeLength = productRows[PRODUCT_CODE_LENGTH_ROW + selected];
          if (emittedLogicalStart != logicalCursor) {
            valid = false;
          }

          if (MAX_LOCALS - physicalCursor < emittedPhysicalWidth) {
            valid = false;
          }

          if (valid) {
            set(stagedCoordinates, selected, physicalCursor);
            set(stagedCoordinates, RESULT_LOCAL_COUNT_ROW + selected, emittedPhysicalWidth);
            set(
              stagedCoordinates,
              RESULT_LOCAL_END_ROW + selected,
              physicalCursor + emittedPhysicalWidth
            );
            set(
              stagedCoordinates,
              RESULT_INSTRUCTION_START_ROW + selected,
              callableInstructionCursor
            );
            set(
              stagedCoordinates,
              RESULT_INSTRUCTION_COUNT_ROW + selected,
              emittedInstructionCount
            );
            set(stagedCoordinates, RESULT_CODE_START_ROW + selected, codeCursor);
            set(stagedCoordinates, RESULT_CODE_LENGTH_ROW + selected, emittedCodeLength);
            set(stagedCoordinates, RESULT_TYPE_START_ROW + selected, typeCursor);
            set(stagedCoordinates, RESULT_TYPE_COUNT_ROW + selected, emittedPhysicalWidth);
          }

          logicalCursor += emittedLogicalWidth;
          if (MAX_LOCALS < logicalCursor) {
            valid = false;
          }

          physicalCursor += emittedPhysicalWidth;
          callableInstructionCursor += emittedInstructionCount;
          codeCursor += emittedCodeLength;
          typeCursor += emittedPhysicalWidth;
          if (MAX_CODE_BYTES < codeCursor) {
            valid = false;
          }

          if (MAX_LOCAL_TYPES < typeCursor) {
            valid = false;
          }

          if (MAX_INSTRUCTIONS < callableInstructionCursor) {
            valid = false;
          }

          priorStart = selectedStart;
          processedProducts += 1;
        }
      }

      set(stagedCallables, callable, physicalCursor);
      set(stagedCallables, CALLABLE_INSTRUCTION_COUNT_ROW + callable, callableInstructionCursor);
      set(stagedCallables, CALLABLE_CODE_START_ROW + callable, callableCodeStart);
      set(stagedCallables, CALLABLE_CODE_LENGTH_ROW + callable, codeCursor - callableCodeStart);
      set(stagedCallables, CALLABLE_TYPE_START_ROW + callable, callableTypeStart);
      totalInstructions += callableInstructionCursor;
      if (MAX_INSTRUCTIONS < totalInstructions) {
        valid = false;
      }

      callable += 1;
    }

    if (processedProducts != productCount) {
      valid = false;
    }

    if (valid) {
      long row = 0;
      while (row < CALLABLE_ROWS) limit CALLABLE_ROWS {
        set(callableRows, row, stagedCallables[row]);
        row += 1;
      }

      row = 0;
      while (row < RESULT_ROWS) limit RESULT_ROWS {
        set(coordinateRows, row, stagedCoordinates[row]);
        row += 1;
      }
    }

    drop(stagedCoordinates);
    drop(stagedCallables);
    drop(staging);
    if (valid == false) {
      return new CallableCoordinatePlan(0, 0, 0, 0, false);
    }

    return new CallableCoordinatePlan(
      processedProducts,
      typeCursor,
      totalInstructions,
      codeCursor,
      true
    );
  }
}
