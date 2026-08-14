package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for source products derived from the physical CoreParsing module. */
final class NativeCompilerCoreParsingSourceProductsExampleTest {
  private static final String SOURCE_PATH = "compiler/backend/core/CoreParsing.w";

  @Test
  void derivesBothCallableStatementBlockLoopAndValueWindows() throws Exception {
    String source = CompilerSources.read(SOURCE_PATH);
    int firstBody = source.indexOf("{", source.indexOf("compactCompilerTokens("));
    int secondBody = source.indexOf("{", source.indexOf("discardLeadingTokens("));
    int limitName = source.indexOf("limit MAX_COMPILER_TOKENS") + "limit ".length();
    Program compiledProgram = program(
        firstBody,
        matchingClose(source, firstBody) - firstBody + 1,
        secondBody,
        matchingClose(source, secondBody) - secondBody + 1,
        limitName);
    VirtualMachine machine = new VirtualMachine(
        compiledProgram, source.getBytes(StandardCharsets.UTF_8), 1);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("blockValid"));
    assertEquals(1, machine.global("loopValid"));
    assertEquals(1, machine.global("valueValid"));
    assertEquals(12, machine.global("kindLocal"));
    assertEquals(14, machine.global("emitLocal"));
    assertEquals(6, machine.global("secondReadLocal"));
    assertEquals(8, machine.global("secondWriteLocal"));
    assertEquals(-1, machine.global("bodyFailure"));
    assertEquals(1, machine.global("bodyValid"));
    assertEquals(1, machine.global("resolvedValid"));
    assertEquals(1, machine.global("valid"));
    assertEquals(25, machine.global("statementCount"));
    assertEquals(7, machine.global("blockCount"));
    assertEquals(2, machine.global("loopCount"));
    assertEquals(15, machine.global("valueCount"));
    assertEquals(38, machine.global("firstProductLocalCount"));
    assertEquals(23, machine.global("secondProductLocalCount"));
    assertEquals(14, machine.global("bodyCount"));
    assertEquals(3, machine.global("nestedCount"));
    assertEquals(4_096, machine.global("firstLimit"));
    assertEquals(4_096, machine.global("secondLimit"));
    assertEquals(0, machine.global("firstLoopOwner"));
    assertEquals(1, machine.global("secondLoopOwner"));
  }

  private static Program program(
      int firstBody,
      int firstLength,
      int secondBody,
      int secondLength,
      int limitName) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_statement_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_loop_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.resolved_loop_body_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.resolved_loop_products"));
    sources.put("CoreParsingSourceProductsExample.w", """
        module example.core_parsing_source_products;

        import wheeler.compiler.closure.resolved_loop_body_products;
        import wheeler.compiler.closure.resolved_loop_products;
        import wheeler.compiler.closure.source_loop_products;
        import wheeler.compiler.closure.source_statement_products;

        classical class CoreParsingSourceProductsExample {
          state long valid = 0;
          state long blockValid = 0;
          state long loopValid = 0;
          state long valueValid = 0;
          state long bodyValid = 0;
          state long resolvedValid = 0;
          state long statementCount = 0;
          state long blockCount = 0;
          state long loopCount = 0;
          state long valueCount = 0;
          state long firstProductLocalCount = 0;
          state long secondProductLocalCount = 0;
          state long kindLocal = 0;
          state long emitLocal = 0;
          state long secondReadLocal = 0;
          state long secondWriteLocal = 0;
          state long bodyFailure = 0;
          state long bodyCount = 0;
          state long nestedCount = 0;
          state long firstLimit = 0;
          state long secondLimit = 0;
          state long firstLoopOwner = 0;
          state long secondLoopOwner = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 1686528, /* allocations= */ 19);
            words bodyStarts = allocate(products, /* length= */ 4096);
            words bodyLengths = allocate(products, /* length= */ 4096);
            words blocks = allocate(products, /* length= */ 6144);
            words statements = allocate(products, /* length= */ 28672);
            words conditions = allocate(products, /* length= */ 1536);
            words loops = allocate(products, /* length= */ 2304);
            words values = allocate(products, /* length= */ 7168);
            words functionLocalCounts = allocate(products, /* length= */ 64);
            words bodyRows = allocate(products, /* length= */ 20480);
            words nestedRows = allocate(products, /* length= */ 20480);
            words resolvedConditions = allocate(products, /* length= */ 1536);
            words resolvedLoops = allocate(products, /* length= */ 2304);
            words symbolOwners = allocate(products, /* length= */ 16384);
            words symbolStarts = allocate(products, /* length= */ 16384);
            words symbolLengths = allocate(products, /* length= */ 16384);
            words symbolTypes = allocate(products, /* length= */ 16384);
            words symbolValues = allocate(products, /* length= */ 16384);
            words symbolResolved = allocate(products, /* length= */ 16384);
            words unused = allocate(products, /* length= */ 1);
            set(bodyStarts, 0, %d);
            set(bodyLengths, 0, %d);
            set(bodyStarts, 1, %d);
            set(bodyLengths, 1, %d);
            set(symbolOwners, 0, 0);
            set(symbolStarts, 0, %d);
            set(symbolLengths, 0, 19);
            set(symbolTypes, 0, 1);
            set(symbolValues, 0, 4096);
            set(symbolResolved, 0, 1);
            SourceBlockProductPlan blockPlan = materializeSourceBlockProducts(
              input, 0, 0, 2, bodyStarts, bodyLengths, blocks
            );
            SourceLoopProductPlan loopPlan = materializeSourceLoopProducts(
              input,
              blockPlan.blockCount,
              blocks,
              statements,
              conditions,
              loops
            );
            SourceValueProductPlan valuePlan = materializeSourceValueProducts(
              input,
              0,
              0,
              2,
              bodyStarts,
              loopPlan.statementCount,
              statements,
              /* statementStartRow= */ 12288,
              /* statementLengthRow= */ 16384,
              values,
              functionLocalCounts
            );
            if (blockPlan.valid) {
              blockValid = 1;
            }
            if (loopPlan.valid) {
              loopValid = 1;
            }
            if (valuePlan.valid) {
              valueValid = 1;
            }
            ResolvedLoopBodyPlan bodyPlan = materializeResolvedLoopBodyProducts(
              input,
              loopPlan.statementCount,
              statements,
              valuePlan.valueCount,
              values,
              bodyRows,
              nestedRows
            );
            if (bodyPlan.valid) {
              bodyValid = 1;
            }
            ResolvedLoopProductPlan resolvedPlan = materializeResolvedLoopProducts(
              input,
              0,
              0,
              loopPlan.loopCount,
              conditions,
              loops,
              valuePlan.valueCount,
              values,
              1,
              symbolOwners,
              symbolStarts,
              symbolLengths,
              symbolTypes,
              symbolValues,
              symbolResolved,
              resolvedConditions,
              resolvedLoops
            );
            if (resolvedPlan.valid) {
              resolvedValid = 1;
            }
            if (blockPlan.valid) {
              if (loopPlan.valid) {
                if (valuePlan.valid) {
                  if (bodyPlan.valid) {
                    if (resolvedPlan.valid) {
                      valid = 1;
                    }
                  }
                }
              }
            }
            statementCount = loopPlan.statementCount;
            blockCount = blockPlan.blockCount;
            loopCount = loopPlan.loopCount;
            valueCount = valuePlan.valueCount;
            firstProductLocalCount = functionLocalCounts[0];
            secondProductLocalCount = functionLocalCounts[1];
            kindLocal = values[3078];
            emitLocal = values[3079];
            secondReadLocal = values[3085];
            secondWriteLocal = values[3086];
            bodyFailure = bodyPlan.failureStatement;
            bodyCount = bodyPlan.bodyCount;
            nestedCount = bodyPlan.nestedCount;
            firstLimit = resolvedLoops[1024];
            secondLimit = resolvedLoops[1025];
            firstLoopOwner = loops[0];
            secondLoopOwner = loops[1];
            setOutputLength(output, 0);
            drop(unused);
            drop(symbolResolved);
            drop(symbolValues);
            drop(symbolTypes);
            drop(symbolLengths);
            drop(symbolStarts);
            drop(symbolOwners);
            drop(resolvedLoops);
            drop(resolvedConditions);
            drop(nestedRows);
            drop(bodyRows);
            drop(functionLocalCounts);
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
        """.formatted(firstBody, firstLength, secondBody, secondLength, limitName));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.core_parsing_source_products");
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
    throw new IllegalArgumentException("unbalanced source");
  }
}
