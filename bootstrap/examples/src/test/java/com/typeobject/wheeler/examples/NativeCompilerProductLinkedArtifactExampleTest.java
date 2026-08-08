package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** End-to-end native evidence from one semantic product set to one canonical artifact. */
final class NativeCompilerProductLinkedArtifactExampleTest {
  @Test
  void reproducesAStageZeroArtifactFromSemanticProducts() throws Exception {
    byte[] artifact = artifact();
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), artifact, 1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"));
    assertArrayEquals(artifact, machine.hostOutput());
    new BytecodeReader().read(machine.hostOutput());
  }

  private static byte[] artifact() {
    String dependency = """
        module fixture.product_linked_helper;

        classical class ProductLinkedHelper {
          public long helper(long value) {
            return value;
          }
        }
        """;
    String source = """
        module fixture.product_linked_artifact;

        import fixture.product_linked_helper;

        classical class ProductLinkedArtifact {
          state long marker = -9;

          record Pair(long left, boolean ready) {}

          rev long local(long value) {
            long result = value + 0;
            return result;
          }

          theorem localInverse proves inverse(local);

          entry void main() {
            Pair pair = new Pair(helper(local(marker)), true);
            assert(pair.ready);
          }
        }
        """;
    Program program = new WheelerCompiler().compileModuleFiles(
        Map.of("ProductLinkedHelper.w", dependency, "ProductLinkedArtifact.w", source),
        "fixture.product_linked_artifact");
    return new BytecodeWriter().write(program);
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_function_rows"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.canonical_product_emitter"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_function_names"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_function_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_global_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_proof_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_string_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.counted_aggregate_layouts"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.counted_function_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_instruction_code"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_local_types"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.opcodes"));
    sources.put("ProductLinkedArtifactExample.w", """
        module example.product_linked_artifact;

        import wheeler.compiler.closure.callable_function_rows;
        import wheeler.compiler.closure.canonical_product_emitter;
        import wheeler.compiler.closure.compiled_function_names;
        import wheeler.compiler.closure.compiled_function_products;
        import wheeler.compiler.closure.compiled_global_products;
        import wheeler.compiler.closure.compiled_proof_products;
        import wheeler.compiler.closure.compiled_string_products;
        import wheeler.compiler.closure.counted_aggregate_layouts;
        import wheeler.compiler.closure.counted_function_products;
        import wheeler.compiler.closure.linked_instruction_code;
        import wheeler.compiler.closure.linked_local_types;
        import wheeler.compiler.opcodes;
        import wheeler.core.encoding.binary;

        classical class ProductLinkedArtifactExample {
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 20445696, /* allocations= */ 34);
            words artifactStarts = allocate(rows, /* length= */ 512);
            words artifactLengths = allocate(rows, /* length= */ 512);
            words localFunctions = allocate(rows, /* length= */ 640);
            words localInstructions = allocate(rows, /* length= */ 24576);
            words closureFunctions = allocate(rows, /* length= */ 49152);
            words closureInstructions = allocate(rows, /* length= */ 917504);
            words moduleFirstFunctions = allocate(rows, /* length= */ 512);
            words moduleFunctionCounts = allocate(rows, /* length= */ 512);
            words linkedTypes = allocate(rows, /* length= */ 1048576);
            words functionNames = allocate(rows, /* length= */ 4096);
            words finalFunctionNames = allocate(rows, /* length= */ 4096);
            words stringArtifactRanks = allocate(rows, /* length= */ 16384);
            words stringStarts = allocate(rows, /* length= */ 16384);
            words stringLengths = allocate(rows, /* length= */ 16384);
            words finalStrings = allocate(rows, /* length= */ 16384);
            words processedAggregates = allocate(rows, /* length= */ 512);
            words aggregates = allocate(rows, /* length= */ 36864);
            words cases = allocate(rows, /* length= */ 32768);
            words members = allocate(rows, /* length= */ 65536);
            words moduleStringBases = allocate(rows, /* length= */ 512);
            words finalDescriptors = allocate(rows, /* length= */ 4096);
            words globals = allocate(rows, /* length= */ 20480);
            words proofs = allocate(rows, /* length= */ 24576);
            words importedRelocations = allocate(rows, /* length= */ 131072);
            bytes functionIdentities = allocateBytes(rows, /* length= */ 131072);
            bytes relocationIdentities = allocateBytes(rows, /* length= */ 131072);
            words hashSlots = allocate(rows, /* length= */ 8192);
            words hashFunctions = allocate(rows, /* length= */ 8192);
            words callableFunctionRows = allocate(rows, /* length= */ 4096);
            words callableRowsPublished = allocate(rows, /* length= */ 4096);
            words identityTargets = allocate(rows, /* length= */ 65536);
            words sectionTypes = allocate(rows, /* length= */ 64);
            words sectionStarts = allocate(rows, /* length= */ 64);
            words sectionLengths = allocate(rows, /* length= */ 64);

            set(artifactStarts, 0, 0);
            set(artifactLengths, 0, bufferLength(source));
            set(moduleStringBases, 0, 0);
            CompiledStringPlan stringPlan = appendCompiledStringProducts(
              source,
              bufferLength(source),
              /* artifactBase= */ 0,
              /* artifactRank= */ 0,
              /* closureStringCount= */ 0,
              stringArtifactRanks,
              stringStarts,
              stringLengths
            );
            CountedAggregateLayoutPlan aggregatePlan = appendCompiledAggregateLayouts(
              source,
              bufferLength(source),
              /* owner= */ 0,
              /* moduleCount= */ 0,
              /* aggregateCount= */ 0,
              /* caseCount= */ 0,
              /* memberCount= */ 0,
              processedAggregates,
              aggregates,
              cases,
              members
            );
            long records = 0;
            long arrays = 0;
            long slices = 0;
            long variants = 0;
            long aggregate = 0;
            while (aggregate < aggregatePlan.aggregateCount) limit 4096 {
              long kind = aggregates[aggregate];
              if (kind == 1) {
                set(finalDescriptors, aggregate, records);
                records += 1;
              } else {
                if (kind == 2) {
                  set(finalDescriptors, aggregate, arrays);
                  arrays += 1;
                } else {
                  if (kind == 3) {
                    set(finalDescriptors, aggregate, slices);
                    slices += 1;
                  } else {
                    assert(kind == 4);
                    set(finalDescriptors, aggregate, variants);
                    variants += 1;
                  }
                }
              }
              aggregate += 1;
            }
            CompiledFunctionPlan localPlan = indexCompiledFunctionProducts(
              source,
              bufferLength(source),
              localFunctions,
              localInstructions
            );
            CountedFunctionWindow functionWindow = appendFunctionProduct(
              /* moduleOwner= */ 0,
              /* artifactRank= */ 0,
              localPlan.functionCount,
              localPlan.instructionCount,
              localFunctions,
              localInstructions,
              /* closureFunctionCount= */ 0,
              /* closureInstructionCount= */ 0,
              moduleFirstFunctions,
              moduleFunctionCounts,
              closureFunctions,
              closureInstructions
            );
            assert(functionWindow.functionCount == 3);
            set(closureFunctions, 1, 1);
            set(closureFunctions, 2, 1);
            set(moduleFunctionCounts, 0, 1);
            set(moduleFirstFunctions, 1, 1);
            set(moduleFunctionCounts, 1, 2);
            aggregate = 0;
            while (aggregate < aggregatePlan.aggregateCount) limit 4096 {
              set(aggregates, 4096 + aggregate, 1);
              aggregate += 1;
            }
            long globalCount = appendCompiledGlobalProducts(
              source,
              bufferLength(source),
              /* moduleOwner= */ 1,
              /* moduleStringBase= */ 0,
              stringPlan.stringCount,
              /* closureGlobalCount= */ 0,
              globals
            );
            appendCompiledFunctionNames(
              source,
              bufferLength(source),
              /* moduleStringBase= */ 0,
              stringPlan.stringCount,
              functionWindow.firstFunction,
              functionWindow.functionCount,
              functionNames
            );
            long proofCount = appendCompiledProofProducts(
              source,
              bufferLength(source),
              /* moduleOwner= */ 0,
              /* moduleStringBase= */ 0,
              stringPlan.stringCount,
              functionWindow.firstFunction,
              functionWindow.functionCount,
              /* closureProofCount= */ 0,
              proofs
            );

            region sections = new region(/* bytes= */ 2097152, /* allocations= */ 2);
            bytes stagedSections = allocateBytes(sections, /* length= */ 1048576);
            bytes stagedCode = allocateBytes(sections, /* length= */ 1048576);
            long codeBytes = emitLinkedInstructionCodeAt(
              source,
              bufferLength(source),
              artifactStarts,
              artifactLengths,
              functionWindow.functionCount,
              functionWindow.instructionCount,
              moduleFirstFunctions,
              moduleFunctionCounts,
              closureFunctions,
              closureInstructions,
              stagedCode,
              /* outputStart= */ 0
            );
            long identityFunction = 0;
            while (identityFunction < functionWindow.functionCount) limit 4096 {
              setByte(
                functionIdentities,
                identityFunction * 32,
                identityFunction + 1
              );
              identityFunction += 1;
            }
            long importedCount = 0;
            long instruction = 0;
            while (instruction < functionWindow.instructionCount) limit 131072 {
              long opcode = closureInstructions[524288 + instruction];
              boolean importedCall = false;
              if (opcode == OPCODE_CALL) {
                importedCall = true;
              }
              if (opcode == OPCODE_UNCALL) {
                importedCall = true;
              }
              if (opcode == OPCODE_CALL_VALUE) {
                importedCall = true;
              }
              if (opcode == OPCODE_CALL_VOID) {
                importedCall = true;
              }
              if (opcode == OPCODE_CALL_RESULT_SLOT) {
                importedCall = true;
              }
              if (opcode == OPCODE_UNCALL_RESULT_SLOT) {
                importedCall = true;
              }
              if (importedCall) {
                if (0 < closureInstructions[instruction]) {
                  long instructionStart = closureInstructions[393216 + instruction];
                  long sourceTarget = readUnsigned(source, instructionStart + 8, 8);
                  set(importedRelocations, importedCount, instruction);
                  long identityByte = 0;
                  while (identityByte < 32) limit 32 {
                    setByte(
                      relocationIdentities,
                      importedCount * 32 + identityByte,
                      functionIdentities[sourceTarget * 32 + identityByte]
                    );
                    identityByte += 1;
                  }
                  importedCount += 1;
                }
              }
              instruction += 1;
            }
            assert(importedCount == 2);
            mapCallableFunctionRows(
              functionWindow.functionCount,
              functionIdentities,
              functionWindow.functionCount,
              functionIdentities,
              hashSlots,
              hashFunctions,
              callableFunctionRows,
              callableRowsPublished
            );
            resolveImportedIdentityFunctionTargets(
              importedCount,
              relocationIdentities,
              functionWindow.functionCount,
              functionIdentities,
              hashSlots,
              hashFunctions,
              identityTargets
            );
            long imported = 0;
            while (imported < importedCount) limit 4096 {
              set(importedRelocations, 65536 + imported, identityTargets[imported]);
              imported += 1;
            }
            rewriteImportedInstructionTargetsAt(
              functionWindow.functionCount,
              functionWindow.instructionCount,
              closureInstructions,
              importedCount,
              importedRelocations,
              stagedCode,
              /* outputStart= */ 0
            );
            long linkedTypeCount = emitLinkedLocalTypes(
              source,
              bufferLength(source),
              artifactStarts,
              artifactLengths,
              functionWindow.functionCount,
              closureFunctions,
              aggregatePlan.aggregateCount,
              aggregates,
              finalDescriptors,
              linkedTypes
            );

            assert(proofCount == 1);
            set(moduleFirstFunctions, 0, 0);
            set(moduleFunctionCounts, 0, 3);
            CanonicalProductSections emitted = emitCanonicalProductSections(
              source,
              bufferLength(source),
              /* rootModule= */ 0,
              /* rootStringBase= */ 0,
              stringPlan.stringCount,
              source,
              bufferLength(source),
              stringPlan.closureStringCount,
              stringStarts,
              stringLengths,
              finalStrings,
              moduleFirstFunctions,
              moduleFunctionCounts,
              globalCount,
              globals,
              aggregatePlan.aggregateCount,
              aggregatePlan.caseCount,
              moduleStringBases,
              aggregates,
              cases,
              members,
              finalDescriptors,
              functionWindow.functionCount,
              closureFunctions,
              functionNames,
              finalFunctionNames,
              linkedTypeCount,
              linkedTypes,
              stagedCode,
              codeBytes,
              proofCount,
              proofs,
              sectionTypes,
              sectionStarts,
              sectionLengths,
              stagedSections
            );
            long artifactBytes = publishCanonicalProductContainer(
              stagedSections,
              emitted,
              sectionTypes,
              sectionStarts,
              sectionLengths,
              output
            );
            published = 1;
            setOutputLength(output, artifactBytes);

            drop(stagedCode);
            drop(stagedSections);
            drop(sections);
            drop(sectionLengths);
            drop(sectionStarts);
            drop(sectionTypes);
            drop(identityTargets);
            drop(callableRowsPublished);
            drop(callableFunctionRows);
            drop(hashFunctions);
            drop(hashSlots);
            drop(relocationIdentities);
            drop(functionIdentities);
            drop(importedRelocations);
            drop(proofs);
            drop(globals);
            drop(finalDescriptors);
            drop(moduleStringBases);
            drop(members);
            drop(cases);
            drop(aggregates);
            drop(processedAggregates);
            drop(finalStrings);
            drop(stringLengths);
            drop(stringStarts);
            drop(stringArtifactRanks);
            drop(finalFunctionNames);
            drop(functionNames);
            drop(linkedTypes);
            drop(moduleFunctionCounts);
            drop(moduleFirstFunctions);
            drop(closureInstructions);
            drop(closureFunctions);
            drop(localInstructions);
            drop(localFunctions);
            drop(artifactLengths);
            drop(artifactStarts);
            drop(rows);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.product_linked_artifact");
  }
}
