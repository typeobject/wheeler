package com.typeobject.wheeler.examples;

import java.util.List;

/** Owns the physical source-product compilation transaction used by closure evidence. */
final class NativeCompilerPhysicalProductSource {
  private static final List<String> DIRECT_SOURCE_MODULES = List.of(
      "wheeler.compiler.closure.aggregate_source_projection",
      "wheeler.compiler.closure.manifest_syntax",
      "wheeler.compiler.closure.reversible_token_coordinates",
      "wheeler.compiler.core_parsing",
      "wheeler.compiler.four_argument_calls",
      "wheeler.compiler.literal_comparison_operations",
      "wheeler.compiler.local_type_encoding",
      "wheeler.compiler.resolved_local_copy_kinds",
      "wheeler.compiler.resolved_local_equality_kinds",
      "wheeler.compiler.resolved_local_inequality_kinds",
      "wheeler.compiler.resolved_local_less_than_kinds",
      "wheeler.compiler.resolved_local_literal_comparisons",
      "wheeler.compiler.resolved_local_loop_operands",
      "wheeler.compiler.result_slot_verifier",
      "wheeler.compiler.type_kinds",
      "wheeler.compiler.wide_return_sources");

  private NativeCompilerPhysicalProductSource() {}

  private static String directSourceRouting() {
    StringBuilder routing = new StringBuilder();
    for (String moduleName : DIRECT_SOURCE_MODULES) {
      int owner = NativeCompilerArchiveClosureProgram.physicalOwner(
          NativeCompilerArchiveClosureProgram.physicalModule(moduleName));
      routing.append("if (physicalOwner == ").append(owner).append(") {\n")
          .append("  directSourceModule = true;\n")
          .append("}\n");
    }
    return routing.toString();
  }

