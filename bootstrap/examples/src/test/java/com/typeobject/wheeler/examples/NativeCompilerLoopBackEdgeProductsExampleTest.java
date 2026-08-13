package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for loop ownership and loan back-edge joins. */
final class NativeCompilerLoopBackEdgeProductsExampleTest {
  @Test
  void acceptsMatchingStateAndLoansReleasedInsideTheBody() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false, false));

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(1, machine.global("loopCount"));
  }

  @Test
  void rejectsChangedOwnershipAndEscapingLoansAtomically() throws Exception {
    for (TestCase testCase : new TestCase[] {
        new TestCase(true, false), new TestCase(false, true)
    }) {
      VirtualMachine machine = new VirtualMachine(
          program(testCase.changedState(), testCase.escapingLoan()));

      machine.run();

      assertEquals(0, machine.global("valid"));
      assertEquals(0, machine.global("loopCount"));
    }
  }

  private static Program program(boolean changedState, boolean escapingLoan) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.loop_back_edge_products"));
    sources.put("LoopBackEdgeProductsExample.w", """
        module example.loop_back_edge_products;

        import wheeler.compiler.closure.loop_back_edge_products;

        classical class LoopBackEdgeProductsExample {
          state long valid = 0;
          state long loopCount = 0;

          entry void main() {
            region products = new region(/* bytes= */ 543744, /* allocations= */ 10);
            words loops = allocate(products, /* length= */ 2304);
            words instructionStarts = allocate(products, /* length= */ 256);
            words instructionCounts = allocate(products, /* length= */ 256);
            words stateStarts = allocate(products, /* length= */ 256);
            words stateCounts = allocate(products, /* length= */ 256);
            words entryStates = allocate(products, /* length= */ 8192);
            words backEdgeStates = allocate(products, /* length= */ 8192);
            words events = allocate(products, /* length= */ 40960);
            words unused0 = allocate(products, /* length= */ 1);
            words unused1 = allocate(products, /* length= */ 1);
            set(loops, 0, 0);
            set(instructionStarts, 0, 8);
            set(instructionCounts, 0, 5);
            set(stateStarts, 0, 0);
            set(stateCounts, 0, 1);
            set(entryStates, 0, 7);
            set(entryStates, 4096, 1);
            set(backEdgeStates, 0, CHANGED_STATE);
            set(backEdgeStates, 4096, 1);
            set(events, 0, 2);
            set(events, 8192, 9);
            set(events, 16384, 0);
            set(events, 24576, 12);
            set(events, 32768, 3);
            set(events, 1, 3);
            set(events, 8193, RELEASE_INSTRUCTION);
            set(events, 16385, 0);
            set(events, 24577, 12);
            set(events, 32769, 3);
            LoopBackEdgePlan plan = validateLoopBackEdges(
              /* loopCount= */ 1,
              loops,
              instructionStarts,
              instructionCounts,
              stateStarts,
              stateCounts,
              /* stateCount= */ 1,
              entryStates,
              backEdgeStates,
              /* eventCount= */ 2,
              events
            );
            if (plan.valid) {
              valid = 1;
            }
            loopCount = plan.loopCount;
            drop(unused1);
            drop(unused0);
            drop(events);
            drop(backEdgeStates);
            drop(entryStates);
            drop(stateCounts);
            drop(stateStarts);
            drop(instructionCounts);
            drop(instructionStarts);
            drop(loops);
            drop(products);
          }
        }
        """.replace("CHANGED_STATE", changedState ? "8" : "7")
            .replace("RELEASE_INSTRUCTION", escapingLoan ? "13" : "11"));
    return new WheelerCompiler().compileModuleFiles(sources, "example.loop_back_edge_products");
  }

  private record TestCase(boolean changedState, boolean escapingLoan) {}
}
