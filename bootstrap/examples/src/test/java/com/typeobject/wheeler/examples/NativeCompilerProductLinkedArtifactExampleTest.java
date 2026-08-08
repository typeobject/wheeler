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
    String source = """
        module fixture.product_linked_artifact;

        classical class ProductLinkedArtifact {
          state long marker = -9;

          record Pair(long left, boolean ready) {}

          public long helper(long value) {
            return value;
          }

          entry void main() {
            Pair pair = new Pair(helper(marker), true);
            assert(pair.ready);
          }
        }
        """;
    Program program = new WheelerCompiler().compileModuleFiles(
        Map.of("ProductLinkedArtifact.w", source), "fixture.product_linked_artifact");
    return new BytecodeWriter().write(program);
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_function_names"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_function_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_global_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_string_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.counted_aggregate_layouts"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.counted_function_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_aggregate_sections"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_container"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_function_section"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_instruction_code"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_local_types"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_manifest_section"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_string_section"));
    sources.put("ProductLinkedArtifactExample.w", """
        module example.product_linked_artifact;

        import wheeler.compiler.closure.compiled_function_names;
        import wheeler.compiler.closure.compiled_function_products;
        import wheeler.compiler.closure.compiled_global_products;
        import wheeler.compiler.closure.compiled_string_products;
        import wheeler.compiler.closure.counted_aggregate_layouts;
        import wheeler.compiler.closure.counted_function_products;
        import wheeler.compiler.closure.linked_aggregate_sections;
        import wheeler.compiler.closure.linked_container;
        import wheeler.compiler.closure.linked_function_section;
        import wheeler.compiler.closure.linked_instruction_code;
        import wheeler.compiler.closure.linked_local_types;
        import wheeler.compiler.closure.linked_manifest_section;
        import wheeler.compiler.closure.linked_string_section;

        classical class ProductLinkedArtifactExample {
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 18217472, /* allocations= */ 25);
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
            long globalCount = appendCompiledGlobalProducts(
              source,
              bufferLength(source),
              /* moduleOwner= */ 0,
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

            long cursor = 24;
            set(sectionTypes, 1, 2);
            set(sectionStarts, 1, cursor);
            long stringBytes = emitLinkedStringSectionAt(
              source,
              bufferLength(source),
              stringPlan.closureStringCount,
              stringStarts,
              stringLengths,
              finalStrings,
              stagedSections,
              cursor
            );
            set(sectionLengths, 1, stringBytes);
            cursor += stringBytes;
            resolveLinkedFunctionNameIds(
              functionWindow.functionCount,
              stringPlan.closureStringCount,
              functionNames,
              finalStrings,
              finalFunctionNames
            );
            set(sectionTypes, 0, 1);
            set(sectionStarts, 0, 0);
            long manifestBytes = emitLinkedManifestSection(
              source,
              bufferLength(source),
              /* rootModule= */ 0,
              /* rootStringBase= */ 0,
              stringPlan.stringCount,
              stringPlan.closureStringCount,
              finalStrings,
              moduleFirstFunctions,
              moduleFunctionCounts,
              stagedSections,
              /* outputStart= */ 0
            );
            set(sectionLengths, 0, manifestBytes);

            set(sectionTypes, 2, 3);
            set(sectionStarts, 2, cursor);
            long typeBytes = emitLinkedTypeSection(
              globalCount,
              globals,
              aggregatePlan.aggregateCount,
              stringPlan.closureStringCount,
              moduleStringBases,
              finalStrings,
              aggregates,
              members,
              finalDescriptors,
              stagedSections,
              cursor
            );
            set(sectionLengths, 2, typeBytes);
            cursor += typeBytes;

            set(sectionTypes, 3, 4);
            set(sectionStarts, 3, cursor);
            long variantBytes = emitLinkedVariantSection(
              aggregatePlan.aggregateCount,
              aggregatePlan.caseCount,
              stringPlan.closureStringCount,
              moduleStringBases,
              finalStrings,
              aggregates,
              cases,
              members,
              finalDescriptors,
              stagedSections,
              cursor
            );
            set(sectionLengths, 3, variantBytes);
            cursor += variantBytes;

            set(sectionTypes, 4, 5);
            set(sectionStarts, 4, cursor);
            long functionBytes = emitLinkedFunctionSectionAt(
              functionWindow.functionCount,
              closureFunctions,
              stringPlan.closureStringCount,
              finalFunctionNames,
              linkedTypeCount,
              linkedTypes,
              codeBytes,
              stagedSections,
              cursor
            );
            set(sectionLengths, 4, functionBytes);
            cursor += functionBytes;

            set(sectionTypes, 5, 6);
            set(sectionStarts, 5, cursor);
            long codeByte = 0;
            while (codeByte < codeBytes) limit 4194304 {
              setByte(stagedSections, cursor + codeByte, stagedCode[codeByte]);
              codeByte += 1;
            }
            set(sectionLengths, 5, codeBytes);
            cursor += codeBytes;
            long artifactBytes = emitCanonicalContainer(
              stagedSections,
              cursor,
              /* sectionCount= */ 6,
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
