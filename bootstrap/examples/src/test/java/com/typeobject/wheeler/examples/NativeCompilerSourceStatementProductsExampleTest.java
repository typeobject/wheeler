package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for callable-owned source statement products. */
final class NativeCompilerSourceStatementProductsExampleTest {
  private static final String SOURCE = """
      classical class Example {
        private long one(long x) { Pair y = new Pair(x); return x; }
        private long two() { return 2; }
      }
      """.strip();

  @Test
  void derivesFunctionsOrdinalsAndRangesFromCallableBodies() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(/* staleFirstBody= */ false), SOURCE.getBytes(StandardCharsets.UTF_8), 1);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(3, machine.global("statementCount"));
    assertEquals(0, machine.global("firstFunction"));
    assertEquals(0, machine.global("secondFunction"));
    assertEquals(1, machine.global("thirdFunction"));
    assertEquals(1, machine.global("firstOrdinal"));
    assertEquals(2, machine.global("secondOrdinal"));
    assertEquals(1, machine.global("thirdOrdinal"));
    assertEquals(SOURCE.indexOf("Pair y = new Pair(x);"), machine.global("firstStart"));
    assertEquals("Pair y = new Pair(x);".length(), machine.global("firstLength"));
    assertEquals(2, machine.global("valueCount"));
    assertEquals(0, machine.global("parameterLocal"));
    assertEquals(2, machine.global("destinationLocal"));
    assertEquals(4, machine.global("firstFunctionLocals"));
    assertEquals(1, machine.global("firstStatementLocal"));
    assertEquals(2, machine.global("firstStatementWidth"));
    assertEquals(3, machine.global("secondStatementLocal"));
    assertEquals(1, machine.global("secondStatementWidth"));
    assertEquals(0, machine.global("thirdStatementLocal"));
    assertEquals(1, machine.global("thirdStatementWidth"));
  }

  @Test
  void treatsAMultiStatementLoopAsOneTopLevelStatement() throws Exception {
    String source = "classical class Example { private long count(long stop) { "
        + "long cursor = 0; while (cursor < stop) limit 8 { "
        + "cursor += 1; cursor += 1; } return cursor; } }";
    int bodyStart = source.indexOf("{", source.indexOf("count("));
    int bodyEnd = source.indexOf("} return cursor") + "} return cursor;".length() + 2;
    VirtualMachine machine = new VirtualMachine(
        oneBodyProgram(bodyStart, bodyEnd - bodyStart),
        source.getBytes(StandardCharsets.UTF_8),
        1);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(3, machine.global("statementCount"));
    assertEquals(source.indexOf("while ("), machine.global("secondStart"));
    assertEquals(
        "while (cursor < stop) limit 8 { cursor += 1; cursor += 1; }".length(),
        machine.global("secondLength"));
  }

  @Test
  void rejectsAStaleBodyExtentBeforeStatementPublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(/* staleFirstBody= */ true), SOURCE.getBytes(StandardCharsets.UTF_8), 1);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("statementCount"));
    assertEquals(91, machine.global("firstStart"));
  }

  private static Program oneBodyProgram(int bodyStart, int bodyLength) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_statement_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_value_products"));
    sources.put("LoopStatementProductsExample.w", """
        module example.loop_statement_products;

        import wheeler.compiler.closure.source_statement_products;
        import wheeler.compiler.closure.source_value_products;

        classical class LoopStatementProductsExample {
          state long valid = 0;
          state long statementCount = 0;
          state long secondStart = 0;
          state long secondLength = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 262144, /* allocations= */ 3);
            words bodyStarts = allocate(products, /* length= */ 4096);
            words bodyLengths = allocate(products, /* length= */ 4096);
            words statements = allocate(products, /* length= */ 24576);
            set(bodyStarts, 0, %d);
            set(bodyLengths, 0, %d);
            SourceStatementProductPlan plan = materializeSourceStatementProducts(
              input,
              /* archiveSourceStart= */ 0,
              /* firstCallable= */ 0,
              /* callableCount= */ 1,
              bodyStarts,
              bodyLengths,
              statements
            );
            if (plan.valid) {
              valid = 1;
            }
            statementCount = plan.statementCount;
            secondStart = statements[16385];
            secondLength = statements[20481];
            setOutputLength(output, 0);
            drop(statements);
            drop(bodyLengths);
            drop(bodyStarts);
            drop(products);
          }
        }
        """.formatted(bodyStart, bodyLength));
    return new WheelerCompiler().compileModuleFiles(sources, "example.loop_statement_products");
  }

  private static Program program(boolean staleFirstBody) throws Exception {
    int firstStart = SOURCE.indexOf("{ Pair y");
    int firstEnd = SOURCE.indexOf("}", firstStart) + 1;
    int secondStart = SOURCE.indexOf("{ return 2");
    int secondEnd = SOURCE.indexOf("}", secondStart) + 1;
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_statement_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_value_products"));
    sources.put("SourceStatementProductsExample.w", """
        module example.source_statement_products;

        import wheeler.compiler.closure.source_statement_products;
        import wheeler.compiler.closure.source_value_products;

        classical class SourceStatementProductsExample {
          state long valid = 0;
          state long statementCount = 0;
          state long firstFunction = 0;
          state long secondFunction = 0;
          state long thirdFunction = 0;
          state long firstOrdinal = 0;
          state long secondOrdinal = 0;
          state long thirdOrdinal = 0;
          state long firstStart = 0;
          state long firstLength = 0;
          state long valueCount = 0;
          state long parameterLocal = 0;
          state long destinationLocal = 0;
          state long firstFunctionLocals = 0;
          state long firstStatementLocal = 0;
          state long firstStatementWidth = 0;
          state long secondStatementLocal = 0;
          state long secondStatementWidth = 0;
          state long thirdStatementLocal = 0;
          state long thirdStatementWidth = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 385536, /* allocations= */ 6);
            words bodyStarts = allocate(products, /* length= */ 4096);
            words bodyLengths = allocate(products, /* length= */ 4096);
            words statements = allocate(products, /* length= */ 24576);
            words values = allocate(products, /* length= */ 7168);
            words functionLocals = allocate(products, /* length= */ 64);
            words statementLocals = allocate(products, /* length= */ 8192);
            set(bodyStarts, 0, %d);
            set(bodyLengths, 0, %d);
            set(bodyStarts, 1, %d);
            set(bodyLengths, 1, %d);
            set(statements, 16384, 91);
            SourceStatementProductPlan plan = materializeSourceStatementProducts(
              input,
              /* archiveSourceStart= */ 0,
              /* firstCallable= */ 0,
              /* callableCount= */ 2,
              bodyStarts,
              bodyLengths,
              statements
            );
            if (plan.valid) {
              valid = 1;
              SourceValueProductPlan valuePlan = materializeSourceValueProducts(
                input,
                /* archiveSourceStart= */ 0,
                /* firstCallable= */ 0,
                /* callableCount= */ 2,
                bodyStarts,
                plan.statementCount,
                statements,
                /* statementStartRow= */ 16384,
                /* statementLengthRow= */ 20480,
                values,
                functionLocals,
                statementLocals
              );
              assert(valuePlan.valid);
              valueCount = valuePlan.valueCount;
              parameterLocal = values[3072];
              destinationLocal = values[3073];
              firstFunctionLocals = functionLocals[0];
              firstStatementLocal = statementLocals[0];
              firstStatementWidth = statementLocals[4096];
              secondStatementLocal = statementLocals[1];
              secondStatementWidth = statementLocals[4097];
              thirdStatementLocal = statementLocals[2];
              thirdStatementWidth = statementLocals[4098];
            }
            statementCount = plan.statementCount;
            firstFunction = statements[0];
            secondFunction = statements[1];
            thirdFunction = statements[2];
            firstOrdinal = statements[8192];
            secondOrdinal = statements[8193];
            thirdOrdinal = statements[8194];
            firstStart = statements[16384];
            firstLength = statements[20480];
            setOutputLength(output, 0);
            drop(statementLocals);
            drop(functionLocals);
            drop(values);
            drop(statements);
            drop(bodyLengths);
            drop(bodyStarts);
            drop(products);
          }
        }
        """.formatted(
            firstStart,
            firstEnd - firstStart - (staleFirstBody ? 1 : 0),
            secondStart,
            secondEnd - secondStart));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_statement_products");
  }
}
