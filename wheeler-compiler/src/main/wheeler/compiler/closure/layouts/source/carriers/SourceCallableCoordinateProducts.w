//! Adapts measured source statement extents to callable coordinate products.

module wheeler.compiler.closure.source_callable_coordinate_products;

import wheeler.compiler.closure.callable_coordinate_products;
import wheeler.compiler.closure.loop_body_layouts;

classical class SourceCallableCoordinateProducts {
  private const long MAX_CALLABLES = 64;
  private const long MAX_STATEMENTS = 4096;
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
  private const long RESULT_ROWS = 36864;
  private const long STAGING_BYTES = 625664;

  /// Reports one complete measured source coordinate set.
  public record SourceCallableCoordinatePlan(
    long statementCount,
    long localTypeCount,
    boolean valid
  ) {}

  private long nearestParent(long statement, long statementCount, borrow mut words statementRows) {
    long owner = statementRows[statement];
    long start = statementRows[LOOP_STATEMENT_START_ROW + statement];
    long end = start + statementRows[LOOP_STATEMENT_LENGTH_ROW + statement];
    long parent = -1;
    long parentStart = -1;
    long candidate = 0;
    while (candidate < statementCount) limit MAX_STATEMENTS {
      if (candidate != statement) {
        if (statementRows[candidate] == owner) {
          if (0 < statementRows[LOOP_STATEMENT_CHILD_COUNT_ROW + candidate]) {
            long candidateStart = statementRows[LOOP_STATEMENT_START_ROW + candidate];
            long candidateEnd = candidateStart + statementRows[LOOP_STATEMENT_LENGTH_ROW
              + candidate];
            if (candidateStart < start) {
              if (end < candidateEnd + 1) {
                if (parentStart < candidateStart) {
                  parent = candidate;
                  parentStart = candidateStart;
                }
              }
            }
          }
        }
      }

      candidate += 1;
    }

    return parent;
  }

  /// Publishes statement physical starts after complete measured-width validation.
  public SourceCallableCoordinatePlan materializeSourceCallableCoordinateProducts(
    long callableCount,
    borrow mut words parameterCounts,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words statementLocalRows,
    borrow mut words statementPhysicalWidths,
    borrow mut words statementPhysicalStarts
  ) {
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(parameterCounts) == MAX_CALLABLES);
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == LOOP_STATEMENT_ROWS);
    assert(bufferLength(statementLocalRows) == 8192);
    assert(bufferLength(statementPhysicalWidths) == MAX_STATEMENTS);
    assert(bufferLength(statementPhysicalStarts) == MAX_STATEMENTS);

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 4);
    words productRows = allocate(staging, PRODUCT_ROWS);
    words signatureCounts = allocate(staging, MAX_CALLABLES);
    words callableRows = allocate(staging, /* length= */ 320);
    words coordinateRows = allocate(staging, RESULT_ROWS);
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      set(signatureCounts, callable, parameterCounts[callable]);
      callable += 1;
    }

    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      long start = statementRows[LOOP_STATEMENT_START_ROW + statement];
      long length = statementRows[LOOP_STATEMENT_LENGTH_ROW + statement];
      long kind = 2;
      if (0 < statementRows[LOOP_STATEMENT_CHILD_COUNT_ROW + statement]) {
        kind = 1;
      }

      set(productRows, statement, statementRows[statement]);
      set(productRows, PRODUCT_SOURCE_START_ROW + statement, start);
      set(productRows, PRODUCT_SOURCE_END_ROW + statement, start + length);
      set(
        productRows,
        PRODUCT_PARENT_ROW + statement,
        nearestParent(statement, statementCount, statementRows)
      );
      set(productRows, PRODUCT_LOGICAL_START_ROW + statement, statementLocalRows[statement]);
      set(
        productRows,
        PRODUCT_LOGICAL_WIDTH_ROW + statement,
        statementLocalRows[MAX_STATEMENTS + statement]
      );
      set(
        productRows,
        PRODUCT_PHYSICAL_WIDTH_ROW + statement,
        statementPhysicalWidths[statement]
      );
      set(productRows, PRODUCT_INSTRUCTION_COUNT_ROW + statement, 0);
      set(productRows, PRODUCT_CODE_LENGTH_ROW + statement, 0);
      set(productRows, PRODUCT_KIND_ROW + statement, kind);
      statement += 1;
    }

    CallableCoordinatePlan planned = materializeCallableCoordinateProducts(
      callableCount,
      signatureCounts,
      statementCount,
      productRows,
      callableRows,
      coordinateRows
    );
    if (planned.valid) {
      statement = 0;
      while (statement < statementCount) limit MAX_STATEMENTS {
        set(statementPhysicalStarts, statement, coordinateRows[statement]);
        statement += 1;
      }
    }

    drop(coordinateRows);
    drop(callableRows);
    drop(signatureCounts);
    drop(productRows);
    drop(staging);
    if (planned.valid == false) {
      return new SourceCallableCoordinatePlan(0, 0, false);
    }

    return new SourceCallableCoordinatePlan(statementCount, planned.localTypeCount, true);
  }
}
