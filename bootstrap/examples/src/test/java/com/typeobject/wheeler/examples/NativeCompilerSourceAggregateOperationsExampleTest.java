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
            long piece = slice(values, index, 2)[0];
            Pair payload = selected.pair;
            long nested = payload.value;
            return member + element + piece + nested;
          }
        }
        """;
    VirtualMachine machine = new VirtualMachine(program(),
        source.getBytes(StandardCharsets.UTF_8), 272);

    machine.run();

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
    assertEquals(1, machine.global("targetsValidState"));
    assertEquals(1, machine.global("projectionsValidState"));
    assertEquals(1, machine.global("operandsValidState"));
    assertEquals(8, machine.global("composedCount"));
    assertEquals(280, machine.global("composedForwardLength"));
    assertEquals(0, machine.global("firstArtifactSelector"));
    assertEquals(1, machine.global("secondArtifactSelector"));
    assertEquals(1, machine.global("closureFunctionCount"));
    assertEquals(8, machine.global("closureInstructionCount"));
    assertEquals(5, machine.global("primitiveArtifactRank"));
    assertEquals(6, machine.global("aggregateArtifactRank"));
    assertEquals(0, machine.global("fieldTarget"));
    assertEquals(3, machine.global("arrayTarget"));
    assertEquals(
        List.of(0x0500, 0x0510, 0x0501, 0x0521, 0x0530, 0x0512, 0x0501),
        opcodes(machine.hostOutput()));
  }

  @Test
  void malformedConstructionPublishesNothing() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(),
        "new Pair(value".getBytes(StandardCharsets.UTF_8), 272);

    machine.run();

    assertEquals(0, machine.global("operationCount"));
    assertEquals(0, machine.global("valid"));
    assertArrayEquals(new byte[0], machine.hostOutput());
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
        "wheeler.compiler.closure.aggregate_resolved_operands"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.counted_function_products"));
    sources.put("SourceAggregateOperationsExample.w", """
        module example.source_aggregate_operations;

        import wheeler.compiler.closure.aggregate_constructor_targets;
        import wheeler.compiler.closure.aggregate_instruction_composition;
        import wheeler.compiler.closure.aggregate_instruction_products;
        import wheeler.compiler.closure.aggregate_projection_targets;
        import wheeler.compiler.closure.aggregate_resolved_operands;
        import wheeler.compiler.closure.counted_function_products;
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
          state long recordTarget = -1;
          state long variantTarget = -1;
          state long aggregatesValid = 0;
          state long targetsValidState = 0;
          state long projectionsValidState = 0;
          state long operandsValidState = 0;
          state long fieldTarget = -1;
          state long arrayTarget = -1;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 564736, /* allocations= */ 20);
            words aggregates = allocate(products, /* length= */ 832);
            words cases = allocate(products, /* length= */ 640);
            words members = allocate(products, /* length= */ 2048);
            words targets = allocate(products, /* length= */ 768);
            words projectionTargets = allocate(products, /* length= */ 1024);
            words ownerAggregates = allocate(products, /* length= */ 256);
            words ownerCases = allocate(products, /* length= */ 256);
            words rows = allocate(products, /* length= */ 2048);
            words arguments = allocate(products, /* length= */ 4096);
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
            long placedOperation = 0;
            while (placedOperation < 7) limit 7 {
              set(placements, 512 + placedOperation, 1);
              placedOperation += 1;
            }
            set(rows, 0, 91);
            set(arguments, 0, 91);
            SourceAggregateProductPlan aggregatesPlan =
              materializeSourceAggregateProducts(input, aggregates, cases, members);
            SourceAggregateOperationPlan plan =
              materializeSourceAggregateOperations(input, rows, arguments);
            long ownerRow = 0;
            while (ownerRow < 256) limit 256 {
              set(ownerAggregates, ownerRow, -1);
              set(ownerCases, ownerRow, -1);
              set(destinationLocals, ownerRow, -1);
              set(ownerLocals, ownerRow, -1);
              set(sliceDescriptors, ownerRow, -1);
              ownerRow += 1;
            }
            set(ownerAggregates, 2, 0);
            set(ownerAggregates, 3, 3);
            set(ownerAggregates, 5, 1);
            set(ownerCases, 5, 0);
            set(ownerAggregates, 6, 0);
            set(destinationLocals, 0, 3);
            set(destinationLocals, 1, 4);
            set(destinationLocals, 2, 5);
            set(destinationLocals, 3, 6);
            set(destinationLocals, 4, 9);
            set(destinationLocals, 5, 11);
            set(destinationLocals, 6, 12);
            set(ownerLocals, 2, 2);
            set(ownerLocals, 3, 7);
            set(ownerLocals, 5, 4);
            set(ownerLocals, 6, 11);
            set(sliceDescriptors, 4, 2);
            set(argumentLocals, 0, 10);
            set(argumentLocals, 1, 11);
            set(argumentLocals, 2, 8);
            set(argumentLocals, 3, 7);
            set(argumentLocals, 4, 8);
            set(argumentLocals, 5, 10);
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
            if (targetsValid) {
              targetsValidState = 1;
            }
            if (projectionsValid) {
              projectionsValidState = 1;
            }
            if (operandsValid) {
              operandsValidState = 1;
            }
            if (plan.valid) {
              assert(aggregatesPlan.valid);
              assert(targetsValid);
              assert(projectionsValid);
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
                /* primitiveArtifactRank= */ 5,
                /* aggregateArtifactRank= */ 6,
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
              drop(closureInstructions);
              drop(closureFunctions);
              drop(moduleFunctionCounts);
              drop(moduleFirstFunctions);
              drop(closure);
              loweredCount = product.instructionCount;
              length = product.length;
              setOutputLength(output, product.length);
              assert(rows[0] != 91);
              assert(arguments[0] != 91);
            } else {
              assert(rows[0] == 91);
              assert(arguments[0] == 91);
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
