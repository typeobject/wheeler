package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Builds the production counted archive-closure evidence program. */
final class NativeCompilerArchiveClosureProgram {
  record PhysicalModule(int owner, String path, String name) {}

  static final List<PhysicalModule> PHYSICAL_MODULES = List.of(
      physical(16, "compiler/syntax/BooleanDeclarationKinds.w", "boolean_declaration_kinds"),
      physical(18, "compiler/syntax/booleans/BooleanTokens.w", "boolean_tokens"),
      physical(22, "compiler/frontend/intrinsics/BorrowedIntrinsicShapes.w", "borrowed_intrinsic_shapes"),
      physical(24, "compiler/syntax/calls/CallArgumentSources.w", "call_argument_sources"),
      physical(125, "compiler/ir/limits/CompilerProgramLimits.w", "compiler_program_limits"),
      physical(135, "compiler/syntax/EarlyReturnKinds.w", "early_return_kinds"),
      physical(137, "compiler/syntax/EarlyReturnResultKinds.w", "early_return_result_kinds"),
      physical(138, "compiler/syntax/returns/EarlyReturnSources.w", "early_return_sources"),
      physical(144, "compiler/backend/EncodingWidths.w", "encoding_widths"),
      physical(147, "compiler/syntax/calls/FourArgumentCalls.w", "four_argument_calls"),
      physical(169, "compiler/syntax/helpers/HelperSignatures.w", "helper_signatures"),
      physical(172, "compiler/syntax/IdentifierStarts.w", "identifier_starts"),
      physical(174, "compiler/ir/InstructionForms.w", "instruction_forms"),
      physical(179, "compiler/syntax/conditionals/LiteralComparisonOperations.w", "literal_comparison_operations"),
      physical(194, "compiler/syntax/returns/NamedBooleanReturnKinds.w", "named_boolean_return_kinds"),
      physical(195, "compiler/syntax/comparisons/NamedComparisonKinds.w", "named_comparison_kinds"),
      physical(196, "compiler/syntax/conditionals/NamedConditionalBases.w", "named_conditional_bases"),
      physical(197, "compiler/syntax/conditionals/NamedLiteralComparisonKinds.w", "named_literal_comparison_kinds"),
      physical(198, "compiler/syntax/assignments/NamedLocalAssignmentKinds.w", "named_local_assignment_kinds"),
      physical(199, "compiler/syntax/conditionals/NamedLocalConditionalKinds.w", "named_local_conditional_kinds"),
      physical(200, "compiler/syntax/conditionals/NamedLocalConditionalValues.w", "named_local_conditional_values"),
      physical(201, "compiler/syntax/updates/NamedLocalUpdateKinds.w", "named_local_update_kinds"),
      physical(202, "compiler/syntax/locals/NamedLongOperations.w", "named_long_operations"),
      physical(203, "compiler/syntax/returns/NamedReturnArithmeticKinds.w", "named_return_arithmetic_kinds"),
      physical(204, "compiler/syntax/returns/NamedReturnComparisonOperands.w", "named_return_comparison_operands"),
      physical(205, "compiler/syntax/returns/NamedSignedReturnKinds.w", "named_signed_return_kinds"),
      physical(206, "compiler/syntax/calls/OneArgumentCalls.w", "one_argument_calls"),
      physical(207, "compiler/ir/OpcodeKinds.w", "opcode_kinds"),
      physical(208, "compiler/ir/Opcodes.w", "opcodes"),
      physical(227, "compiler/ir/ProofRules.w", "proof_rules"),
      physical(229, "compiler/syntax/assertions/ResolvedBooleanLiteralAssertions.w", "resolved_boolean_literal_assertions"),
      physical(230, "compiler/syntax/booleans/ResolvedBooleanLiteralComparisons.w", "resolved_boolean_literal_comparisons"),
      physical(231, "compiler/syntax/returns/ResolvedEarlyComparisonKinds.w", "resolved_early_comparison_kinds"),
      physical(232, "compiler/syntax/returns/ResolvedEarlyResultKinds.w", "resolved_early_result_kinds"),
      physical(234, "compiler/syntax/assertions/ResolvedLessThanAssertions.w", "resolved_less_than_assertions"),
      physical(235, "compiler/syntax/conditionals/ResolvedLiteralComparisonKinds.w", "resolved_literal_comparison_kinds"),
      physical(236, "compiler/syntax/assignments/ResolvedLocalAssignments.w", "resolved_local_assignments"),
      physical(237, "compiler/syntax/conditionals/ResolvedLocalConditionalKinds.w", "resolved_local_conditional_kinds"),
      physical(238, "compiler/syntax/conditionals/ResolvedLocalConditionalOperands.w", "resolved_local_conditional_operands"),
      physical(239, "compiler/syntax/conditionals/ResolvedLocalConditionalSources.w", "resolved_local_conditional_sources"),
      physical(240, "compiler/syntax/locals/ResolvedLocalCopyKinds.w", "resolved_local_copy_kinds"),
      physical(241, "compiler/syntax/locals/ResolvedLocalEqualityKinds.w", "resolved_local_equality_kinds"),
      physical(242, "compiler/syntax/locals/ResolvedLocalInequalityKinds.w", "resolved_local_inequality_kinds"),
      physical(243, "compiler/syntax/locals/ResolvedLocalLessThanKinds.w", "resolved_local_less_than_kinds"),
      physical(244, "compiler/syntax/locals/ResolvedLocalLiteralComparisonSources.w", "resolved_local_literal_comparison_sources"),
      physical(245, "compiler/syntax/locals/ResolvedLocalLiteralComparisons.w", "resolved_local_literal_comparisons"),
      physical(246, "compiler/syntax/loops/ResolvedLocalLoopForms.w", "resolved_local_loop_forms"),
      physical(247, "compiler/syntax/loops/ResolvedLocalLoopKinds.w", "resolved_local_loop_kinds"),
      physical(248, "compiler/syntax/loops/ResolvedLocalLoopOperands.w", "resolved_local_loop_operands"),
      physical(249, "compiler/syntax/assertions/ResolvedLocalPairAssertions.w", "resolved_local_pair_assertions"),
      physical(250, "compiler/syntax/returns/ResolvedLocalReturns.w", "resolved_local_returns"),
      physical(251, "compiler/syntax/updates/ResolvedLocalUpdates.w", "resolved_local_updates"),
      physical(252, "compiler/syntax/locals/ResolvedLongOperations.w", "resolved_long_operations"),
      physical(253, "compiler/syntax/returns/ResolvedReturnCallKinds.w", "resolved_return_call_kinds"),
      physical(254, "compiler/ir/ResolvedStatements.w", "resolved_statements"),
      physical(260, "compiler/resolution/returns/ReturnOpcodeKinds.w", "return_opcode_kinds"),
      physical(274, "compiler/ir/StatementKinds.w", "statement_kinds"),
      physical(278, "compiler/ir/StorageOpcodes.w", "storage_opcodes"),
      physical(285, "compiler/syntax/calls/TwoArgumentCallKinds.w", "two_argument_call_kinds"),
      physical(286, "compiler/ir/TypeCodes.w", "type_codes"),
      physical(287, "compiler/ir/TypeKinds.w", "type_kinds"),
      physical(290, "compiler/syntax/calls/VoidCallKinds.w", "void_call_kinds"),
      physical(294, "compiler/syntax/calls/VoidCallSourceKinds.w", "void_call_source_kinds"),
      physical(302, "compiler/resolution/returns/WideReturnSources.w", "wide_return_sources"));

