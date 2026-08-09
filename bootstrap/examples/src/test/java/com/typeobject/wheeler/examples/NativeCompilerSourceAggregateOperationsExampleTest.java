package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for source aggregate operation products. */
final class NativeCompilerSourceAggregateOperationsExampleTest {
  @Test
  void indexesConstructorsAndProjectionsInSourceOrder() throws Exception {
    String source = """
        classical class Example {
          record Pair(long value) {}
          variant Choice {
            case Some(Pair pair);
          }
          record ArrayOwner(long[4] values) {}
          private long read(Pair pair, long[4] values, long index) {
            Pair made = new Pair(index);
            Choice selected = new Choice.Some(made);
            long member = pair.value;
            long element = values[index];
            long piece = slice(values, index, 2);
            Pair payload = selected.pair;
            long nested = payload.value;
            return member + element + piece + nested;
          }
        }
        """;
    VirtualMachine machine = new VirtualMachine(program(),
        source.getBytes(StandardCharsets.UTF_8), 280);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(7, machine.global("operationCount"));
    assertEquals(6, machine.global("argumentCount"));
    assertEquals(1, machine.global("firstKind"));
    assertEquals(2, machine.global("secondKind"));
    assertEquals(3, machine.global("thirdKind"));
    assertEquals(4, machine.global("fourthKind"));
    assertEquals(5, machine.global("fifthKind"));
    assertEquals("Pair", source.substring(
        Math.toIntExact(machine.global("firstTypeStart")),
        Math.toIntExact(machine.global("firstTypeEnd"))));
    assertEquals("Some", source.substring(
        Math.toIntExact(machine.global("caseStart")),
        Math.toIntExact(machine.global("caseEnd"))));
    assertEquals("value", source.substring(
        Math.toIntExact(machine.global("memberStart")),
        Math.toIntExact(machine.global("memberEnd"))));
    assertEquals("index", source.substring(
        Math.toIntExact(machine.global("firstArgumentStart")),
        Math.toIntExact(machine.global("firstArgumentEnd"))));
    assertEquals(7, machine.global("loweredCount"));
    assertEquals(272, machine.global("length"));
    assertEquals(0, machine.global("recordTarget"));
    assertEquals(1, machine.global("variantTarget"));
    assertEquals(1, machine.global("aggregatesValid"));
    assertEquals(6, machine.global("localNominalReferenceCount"));
    assertEquals(0, machine.global("firstLocalNominalTarget"));
    assertEquals(0, machine.global("lastLocalNominalTarget"));
    assertEquals(source.getBytes(StandardCharsets.UTF_8).length - 4,
        machine.global("localCarrierLength"));
    assertEquals(108, machine.global("firstLocalCarrierByte"));
    assertEquals(108, machine.global("firstVariantCarrierByte"));
    assertEquals(1, machine.global("targetsValidState"));
    assertEquals(1, machine.global("projectionsValidState"));
    assertEquals(1, machine.global("bindingsValidState"));
    assertEquals(1, machine.global("operandsValidState"));
    assertEquals(8, machine.global("composedCount"));
    assertEquals(280, machine.global("composedForwardLength"));
    assertEquals(0, machine.global("firstArtifactSelector"));
    assertEquals(1, machine.global("secondArtifactSelector"));
    assertEquals(1, machine.global("closureFunctionCount"));
    assertEquals(8, machine.global("closureInstructionCount"));
    assertEquals(0, machine.global("primitiveArtifactRank"));
    assertEquals(1, machine.global("aggregateArtifactRank"));
    assertEquals(280, machine.global("linkedLength"));
    assertEquals(0x0500, machine.global("firstAggregateOpcode"));
    assertEquals(0, machine.global("fieldTarget"));
    assertEquals(3, machine.global("arrayTarget"));
    assertEquals(
        List.of(0x0001, 0x0500, 0x0510, 0x0501, 0x0521, 0x0530, 0x0512, 0x0501),
        opcodes(machine.hostOutput()));
  }

  @Test
  void nestedConstructorsPublishInEvaluationOrder() throws Exception {
    String source = "new Token(new Span(3, 8), true)";
    VirtualMachine machine = new VirtualMachine(nestedProgram(),
        source.getBytes(StandardCharsets.UTF_8), 1);

    machine.run();

    assertEquals(2, machine.global("operationCount"));
    assertEquals(4, machine.global("argumentCount"));
    assertEquals("Span", source.substring(
        Math.toIntExact(machine.global("firstTypeStart")),
        Math.toIntExact(machine.global("firstTypeEnd"))));
    assertEquals("Token", source.substring(
        Math.toIntExact(machine.global("secondTypeStart")),
        Math.toIntExact(machine.global("secondTypeEnd"))));
    assertEquals(0, machine.global("firstArgumentOwner"));
    assertEquals(1, machine.global("thirdArgumentOwner"));
  }

