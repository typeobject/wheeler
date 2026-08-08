package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for counted semantic aggregate-layout products. */
final class NativeCompilerAggregateProductsExampleTest {
  @Test
  void decodesRecordArrayAndVariantLayoutsFromCanonicalBytecode() throws Exception {
    byte[] artifact = aggregateArtifact();
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(), artifact);

    machine.run();

    assertEquals(3, machine.global("aggregateCount"));
    assertEquals(2, machine.global("caseCount"));
    assertEquals(4, machine.global("memberCount"));
    assertEquals(1, machine.global("firstKind"));
    assertEquals(2, machine.global("secondKind"));
    assertEquals(4, machine.global("lastKind"));
    assertEquals(3, machine.global("arrayLength"));
    assertEquals(1, machine.global("firstOwner"));
  }

  @Test
  void rejectsMalformedContainersBeforePublishingCounts() throws Exception {
    byte[] malformed = aggregateArtifact();
    malformed[0] = 0;
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(), malformed);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
  }

  private static Program decoder() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_aggregate_layouts"));
    sources.put("AggregateProductsExample.w", """
        module example.aggregate_products;

        import wheeler.compiler.closure.compiled_aggregate_layouts;

        classical class AggregateProductsExample {
          state long aggregateCount = 0;
          state long caseCount = 0;
          state long memberCount = 0;
          state long firstKind = 0;
          state long secondKind = 0;
          state long lastKind = 0;
          state long arrayLength = 0;
          state long firstOwner = 0;
          state long published = 0;

          entry void main(borrow byteview source) {
            region rows = new region(/* bytes= */ 16896, /* allocations= */ 3);
            words aggregates = allocate(rows, /* length= */ 576);
            words cases = allocate(rows, /* length= */ 512);
            words members = allocate(rows, /* length= */ 1024);
            CompiledAggregatePlan plan = indexCompiledAggregateLayouts(
              source,
              bufferLength(source),
              /* owner= */ 1,
              aggregates,
              cases,
              members
            );
            aggregateCount = plan.aggregateCount;
            caseCount = plan.caseCount;
            memberCount = plan.memberCount;
            firstKind = aggregates[0];
            secondKind = aggregates[1];
            lastKind = aggregates[plan.aggregateCount - 1];
            arrayLength = aggregates[512 + 1];
            firstOwner = aggregates[64];
            published = 1;
            drop(members);
            drop(cases);
            drop(aggregates);
            drop(rows);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.aggregate_products");
  }

  private static byte[] aggregateArtifact() {
    String source = """
        module fixture.aggregate_products;

        classical class AggregateProducts {
          record Pair(long left, boolean ready) {}

          variant Choice {
            case Empty();
            case Value(long item);
          }

          entry void main() {
            Pair pair = new Pair(4, true);
            long[3] values = new long[3](1, 2, 3);
            Choice choice = new Choice.Value(pair.left);
            assert(values[1] == 2);
            match (choice) {
              case Choice.Empty() {
                assert(false);
              }
              case Choice.Value(long item) {
                assert(item == 4);
              }
            }
          }
        }
        """;
    Program program = new WheelerCompiler().compileModuleFiles(
        Map.of("AggregateProducts.w", source),
        "fixture.aggregate_products");
    return new BytecodeWriter().write(program);
  }
}
