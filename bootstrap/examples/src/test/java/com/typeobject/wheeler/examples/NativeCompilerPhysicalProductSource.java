package com.typeobject.wheeler.examples;

import java.util.List;

/** Owns the physical source-product compilation transaction used by closure evidence. */
final class NativeCompilerPhysicalProductSource {
  private static final List<String> DIRECT_SOURCE_MODULES = List.of(
      "wheeler.compiler.assignment_call_arities",
      "wheeler.compiler.assignment_call_code_widths",
      "wheeler.compiler.assignment_call_columns",
      "wheeler.compiler.assignment_call_instruction_widths",
      "wheeler.compiler.assignment_call_kinds",
      "wheeler.compiler.assignment_call_local_widths",
      "wheeler.compiler.assignment_call_operands",
      "wheeler.compiler.assignment_call_syntax",
      "wheeler.compiler.boolean_declaration_kinds",
      "wheeler.compiler.boolean_tokens",
      "wheeler.compiler.borrowed_intrinsic_shapes",
      "wheeler.compiler.call_argument_sources",
      "wheeler.compiler.call_arguments",
      "wheeler.compiler.call_forms",
      "wheeler.compiler.closure.aggregate_source_projection",
      "wheeler.compiler.closure.manifest_assertions",
      "wheeler.compiler.closure.manifest_profile",
      "wheeler.compiler.closure.manifest_syntax",
      "wheeler.compiler.closure.reversible_token_coordinates",
      "wheeler.compiler.core_parsing",
      "wheeler.compiler.early_comparison_forms",
      "wheeler.compiler.early_return_kinds",
      "wheeler.compiler.early_utf8_call_forms",
      "wheeler.compiler.early_return_result_kinds",
      "wheeler.compiler.early_return_sources",
      "wheeler.compiler.four_argument_calls",
      "wheeler.compiler.forwarded_helper_result_kinds",
      "wheeler.compiler.forwarded_helper_result_statements",
      "wheeler.compiler.helper_result_kinds",
      "wheeler.compiler.helper_signatures",
      "wheeler.compiler.helper_value_kinds",
      "wheeler.compiler.identifier_starts",
      "wheeler.compiler.instruction_forms",
      "wheeler.compiler.literal_comparison_operations",
      "wheeler.compiler.local_type_encoding",
      "wheeler.compiler.named_boolean_return_kinds",
      "wheeler.compiler.named_comparison_kinds",
      "wheeler.compiler.named_conditional_bases",
      "wheeler.compiler.named_literal_comparison_kinds",
      "wheeler.compiler.named_local_assignment_kinds",
      "wheeler.compiler.named_local_conditional_kinds",
      "wheeler.compiler.named_local_conditional_values",
      "wheeler.compiler.named_local_update_kinds",
      "wheeler.compiler.named_long_operations",
      "wheeler.compiler.named_return_arithmetic_kinds",
      "wheeler.compiler.named_return_comparison_operands",
      "wheeler.compiler.named_signed_return_kinds",
      "wheeler.compiler.one_argument_calls",
      "wheeler.compiler.opcode_kinds",
      "wheeler.compiler.packages.manifest_tokens",
      "wheeler.compiler.packages.names",
      "wheeler.compiler.packages.paths",
      "wheeler.compiler.packages.semver_coordinates",
      "wheeler.compiler.packages.semver_core_validation",
      "wheeler.compiler.packages.semver_identifier_comparison",
      "wheeler.compiler.packages.semver_core_comparison",
      "wheeler.compiler.packages.semver_prerelease_validation",
      "wheeler.compiler.resolved_boolean_literal_assertions",
      "wheeler.compiler.resolved_boolean_literal_comparisons",
      "wheeler.compiler.resolved_early_comparison_kinds",
      "wheeler.compiler.resolved_early_result_kinds",
      "wheeler.compiler.resolved_less_than_assertions",
      "wheeler.compiler.resolved_literal_comparison_kinds",
      "wheeler.compiler.resolved_local_assignments",
      "wheeler.compiler.resolved_local_conditional_kinds",
      "wheeler.compiler.resolved_local_conditional_operands",
      "wheeler.compiler.resolved_local_conditional_sources",
      "wheeler.compiler.resolved_local_copy_kinds",
      "wheeler.compiler.resolved_local_equality_kinds",
      "wheeler.compiler.resolved_local_inequality_kinds",
      "wheeler.compiler.resolved_local_less_than_kinds",
      "wheeler.compiler.resolved_local_literal_comparison_sources",
      "wheeler.compiler.resolved_local_literal_comparisons",
      "wheeler.compiler.resolved_local_loop_forms",
      "wheeler.compiler.resolved_local_loop_kinds",
      "wheeler.compiler.resolved_local_loop_operands",
      "wheeler.compiler.resolved_local_pair_assertions",
      "wheeler.compiler.resolved_local_result_kinds",
      "wheeler.compiler.resolved_local_return_statements",
      "wheeler.compiler.resolved_local_returns",
      "wheeler.compiler.resolved_local_updates",
      "wheeler.compiler.resolved_long_operations",
      "wheeler.compiler.resolved_return_call_kinds",
      "wheeler.compiler.result_slot_verifier",
      "wheeler.compiler.return_opcode_kinds",
      "wheeler.compiler.signed_helper_result_kinds",
      "wheeler.compiler.signed_return_statements",
      "wheeler.compiler.three_argument_calls",
      "wheeler.compiler.two_argument_call_kinds",
      "wheeler.compiler.type_kinds",
      "wheeler.compiler.void_call_kinds",
      "wheeler.compiler.void_call_operands",
      "wheeler.compiler.void_call_source_forms",
      "wheeler.compiler.void_call_source_kinds",
      "wheeler.compiler.void_call_source_widths",
      "wheeler.compiler.void_call_syntax",
      "wheeler.compiler.void_call_widths",
      "wheeler.compiler.wide_local_calls",
      "wheeler.compiler.wide_return_sources");