  @Test
  void fixedArrayConstructorBracketsAreNotIndexes() throws Exception {
    String source = "new long[4](1, 2, 3, 4)";
    VirtualMachine machine = new VirtualMachine(nestedProgram(),
        source.getBytes(StandardCharsets.UTF_8), 1);

    machine.run();

    assertEquals(1, machine.global("operationCount"));
    assertEquals(4, machine.global("argumentCount"));
    assertEquals(1, machine.global("firstKind"));
    assertEquals("long[4]", source.substring(
        Math.toIntExact(machine.global("firstTypeStart")),
        Math.toIntExact(machine.global("firstTypeEnd"))));
  }

  @Test
  void postfixSliceProjectionUsesTheNestedResult() throws Exception {
    String source = "slice(values, 0, 2)[1]";
    VirtualMachine machine = new VirtualMachine(nestedProgram(),
        source.getBytes(StandardCharsets.UTF_8), 1);

    machine.run();

    assertEquals(2, machine.global("operationCount"));
    assertEquals(4, machine.global("argumentCount"));
    assertEquals(5, machine.global("firstKind"));
    assertEquals(4, machine.global("secondKind"));
    assertEquals("slice(values, 0, 2)", source.substring(
        Math.toIntExact(machine.global("secondOwnerStart")),
        Math.toIntExact(machine.global("secondOwnerEnd"))));
  }

