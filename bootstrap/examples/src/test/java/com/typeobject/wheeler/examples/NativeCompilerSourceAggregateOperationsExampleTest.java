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
    assertEquals(7, machine.global("loweredCount"));
    assertEquals(272, machine.global("length"));
    assertEquals(0, machine.global("recordTarget"));
    assertEquals(1, machine.global("variantTarget"));
    assertEquals(1, machine.global("aggregatesValid"));
    assertEquals(1, machine.global("targetsValidState"));
    assertEquals(1, machine.global("projectionsValidState"));
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
    sources.put("SourceAggregateOperationsExample.w", """
        module example.source_aggregate_operations;

        import wheeler.compiler.closure.aggregate_constructor_targets;
        import wheeler.compiler.closure.aggregate_instruction_products;
        import wheeler.compiler.closure.aggregate_projection_targets;
        import wheeler.compiler.closure.resolved_aggregate_operations;
        import wheeler.compiler.closure.source_aggregate_operations;
        import wheeler.compiler.closure.source_aggregate_products;

        classical class SourceAggregateOperationsExample {
          state long operationCount = 0;
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
          state long loweredCount = 0;
          state long length = 0;
          state long recordTarget = -1;
          state long variantTarget = -1;
          state long aggregatesValid = 0;
          state long targetsValidState = 0;
          state long projectionsValidState = 0;
          state long fieldTarget = -1;
          state long arrayTarget = -1;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 75264, /* allocations= */ 9);
            words aggregates = allocate(products, /* length= */ 832);
            words cases = allocate(products, /* length= */ 640);
            words members = allocate(products, /* length= */ 2048);
            words targets = allocate(products, /* length= */ 768);
            words projectionTargets = allocate(products, /* length= */ 1024);
            words ownerAggregates = allocate(products, /* length= */ 256);
            words ownerCases = allocate(products, /* length= */ 256);
            words rows = allocate(products, /* length= */ 2048);
            words resolved = allocate(products, /* length= */ 1536);
            set(rows, 0, 91);
            SourceAggregateProductPlan aggregatesPlan =
              materializeSourceAggregateProducts(input, aggregates, cases, members);
            SourceAggregateOperationPlan plan = materializeSourceAggregateOperations(input, rows);
            long ownerRow = 0;
            while (ownerRow < 256) limit 256 {
              set(ownerAggregates, ownerRow, -1);
              set(ownerCases, ownerRow, -1);
              ownerRow += 1;
            }
            set(ownerAggregates, 2, 0);
            set(ownerAggregates, 3, 3);
            set(ownerAggregates, 5, 1);
            set(ownerCases, 5, 0);
            set(ownerAggregates, 6, 0);
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
            operationCount = plan.operationCount;
            if (aggregatesPlan.valid) {
              aggregatesValid = 1;
            }
            if (targetsValid) {
              targetsValidState = 1;
            }
            if (projectionsValid) {
              projectionsValidState = 1;
            }
            if (plan.valid) {
              assert(aggregatesPlan.valid);
              assert(targetsValid);
              assert(projectionsValid);
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
              recordTarget = targets[256];
              variantTarget = targets[257];
              fieldTarget = projectionTargets[258];
              arrayTarget = projectionTargets[259];
              set(resolved, 0, targets[0]);
              set(resolved, 1, targets[1]);
              set(resolved, 2, projectionTargets[2]);
              set(resolved, 3, projectionTargets[3]);
              set(resolved, 4, 0x0530);
              set(resolved, 5, projectionTargets[5]);
              set(resolved, 6, projectionTargets[6]);
              set(resolved, 256, 3);
              set(resolved, 257, 4);
              set(resolved, 258, 5);
              set(resolved, 259, 6);
              set(resolved, 260, 9);
              set(resolved, 261, 11);
              set(resolved, 262, 12);
              set(resolved, 512, targets[256]);
              set(resolved, 513, targets[257]);
              set(resolved, 514, 2);
              set(resolved, 515, 7);
              set(resolved, 516, 2);
              set(resolved, 517, 4);
              set(resolved, 518, 11);
              set(resolved, 768, 10);
              set(resolved, 769, targets[513]);
              set(resolved, 770, projectionTargets[770]);
              set(resolved, 771, 8);
              set(resolved, 772, 7);
              set(resolved, 773, projectionTargets[517]);
              set(resolved, 774, projectionTargets[774]);
              set(resolved, 1024, 1);
              set(resolved, 1025, 11);
              set(resolved, 1027, 0);
              set(resolved, 1028, 8);
              set(resolved, 1029, projectionTargets[773]);
              set(resolved, 1281, 1);
              set(resolved, 1284, 10);
              AggregateInstructionProductPlan product =
                writeResolvedSourceAggregateInstructions(plan.operationCount, rows, resolved, output);
              loweredCount = product.instructionCount;
              length = product.length;
              setOutputLength(output, product.length);
              assert(rows[0] != 91);
            } else {
              assert(rows[0] == 91);
              setOutputLength(output, 0);
            }
            drop(resolved);
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
