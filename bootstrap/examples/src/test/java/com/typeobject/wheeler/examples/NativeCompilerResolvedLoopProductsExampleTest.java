package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for source-independent resolved loop operands. */
final class NativeCompilerResolvedLoopProductsExampleTest {
  private static final String SOURCE = """
      classical class Example {
        private void nested(long start) {
          long cursor = start;
          while (cursor < 2) limit 2 {
            cursor += 1;
          }
          while (0 < cursor) limit 3 {
            cursor -= 1;
          }
        }
      }
      """.strip();

  @Test
  void resolvesParameterLocalLiteralAndReversedConditions() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(SOURCE, /* mutateValues= */ false),
        SOURCE.getBytes(StandardCharsets.UTF_8),
        1);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(2, machine.global("conditionCount"));
    assertEquals(2, machine.global("loopCount"));
    assertEquals(1, machine.global("firstLeftKind"));
    assertEquals(2, machine.global("firstLeftOperand"));
    assertEquals(0, machine.global("firstRightKind"));
    assertEquals(2, machine.global("firstRightOperand"));
    assertEquals(1, machine.global("firstType"));
    assertEquals(0, machine.global("secondLeftKind"));
    assertEquals(0, machine.global("secondLeftOperand"));
    assertEquals(1, machine.global("secondRightKind"));
    assertEquals(2, machine.global("secondRightOperand"));
    assertEquals(2, machine.global("firstLimit"));
    assertEquals(3, machine.global("secondLimit"));
    assertEquals(1, machine.global("firstBodyCount"));
    assertEquals(1, machine.global("secondBodyCount"));
  }

  @Test
  void rejectsAUseBeforeDefinitionAndLeavesCallerRowsUntouched() throws Exception {
    String invalid = SOURCE.replace(
        "long cursor = start;\n    while",
        "while");
    VirtualMachine machine = new VirtualMachine(
        program(invalid, /* mutateValues= */ false),
        invalid.getBytes(StandardCharsets.UTF_8),
        1);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("conditionCount"));
    assertEquals(0, machine.global("loopCount"));
    assertEquals(91, machine.global("firstLeftOperand"));
    assertEquals(92, machine.global("firstLimit"));
  }

  @Test
  void rejectsAnAmbiguousValueProductWithoutPublishingRows() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(SOURCE, /* mutateValues= */ true),
        SOURCE.getBytes(StandardCharsets.UTF_8),
        1);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("conditionCount"));
    assertEquals(0, machine.global("loopCount"));
    assertEquals(91, machine.global("firstLeftOperand"));
    assertEquals(92, machine.global("firstLimit"));
  }

  private static Program program(String source, boolean mutateValues) throws Exception {
    int bodyStart = source.indexOf("{", source.indexOf("nested("));
    int bodyEnd = matchingClose(source, bodyStart) + 1;
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.resolved_loop_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_loop_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_statement_products"));
    sources.put("ResolvedLoopProductsExample.w", """
        module example.resolved_loop_products;

        import wheeler.compiler.closure.resolved_loop_products;
        import wheeler.compiler.closure.source_loop_products;
        import wheeler.compiler.closure.source_statement_products;

        classical class ResolvedLoopProductsExample {
          state long valid = 0;
          state long conditionCount = 0;
          state long loopCount = 0;
          state long firstLeftKind = 0;
          state long firstLeftOperand = 0;
          state long firstRightKind = 0;
          state long firstRightOperand = 0;
          state long firstType = 0;
          state long secondLeftKind = 0;
          state long secondLeftOperand = 0;
          state long secondRightKind = 0;
          state long secondRightOperand = 0;
          state long firstLimit = 0;
          state long secondLimit = 0;
          state long firstBodyCount = 0;
          state long secondBodyCount = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 655872, /* allocations= */ 11);
            words bodyStarts = allocate(products, /* length= */ 4096);
            words bodyLengths = allocate(products, /* length= */ 4096);
            words blocks = allocate(products, /* length= */ 6144);
            words sourceStatements = allocate(products, /* length= */ 24576);
            words sourceConditions = allocate(products, /* length= */ 1536);
            words sourceLoops = allocate(products, /* length= */ 2048);
            words values = allocate(products, /* length= */ 7168);
            words localCounts = allocate(products, /* length= */ 64);
            words structuralStatements = allocate(products, /* length= */ 28672);
            words resolvedConditions = allocate(products, /* length= */ 1536);
            words resolvedLoops = allocate(products, /* length= */ 2048);
            set(bodyStarts, 0, %d);
            set(bodyLengths, 0, %d);
            set(resolvedConditions, 512, 91);
            set(resolvedLoops, 1024, 92);
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
            SourceStatementProductPlan statementPlan = materializeSourceStatementProducts(
              input,
              /* archiveSourceStart= */ 0,
              /* firstCallable= */ 0,
              /* callableCount= */ 1,
              bodyStarts,
              bodyLengths,
              sourceStatements
            );
            assert(statementPlan.valid);
            SourceValueProductPlan valuePlan = materializeSourceValueProducts(
              input,
              /* archiveSourceStart= */ 0,
              /* firstCallable= */ 0,
              /* callableCount= */ 1,
              bodyStarts,
              statementPlan.statementCount,
              sourceStatements,
              values,
              localCounts
            );
            assert(valuePlan.valid);
            %s
            SourceLoopProductPlan loopPlan = materializeSourceLoopProducts(
              input,
              blockPlan.blockCount,
              blocks,
              structuralStatements,
              sourceConditions,
              sourceLoops
            );
            assert(loopPlan.valid);
            ResolvedLoopProductPlan resolvedPlan = materializeResolvedLoopProducts(
              input,
              loopPlan.loopCount,
              sourceConditions,
              sourceLoops,
              valuePlan.valueCount,
              values,
              resolvedConditions,
              resolvedLoops
            );
            if (resolvedPlan.valid) {
              valid = 1;
            }
            conditionCount = resolvedPlan.conditionCount;
            loopCount = resolvedPlan.loopCount;
            firstLeftKind = resolvedConditions[256];
            firstLeftOperand = resolvedConditions[512];
            firstRightKind = resolvedConditions[768];
            firstRightOperand = resolvedConditions[1024];
            firstType = resolvedConditions[1280];
            secondLeftKind = resolvedConditions[257];
            secondLeftOperand = resolvedConditions[513];
            secondRightKind = resolvedConditions[769];
            secondRightOperand = resolvedConditions[1025];
            firstLimit = resolvedLoops[1024];
            secondLimit = resolvedLoops[1025];
            firstBodyCount = resolvedLoops[1536];
            secondBodyCount = resolvedLoops[1537];
            setOutputLength(output, 0);
            drop(resolvedLoops);
            drop(resolvedConditions);
            drop(structuralStatements);
            drop(localCounts);
            drop(values);
            drop(sourceLoops);
            drop(sourceConditions);
            drop(sourceStatements);
            drop(blocks);
            drop(bodyLengths);
            drop(bodyStarts);
            drop(products);
          }
        }
        """.formatted(
            bodyStart,
            bodyEnd - bodyStart,
            mutateValues
                ? "set(values, 1024, values[1025]);\n"
                    + "set(values, 2048, values[2049]);\n"
                    + "set(values, 3072, values[3073]);\n"
                    + "set(values, 4096, values[4097]);"
                : ""));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.resolved_loop_products");
  }

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
