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

/** Native evidence that generated aggregate scaffolding never reaches closure rows. */
final class NativeCompilerGeneratedAggregateExclusionExampleTest {
  private static final String SOURCE = """
      classical class Root {
        public record Local(long value) {}
        entry void main() {}
        private record WheelerNominal3(long value) {}
        private variant WheelerNominal8 { case Value(long value); }
      }
      """;

  @Test
  void retainsOnlyTheLocalAggregatePrefix() throws Exception {
    VirtualMachine machine = machine(2);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("moduleCount"));
    assertEquals(1, machine.global("aggregateCount"));
    assertEquals(0, machine.global("caseCount"));
    assertEquals(1, machine.global("memberCount"));
    assertEquals(1, machine.global("firstKind"));
    assertEquals(1, machine.global("processed"));
  }

  @Test
  void rejectsASuffixThatWouldTruncateLocalMembersBeforeMutation() throws Exception {
    VirtualMachine machine = machine(3);

    assertThrows(
        VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("processed"));
    assertEquals(91, machine.global("firstKind"));
  }

  private static VirtualMachine machine(int generatedMembers) throws Exception {
    byte[] artifact = new BytecodeWriter().write(new WheelerCompiler().compile(SOURCE));
    return VirtualMachine.withBinaryInput(program(generatedMembers), artifact);
  }

  private static Program program(int generatedMembers) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.counted_aggregate_layouts"));
    sources.put("GeneratedAggregateExclusionExample.w", """
        module example.generated_aggregate_exclusion;

        import wheeler.compiler.closure.counted_aggregate_layouts;

        classical class GeneratedAggregateExclusionExample {
          state long moduleCount = 0;
          state long aggregateCount = 0;
          state long caseCount = 0;
          state long memberCount = 0;
          state long firstKind = 91;
          state long processed = 0;

          entry void main(borrow byteview input) {
            region rows = new region(/* bytes= */ 1085440, /* allocations= */ 4);
            words processedModules = allocate(rows, /* length= */ 512);
            words aggregates = allocate(rows, /* length= */ 36864);
            words cases = allocate(rows, /* length= */ 32768);
            words members = allocate(rows, /* length= */ 65536);
            CountedAggregateLayoutPlan plan = appendCompiledAggregateLayouts(
              input,
              bufferLength(input),
              /* owner= */ 0,
              /* moduleCount= */ 0,
              /* aggregateCount= */ 0,
              /* caseCount= */ 0,
              /* memberCount= */ 0,
              /* generatedAggregateCount= */ 2,
              /* generatedCaseCount= */ 1,
              /* generatedMemberCount= */ %d,
              processedModules,
              aggregates,
              cases,
              members
            );
            moduleCount = plan.moduleCount;
            aggregateCount = plan.aggregateCount;
            caseCount = plan.caseCount;
            memberCount = plan.memberCount;
            firstKind = aggregates[0];
            processed = processedModules[0];
            drop(members);
            drop(cases);
            drop(aggregates);
            drop(processedModules);
            drop(rows);
          }
        }
        """.formatted(generatedMembers));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.generated_aggregate_exclusion");
  }
}
