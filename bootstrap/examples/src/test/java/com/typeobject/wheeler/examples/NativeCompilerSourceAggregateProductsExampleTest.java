package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for source-local aggregate products. */
final class NativeCompilerSourceAggregateProductsExampleTest {
  @Test
  void publishesRecursiveRecordProductsWithoutCompiledArtifacts() throws Exception {
    String source = """
        classical class Root {
          public record Node(long value, Node next) {}
          private record Pair(boolean ready, Node node) {}
        }
        """;
    VirtualMachine machine = machine(source);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("productValid"));
    assertEquals(2, machine.global("aggregateCount"));
    assertEquals(4, machine.global("memberCount"));
    assertEquals(source.indexOf("Node"), machine.global("firstNameStart"));
    assertEquals(source.indexOf("Pair"), machine.global("secondNameStart"));
    assertEquals(0, machine.global("firstMember"));
    assertEquals(2, machine.global("secondMember"));
    assertEquals(2, machine.global("firstMemberCount"));
    assertEquals(2, machine.global("secondMemberCount"));
    assertEquals(1, machine.global("firstVisibility"));
    assertEquals(0, machine.global("secondVisibility"));
    assertEquals(source.indexOf("long"), machine.global("firstTypeStart"));
    assertEquals(4, machine.global("firstTypeLength"));
    assertEquals(source.indexOf("boolean"), machine.global("thirdTypeStart"));
    assertEquals(7, machine.global("thirdTypeLength"));
    assertEquals(0, machine.global("firstTypeKind"));
    assertEquals(1, machine.global("firstTypeValue"));
    assertEquals(1, machine.global("secondTypeKind"));
    assertEquals(0, machine.global("secondTypeValue"));
    assertEquals(0, machine.global("thirdTypeKind"));
    assertEquals(2, machine.global("thirdTypeValue"));
  }

  @Test
  void leavesCallerRowsUntouchedWhenARecordMemberIsMalformed() throws Exception {
    String source = "classical class Root { public record Broken(long) {} }";
    VirtualMachine machine = machine(source);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(0, machine.global("productValid"));
    assertEquals(91, machine.global("firstNameStart"));
    assertEquals(73, machine.global("firstMemberOwner"));
  }

  @Test
  void rejectsUnresolvedMemberTypesBeforePublication() throws Exception {
    String source = "classical class Root { public record Broken(Missing value) {} }";
    VirtualMachine machine = machine(source);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(0, machine.global("productValid"));
    assertEquals(91, machine.global("firstNameStart"));
    assertEquals(73, machine.global("firstMemberOwner"));
  }

  private static VirtualMachine machine(String source) throws Exception {
    return new VirtualMachine(program(), source.getBytes(StandardCharsets.UTF_8));
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_aggregate_products"));
    sources.put("SourceAggregateProductsExample.w", """
        module example.source_aggregate_products;

        import wheeler.compiler.closure.source_aggregate_products;

        classical class SourceAggregateProductsExample {
          state long productValid = 0;
          state long aggregateCount = 0;
          state long memberCount = 0;
          state long firstNameStart = 0;
          state long secondNameStart = 0;
          state long firstMember = 0;
          state long secondMember = 0;
          state long firstMemberCount = 0;
          state long secondMemberCount = 0;
          state long firstVisibility = 0;
          state long secondVisibility = 0;
          state long firstTypeStart = 0;
          state long firstTypeLength = 0;
          state long thirdTypeStart = 0;
          state long thirdTypeLength = 0;
          state long firstMemberOwner = 0;
          state long firstTypeKind = 0;
          state long firstTypeValue = 0;
          state long secondTypeKind = 0;
          state long secondTypeValue = 0;
          state long thirdTypeKind = 0;
          state long thirdTypeValue = 0;

          entry void main(borrow utf8 input) {
            region rows = new region(/* bytes= */ 17408, /* allocations= */ 2);
            words aggregates = allocate(rows, /* length= */ 384);
            words members = allocate(rows, /* length= */ 1792);
            set(aggregates, 0, 91);
            set(members, 0, 73);
            SourceAggregateProductPlan product = materializeSourceRecordProducts(
              input,
              aggregates,
              members
            );
            if (product.valid) {
              productValid = 1;
            }
            aggregateCount = product.aggregateCount;
            memberCount = product.memberCount;
            firstNameStart = aggregates[0];
            secondNameStart = aggregates[1];
            firstMember = aggregates[128];
            secondMember = aggregates[129];
            firstMemberCount = aggregates[192];
            secondMemberCount = aggregates[193];
            firstVisibility = aggregates[256];
            secondVisibility = aggregates[257];
            firstTypeStart = members[768];
            firstTypeLength = members[1024];
            thirdTypeStart = members[770];
            thirdTypeLength = members[1026];
            firstMemberOwner = members[0];
            firstTypeKind = members[1280];
            firstTypeValue = members[1536];
            secondTypeKind = members[1281];
            secondTypeValue = members[1537];
            thirdTypeKind = members[1282];
            thirdTypeValue = members[1538];
            drop(members);
            drop(aggregates);
            drop(rows);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.source_aggregate_products");
  }
}
