package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for pre-coordinate source-call layouts. */
final class NativeCompilerSourceCallLayoutProductsExampleTest {
  @Test
  void validatesMeasuredWidthsAgainstTypedCallLayouts() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false), new byte[0]);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(3, machine.global("callCount"));
    assertEquals(6, machine.global("localTypeCount"));
    assertEquals(1, machine.global("firstKind"));
    assertEquals(2, machine.global("secondKind"));
    assertEquals(0, machine.global("thirdKind"));
    assertEquals(4, machine.global("firstWidth"));
    assertEquals(2, machine.global("secondWidth"));
    assertEquals(0, machine.global("thirdWidth"));
    assertEquals(3, machine.global("firstOwner"));
  }

  @Test
  void rejectsTypeMismatchBeforeWidthPublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true), new byte[0]);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(2, machine.global("firstWidth"));
    assertEquals(91, machine.global("firstKind"));
    assertEquals(92, machine.global("firstCallWidth"));
  }

  private static Program program(boolean mismatch) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_call_layout_products"));
    sources.put("SourceCallLayoutProductsExample.w", """
        module example.source_call_layout_products;

        import wheeler.compiler.closure.source_call_layout_products;

        classical class SourceCallLayoutProductsExample {
          state long valid = 0;
          state long callCount = 0;
          state long localTypeCount = 0;
          state long firstKind = 0;
          state long secondKind = 0;
          state long thirdKind = 0;
          state long firstWidth = 0;
          state long secondWidth = 0;
          state long thirdWidth = 0;
          state long firstOwner = 0;
          state long firstCallWidth = 0;

          entry void main(borrow utf8 input) {
            assert(bufferLength(input) == 0);
            region rows = new region(/* bytes= */ 544768, /* allocations= */ 13);
            words sourceCalls = allocate(rows, /* length= */ 1024);
            words callStatements = allocate(rows, /* length= */ 256);
            words argumentStarts = allocate(rows, /* length= */ 256);
            words argumentCounts = allocate(rows, /* length= */ 256);
            words arguments = allocate(rows, /* length= */ 3584);
            words targetParameterStarts = allocate(rows, /* length= */ 4096);
            words targetParameterCounts = allocate(rows, /* length= */ 4096);
            words targetParameterTypes = allocate(rows, /* length= */ 16384);
            words targetResultTypes = allocate(rows, /* length= */ 4096);
            words statements = allocate(rows, /* length= */ 28672);
            words statementWidths = allocate(rows, /* length= */ 4096);
            words resolvedCalls = allocate(rows, /* length= */ 1024);
            words callWidths = allocate(rows, /* length= */ 256);
            set(sourceCalls, 0, 10);
            set(sourceCalls, 768, 0);
            set(sourceCalls, 1, 20);
            set(sourceCalls, 769, 1);
            set(sourceCalls, 2, 30);
            set(sourceCalls, 770, 2);
            set(callStatements, 0, 0);
            set(callStatements, 1, 1);
            set(callStatements, 2, 2);
            set(argumentStarts, 0, 0);
            set(argumentCounts, 0, 1);
            set(argumentStarts, 1, 1);
            set(argumentStarts, 2, 1);
            set(arguments, 1792, ARGUMENT_TYPE);
            set(targetParameterCounts, 0, 1);
            set(targetParameterTypes, 0, 1);
            set(targetResultTypes, 0, 1);
            set(targetResultTypes, 1, 2);
            set(statements, 0, 3);
            set(statements, 1, 4);
            set(statements, 2, 5);
            set(statementWidths, 0, FIRST_WIDTH);
            set(statementWidths, 1, 2);
            set(resolvedCalls, 256, 91);
            set(callWidths, 0, 92);
            SourceCallLayoutPlan plan = materializeSourceCallLayoutProducts(
              /* callCount= */ 3,
              sourceCalls,
              callStatements,
              argumentStarts,
              argumentCounts,
              arguments,
              /* targetCount= */ 3,
              targetParameterStarts,
              targetParameterCounts,
              targetParameterTypes,
              targetResultTypes,
              statements,
              statementWidths,
              resolvedCalls,
              callWidths
            );
            if (plan.valid) {
              valid = 1;
            }
            callCount = plan.callCount;
            localTypeCount = plan.localTypeCount;
            firstKind = resolvedCalls[256];
            secondKind = resolvedCalls[257];
            thirdKind = resolvedCalls[258];
            firstWidth = statementWidths[0];
            secondWidth = statementWidths[1];
            thirdWidth = statementWidths[2];
            firstOwner = resolvedCalls[0];
            firstCallWidth = callWidths[0];
            drop(callWidths);
            drop(resolvedCalls);
            drop(statementWidths);
            drop(statements);
            drop(targetResultTypes);
            drop(targetParameterTypes);
            drop(targetParameterCounts);
            drop(targetParameterStarts);
            drop(arguments);
            drop(argumentCounts);
            drop(argumentStarts);
            drop(callStatements);
            drop(sourceCalls);
            drop(rows);
          }
        }
        """.replace("ARGUMENT_TYPE", mismatch ? "2" : "1")
            .replace("FIRST_WIDTH", mismatch ? "2" : "4"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_call_layout_products");
  }
}
