package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
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
          variant Choice { Some(Pair pair) }
          private long read(Pair pair, long[4] values, long index) {
            Pair made = new Pair(index);
            Choice selected = new Choice.Some(made);
            long member = pair.value;
            long element = values[index];
            long piece = slice(values, index, 2)[0];
            return member + element + piece;
          }
        }
        """;
    VirtualMachine machine = new VirtualMachine(program(),
        source.getBytes(StandardCharsets.UTF_8), 40);

    machine.run();

    assertEquals(5, machine.global("operationCount"));
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
  }

  @Test
  void malformedConstructionPublishesNothing() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(),
        "new Pair(value".getBytes(StandardCharsets.UTF_8), 40);

    machine.run();

    assertEquals(0, machine.global("operationCount"));
    assertEquals(0, machine.global("valid"));
    assertArrayEquals(new byte[0], machine.hostOutput());
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_aggregate_operations"));
    sources.put("SourceAggregateOperationsExample.w", """
        module example.source_aggregate_operations;

        import wheeler.compiler.closure.source_aggregate_operations;

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

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 16384, /* allocations= */ 1);
            words rows = allocate(products, /* length= */ 2048);
            set(rows, 0, 91);
            SourceAggregateOperationPlan plan = materializeSourceAggregateOperations(input, rows);
            operationCount = plan.operationCount;
            if (plan.valid) {
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
            }
            if (plan.valid) {
              assert(rows[0] != 91);
            } else {
              assert(rows[0] == 91);
            }
            setOutputLength(output, 0);
            drop(rows);
            drop(products);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_aggregate_operations");
  }
}
