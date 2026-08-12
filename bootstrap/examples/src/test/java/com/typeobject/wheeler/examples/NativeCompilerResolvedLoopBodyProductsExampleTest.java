package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for direct structured-loop body resolution. */
final class NativeCompilerResolvedLoopBodyProductsExampleTest {
  private static final String SOURCE = """
      classical class Example {
        entry void main() {
          long cursor = 0;
          while (cursor < 2) limit 2 {
            long delta = 1;
            cursor += delta;
          }
        }
      }
      """.strip();

  @Test
  void resolvesBodyDeclarationsUpdatesAndPriorLocals() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(SOURCE, /* duplicateCursor= */ false),
        SOURCE.getBytes(StandardCharsets.UTF_8),
        1);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(2, machine.global("bodyCount"));
    assertEquals(2, machine.global("firstStatement"));
    assertEquals(2, machine.global("firstLocalBase"));
    assertEquals(769, machine.global("firstOpcode"));
    assertEquals(0, machine.global("firstOperandKind"));
    assertEquals(1, machine.global("firstOperand"));
    assertEquals(3, machine.global("secondStatement"));
    assertEquals(4, machine.global("secondLocalBase"));
    assertEquals(16_385, machine.global("secondOpcode"));
    assertEquals(1, machine.global("secondOperandKind"));
    assertEquals(3, machine.global("secondOperand"));
  }

  @Test
  void rejectsUnsupportedAndAmbiguousBodyRowsWithoutPublishing() throws Exception {
    for (TestCase testCase : new TestCase[] {
        new TestCase(SOURCE.replace("cursor += delta;", "return;"), false),
        new TestCase(SOURCE, true)
    }) {
      VirtualMachine machine = new VirtualMachine(
          program(testCase.source(), testCase.duplicateCursor()),
          testCase.source().getBytes(StandardCharsets.UTF_8),
          1);

      machine.run();

      assertEquals(0, machine.global("valid"));
      assertEquals(0, machine.global("bodyCount"));
      assertEquals(91, machine.global("firstOpcode"));
    }
  }

  private static Program program(String source, boolean duplicateCursor) throws Exception {
    int bodyStart = source.indexOf("{", source.indexOf("main("));
    int bodyEnd = matchingClose(source, bodyStart) + 1;
    int cursorStart = source.indexOf("cursor = 0");
    int deltaStart = source.indexOf("delta = 1");
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.resolved_loop_body_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_loop_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_statement_products"));
    sources.put("ResolvedLoopBodyProductsExample.w", """
        module example.resolved_loop_body_products;

        import wheeler.compiler.closure.resolved_loop_body_products;
        import wheeler.compiler.closure.source_loop_products;
        import wheeler.compiler.closure.source_statement_products;

        classical class ResolvedLoopBodyProductsExample {
          state long valid = 0;
          state long bodyCount = 0;
          state long firstStatement = 0;
          state long firstLocalBase = 0;
          state long firstOpcode = 0;
          state long firstOperandKind = 0;
          state long firstOperand = 0;
          state long secondStatement = 0;
          state long secondLocalBase = 0;
          state long secondOpcode = 0;
          state long secondOperandKind = 0;
          state long secondOperand = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 595976, /* allocations= */ 9);
            words bodyStarts = allocate(products, /* length= */ 4096);
            words bodyLengths = allocate(products, /* length= */ 4096);
            words blocks = allocate(products, /* length= */ 6144);
            words statements = allocate(products, /* length= */ 28672);
            words conditions = allocate(products, /* length= */ 1536);
            words loops = allocate(products, /* length= */ 2304);
            words values = allocate(products, /* length= */ 7168);
            words bodyRows = allocate(products, /* length= */ 20480);
            words unused = allocate(products, /* length= */ 1);
            set(bodyStarts, 0, %d);
            set(bodyLengths, 0, %d);
            set(values, 0, 0);
            set(values, 1024, %d);
            set(values, 2048, 6);
            set(values, 3072, 1);
            set(values, 4096, 1);
            set(values, 1, 0);
            set(values, 1025, %d);
            set(values, 2049, 5);
            set(values, 3073, 3);
            set(values, 4097, 3);
            %s
            set(bodyRows, 8192, 91);
            SourceBlockProductPlan blockPlan = materializeSourceBlockProducts(
              input,
              /* archiveSourceStart= */ 0,
              /* firstCallable= */ 0,
              /* callableCount= */ 1,
              bodyStarts,
              bodyLengths,
              blocks
            );
            assert(blockPlan.valid);
            SourceLoopProductPlan loopPlan = materializeSourceLoopProducts(
              input,
              blockPlan.blockCount,
              blocks,
              statements,
              conditions,
              loops
            );
            assert(loopPlan.valid);
            ResolvedLoopBodyPlan bodyPlan = materializeResolvedLoopBodyProducts(
              input,
              loopPlan.statementCount,
              statements,
              /* valueCount= */ %d,
              values,
              bodyRows
            );
            if (bodyPlan.valid) {
              valid = 1;
            }
            bodyCount = bodyPlan.bodyCount;
            firstStatement = bodyRows[0];
            firstLocalBase = bodyRows[4096];
            firstOpcode = bodyRows[8192];
            firstOperandKind = bodyRows[12288];
            firstOperand = bodyRows[16384];
            secondStatement = bodyRows[1];
            secondLocalBase = bodyRows[4097];
            secondOpcode = bodyRows[8193];
            secondOperandKind = bodyRows[12289];
            secondOperand = bodyRows[16385];
            setOutputLength(output, 0);
            drop(unused);
            drop(bodyRows);
            drop(values);
            drop(loops);
            drop(conditions);
            drop(statements);
            drop(blocks);
            drop(bodyLengths);
            drop(bodyStarts);
            drop(products);
          }
        }
        """.formatted(
            bodyStart,
            bodyEnd - bodyStart,
            cursorStart,
            deltaStart,
            duplicateCursor
                ? "set(values, 2, 0);\n"
                    + "set(values, 1026, %d);\n".formatted(cursorStart)
                    + "set(values, 2050, 6);\n"
                    + "set(values, 3074, 1);\n"
                    + "set(values, 4098, 1);"
                : "",
            duplicateCursor ? 3 : 2));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.resolved_loop_body_products");
  }

  private record TestCase(String source, boolean duplicateCursor) {}

  private static int matchingClose(String source, int open) {
    int depth = 0;
    for (int cursor = open; cursor < source.length(); cursor++) {
      if (source.charAt(cursor) == '{') {
        depth += 1;
      }
      if (source.charAt(cursor) == '}') {
        depth -= 1;
        if (depth == 0) {
          return cursor;
        }
      }
    }
    throw new IllegalArgumentException("Unbalanced fixture");
  }
}