  static String compilation() {
    return """
        if (closure.moduleCount == PHYSICAL_CLOSURE_MODULE_COUNT) {
          long physicalProduct = 0;
          while (physicalProduct < PHYSICAL_MODULE_COUNT) limit 128 {
            long physicalOwner = physicalOwners[physicalProduct];
            physicalModuleOwner = physicalOwner;
            boolean directSourceModule = moduleCallableCounts[physicalOwner] == 0;
            DIRECT_SOURCE_MODULE_ROUTING
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
            if (directSourceModule) {
              physicalImportedCount = appendDirectLocalValues(
                physicalOwner,
                physicalImportedCount,
                moduleFirstSymbols,
                moduleSymbolCounts,
                moduleProductNameStarts,
                moduleProductNameLengths,
                symbolStarts,
                symbolLengths,
                symbolTypes,
                symbolValues,
                symbolResolved,
                physicalImportedRows
              );
            }
            long physicalImportedNameBytes = writeDirectImportedValueNames(
              archive,
              physicalImportedCount,
              physicalImportedRows,
              callableProductNameBytes,
              physicalTargetRows,
              callableProductNames
            );
            if (0 < physicalImportedCount) {
              assert(0 < physicalImportedNameBytes);
            }
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
            long physicalCallCount = 0;
            if (PHYSICAL_COMPARABLE_COUNT < physicalProduct + 1) {
              long physicalDependencyCount = packCallableDependencyProducts(
                closure.moduleCount,
                closure.externalCount,
                physicalOwner,
                firstImports,
                directImportCounts,
                edgeTargets,
                moduleFirstCallables,
                moduleCallableCounts,
                callableVisibilities,
                externalFirstCallables,
                externalCallableCounts,
                externalCallableVisibilities,
                physicalDependencyRows
              );
              physicalCallCount = resolveProductSourceCallProducts(
                physicalProductSource,
                /* sourceStart= */ 0,
                physicalSourceLength,
                callableProductNames,
                moduleFirstCallables[physicalOwner],
                moduleCallableCounts[physicalOwner],
                callableProductNameStarts,
                callableNameLengths,
                callableParameterCounts,
                physicalDependencyCount,
                physicalDependencyRows,
                physicalCalls
              );
              assert(0 < physicalCallCount);
              long physicalCall = 0;
              while (physicalCall < physicalCallCount) limit 256 {
                long physicalTarget = physicalCalls[768 + physicalCall];
                assert(primitiveCallables[physicalTarget] == 1);
                physicalCall += 1;
              }
            }
            CompiledCallableBody physicalModule = new CompiledCallableBody(0, 0, 0, 0);
            if (directSourceModule) {
              SourceProductArtifactPlan directArtifact = compileStructuredArchiveModuleProduct(
                archive,
                archiveSourceStarts[physicalOwner],
                archiveSourceLengths[physicalOwner],
                physicalOwner,
                moduleFirstCallables[physicalOwner],
                moduleCallableCounts[physicalOwner],
                callableBodyStarts,
                callableBodyLengths,
                physicalImportedCount,
                physicalImportedRows,
                callableProductNames,
                physicalTargetRows,
                callableFirstParameters,
                callableParameterCounts,
                physicalResultTypes,
                callableEffects,
                physicalParameterTypes,
                parameterModes,
                callableProductNames,
                callableProductNameStarts,
                callableNameLengths,
                compiledCallableArtifact,
                compiledCallableIdentity
              );
              physicalModule = new CompiledCallableBody(
                directArtifact.length,
                directArtifact.codeStart,
                directArtifact.functionCount,
                directArtifact.maxLocalCount
              );
            } else {
              physicalModule = compileSourceModuleProductWithImports(
                physicalProductSource,
                /* sourceStart= */ 0,
                physicalSourceLength,
                /* aggregateCount= */ 0,
                physicalAggregates,
                physicalCallCount,
                physicalCalls,
                callableEffects,
                callableFirstParameters,
                callableParameterCounts,
                physicalResultTypes,
                physicalParameterTypes,
                parameterModes,
                compiledCallableArtifact,
                compiledCallableIdentity
              );
            }
            CompiledFunctionPlan physicalFunctions = indexCompiledFunctionProducts(
              compiledCallableArtifact,
              physicalModule.length,
              physicalFunctionRows,
              physicalInstructionRows
            );
            long physicalLocalFunctionCount = moduleCallableCounts[physicalOwner];
            if (physicalProduct + 1 == PHYSICAL_COMPARABLE_COUNT) {
              assert(physicalFunctions.functionCount == physicalLocalFunctionCount + 1);
              physicalLocalFunctionCount = physicalFunctions.functionCount;
            }
            if (0 < physicalLocalFunctionCount) {
              RetainedFunctionProduct physicalRetained = retainLocalFunctionProduct(
                physicalLocalFunctionCount,
                physicalFunctions.functionCount,
                physicalFunctions.instructionCount,
                physicalInstructionRows
              );
              physicalRetainedFunctionCount += physicalRetained.functionCount;
              physicalRetainedInstructionCount += physicalRetained.instructionCount;
            }
            if (PHYSICAL_COMPARABLE_COUNT < physicalProduct + 1) {
              long physicalFunction = 0;
              while (physicalFunction < physicalFunctions.functionCount) limit 64 {
                set(physicalFunctionOwners, physicalFunction, physicalOwner);
                set(physicalFunctionVisibilities, physicalFunction, 1);
                physicalFunction += 1;
              }
              long physicalStub = moduleCallableCounts[physicalOwner];
              long relocationTarget = 0;
              while (relocationTarget < callables.callableCount) limit 4096 {
                boolean physicalSelectedTarget = false;
                long physicalSelectedCall = 0;
                while (physicalSelectedCall < physicalCallCount) limit 256 {
                  if (physicalCalls[768 + physicalSelectedCall] == relocationTarget) {
                    physicalSelectedTarget = true;
                  }
                  physicalSelectedCall += 1;
                }
                if (physicalSelectedTarget) {
                  assert(physicalStub < physicalFunctions.functionCount);
                  set(
                    physicalFunctionOwners,
                    physicalStub,
                    callableOwners[relocationTarget]
                  );
                  set(
                    physicalFunctionVisibilities,
                    physicalStub,
                    callableVisibilities[relocationTarget]
                  );
                  set(physicalStubCallableRows, physicalStub, relocationTarget);
                  long physicalRelocationIdentityByte = 0;
                  while (physicalRelocationIdentityByte < 32) limit 32 {
                    setByte(
                      physicalFunctionIdentities,
                      physicalStub * 32 + physicalRelocationIdentityByte,
                      callableIdentities[
                        relocationTarget * 32 + physicalRelocationIdentityByte
                      ]
                    );
                    physicalRelocationIdentityByte += 1;
                  }
                  physicalStub += 1;
                }
                relocationTarget += 1;
              }
              long physicalRelocationCount = resolveImportedCallRelocations(
                compiledCallableArtifact,
                physicalFunctions.functionCount,
                physicalFunctions.instructionCount,
                physicalInstructionRows,
                physicalFunctionOwners,
                physicalFunctionVisibilities,
                physicalFunctionIdentities,
                physicalRelocationRows,
                physicalRelocationIdentities
              );
              assert(physicalRelocationCount == physicalCallCount);
              resolveImportedIdentityFunctionTargets(
                physicalRelocationCount,
                physicalRelocationIdentities,
                callables.callableCount,
                callableIdentities,
                callableHashSlots,
                callableHashFunctions,
                physicalTargetRows
              );
              long physicalResolvedTarget = 0;
              while (
                physicalResolvedTarget < physicalRelocationCount
              ) limit 4096 {
                long physicalStubTarget = physicalRelocationRows[
                  4096 + physicalResolvedTarget
                ];
                assert(
                  physicalTargetRows[physicalResolvedTarget]
                    == physicalStubCallableRows[physicalStubTarget]
                );
                long physicalRelocationFrame = physicalCallableRelocationCount
                  + physicalResolvedTarget;
                assert(physicalRelocationFrame < 2048);
                set(physicalRelocationRows, 2048 + physicalRelocationFrame, physicalProduct);
                set(
                  physicalRelocationRows,
                  6144 + physicalRelocationFrame,
                  physicalRelocationRows[physicalResolvedTarget]
                );
                set(
                  physicalRelocationRows,
                  10240 + physicalRelocationFrame,
                  physicalTargetRows[physicalResolvedTarget]
                );
                physicalResolvedTarget += 1;
              }
              physicalCallableRelocationCount += physicalRelocationCount;
              physicalResolvedCallableTargetCount += physicalRelocationCount;
            }
            CompiledBodyArchivePlan retained = appendCompiledBodyArtifact(
              compiledCallableArtifact,
              physicalModule.length,
              physicalOwner,
              physicalArchivedProductCount,
              physicalArchivedProductLength,
              bodyModulePublished,
              bodyModuleRanks,
              bodyStarts,
              bodyLengths,
              bodyArchive
            );
            physicalArchivedProductLength = retained.archiveBytes;
            physicalArchivedProductCount = retained.artifactCount;
            physicalRetainedProductLength = retained.archiveBytes;
            if (physicalProduct < PHYSICAL_COMPARABLE_COUNT) {
              physicalModuleProductLength = retained.archiveBytes;
              physicalModuleProductCount = retained.artifactCount;
              physicalModuleProductFunctions += physicalModule.functionCount;
            } else {
              physicalCallableProductCount += 1;
            }
            physicalProduct += 1;
          }
        }
        """
        .replace("DIRECT_SOURCE_MODULE_ROUTING", directSourceRouting());
  }

