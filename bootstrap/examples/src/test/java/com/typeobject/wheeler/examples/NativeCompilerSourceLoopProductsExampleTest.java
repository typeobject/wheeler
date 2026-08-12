package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for structural source statements and bounded loop products. */
final class NativeCompilerSourceLoopProductsExampleTest {
  private static final String SOURCE = """
      classical class Example {
        private void nested() {
          long cursor = 0;
          while (cursor < 2) limit 2 {
            long delta = 1;
            if (cursor < 1) {
              cursor += delta;
            }
            cursor += 1;
          }
          while (0 < cursor) limit 3 {
            cursor -= 1;
          }
          cursor += 1;
        }

        private void empty() {}
      }
      """.strip();

  @Test
  void publishesBlockGroupedStatementsConditionsAndAdjacentLoops() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(SOURCE, /* forgeParent= */ false),
        SOURCE.getBytes(StandardCharsets.UTF_8),
        1);

    machine.run();

    assertEquals(1, machine.global("blocksValid"));
    assertEquals(1, machine.global("loopsValid"));
    assertEquals(5, machine.global("blockCount"));
    assertEquals(9, machine.global("statementCount"));
    assertEquals(2, machine.global("conditionCount"));
    assertEquals(2, machine.global("loopCount"));
    assertEquals(0, machine.global("firstLoopOwner"));
    assertEquals(0, machine.global("firstLoopParent"));
    assertEquals(1, machine.global("firstLoopOrdinal"));
    assertEquals(0, machine.global("firstLoopCondition"));
    assertEquals(SOURCE.indexOf("2 {"), machine.global("firstLoopLimit"));
    assertEquals(4, machine.global("firstLoopBodyStart"));
    assertEquals(3, machine.global("firstLoopBodyCount"));
    assertEquals(1, machine.global("firstLoopDepth"));
    assertEquals(0, machine.global("secondLoopParent"));
    assertEquals(6, machine.global("secondLoopOrdinal"));
    assertEquals(SOURCE.indexOf("3 {"), machine.global("secondLoopLimit"));
    assertEquals(8, machine.global("secondLoopBodyStart"));
    assertEquals(1, machine.global("secondLoopBodyCount"));
    assertEquals(0, machine.global("firstConditionReversed"));
    assertEquals(1, machine.global("secondConditionReversed"));
    assertEquals(SOURCE.indexOf("cursor < 2"), machine.global("firstConditionLeftStart"));
    assertEquals(6, machine.global("firstConditionLeftLength"));
    assertEquals(SOURCE.indexOf("2) limit"), machine.global("firstConditionRightStart"));
    assertEquals(1, machine.global("firstConditionRightLength"));
    assertEquals(SOURCE.indexOf("while (cursor"), machine.global("firstLoopStart"));
    assertEquals(SOURCE.indexOf("long delta"), machine.global("firstBodyStart"));
    assertEquals(2, machine.global("firstBodyOrdinal"));
  }

  @Test
  void publishesAnEmptyLoopBody() throws Exception {
    String emptyBody = sourceWithLoopStatements(0);
    VirtualMachine machine = new VirtualMachine(
        program(emptyBody, /* forgeParent= */ false),
        emptyBody.getBytes(StandardCharsets.UTF_8),
        1);

    machine.run();

    assertEquals(1, machine.global("loopsValid"));
    assertEquals(2, machine.global("statementCount"));
    assertEquals(1, machine.global("loopCount"));
    assertEquals(2, machine.global("firstLoopBodyStart"));
    assertEquals(0, machine.global("firstLoopBodyCount"));
  }

  @Test
  void acceptsSixtyFourBodyStatementsAndRejectsSixtyFiveAtomically() throws Exception {
    String accepted = sourceWithLoopStatements(64);
    VirtualMachine acceptedMachine = new VirtualMachine(
        program(accepted, /* forgeParent= */ false),
        accepted.getBytes(StandardCharsets.UTF_8),
        1);

    acceptedMachine.run();

    assertEquals(1, acceptedMachine.global("loopsValid"));
    assertEquals(66, acceptedMachine.global("statementCount"));
    assertEquals(2, acceptedMachine.global("firstLoopBodyStart"));
    assertEquals(64, acceptedMachine.global("firstLoopBodyCount"));

    String rejected = sourceWithLoopStatements(65);
    VirtualMachine rejectedMachine = new VirtualMachine(
        program(rejected, /* forgeParent= */ false),
        rejected.getBytes(StandardCharsets.UTF_8),
        1);

    rejectedMachine.run();

    assertEquals(1, rejectedMachine.global("blocksValid"));
    assertEquals(0, rejectedMachine.global("loopsValid"));
    assertEquals(0, rejectedMachine.global("statementCount"));
    assertEquals(91, rejectedMachine.global("firstLoopLimit"));
  }

  @Test
  void rejectsZeroAndExcessiveLimitsWithoutPublishingRows() throws Exception {
    for (String invalid : new String[] {
        SOURCE.replace("limit 2", "limit 0"),
        SOURCE.replace("limit 2", "limit 16777217")
    }) {
      VirtualMachine machine = new VirtualMachine(
          program(invalid, /* forgeParent= */ false),
          invalid.getBytes(StandardCharsets.UTF_8),
          1);

      machine.run();

      assertEquals(1, machine.global("blocksValid"));
      assertEquals(0, machine.global("loopsValid"));
      assertEquals(0, machine.global("statementCount"));
      assertEquals(0, machine.global("conditionCount"));
      assertEquals(0, machine.global("loopCount"));
      assertEquals(91, machine.global("firstLoopLimit"));
      assertEquals(92, machine.global("firstConditionLeftStart"));
      assertEquals(93, machine.global("firstLoopStart"));
    }
  }

  @Test
  void rejectsForgedBlockParentsWithoutPublishingRows() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(SOURCE, /* forgeParent= */ true),
        SOURCE.getBytes(StandardCharsets.UTF_8),
        1);

    machine.run();

    assertEquals(1, machine.global("blocksValid"));
    assertEquals(0, machine.global("loopsValid"));
    assertEquals(0, machine.global("statementCount"));
    assertEquals(0, machine.global("conditionCount"));
    assertEquals(0, machine.global("loopCount"));
    assertEquals(91, machine.global("firstLoopLimit"));
  }

  private static String sourceWithLoopStatements(int statementCount) {
    StringBuilder statements = new StringBuilder();
    for (int statement = 0; statement < statementCount; statement++) {
      statements.append("      cursor += 1;\n");
    }
    return """
        classical class Example {
          private void nested() {
            long cursor = 0;
            while (cursor < 66) limit 66 {
        %s    }
          }

          private void empty() {}
        }
        """.formatted(statements).strip();
  }

  private static Program program(String source, boolean forgeParent) throws Exception {
    int firstStart = source.indexOf("{", source.indexOf("nested()"));
    int firstEnd = matchingClose(source, firstStart) + 1;
    int secondStart = source.indexOf("{", source.indexOf("empty()"));
    int secondEnd = matchingClose(source, secondStart) + 1;
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_loop_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_statement_products"));
    sources.put("SourceLoopProductsExample.w", """
        module example.source_loop_products;

        import wheeler.compiler.closure.source_loop_products;
        import wheeler.compiler.closure.source_statement_products;

        classical class SourceLoopProductsExample {
          state long blocksValid = 0;
          state long loopsValid = 0;
          state long blockCount = 0;
          state long statementCount = 0;
          state long conditionCount = 0;
          state long loopCount = 0;
          state long firstLoopOwner = 0;
          state long firstLoopParent = 0;
          state long firstLoopOrdinal = 0;
          state long firstLoopCondition = 0;
          state long firstLoopLimit = 0;
          state long firstLoopBodyStart = 0;
          state long firstLoopBodyCount = 0;
          state long firstLoopDepth = 0;
          state long secondLoopParent = 0;
          state long secondLoopOrdinal = 0;
          state long secondLoopLimit = 0;
          state long secondLoopBodyStart = 0;
          state long secondLoopBodyCount = 0;
          state long firstConditionReversed = 0;
          state long secondConditionReversed = 0;
          state long firstConditionLeftStart = 0;
          state long firstConditionLeftLength = 0;
          state long firstConditionRightStart = 0;
          state long firstConditionRightLength = 0;
          state long firstLoopStart = 0;
          state long firstBodyStart = 0;
          state long firstBodyOrdinal = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 374784, /* allocations= */ 6);
            words bodyStarts = allocate(products, /* length= */ 4096);
            words bodyLengths = allocate(products, /* length= */ 4096);
            words blocks = allocate(products, /* length= */ 6144);
            words statements = allocate(products, /* length= */ 28672);
            words conditions = allocate(products, /* length= */ 1536);
            words loops = allocate(products, /* length= */ 2304);
            set(bodyStarts, 0, %d);
            set(bodyLengths, 0, %d);
            set(bodyStarts, 1, %d);
            set(bodyLengths, 1, %d);
            set(loops, 1024, 91);
            set(conditions, 256, 92);
            set(statements, 12289, 93);
            SourceBlockProductPlan blockPlan = materializeSourceBlockProducts(
              input,
              /* archiveSourceStart= */ 0,
              /* firstCallable= */ 0,
              /* callableCount= */ 2,
              bodyStarts,
              bodyLengths,
              blocks
            );
            if (blockPlan.valid) {
              blocksValid = 1;
            }
            blockCount = blockPlan.blockCount;
            %s
            SourceLoopProductPlan loopPlan = materializeSourceLoopProducts(
              input,
              blockPlan.blockCount,
              blocks,
              statements,
              conditions,
              loops
            );
            if (loopPlan.valid) {
              loopsValid = 1;
            }
            statementCount = loopPlan.statementCount;
            conditionCount = loopPlan.conditionCount;
            loopCount = loopPlan.loopCount;
            firstLoopOwner = loops[0];
            firstLoopParent = loops[256];
            firstLoopOrdinal = loops[512];
            firstLoopCondition = loops[768];
            firstLoopLimit = loops[1024];
            firstLoopBodyStart = loops[1536];
            firstLoopBodyCount = loops[1792];
            firstLoopDepth = loops[2048];
            secondLoopParent = loops[257];
            secondLoopOrdinal = loops[513];
            secondLoopLimit = loops[1025];
            secondLoopBodyStart = loops[1537];
            secondLoopBodyCount = loops[1793];
            firstConditionReversed = conditions[1280];
            secondConditionReversed = conditions[1281];
            firstConditionLeftStart = conditions[256];
            firstConditionLeftLength = conditions[512];
            firstConditionRightStart = conditions[768];
            firstConditionRightLength = conditions[1024];
            firstLoopStart = statements[12289];
            firstBodyStart = statements[12292];
            firstBodyOrdinal = statements[8196];
            setOutputLength(output, 0);
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
            firstStart,
            firstEnd - firstStart,
            secondStart,
            secondEnd - secondStart,
            forgeParent ? "set(blocks, 1024, 1024);" : ""));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_loop_products");
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
