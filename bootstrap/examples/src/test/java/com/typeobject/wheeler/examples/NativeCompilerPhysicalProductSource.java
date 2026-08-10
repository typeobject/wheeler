package com.typeobject.wheeler.examples;

/** Owns the physical source-product compilation transaction used by closure evidence. */
final class NativeCompilerPhysicalProductSource {
  private NativeCompilerPhysicalProductSource() {}

  static String compilation() {
    return """
        if (closure.moduleCount == 304) {
          long physicalProduct = 0;
          while (physicalProduct < PHYSICAL_MODULE_COUNT) limit 128 {
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
            CompiledCallableBody physicalModule = compileSourceModuleProductWithImports(
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
        """;
  }
}