  static String publication() {
    return """
        if (1 < bufferLength(output)) {
          long physicalByte = 0;
          while (physicalByte < physicalRetainedProductLength) limit 16777216 {
            setByte(output, physicalByte, bodyArchive[physicalByte]);
            physicalByte += 1;
          }
          long physicalMetadata = physicalRetainedProductLength;
          long physicalArtifact = 0;
          while (physicalArtifact < PHYSICAL_MODULE_COUNT) limit 512 {
            long physicalArtifactOwner = physicalOwners[physicalArtifact];
            long physicalArtifactLength = bodyLengths[physicalArtifact];
            setByte(output, physicalMetadata, physicalArtifactOwner / 256);
            setByte(output, physicalMetadata + 1, physicalArtifactOwner % 256);
            setByte(output, physicalMetadata + 2, physicalArtifactLength / 65536);
            setByte(
              output,
              physicalMetadata + 3,
              physicalArtifactLength / 256 % 256
            );
            setByte(output, physicalMetadata + 4, physicalArtifactLength % 256);
            long physicalArtifactFunctionCount = moduleCallableCounts[
              physicalArtifactOwner
            ];
            if (physicalArtifact + 1 == PHYSICAL_COMPARABLE_COUNT) {
              physicalArtifactFunctionCount += 1;
            }
            setByte(output, physicalMetadata + 5, physicalArtifactFunctionCount);
            physicalMetadata += 6;
            physicalArtifact += 1;
          }
          long publishedRelocationFrame = 0;
          while (
            publishedRelocationFrame < physicalCallableRelocationCount
          ) limit 2048 {
            long physicalRelocationProduct = physicalRelocationRows[
              2048 + publishedRelocationFrame
            ];
            long physicalRelocationInstruction = physicalRelocationRows[
              6144 + publishedRelocationFrame
            ];
            long physicalRelocationTarget = physicalRelocationRows[
              10240 + publishedRelocationFrame
            ];
            long physicalRelocationOwner = callableOwners[physicalRelocationTarget];
            long physicalRelocationLocal = physicalRelocationTarget
              - moduleFirstCallables[physicalRelocationOwner];
            setByte(output, physicalMetadata, physicalRelocationProduct);
            setByte(
              output,
              physicalMetadata + 1,
              physicalRelocationInstruction / 256
            );
            setByte(
              output,
              physicalMetadata + 2,
              physicalRelocationInstruction % 256
            );
            setByte(output, physicalMetadata + 3, physicalRelocationOwner / 256);
            setByte(output, physicalMetadata + 4, physicalRelocationOwner % 256);
            setByte(output, physicalMetadata + 5, physicalRelocationLocal);
            physicalMetadata += 6;
            publishedRelocationFrame += 1;
          }
          setByte(output, physicalMetadata, 87);
          setByte(output, physicalMetadata + 1, 80);
          setByte(output, physicalMetadata + 2, 70);
          setByte(output, physicalMetadata + 3, 1);
          setByte(output, physicalMetadata + 4, PHYSICAL_MODULE_COUNT / 256);
          setByte(output, physicalMetadata + 5, PHYSICAL_MODULE_COUNT % 256);
          setByte(output, physicalMetadata + 6, physicalCallableRelocationCount / 256);
          setByte(
            output,
            physicalMetadata + 7,
            physicalCallableRelocationCount % 256
          );
          setOutputLength(output, physicalMetadata + 8);
        } else {
          setByte(output, 0, 1);
        }
        """;
  }
}
