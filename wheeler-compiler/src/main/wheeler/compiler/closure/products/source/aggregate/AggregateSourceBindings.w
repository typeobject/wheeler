//! Binds original aggregate source values and resolves private operation products.

module wheeler.compiler.closure.aggregate_source_bindings;

import wheeler.compiler.closure.aggregate_constructor_targets;
import wheeler.compiler.closure.aggregate_expression_temporaries;
import wheeler.compiler.closure.aggregate_frontend_bindings;
import wheeler.compiler.closure.aggregate_indexed_owners;
import wheeler.compiler.closure.aggregate_instruction_products;
import wheeler.compiler.closure.aggregate_projection_targets;
import wheeler.compiler.closure.aggregate_resolved_operands;
import wheeler.compiler.closure.aggregate_source_owners;
import wheeler.compiler.closure.local_nominal_carrier_projections;
import wheeler.compiler.closure.resolved_aggregate_operations;
import wheeler.compiler.closure.source_statement_products;
import wheeler.compiler.closure.source_value_products;

classical class AggregateSourceBindings {
  /// Counts the active original-source products needed by later private phases.
  public record AggregateSourceValuePlan(
    long statementCount,
    long valueCount,
    long projectionCount
  ) {}

  /// Binds admitted original-source windows into compiler-private value and placement rows.
  /// Rejection may change scratch. The outer adapter must not lend caller publication buffers.
  public AggregateSourceValuePlan bindAggregateSourceValues(
    borrow utf8 source,
    borrow byteview sourceArchive,
    long sourceStart,
    long firstLocalCallable,
    long localCallableCount,
    borrow mut words localCallableBodyStarts,
    borrow mut words localCallableBodyLengths,
    long operationCount,
    borrow mut words operationRows,
    long argumentCount,
    borrow mut words argumentRows,
    long aggregateCount,
    borrow mut words aggregateRows,
    long localCaseCount,
    borrow mut words localCaseRows,
    long localNominalReferenceCount,
    borrow mut words localNominalReferenceRows,
    borrow mut words stagedStatements,
    borrow mut words stagedValues,
    borrow mut words stagedLocalCounts,
    borrow mut words stagedStatementLocals,
    borrow mut words stagedLocalProjections,
    borrow mut words stagedDestinations,
    borrow mut words stagedOwners,
    borrow mut words stagedArguments,
    borrow mut words stagedPlacements,
    borrow mut words stagedConstructorTargets
  ) {
    SourceStatementProductPlan sourceStatements = materializeSourceStatementProducts(
      source,
      sourceStart,
      firstLocalCallable,
      localCallableCount,
      localCallableBodyStarts,
      localCallableBodyLengths,
      stagedStatements
    );
    assert(sourceStatements.valid);
    SourceValueProductPlan sourceValues = materializeSourceValueProducts(
      source,
      /* globalNames= */ sourceArchive,
      /* globalCount= */ 0,
      /* globalProductStart= */ 0,
      /* globals= */ operationRows,
      sourceStart,
      firstLocalCallable,
      localCallableCount,
      /* reversibleCallableCount= */ 0,
      localCallableBodyStarts,
      sourceStatements.statementCount,
      stagedStatements,
      /* statementStartRow= */ 16384,
      /* statementLengthRow= */ 20480,
      stagedValues,
      stagedLocalCounts,
      stagedStatementLocals
    );
    assert(sourceValues.valid);
    AggregateExpressionTemporaryPlan expressionValues = appendAggregateExpressionTemporaries(
      operationCount,
      operationRows,
      sourceStatements.statementCount,
      stagedStatements,
      sourceValues.valueCount,
      stagedValues,
      stagedLocalCounts
    );
    assert(expressionValues.valid);
    AggregateFrontendBindingPlan frontendBindings = projectAggregateFrontendBindings(
      source,
      operationCount,
      operationRows,
      argumentCount,
      argumentRows,
      expressionValues.valueCount,
      stagedValues,
      sourceStatements.statementCount,
      stagedStatements,
      stagedDestinations,
      stagedOwners,
      stagedArguments,
      stagedPlacements
    );
    assert(frontendBindings.valid);
    boolean constructorTargetsValid = resolveLocalAggregateConstructorTargets(
      source,
      operationCount,
      operationRows,
      aggregateCount,
      aggregateRows,
      localCaseCount,
      localCaseRows,
      stagedConstructorTargets
    );
    assert(constructorTargetsValid);
    LocalNominalCarrierProjectionPlan localProjectionPlan = publishLocalNominalCarrierProjections(
      source,
      localNominalReferenceCount,
      localNominalReferenceRows,
      expressionValues.valueCount,
      stagedValues,
      operationCount,
      operationRows,
      stagedLocalProjections
    );
    assert(localProjectionPlan.valid);
    return new AggregateSourceValuePlan(
      sourceStatements.statementCount,
      expressionValues.valueCount,
      localProjectionPlan.projectionCount
    );
  }

  /// Resolves original operation coordinates into private canonical supplemental instructions.
  /// Inputs come from the admitted fronts and value phase, not dependency source bodies.
  public AggregateInstructionProductPlan resolveAggregateSourceOperations(
    borrow utf8 source,
    long operationCount,
    borrow mut words operationRows,
    long argumentCount,
    borrow mut words argumentRows,
    long aggregateCount,
    borrow mut words aggregateRows,
    long localCaseCount,
    borrow mut words localCaseRows,
    long localMemberCount,
    borrow mut words localMemberRows,
    long valueCount,
    long projectionCount,
    borrow mut words stagedValues,
    borrow mut words stagedValueStructures,
    borrow mut words stagedLocalProjections,
    borrow mut words stagedDestinations,
    borrow mut words stagedOwners,
    borrow mut words stagedArguments,
    borrow mut words stagedPlacements,
    borrow mut words stagedConstructorTargets,
    borrow mut words stagedOwnerAggregates,
    borrow mut words stagedOwnerCases,
    borrow mut words stagedProjectionTargets,
    borrow mut words stagedSliceDescriptors,
    borrow mut words stagedResolvedOperations,
    borrow mut bytes stagedSupplementalCode
  ) {
    AggregateSourceOwnerPlan sourceOwners = deriveAggregateSourceOwners(
      operationCount,
      operationRows,
      stagedDestinations,
      stagedOwners,
      stagedPlacements,
      projectionCount,
      stagedLocalProjections,
      stagedConstructorTargets,
      stagedOwnerAggregates,
      stagedOwnerCases
    );
    assert(sourceOwners.valid);
    AggregateIndexedOwnerPlan indexedOwners = deriveAggregateIndexedOwners(
      source,
      operationCount,
      operationRows,
      stagedDestinations,
      stagedOwners,
      stagedPlacements,
      valueCount,
      stagedValues,
      stagedValueStructures,
      aggregateCount,
      aggregateRows,
      localCaseCount,
      localCaseRows,
      localMemberCount,
      localMemberRows,
      stagedOwnerAggregates,
      stagedOwnerCases,
      stagedSliceDescriptors
    );
    assert(indexedOwners.valid);
    boolean projectionTargetsValid = resolveLocalAggregateProjectionTargets(
      source,
      operationCount,
      operationRows,
      aggregateCount,
      aggregateRows,
      localCaseCount,
      localCaseRows,
      localMemberCount,
      localMemberRows,
      stagedOwnerAggregates,
      stagedOwnerCases,
      stagedProjectionTargets
    );
    assert(projectionTargetsValid);
    boolean resolvedOperandsValid = assembleAggregateResolvedOperands(
      operationCount,
      operationRows,
      argumentCount,
      argumentRows,
      stagedArguments,
      stagedConstructorTargets,
      stagedProjectionTargets,
      stagedDestinations,
      stagedOwners,
      stagedSliceDescriptors,
      stagedResolvedOperations
    );
    assert(resolvedOperandsValid);
    return writeResolvedSourceAggregateInstructions(
      operationCount,
      operationRows,
      stagedResolvedOperations,
      stagedSupplementalCode
    );
  }
}
