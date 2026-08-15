package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for qualified imported source-call selection. */
final class NativeCompilerQualifiedSourceCallProductsExampleTest {
  @Test
  void selectsOneOfTwoEqualImportedNames() throws Exception {
    Program program = program();
    VirtualMachine alpha = machine(program, "alpha.beta::run(value)");
    VirtualMachine zeta = machine(program, "zeta::run(value)");

    alpha.run();
    zeta.run();

    assertEquals(1, alpha.global("valid"));
    assertEquals(1, alpha.global("callCount"));
    assertEquals(1, alpha.global("target"));
    assertEquals(2, zeta.global("target"));
  }

  @Test
  void rejectsMalformedQualificationBeforePublication() throws Exception {
    Program program = program();
    VirtualMachine dotted = machine(program, "alpha..beta::run(value)");
    VirtualMachine spaced = machine(program, "alpha.beta:: run(value)");
    VirtualMachine uppercase = machine(program, "Alpha.beta::run(value)");

    dotted.run();
    spaced.run();
    uppercase.run();

    assertEquals(0, dotted.global("valid"));
    assertEquals(77, dotted.global("target"));
    assertEquals(0, spaced.global("valid"));
    assertEquals(77, spaced.global("target"));
    assertEquals(0, uppercase.global("valid"));
    assertEquals(77, uppercase.global("target"));
  }

  @Test
  void leavesUnqualifiedCallsForTheOrdinaryScanner() throws Exception {
    VirtualMachine machine = machine(program(), "run(value)");

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(0, machine.global("callCount"));
    assertEquals(77, machine.global("target"));
  }

  private static VirtualMachine machine(Program program, String source) {
    return new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8));
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.qualified_source_call_products"));
    sources.put("QualifiedSourceCallProductsExample.w", """
        module example.qualified_source_call_products;

        import wheeler.compiler.closure.qualified_source_call_products;

        classical class QualifiedSourceCallProductsExample {
          state long valid = 0;
          state long callCount = 0;
          state long target = 0;

          entry void main(borrow utf8 input) {
            region products = new region(/* bytes= */ 1277958, /* allocations= */ 8);
            bytes callableNames = allocateBytes(products, /* length= */ 9);
            words callableNameStarts = allocate(products, /* length= */ 4096);
            words callableNameLengths = allocate(products, /* length= */ 4096);
            words callableParameterCounts = allocate(products, /* length= */ 4096);
            bytes qualifierNames = allocateBytes(products, /* length= */ 1048576);
            words qualifierNameStarts = allocate(products, /* length= */ 4096);
            words qualifierNameLengths = allocate(products, /* length= */ 4096);
            words qualifierRanks = allocate(products, /* length= */ 4096);
            writeAscii(callableNames, 0, "runrunrun");
            set(callableNameLengths, 0, 3);
            set(callableNameStarts, 1, 3);
            set(callableNameLengths, 1, 3);
            set(callableParameterCounts, 1, 1);
            set(callableNameStarts, 2, 6);
            set(callableNameLengths, 2, 3);
            set(callableParameterCounts, 2, 1);
            writeAscii(qualifierNames, 0, "alpha.betazeta");
            set(qualifierNameLengths, 0, 10);
            set(qualifierNameStarts, 1, 10);
            set(qualifierNameLengths, 1, 4);
            set(qualifierRanks, 0, 2);
            set(qualifierRanks, 1, 5);
            region ranks = new region(/* bytes= */ 32768, /* allocations= */ 1);
            words callableRanks = allocate(ranks, /* length= */ 4096);
            set(callableRanks, 0, 2);
            set(callableRanks, 1, 5);
            region output = new region(/* bytes= */ 8192, /* allocations= */ 1);
            words calls = allocate(output, /* length= */ 1024);
            set(calls, 768, 77);
            QualifiedSourceCallPlan plan = resolveQualifiedSourceCallProducts(
              input,
              /* bodyStart= */ 0,
              bufferLength(input),
              callableNames,
              /* firstImportedCallable= */ 1,
              /* importedCallableCount= */ 2,
              callableNameStarts,
              callableNameLengths,
              callableParameterCounts,
              qualifierNames,
              qualifierNameStarts,
              qualifierNameLengths,
              qualifierRanks,
              callableRanks,
              calls
            );
            if (plan.valid) {
              valid = 1;
            }
            callCount = plan.callCount;
            target = calls[768];
            drop(calls);
            drop(output);
            drop(callableRanks);
            drop(ranks);
            drop(qualifierRanks);
            drop(qualifierNameLengths);
            drop(qualifierNameStarts);
            drop(qualifierNames);
            drop(callableParameterCounts);
            drop(callableNameLengths);
            drop(callableNameStarts);
            drop(callableNames);
            drop(products);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.qualified_source_call_products");
  }
}