  private NativeCompilerPhysicalProductSource() {}

  private static String directSourceRouting() {
    StringBuilder routing = new StringBuilder();
    for (String moduleName : DIRECT_SOURCE_MODULES) {
      int owner = NativeCompilerPhysicalSelection.owner(
          NativeCompilerPhysicalSelection.selected(moduleName));
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
            long physicalSourceLength = 0;
            if (!directSourceModule) {
              physicalSourceLength = writeProductModuleSource(
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
            }
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
              primitiveCallables,
              externalFirstCallables,
              externalCallableCounts,
              externalCallableVisibilities,
              externalPrimitiveCallables,
              physicalDependencyRows
            );
            long physicalCallCount = 0;
            if (PHYSICAL_COMPARABLE_COUNT < physicalProduct + 1) {
              if (directSourceModule == false) {
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
            }
            long physicalDirectRelocationCount = 0;
            CompiledCallableBody physicalModule = new CompiledCallableBody(0, 0, 0, 0);
            if (directSourceModule) {
              SourceProductArtifactPlan directArtifact = new SourceProductArtifactPlan(
                0,
                0,
                0,
                0,
                0
              );
              if (PHYSICAL_COMPARABLE_COUNT < physicalProduct + 1) {
                directArtifact = compileStructuredArchiveModuleWithImportedTargets(
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
                  physicalDependencyCount,
                  physicalDependencyRows,
                  callableFirstParameters,
                  callableParameterCounts,
                  physicalResultTypes,
                  callableEffects,
                  physicalParameterTypes,
                  parameterModes,
                  callableProductNames,
                  callableProductNameStarts,
                  callableNameLengths,
                  callableIdentities,
                  callableOwners,
                  archive,
                  moduleProductNameStarts,
                  moduleProductNameLengths,
                  callables.callableCount,
                  callableIdentities,
                  callableHashSlots,
                  callableHashFunctions,
                  directRelocationRows,
                  directRelocationOwners,
                  directRelocationIdentities,
                  compiledCallableArtifact,
                  compiledCallableIdentity
                );
                physicalDirectRelocationCount = directArtifact.relocationCount;
              } else {
                directArtifact = compileStructuredArchiveModuleProduct(
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
              }
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
            if (0 < physicalDirectRelocationCount) {
              resolveImportedIdentityFunctionTargets(
                physicalDirectRelocationCount,
                directRelocationIdentities,
                callables.callableCount,
                callableIdentities,
                callableHashSlots,
                callableHashFunctions,
                physicalTargetRows
              );
              long directRelocation = 0;
              while (directRelocation < physicalDirectRelocationCount) limit 256 {
                long directTarget = physicalTargetRows[directRelocation];
                if (callableOwners[directTarget] != physicalOwner) {
                  long directOwner = directRelocationOwners[directRelocation];
                  long directOwnerInstruction = directRelocationRows[directRelocation];
                  long directInstruction = 0;
                  long directOwnerOrdinal = 0;
                  long selectedInstruction = -1;
                  while (
                    directInstruction < physicalFunctions.instructionCount
                  ) limit 4096 {
                    if (physicalInstructionRows[directInstruction] == directOwner) {
                      if (physicalInstructionRows[4096 + directInstruction] == 0) {
                        if (directOwnerOrdinal == directOwnerInstruction) {
                          assert(selectedInstruction == -1);
                          selectedInstruction = directInstruction;
                        }
                        directOwnerOrdinal += 1;
                      }
                    }
                    directInstruction += 1;
                  }
                  assert(-1 < selectedInstruction);
                  long directFrame = physicalCallableRelocationCount;
                  assert(directFrame < 2048);
                  set(physicalRelocationRows, 2048 + directFrame, physicalProduct);
                  set(physicalRelocationRows, 6144 + directFrame, selectedInstruction);
                  set(physicalRelocationRows, 10240 + directFrame, directTarget);
                  physicalCallableRelocationCount += 1;
                  physicalResolvedCallableTargetCount += 1;
                }
                directRelocation += 1;
              }
            }
            boolean parserCallableProduct = PHYSICAL_COMPARABLE_COUNT
              < physicalProduct + 1;
            if (directSourceModule) {
              parserCallableProduct = false;
            }
            if (parserCallableProduct) {
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