  @Test
  void malformedConstructionPublishesNothing() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(),
        "new Pair(value".getBytes(StandardCharsets.UTF_8), 280);

    machine.run();

    assertEquals(0, machine.global("operationCount"));
    assertEquals(0, machine.global("valid"));
    assertArrayEquals(new byte[0], machine.hostOutput());
  }

  private static Program nestedProgram() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_aggregate_operations"));
    sources.put("NestedAggregateOperationsExample.w", """
        module example.nested_aggregate_operations;

        import wheeler.compiler.closure.source_aggregate_operations;

        classical class NestedAggregateOperationsExample {
          state long operationCount = 0;
          state long argumentCount = 0;
          state long firstKind = 0;
          state long secondKind = 0;
          state long firstTypeStart = 0;
          state long firstTypeEnd = 0;
          state long secondTypeStart = 0;
          state long secondTypeEnd = 0;
          state long secondOwnerStart = 0;
          state long secondOwnerEnd = 0;
          state long firstArgumentOwner = -1;
          state long thirdArgumentOwner = -1;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 49152, /* allocations= */ 2);
            words operations = allocate(products, /* length= */ 2048);
            words arguments = allocate(products, /* length= */ 4096);
            SourceAggregateOperationPlan plan =
              materializeSourceAggregateOperations(input, operations, arguments);
            assert(plan.valid);
            operationCount = plan.operationCount;
            argumentCount = plan.argumentCount;
            firstKind = operations[0];
            secondKind = operations[1];
            firstTypeStart = operations[256];
            firstTypeEnd = operations[256] + operations[512];
            secondTypeStart = operations[257];
            secondTypeEnd = operations[257] + operations[513];
            secondOwnerStart = operations[257];
            secondOwnerEnd = operations[257] + operations[513];
            firstArgumentOwner = arguments[0];
            thirdArgumentOwner = arguments[2];
            setOutputLength(output, 0);
            drop(arguments);
            drop(operations);
            drop(products);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.nested_aggregate_operations");
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.resolved_aggregate_operations"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_aggregate_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_constructor_targets"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_projection_targets"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_instruction_composition"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_frontend_bindings"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_resolved_operands"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.counted_function_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_body_archive"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_instruction_code"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.local_nominal_references"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.local_nominal_carriers"));
    sources.put("SourceAggregateOperationsExample.w", """
        module example.source_aggregate_operations;

        import wheeler.compiler.closure.aggregate_constructor_targets;
        import wheeler.compiler.closure.aggregate_frontend_bindings;
        import wheeler.compiler.closure.aggregate_instruction_composition;
        import wheeler.compiler.closure.aggregate_instruction_products;
        import wheeler.compiler.closure.aggregate_projection_targets;
        import wheeler.compiler.closure.aggregate_resolved_operands;
        import wheeler.compiler.closure.compiled_body_archive;
        import wheeler.compiler.closure.counted_function_products;
        import wheeler.compiler.closure.linked_instruction_code;
        import wheeler.compiler.closure.local_nominal_carriers;
        import wheeler.compiler.closure.local_nominal_references;
        import wheeler.compiler.closure.resolved_aggregate_operations;
        import wheeler.compiler.closure.source_aggregate_operations;
        import wheeler.compiler.closure.source_aggregate_products;

        classical class SourceAggregateOperationsExample {
          state long operationCount = 0;
          state long argumentCount = 0;
          state long valid = 0;
          state long firstKind = 0;
          state long secondKind = 0;
          state long thirdKind = 0;
          state long fourthKind = 0;
          state long fifthKind = 0;
          state long firstTypeStart = 0;
          state long firstTypeEnd = 0;
          state long caseStart = 0;
          state long caseEnd = 0;
          state long memberStart = 0;
          state long memberEnd = 0;
          state long firstArgumentStart = 0;
          state long firstArgumentEnd = 0;
          state long loweredCount = 0;
          state long length = 0;
          state long composedCount = 0;
          state long composedForwardLength = 0;
          state long firstArtifactSelector = 0;
          state long secondArtifactSelector = 0;
          state long closureFunctionCount = 0;
          state long closureInstructionCount = 0;
          state long primitiveArtifactRank = -1;
          state long aggregateArtifactRank = -1;
          state long linkedLength = 0;
          state long firstAggregateOpcode = 0;
          state long recordTarget = -1;
          state long variantTarget = -1;
          state long aggregatesValid = 0;
          state long localNominalReferenceCount = 0;
          state long firstLocalNominalTarget = -1;
          state long lastLocalNominalTarget = -1;
          state long localCarrierLength = 0;
          state long firstLocalCarrierByte = 0;
          state long firstVariantCarrierByte = 0;
          state long targetsValidState = 0;
          state long projectionsValidState = 0;
          state long bindingsValidState = 0;
          state long operandsValidState = 0;
          state long fieldTarget = -1;
          state long arrayTarget = -1;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 912896, /* allocations= */ 26);
            words aggregates = allocate(products, /* length= */ 832);
            words cases = allocate(products, /* length= */ 640);
            words members = allocate(products, /* length= */ 2048);
            words targets = allocate(products, /* length= */ 768);
            words projectionTargets = allocate(products, /* length= */ 1024);
            words ownerAggregates = allocate(products, /* length= */ 256);
            words ownerCases = allocate(products, /* length= */ 256);
            words rows = allocate(products, /* length= */ 2048);
            words arguments = allocate(products, /* length= */ 4096);
            words localNominalReferences = allocate(products, /* length= */ 1536);
            words localCarrierRows = allocate(products, /* length= */ 2048);
            bytes localSourceStorage = allocateBytes(products, /* length= */ 32768);
            bytes localCarrierSource = allocateBytes(products, /* length= */ 32768);
            words valueRows = allocate(products, /* length= */ 7168);
            words statementRows = allocate(products, /* length= */ 24576);
            words argumentLocals = allocate(products, /* length= */ 1024);
            words destinationLocals = allocate(products, /* length= */ 256);
            words ownerLocals = allocate(products, /* length= */ 256);
            words sliceDescriptors = allocate(products, /* length= */ 256);
            words resolved = allocate(products, /* length= */ 1536);
            words primitiveFunctions = allocate(products, /* length= */ 640);
            words primitiveInstructions = allocate(products, /* length= */ 24576);
            words placements = allocate(products, /* length= */ 768);
            words composedFunctions = allocate(products, /* length= */ 640);
            words composedInstructions = allocate(products, /* length= */ 24576);
            words artifactSelectors = allocate(products, /* length= */ 4096);
            set(primitiveInstructions, 12288, 0x0001);
            set(primitiveInstructions, 20480, 8);
            set(rows, 0, 91);
            set(arguments, 0, 91);
            set(destinationLocals, 0, 91);
            set(placements, 0, 91);
            SourceAggregateProductPlan aggregatesPlan =
              materializeSourceAggregateProducts(input, aggregates, cases, members);
            SourceAggregateOperationPlan plan =
              materializeSourceAggregateOperations(input, rows, arguments);
            LocalNominalReferencePlan localNominals = materializeLocalNominalReferences(
              input,
              aggregatesPlan.aggregateCount,
              aggregates,
              localNominalReferences
            );
            long localSourceByte = 0;
            while (localSourceByte < bufferLength(input)) limit 32768 {
              setByte(localSourceStorage, localSourceByte, utf8Scalar(input, localSourceByte));
              localSourceByte += 1;
            }
            LocalNominalCarrierPlan localCarriers = writeLocalNominalCarriers(
              localSourceStorage,
              bufferLength(input),
              localNominals.referenceCount,
              localNominalReferences,
              localCarrierRows,
              localCarrierSource
            );
            long frontendOperation = 0;
            while (frontendOperation < plan.operationCount) limit 256 {
              set(statementRows, 8192 + frontendOperation, frontendOperation);
              set(statementRows, 12288 + frontendOperation, 1);
              set(statementRows, 16384 + frontendOperation, rows[1280 + frontendOperation]);
              set(statementRows, 20480 + frontendOperation, rows[1536 + frontendOperation]);
              set(valueRows, 1024 + frontendOperation, rows[1280 + frontendOperation]);
              set(valueRows, 2048 + frontendOperation, rows[1536 + frontendOperation]);
              set(valueRows, 4096 + frontendOperation, frontendOperation);
              set(valueRows, 5120 + frontendOperation, rows[1280 + frontendOperation]);
              set(valueRows, 6144 + frontendOperation, rows[1536 + frontendOperation]);
              frontendOperation += 1;
            }
            set(valueRows, 3072, 3);
            set(valueRows, 3073, 4);
            set(valueRows, 3074, 5);
            set(valueRows, 3075, 6);
            set(valueRows, 3076, 9);
            set(valueRows, 3077, 11);
            set(valueRows, 3078, 12);
            set(valueRows, 1031, rows[258]);
            set(valueRows, 2055, rows[514]);
            set(valueRows, 3079, 2);
            set(valueRows, 5127, rows[258]);
            set(valueRows, 6151, rows[514]);
            set(valueRows, 1032, rows[259]);
            set(valueRows, 2056, rows[515]);
            set(valueRows, 3080, 7);
            set(valueRows, 5128, rows[259]);
            set(valueRows, 6152, rows[515]);
            set(valueRows, 1033, arguments[2048]);
            set(valueRows, 2057, arguments[3072]);
            set(valueRows, 3081, 8);
            set(valueRows, 5129, arguments[2048]);
            set(valueRows, 6153, arguments[3072]);
            set(valueRows, 1034, arguments[2049]);
            set(valueRows, 2058, arguments[3073]);
            set(valueRows, 3082, 11);
            set(valueRows, 5130, arguments[2049]);
            set(valueRows, 6154, arguments[3073]);
            set(valueRows, 1035, rows[261]);
            set(valueRows, 2059, rows[517]);
            set(valueRows, 3083, 4);
            set(valueRows, 4107, 1);
            set(valueRows, 5131, rows[261]);
            set(valueRows, 6155, rows[517]);
            set(valueRows, 1036, rows[262]);
            set(valueRows, 2060, rows[518]);
            set(valueRows, 3084, 11);
            set(valueRows, 4108, 5);
            set(valueRows, 5132, rows[262]);
            set(valueRows, 6156, rows[518]);
            set(valueRows, 1037, arguments[2053]);
            set(valueRows, 2061, arguments[3077]);
            set(valueRows, 3085, 10);
            set(valueRows, 4109, 4);
            set(valueRows, 5133, arguments[2053]);
            set(valueRows, 6157, arguments[3077]);
            AggregateFrontendBindingPlan bindings = projectAggregateFrontendBindings(
              input,
              plan.operationCount,
              rows,
              plan.argumentCount,
              arguments,
              /* valueCount= */ 14,
              valueRows,
              plan.operationCount,
              statementRows,
              destinationLocals,
              ownerLocals,
              argumentLocals,
              placements
            );
            long ownerRow = 0;
            while (ownerRow < 256) limit 256 {
              set(ownerAggregates, ownerRow, -1);
              set(ownerCases, ownerRow, -1);
              set(sliceDescriptors, ownerRow, -1);
              ownerRow += 1;
            }
            set(ownerAggregates, 2, 0);
            set(ownerAggregates, 3, 3);
            set(ownerAggregates, 5, 1);
            set(ownerCases, 5, 0);
            set(ownerAggregates, 6, 0);
            set(sliceDescriptors, 4, 2);
            boolean targetsValid = resolveLocalAggregateConstructorTargets(
              input,
              plan.operationCount,
              rows,
              aggregatesPlan.aggregateCount,
              aggregates,
              aggregatesPlan.caseCount,
              cases,
              targets
            );
            boolean projectionsValid = resolveLocalAggregateProjectionTargets(
              input,
              plan.operationCount,
              rows,
              aggregatesPlan.aggregateCount,
              aggregates,
              aggregatesPlan.caseCount,
              cases,
              aggregatesPlan.memberCount,
              members,
              ownerAggregates,
              ownerCases,
              projectionTargets
            );
            boolean operandsValid = assembleAggregateResolvedOperands(
              plan.operationCount,
              rows,
              plan.argumentCount,
              arguments,
              argumentLocals,
              targets,
              projectionTargets,
              destinationLocals,
              ownerLocals,
              sliceDescriptors,
              resolved
            );
            operationCount = plan.operationCount;
            argumentCount = plan.argumentCount;
            if (aggregatesPlan.valid) {
              aggregatesValid = 1;
            }
            if (localNominals.valid) {
              localNominalReferenceCount = localNominals.referenceCount;
              if (0 < localNominals.referenceCount) {
                firstLocalNominalTarget = localNominalReferences[0];
                lastLocalNominalTarget =
                  localNominalReferences[localNominals.referenceCount - 1];
              }
            }
            if (localCarriers.valid) {
              localCarrierLength = localCarriers.length;
              firstLocalCarrierByte = localCarrierSource[localCarrierRows[1536]];
              firstVariantCarrierByte = localCarrierSource[localCarrierRows[1539]];
            }
            if (targetsValid) {
              targetsValidState = 1;
            }
            if (projectionsValid) {
              projectionsValidState = 1;
            }
            if (bindings.valid) {
              bindingsValidState = 1;
            }
            if (operandsValid) {
              operandsValidState = 1;
            }
            if (plan.valid) {
              assert(aggregatesPlan.valid);
              assert(localNominals.valid);
              assert(localCarriers.valid);
              assert(targetsValid);
              assert(projectionsValid);
              assert(bindings.valid);
              assert(operandsValid);
              valid = 1;
              firstKind = rows[0];
              secondKind = rows[1];
              thirdKind = rows[2];
              fourthKind = rows[3];
              fifthKind = rows[4];
              firstTypeStart = rows[256];
              firstTypeEnd = rows[256] + rows[512];
              caseStart = rows[769];
              caseEnd = rows[769] + rows[1025];
              memberStart = rows[770];
              memberEnd = rows[770] + rows[1026];
              firstArgumentStart = arguments[2048];
              firstArgumentEnd = arguments[2048] + arguments[3072];
              recordTarget = targets[256];
              variantTarget = targets[257];
              fieldTarget = projectionTargets[258];
              arrayTarget = projectionTargets[259];
              AggregateInstructionProductPlan product =
                writeResolvedSourceAggregateInstructions(plan.operationCount, rows, resolved, output);
              AggregateCompositionPlan composition = composeAggregateInstructionProducts(
                /* functionCount= */ 1,
                primitiveFunctions,
                /* primitiveInstructionCount= */ 1,
                primitiveInstructions,
                plan.operationCount,
                output,
                product.length,
                placements,
                composedFunctions,
                composedInstructions,
                artifactSelectors
              );
              assert(composition.valid);
              composedCount = composition.instructionCount;
              composedForwardLength = composedFunctions[192];
              firstArtifactSelector = artifactSelectors[0];
              secondArtifactSelector = artifactSelectors[1];
              region closure = new region(/* bytes= */ 7741440, /* allocations= */ 4);
              words moduleFirstFunctions = allocate(closure, /* length= */ 512);
              words moduleFunctionCounts = allocate(closure, /* length= */ 512);
              words closureFunctions = allocate(closure, /* length= */ 49152);
              words closureInstructions = allocate(closure, /* length= */ 917504);
              CountedFunctionWindow window = appendComposedFunctionProduct(
                /* moduleOwner= */ 0,
                /* primitiveArtifactRank= */ 0,
                /* aggregateArtifactRank= */ 1,
                /* functionCount= */ 1,
                composition.instructionCount,
                composedFunctions,
                composedInstructions,
                artifactSelectors,
                /* closureFunctionCount= */ 0,
                /* closureInstructionCount= */ 0,
                moduleFirstFunctions,
                moduleFunctionCounts,
                closureFunctions,
                closureInstructions
              );
              closureFunctionCount = window.functionCount;
              closureInstructionCount = window.instructionCount;
              primitiveArtifactRank = closureInstructions[262144];
              aggregateArtifactRank = closureInstructions[262145];
              region archival = new region(/* bytes= */ 16797704, /* allocations= */ 7);
              bytes primitiveCode = allocateBytes(archival, /* length= */ 8);
              words modulePublished = allocate(archival, /* length= */ 512);
              words moduleSupplementalPublished = allocate(archival, /* length= */ 512);
              words moduleArtifactRanks = allocate(archival, /* length= */ 512);
              words artifactStarts = allocate(archival, /* length= */ 512);
              words artifactLengths = allocate(archival, /* length= */ 512);
              bytes archive = allocateBytes(archival, /* length= */ 16777216);
              setByte(primitiveCode, 0, 0x01);
              setByte(primitiveCode, 4, 0x08);
              CompiledBodyArchivePlan primitivePlan = appendCompiledBodyArtifact(
                primitiveCode,
                /* artifactLength= */ 8,
                /* moduleOwner= */ 0,
                /* artifactCount= */ 0,
                /* archiveBytes= */ 0,
                modulePublished,
                moduleArtifactRanks,
                artifactStarts,
                artifactLengths,
                archive
              );
              CompiledBodyArchivePlan aggregatePlan = appendSupplementalBodyArtifact(
                output,
                product.length,
                /* moduleOwner= */ 0,
                primitivePlan.artifactCount,
                primitivePlan.archiveBytes,
                modulePublished,
                moduleSupplementalPublished,
                artifactStarts,
                artifactLengths,
                archive
              );
              linkedLength = emitLinkedInstructionCodeAt(
                archive,
                aggregatePlan.archiveBytes,
                artifactStarts,
                artifactLengths,
                window.functionCount,
                window.instructionCount,
                moduleFirstFunctions,
                moduleFunctionCounts,
                closureFunctions,
                closureInstructions,
                output,
                /* outputStart= */ 0
              );
              firstAggregateOpcode = output[8] + output[9] * 256;
              drop(archive);
              drop(artifactLengths);
              drop(artifactStarts);
              drop(moduleArtifactRanks);
              drop(moduleSupplementalPublished);
              drop(modulePublished);
              drop(primitiveCode);
              drop(archival);
              drop(closureInstructions);
              drop(closureFunctions);
              drop(moduleFunctionCounts);
              drop(moduleFirstFunctions);
              drop(closure);
              loweredCount = product.instructionCount;
              length = product.length;
              setOutputLength(output, linkedLength);
              assert(rows[0] != 91);
              assert(arguments[0] != 91);
            } else {
              assert(rows[0] == 91);
              assert(arguments[0] == 91);
              assert(destinationLocals[0] == 91);
              assert(placements[0] == 91);
              setOutputLength(output, 0);
            }
            drop(artifactSelectors);
            drop(composedInstructions);
            drop(composedFunctions);
            drop(placements);
            drop(primitiveInstructions);
            drop(primitiveFunctions);
            drop(resolved);
            drop(sliceDescriptors);
            drop(ownerLocals);
            drop(destinationLocals);
            drop(argumentLocals);
            drop(statementRows);
            drop(valueRows);
            drop(localCarrierSource);
            drop(localSourceStorage);
            drop(localCarrierRows);
            drop(localNominalReferences);
            drop(arguments);
            drop(rows);
            drop(ownerCases);
            drop(ownerAggregates);
            drop(projectionTargets);
            drop(targets);
            drop(members);
            drop(cases);
            drop(aggregates);
            drop(products);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_aggregate_operations");
  }

  private static List<Integer> opcodes(byte[] code) {
    ByteBuffer input = ByteBuffer.wrap(code).order(ByteOrder.LITTLE_ENDIAN);
    List<Integer> result = new ArrayList<>();
    while (input.hasRemaining()) {
      result.add(Short.toUnsignedInt(input.getShort()));
      int operands = Short.toUnsignedInt(input.getShort());
      int length = input.getInt();
      assertEquals(8 + operands * 8, length);
      input.position(input.position() + operands * 8);
    }
    return List.copyOf(result);
  }
}