  private static PhysicalModule physical(int owner, String path, String localName) {
    return new PhysicalModule(owner, path, "wheeler.compiler." + localName);
  }

  private NativeCompilerArchiveClosureProgram() {}

  private static String physicalOwnerRows() {
    StringBuilder rows = new StringBuilder();
    for (int index = 0; index < PHYSICAL_MODULES.size(); index++) {
      rows.append("set(physicalOwners, ").append(index).append(", ")
          .append(PHYSICAL_MODULES.get(index).owner()).append(");\n");
    }
    return rows.toString();
  }

  static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.archive_module_sources"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.callable_identities"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_callable_bodies"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_body_archive"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.counted_constant_executor"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_constant_values"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.module_callables"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.module_symbols"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.package_target"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.product_root_source"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.plan"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.schedule"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.scalar_module_identities"));
    sources.put("ArchiveClosureExample.w", """
        module example.archive_closure;

        import wheeler.compiler.closure.archive_module_sources;
        import wheeler.compiler.closure.archive_sources;
        import wheeler.compiler.closure.callable_identities;
        import wheeler.compiler.closure.compiled_body_archive;
        import wheeler.compiler.closure.compiled_callable_bodies;
        import wheeler.compiler.closure.counted_constant_executor;
        import wheeler.compiler.closure.imported_constant_values;
        import wheeler.compiler.closure.module_callables;
        import wheeler.compiler.closure.module_manifest;
        import wheeler.compiler.closure.module_symbols;
        import wheeler.compiler.closure.package_target;
        import wheeler.compiler.closure.plan;
        import wheeler.compiler.closure.product_root_source;
        import wheeler.compiler.closure.scalar_module_identities;
        import wheeler.compiler.closure.schedule;
        import wheeler.compiler.closure.symbol_identities;

        classical class ArchiveClosureExample {
          private const long MAX_ARCHIVE_BYTES = 16777216;
          private const long MAX_EXTERNALS = 64;
          private const long MAX_IMPORTS = 3072;
          private const long MAX_MANIFEST_BYTES = 262144;
          private const long MAX_MODULES = 512;
          private const long MAX_SYMBOLS = 16384;

          state long moduleCount = 0;
          state long importCount = 0;
          state long archiveEntryCount = 0;
          state long rootEntry = 0;
          state long rootDataStart = 0;
          state long rootDataLength = 0;
          state long rootOrder = 0;
          state long rootExecutable = 0;
          state long executableCount = 0;
          state long peakActiveSources = 0;
          state long rootGeneration = 0;
          state long compilerTarget = -1;
          state long symbolCount = 0;
          state long resolvedSymbolCount = 0;
          state long rootLocalSymbols = 0;
          state long rootImportedSymbols = 0;
          state long maxImportedSymbols = 0;
          state long symbolGeneration = 0;
          state long callableCount = 0;
          state long callableParameterCount = 0;
          state long borrowedParameterCount = 0;
          state long mutableParameterCount = 0;
          state long resultSlotCallableCount = 0;
          state long rootLocalCallables = 0;
          state long rootImportedCallables = 0;
          state long maxImportedCallables = 0;
          state long callableGeneration = 0;
          state long firstCallableSignatureLength = 0;
          state long firstCallableBodyLength = 0;
          state long firstCallableResultTypeLength = 0;
          state long lastCallableParameterCount = 0;
          state long lastCallableEffects = 0;
          state long firstCallableIdentityPrefix = 0;
          state long lastCallableIdentityPrefix = 0;
          state long callableIdentitiesPublished = 0;
          state long invalidCallableIdentityRejected = 0;
          state long compiledCallableBodyLength = 0;
          state long compiledCallableBodyIdentityPrefix = 0;
          state long compiledCallableModuleLength = 0;
          state long compiledCallableModuleIdentityPrefix = 0;
          state long compiledCallableFunctionCount = 0;
          state long compiledCallableMaxLocalCount = 0;
          state long physicalModuleProductLength = 0;
          state long physicalModuleProductFunctions = 0;
          state long physicalModuleProductCount = 0;
          state long physicalModuleOwner = -1;
          state long packageIdentityPrefix = 0;
          state long firstSymbolIdentityPrefix = 0;
          state long lastSymbolIdentityPrefix = 0;
          state long firstModuleIdentityPrefix = 0;
          state long lastModuleIdentityPrefix = 0;
          state long moduleIdentitiesPublished = 0;
          state long lastSymbolValue = 0;
          state long lastSymbolResolved = 0;
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            long archiveLength = source[0]
              + source[1] * 256
              + source[2] * 65536
              + source[3] * 16777216;
            assert(archiveLength < MAX_ARCHIVE_BYTES + 1);
            long manifestLength = bufferLength(source) - archiveLength - 4;
            assert(0 < manifestLength);
            assert(manifestLength < MAX_MANIFEST_BYTES + 1);
            region inputArena = new region(/* bytes= */ 17039360, /* allocations= */ 2);
            bytes archive = allocateBytes(inputArena, archiveLength);
            bytes manifest = allocateBytes(inputArena, manifestLength);
            long cursor = 0;
            while (cursor < archiveLength) limit MAX_ARCHIVE_BYTES {
              setByte(archive, cursor, source[cursor + 4]);
              cursor += 1;
            }

            cursor = 0;
            while (cursor < manifestLength) limit MAX_MANIFEST_BYTES {
              setByte(manifest, cursor, source[archiveLength + cursor + 4]);
              cursor += 1;
            }

            region products = new region(/* bytes= */ 16793600, /* allocations= */ 5);
            bytes bodyArchive = allocateBytes(products, /* length= */ 16777216);
            words bodyModulePublished = allocate(products, /* length= */ 512);
            words bodyModuleRanks = allocate(products, /* length= */ 512);
            words bodyStarts = allocate(products, /* length= */ 512);
            words bodyLengths = allocate(products, /* length= */ 512);
            region columns = new region(/* bytes= */ 4126760, /* allocations= */ 74);
            words archivePathStarts = allocate(columns, MAX_MODULES);
            words archivePathLengths = allocate(columns, MAX_MODULES);
            words archiveDataStarts = allocate(columns, MAX_MODULES);
            words archiveDataLengths = allocate(columns, MAX_MODULES);
            words externalStarts = allocate(columns, MAX_EXTERNALS);
            words externalLengths = allocate(columns, MAX_EXTERNALS);
            words moduleStarts = allocate(columns, MAX_MODULES);
            words moduleLengths = allocate(columns, MAX_MODULES);
            words sourceStarts = allocate(columns, MAX_MODULES);
            words sourceLengths = allocate(columns, MAX_MODULES);
            words identityStarts = allocate(columns, MAX_MODULES);
            words edgeOwners = allocate(columns, MAX_IMPORTS);
            words edgeStarts = allocate(columns, MAX_IMPORTS);
            words edgeLengths = allocate(columns, MAX_IMPORTS);
            words edgeTargets = allocate(columns, MAX_IMPORTS);
            words moduleEntries = allocate(columns, MAX_MODULES);
            words archiveSourceStarts = allocate(columns, MAX_MODULES);
            words archiveSourceLengths = allocate(columns, MAX_MODULES);
            words firstImports = allocate(columns, MAX_MODULES);
            words directImportCounts = allocate(columns, MAX_MODULES);
            words importRanks = allocate(columns, MAX_IMPORTS);
            words leafFirstOrder = allocate(columns, MAX_MODULES);
            words executableOwners = allocate(columns, MAX_MODULES);
            words moduleSlots = allocate(columns, MAX_MODULES);
            words moduleGenerations = allocate(columns, MAX_MODULES);
            words moduleFirstSymbols = allocate(columns, MAX_MODULES);
            words moduleSymbolCounts = allocate(columns, MAX_MODULES);
            words moduleProductNameStarts = allocate(columns, MAX_MODULES);
            words moduleProductNameLengths = allocate(columns, MAX_MODULES);
            words moduleImportedSymbolCounts = allocate(columns, MAX_MODULES);
            words edgeSymbolCounts = allocate(columns, MAX_IMPORTS);
            words symbolOwners = allocate(columns, MAX_SYMBOLS);
            words symbolStarts = allocate(columns, MAX_SYMBOLS);
            words symbolLengths = allocate(columns, MAX_SYMBOLS);
            words symbolKinds = allocate(columns, MAX_SYMBOLS);
            words symbolVisibilities = allocate(columns, MAX_SYMBOLS);
            words symbolTypes = allocate(columns, MAX_SYMBOLS);
            words symbolValues = allocate(columns, MAX_SYMBOLS);
            words symbolResolved = allocate(columns, MAX_SYMBOLS);
            words moduleFirstCallables = allocate(columns, MAX_MODULES);
            words moduleCallableCounts = allocate(columns, MAX_MODULES);
            words moduleImportedCallableCounts = allocate(columns, MAX_MODULES);
            words edgeCallableCounts = allocate(columns, MAX_IMPORTS);
            words callableOwners = allocate(columns, /* length= */ 4096);
            words callableVisibilities = allocate(columns, /* length= */ 4096);
            words callableNameStarts = allocate(columns, /* length= */ 4096);
            words callableNameLengths = allocate(columns, /* length= */ 4096);
            words callableSignatureStarts = allocate(columns, /* length= */ 4096);
            words callableSignatureLengths = allocate(columns, /* length= */ 4096);
            words callableBodyStarts = allocate(columns, /* length= */ 4096);
            words callableBodyLengths = allocate(columns, /* length= */ 4096);
            words callableParameterCounts = allocate(columns, /* length= */ 4096);
            words callableFirstParameters = allocate(columns, /* length= */ 4096);
            words callableResultTypeStarts = allocate(columns, /* length= */ 4096);
            words callableResultTypeLengths = allocate(columns, /* length= */ 4096);
            words callableEffects = allocate(columns, /* length= */ 4096);
            words callableResultSlotWidths = allocate(columns, /* length= */ 4096);
            words parameterTypeStarts = allocate(columns, MAX_SYMBOLS);
            words parameterTypeLengths = allocate(columns, MAX_SYMBOLS);
            words parameterModes = allocate(columns, MAX_SYMBOLS);
            words physicalAggregates = allocate(columns, /* length= */ 832);
            words physicalCalls = allocate(columns, /* length= */ 1024);
            words physicalResultTypes = allocate(columns, /* length= */ 4096);
            words physicalOwners = allocate(columns, /* length= */ 64);
            words physicalImportedRows = allocate(columns, /* length= */ 114689);
            bytes physicalProductSource = allocateBytes(columns, /* length= */ 32768);
            PHYSICAL_MODULE_OWNERS
            bytes packageIdentity = allocateBytes(columns, /* length= */ 32);
            bytes symbolIdentities = allocateBytes(columns, MAX_SYMBOLS * 32);
            bytes moduleIdentities = allocateBytes(columns, MAX_MODULES * 32);
            bytes callableIdentities = allocateBytes(columns, /* length= */ 131072);
            bytes rejectedCallableIdentities = allocateBytes(columns, /* length= */ 131072);
            bytes compiledCallableArtifact = allocateBytes(columns, /* length= */ 32768);
            bytes compiledCallableIdentity = allocateBytes(columns, /* length= */ 32);
            bytes expected = allocateBytes(columns, /* length= */ 256);
            ArchiveSourceIndexResult indexed = indexArchiveSources(
              archive,
              archivePathStarts,
              archivePathLengths,
              archiveDataStarts,
              archiveDataLengths
            );
            match (indexed) {
              case ArchiveSourceIndexResult.Value(ArchiveSourceIndex archiveIndex) {
                BootstrapModuleManifestPlan manifestPlan = parseBootstrapModuleManifest(
                  manifest,
                  expected,
                  externalStarts,
                  externalLengths,
                  moduleStarts,
                  moduleLengths,
                  sourceStarts,
                  sourceLengths,
                  identityStarts,
                  edgeOwners,
                  edgeStarts,
                  edgeLengths,
                  edgeTargets
                );
                long selectedCompilerTarget = -1;
                CompilerToolTargetResult selectedTarget = validateCompilerToolTarget(
                  archive,
                  archiveIndex,
                  manifest,
                  manifestPlan,
                  moduleStarts,
                  moduleLengths,
                  sourceStarts,
                  sourceLengths
                );
                match (selectedTarget) {
                  case CompilerToolTargetResult.Value(CompilerToolTarget target) {
                    selectedCompilerTarget = target.target;
                  }
                  case CompilerToolTargetResult.Error(long targetOffset) {
                    assert(targetOffset < 0);
                  }
                }
                assert(-1 < selectedCompilerTarget);
                ArchiveModuleSourcePlan plan = joinArchiveModuleSources(
                  archive,
                  archiveIndex,
                  archivePathStarts,
                  archivePathLengths,
                  archiveDataStarts,
                  archiveDataLengths,
                  manifest,
                  manifestPlan,
                  sourceStarts,
                  sourceLengths,
                  identityStarts,
                  moduleEntries
                );
                CountedClosurePlan closure = planClosureStructure(
                  archive,
                  manifest,
                  manifestPlan,
                  edgeOwners,
                  edgeTargets,
                  moduleEntries,
                  archiveDataStarts,
                  archiveDataLengths,
                  archiveSourceStarts,
                  archiveSourceLengths,
                  firstImports,
                  directImportCounts,
                  importRanks,
                  leafFirstOrder
                );
                CountedModuleSymbolPlan symbols = indexCountedModuleSymbols(
                  archive,
                  manifest,
                  closure,
                  edgeTargets,
                  firstImports,
                  directImportCounts,
                  importRanks,
                  leafFirstOrder,
                  archiveSourceStarts,
                  archiveSourceLengths,
                  moduleFirstSymbols,
                  moduleSymbolCounts,
                  moduleProductNameStarts,
                  moduleProductNameLengths,
                  moduleImportedSymbolCounts,
                  edgeSymbolCounts,
                  symbolOwners,
                  symbolStarts,
                  symbolLengths,
                  symbolKinds,
                  symbolVisibilities,
                  symbolTypes,
                  symbolValues,
                  symbolResolved
                );
                CountedModuleCallablePlan callables = indexCountedModuleCallables(
                  archive,
                  manifest,
                  closure,
                  edgeTargets,
                  firstImports,
                  directImportCounts,
                  leafFirstOrder,
                  archiveSourceStarts,
                  archiveSourceLengths,
                  moduleFirstCallables,
                  moduleCallableCounts,
                  moduleImportedCallableCounts,
                  edgeCallableCounts,
                  callableOwners,
                  callableVisibilities,
                  callableNameStarts,
                  callableNameLengths,
                  callableSignatureStarts,
                  callableSignatureLengths,
                  callableBodyStarts,
                  callableBodyLengths,
                  callableParameterCounts,
                  callableFirstParameters,
                  callableResultTypeStarts,
                  callableResultTypeLengths,
                  callableEffects,
                  callableResultSlotWidths,
                  parameterTypeStarts,
                  parameterTypeLengths,
                  parameterModes
                );
                publishCountedSymbolIdentities(
                  archive,
                  manifest,
                  closure,
                  symbols.symbolCount,
                  identityStarts,
                  symbolOwners,
                  symbolStarts,
                  symbolLengths,
                  symbolKinds,
                  symbolVisibilities,
                  symbolTypes,
                  packageIdentity,
                  symbolIdentities
                );
                boolean callableIdentityPublication = publishCallableIdentities(
                  archive,
                  manifest,
                  closure.moduleCount,
                  callables.callableCount,
                  identityStarts,
                  callableOwners,
                  callableVisibilities,
                  callableNameStarts,
                  callableNameLengths,
                  callableResultTypeStarts,
                  callableResultTypeLengths,
                  callableEffects,
                  callableFirstParameters,
                  callableParameterCounts,
                  parameterTypeStarts,
                  parameterTypeLengths,
                  parameterModes,
                  packageIdentity,
                  callableIdentities
                );
                if (closure.moduleCount == 3) {
                  if (0 < callables.parameterCount) {
                    long savedMode = parameterModes[0];
                    set(parameterModes, 0, 3);
                    boolean invalidCallableIdentity = publishCallableIdentities(
                      archive,
                      manifest,
                      closure.moduleCount,
                      callables.callableCount,
                      identityStarts,
                      callableOwners,
                      callableVisibilities,
                      callableNameStarts,
                      callableNameLengths,
                      callableResultTypeStarts,
                      callableResultTypeLengths,
                      callableEffects,
                      callableFirstParameters,
                      callableParameterCounts,
                      parameterTypeStarts,
                      parameterTypeLengths,
                      parameterModes,
                      packageIdentity,
                      rejectedCallableIdentities
                    );
                    set(parameterModes, 0, savedMode);
                    if (invalidCallableIdentity == false) {
                      if (rejectedCallableIdentities[0] == 0) {
                        invalidCallableIdentityRejected = 1;
                      }
                    }
                  }
                }
                if (closure.moduleCount == 3) {
                  if (callables.callableCount == 6) {
                    CompiledCallableBody compiledCallable = compileCallableBodyProduct(
                      archive,
                      callableSignatureStarts[0],
                      callableSignatureLengths[0],
                      callableBodyStarts[0],
                      callableBodyLengths[0],
                      compiledCallableArtifact,
                      compiledCallableIdentity
                    );
                    compiledCallableBodyLength = compiledCallable.length;
                    compiledCallableBodyIdentityPrefix = compiledCallableIdentity[0]
                        * 16777216
                      + compiledCallableIdentity[1] * 65536
                      + compiledCallableIdentity[2] * 256
                      + compiledCallableIdentity[3];
                    CompiledCallableBody compiledModule = compileCallableModuleProduct(
                      archive,
                      /* owner= */ 1,
                      /* firstCallable= */ 1,
                      /* callableCount= */ 3,
                      callableOwners,
                      callableSignatureStarts,
                      callableSignatureLengths,
                      callableBodyStarts,
                      callableBodyLengths,
                      compiledCallableArtifact,
                      compiledCallableIdentity
                    );
                    compiledCallableModuleLength = compiledModule.length;
                    compiledCallableFunctionCount = compiledModule.functionCount;
                    compiledCallableMaxLocalCount = compiledModule.maxLocalCount;
                    compiledCallableModuleIdentityPrefix = compiledCallableIdentity[0]
                        * 16777216
                      + compiledCallableIdentity[1] * 65536
                      + compiledCallableIdentity[2] * 256
                      + compiledCallableIdentity[3];
                  }
                }
                ScalarModuleIdentityPlan scalarIdentities = publishScalarModuleIdentities(
                  archive,
                  manifest,
                  closure,
                  leafFirstOrder,
                  identityStarts,
                  moduleProductNameStarts,
                  moduleProductNameLengths,
                  firstImports,
                  directImportCounts,
                  edgeTargets,
                  moduleFirstSymbols,
                  moduleSymbolCounts,
                  packageIdentity,
                  symbolIdentities,
                  symbolValues,
                  symbolResolved,
                  moduleIdentities
                );
                if (closure.moduleCount == 304) {
                  long physicalProduct = 0;
                  while (physicalProduct < PHYSICAL_MODULE_COUNT) limit 64 {
                    long physicalOwner = physicalOwners[physicalProduct];
                    physicalModuleOwner = physicalOwner;
                    long physicalImportedCount = writeDirectImportedValues(
                      firstImports[physicalOwner],
                      directImportCounts[physicalOwner],
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
                      physicalImportedRows
                    );
                    assert(-1 < physicalImportedCount);
                    long physicalSourceLength = writeProductModuleSource(
                      archive,
                      archiveSourceStarts[physicalOwner],
                      archiveSourceLengths[physicalOwner],
                      moduleFirstSymbols[physicalOwner],
                      moduleSymbolCounts[physicalOwner],
                      symbolStarts,
                      symbolLengths,
                      physicalImportedRows,
                      physicalProductSource
                    );
                    assert(0 < physicalSourceLength);
                    CompiledCallableBody physicalModule = compileSourceModuleProductWithImports(
                      physicalProductSource,
                      /* sourceStart= */ 0,
                      physicalSourceLength,
                      /* aggregateCount= */ 0,
                      physicalAggregates,
                      /* callCount= */ 0,
                      physicalCalls,
                      callableEffects,
                      callableFirstParameters,
                      callableParameterCounts,
                      physicalResultTypes,
                      parameterTypeStarts,
                      parameterModes,
                      compiledCallableArtifact,
                      compiledCallableIdentity
                    );
                    CompiledBodyArchivePlan retained = appendCompiledBodyArtifact(
                      compiledCallableArtifact,
                      physicalModule.length,
                      physicalOwner,
                      physicalModuleProductCount,
                      physicalModuleProductLength,
                      bodyModulePublished,
                      bodyModuleRanks,
                      bodyStarts,
                      bodyLengths,
                      bodyArchive
                    );
                    physicalModuleProductLength = retained.archiveBytes;
                    physicalModuleProductCount = retained.artifactCount;
                    physicalModuleProductFunctions += physicalModule.functionCount;
                    physicalProduct += 1;
                  }
                }
                classifyClosureExecutableOwners(
                  archive,
                  manifest,
                  closure,
                  moduleStarts,
                  moduleLengths,
                  archiveSourceStarts,
                  archiveSourceLengths,
                  executableOwners
                );
                CountedConstantExecution constantExecution = compileCountedConstantRoot(
                  archive,
                  closure.rootModule,
                  executableOwners[closure.rootModule],
                  archiveSourceStarts,
                  archiveSourceLengths,
                  firstImports,
                  directImportCounts,
                  edgeTargets,
                  edgeSymbolCounts,
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
                  output
                );
                ClosureSourceSchedule schedule = stageClosureSources(
                  archive,
                  manifest,
                  closure,
                  leafFirstOrder,
                  archiveSourceStarts,
                  archiveSourceLengths,
                  moduleSlots,
                  moduleGenerations
                );
                long selectedRootEntry = moduleEntries[plan.rootModule];
                long executableModule = 0;
                long parsedExecutables = 0;
                long largestImportedSymbols = 0;
                while (executableModule < closure.moduleCount) limit MAX_MODULES {
                  parsedExecutables += executableOwners[executableModule];
                  if (
                    largestImportedSymbols < moduleImportedSymbolCounts[executableModule]
                  ) {
                    largestImportedSymbols = moduleImportedSymbolCounts[executableModule];
                  }

                  executableModule += 1;
                }
                long largestImportedCallables = 0;
                long callableModule = 0;
                while (callableModule < closure.moduleCount) limit MAX_MODULES {
                  if (
                    largestImportedCallables
                      < moduleImportedCallableCounts[callableModule]
                  ) {
                    largestImportedCallables = moduleImportedCallableCounts[callableModule];
                  }

                  callableModule += 1;
                }
                long parsedResolvedSymbols = 0;
                long resolvedSymbol = 0;
                while (resolvedSymbol < symbols.symbolCount) limit MAX_SYMBOLS {
                  parsedResolvedSymbols += symbolResolved[resolvedSymbol];
                  resolvedSymbol += 1;
                }

                long selectedRootOrder = 0;
                while (
                  leafFirstOrder[selectedRootOrder] != closure.rootModule
                ) limit MAX_MODULES {
                  selectedRootOrder += 1;
                }
                moduleCount = plan.moduleCount;
                importCount = manifestPlan.importCount;
                archiveEntryCount = plan.archiveEntryCount;
                rootEntry = selectedRootEntry;
                rootDataStart = archiveDataStarts[selectedRootEntry];
                rootDataLength = archiveDataLengths[selectedRootEntry];
                rootOrder = selectedRootOrder;
                rootExecutable = executableOwners[closure.rootModule];
                executableCount = parsedExecutables;
                peakActiveSources = schedule.peakActiveSources;
                rootGeneration = moduleGenerations[closure.rootModule];
                compilerTarget = selectedCompilerTarget;
                symbolCount = symbols.symbolCount;
                resolvedSymbolCount = parsedResolvedSymbols;
                rootLocalSymbols = moduleSymbolCounts[closure.rootModule];
                rootImportedSymbols = moduleImportedSymbolCounts[closure.rootModule];
                maxImportedSymbols = largestImportedSymbols;
                symbolGeneration = symbols.finalGeneration;
                callableCount = callables.callableCount;
                callableParameterCount = callables.parameterCount;
                long parameter = 0;
                while (parameter < callables.parameterCount) limit MAX_SYMBOLS {
                  if (0 < parameterModes[parameter]) {
                    borrowedParameterCount += 1;
                  }
                  if (parameterModes[parameter] == 2) {
                    mutableParameterCount += 1;
                  }
                  parameter += 1;
                }
                long slotCallable = 0;
                while (slotCallable < callables.callableCount) limit 4096 {
                  if (callableResultSlotWidths[slotCallable] == 2) {
                    resultSlotCallableCount += 1;
                  }
                  slotCallable += 1;
                }
                rootLocalCallables = moduleCallableCounts[closure.rootModule];
                rootImportedCallables = moduleImportedCallableCounts[closure.rootModule];
                maxImportedCallables = largestImportedCallables;
                callableGeneration = callables.finalGeneration;
                if (0 < callables.callableCount) {
                  firstCallableSignatureLength = callableSignatureLengths[0];
                  firstCallableBodyLength = callableBodyLengths[0];
                  firstCallableResultTypeLength = callableResultTypeLengths[0];
                  lastCallableParameterCount = callableParameterCounts[
                    callables.callableCount - 1
                  ];
                  lastCallableEffects = callableEffects[callables.callableCount - 1];
                }
                packageIdentityPrefix = packageIdentity[0] * 16777216
                  + packageIdentity[1] * 65536
                  + packageIdentity[2] * 256
                  + packageIdentity[3];
                if (0 < symbols.symbolCount) {
                  firstSymbolIdentityPrefix = symbolIdentities[0] * 16777216
                    + symbolIdentities[1] * 65536
                    + symbolIdentities[2] * 256
                    + symbolIdentities[3];
                  long finalIdentity = (symbols.symbolCount - 1) * 32;
                  lastSymbolIdentityPrefix = symbolIdentities[finalIdentity] * 16777216
                    + symbolIdentities[finalIdentity + 1] * 65536
                    + symbolIdentities[finalIdentity + 2] * 256
                    + symbolIdentities[finalIdentity + 3];
                  lastSymbolValue = symbolValues[symbols.symbolCount - 1];
                  lastSymbolResolved = symbolResolved[symbols.symbolCount - 1];
                }
                if (callableIdentityPublication) {
                  if (0 < callables.callableCount) {
                    long finalCallableIdentity = (callables.callableCount - 1) * 32;
                    firstCallableIdentityPrefix = callableIdentities[0] * 16777216
                      + callableIdentities[1] * 65536
                      + callableIdentities[2] * 256
                      + callableIdentities[3];
                    lastCallableIdentityPrefix = callableIdentities[finalCallableIdentity]
                        * 16777216
                      + callableIdentities[finalCallableIdentity + 1] * 65536
                      + callableIdentities[finalCallableIdentity + 2] * 256
                      + callableIdentities[finalCallableIdentity + 3];
                  }
                  callableIdentitiesPublished = 1;
                }
                if (scalarIdentities.valid) {
                  long rootModuleIdentity = closure.rootModule * 32;
                  firstModuleIdentityPrefix = moduleIdentities[0] * 16777216
                    + moduleIdentities[1] * 65536
                    + moduleIdentities[2] * 256
                    + moduleIdentities[3];
                  lastModuleIdentityPrefix = moduleIdentities[rootModuleIdentity] * 16777216
                    + moduleIdentities[rootModuleIdentity + 1] * 65536
                    + moduleIdentities[rootModuleIdentity + 2] * 256
                    + moduleIdentities[rootModuleIdentity + 3];
                  moduleIdentitiesPublished = 1;
                }
                published = 1;
                if (constantExecution.attempted) {
                  setOutputLength(output, constantExecution.length);
                } else {
                  if (0 < compiledCallableModuleLength) {
                    long artifactByte = 0;
                    while (
                      artifactByte < compiledCallableModuleLength
                    ) limit 32768 {
                      setByte(output, artifactByte, compiledCallableArtifact[artifactByte]);
                      artifactByte += 1;
                    }
                    setOutputLength(output, compiledCallableModuleLength);
                  } else {
                    if (1 < bufferLength(output)) {
                      long physicalByte = 0;
                      while (physicalByte < physicalModuleProductLength) limit 196608 {
                        setByte(output, physicalByte, bodyArchive[physicalByte]);
                        physicalByte += 1;
                      }
                      setOutputLength(output, physicalModuleProductLength);
                    } else {
                      setByte(output, 0, 1);
                    }
                  }
                }
              }
              case ArchiveSourceIndexResult.Error(long offset) {
                assert(offset < 0);
              }
            }
            drop(expected);
            drop(compiledCallableIdentity);
            drop(compiledCallableArtifact);
            drop(rejectedCallableIdentities);
            drop(callableIdentities);
            drop(moduleIdentities);
            drop(symbolIdentities);
            drop(packageIdentity);
            drop(physicalProductSource);
            drop(physicalImportedRows);
            drop(physicalOwners);
            drop(physicalResultTypes);
            drop(physicalCalls);
            drop(physicalAggregates);
            drop(parameterModes);
            drop(parameterTypeLengths);
            drop(parameterTypeStarts);
            drop(callableResultSlotWidths);
            drop(callableEffects);
            drop(callableResultTypeLengths);
            drop(callableResultTypeStarts);
            drop(callableFirstParameters);
            drop(callableParameterCounts);
            drop(callableBodyLengths);
            drop(callableBodyStarts);
            drop(callableSignatureLengths);
            drop(callableSignatureStarts);
            drop(callableNameLengths);
            drop(callableNameStarts);
            drop(callableVisibilities);
            drop(callableOwners);
            drop(edgeCallableCounts);
            drop(moduleImportedCallableCounts);
            drop(moduleCallableCounts);
            drop(moduleFirstCallables);
            drop(symbolResolved);
            drop(symbolValues);
            drop(symbolTypes);
            drop(symbolVisibilities);
            drop(symbolKinds);
            drop(symbolLengths);
            drop(symbolStarts);
            drop(symbolOwners);
            drop(edgeSymbolCounts);
            drop(moduleImportedSymbolCounts);
            drop(moduleProductNameLengths);
            drop(moduleProductNameStarts);
            drop(moduleSymbolCounts);
            drop(moduleFirstSymbols);
            drop(moduleGenerations);
            drop(moduleSlots);
            drop(executableOwners);
            drop(leafFirstOrder);
            drop(importRanks);
            drop(directImportCounts);
            drop(firstImports);
            drop(archiveSourceLengths);
            drop(archiveSourceStarts);
            drop(moduleEntries);
            drop(edgeTargets);
            drop(edgeLengths);
            drop(edgeStarts);
            drop(edgeOwners);
            drop(identityStarts);
            drop(sourceLengths);
            drop(sourceStarts);
            drop(moduleLengths);
            drop(moduleStarts);
            drop(externalLengths);
            drop(externalStarts);
            drop(archiveDataLengths);
            drop(archiveDataStarts);
            drop(archivePathLengths);
            drop(archivePathStarts);
            drop(columns);
            drop(manifest);
            drop(archive);
            drop(inputArena);
            drop(bodyLengths);
            drop(bodyStarts);
            drop(bodyModuleRanks);
            drop(bodyModulePublished);
            drop(bodyArchive);
            drop(products);
          }
        }
        """
            .replace("PHYSICAL_MODULE_OWNERS", physicalOwnerRows())
            .replace("PHYSICAL_MODULE_COUNT", Integer.toString(PHYSICAL_MODULES.size())));
    return new WheelerCompiler().compileModuleFiles(sources, "example.archive_closure");
  }

}
