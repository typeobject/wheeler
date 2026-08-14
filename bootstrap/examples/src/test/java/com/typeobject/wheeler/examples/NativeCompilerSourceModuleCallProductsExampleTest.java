package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for module-wide source-call collection. */
final class NativeCompilerSourceModuleCallProductsExampleTest {
  private static final byte[] SOURCE =
      "foo(){bar()} bar(){foo()}".getBytes(StandardCharsets.UTF_8);

  @Test
  void collectsAbsoluteCallsInCallableOrder() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false), SOURCE);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(2, machine.global("callCount"));
    assertEquals(6, machine.global("firstStart"));
    assertEquals(1, machine.global("firstTarget"));
    assertEquals(0, machine.global("firstStatement"));
    assertEquals(19, machine.global("secondStart"));
    assertEquals(0, machine.global("secondTarget"));
    assertEquals(1, machine.global("secondStatement"));
  }

  @Test
  void rejectsDetachedModuleCallsAtomically() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true), SOURCE);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("callCount"));
    assertEquals(77, machine.global("firstStart"));
    assertEquals(78, machine.global("firstStatement"));
  }

  private static Program program(boolean detached) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_module_call_products"));
    sources.put("SourceModuleCallProductsExample.w", """
        module example.source_module_call_products;

        import wheeler.compiler.closure.source_module_call_products;

        classical class SourceModuleCallProductsExample {
          state long valid = 0;
          state long callCount = 0;
          state long firstStart = 0;
          state long firstTarget = 0;
          state long firstStatement = 0;
          state long secondStart = 0;
          state long secondTarget = 0;
          state long secondStatement = 0;

          entry void main(borrow utf8 input) {
            region rows = new region(/* bytes= */ 403470, /* allocations= */ 10);
            words bodyStarts = allocate(rows, /* length= */ 4096);
            words bodyLengths = allocate(rows, /* length= */ 4096);
            bytes names = allocateBytes(rows, /* length= */ 6);
            words nameStarts = allocate(rows, /* length= */ 4096);
            words nameLengths = allocate(rows, /* length= */ 4096);
            words parameterCounts = allocate(rows, /* length= */ 4096);
            words statements = allocate(rows, /* length= */ 28672);
            words calls = allocate(rows, /* length= */ 1024);
            words callStatements = allocate(rows, /* length= */ 256);
            words unused = allocate(rows, /* length= */ 1);
            writeAscii(names, 0, "foobar");
            set(bodyStarts, 0, 5);
            set(bodyLengths, 0, 7);
            set(bodyStarts, 1, 18);
            set(bodyLengths, 1, 7);
            set(nameStarts, 0, 0);
            set(nameLengths, 0, 3);
            set(nameStarts, 1, 3);
            set(nameLengths, 1, 3);
            set(statements, 0, 0);
            set(statements, 12288, STATEMENT_START);
            set(statements, 16384, 5);
            set(statements, 1, 1);
            set(statements, 12289, 19);
            set(statements, 16385, 5);
            set(calls, 0, 77);
            set(callStatements, 0, 78);
            SourceModuleCallPlan plan = materializeLocalSourceModuleCallProducts(
              input,
              /* archiveSourceStart= */ 0,
              /* firstCallable= */ 0,
              /* callableCount= */ 2,
              bodyStarts,
              bodyLengths,
              names,
              nameStarts,
              nameLengths,
              parameterCounts,
              /* statementCount= */ 2,
              statements,
              calls,
              callStatements
            );
            if (plan.valid) {
              valid = 1;
            }
            callCount = plan.callCount;
            firstStart = calls[0];
            firstTarget = calls[768];
            firstStatement = callStatements[0];
            secondStart = calls[1];
            secondTarget = calls[769];
            secondStatement = callStatements[1];
            drop(unused);
            drop(callStatements);
            drop(calls);
            drop(statements);
            drop(parameterCounts);
            drop(nameLengths);
            drop(nameStarts);
            drop(names);
            drop(bodyLengths);
            drop(bodyStarts);
            drop(rows);
          }
        }
        """.replace("STATEMENT_START", detached ? "7" : "6"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_module_call_products");
  }
}
