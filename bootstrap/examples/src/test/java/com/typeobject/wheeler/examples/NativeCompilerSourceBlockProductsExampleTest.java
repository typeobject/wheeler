package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for balanced callable-local source block products. */
final class NativeCompilerSourceBlockProductsExampleTest {
  private static final String SOURCE = """
      classical class Example {
        private void nested() {
          long cursor = 0;
          while (cursor < 2) limit 2 {
            if (cursor == 0) {
              if (cursor < 2) {
                if (cursor < 3) {
                  cursor += 1;
                }
              }
            }
            cursor += 1;
          }
        }

        private void empty() {}
      }
      """.strip();

  @Test
  void publishesNestedBlockParentsDepthsAndExtents() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(SOURCE, /* firstBodyLengthAdjustment= */ 0, /* overlapBodies= */ false,
            /* archiveSourceStart= */ 0),
        SOURCE.getBytes(StandardCharsets.UTF_8),
        1);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(6, machine.global("blockCount"));
    assertEquals(-1, machine.global("firstParent"));
    assertEquals(0, machine.global("whileParent"));
    assertEquals(1, machine.global("ifParent"));
    assertEquals(3, machine.global("deepestParent"));
    assertEquals(-1, machine.global("emptyParent"));
    assertEquals(0, machine.global("firstDepth"));
    assertEquals(1, machine.global("whileDepth"));
    assertEquals(2, machine.global("ifDepth"));
    assertEquals(4, machine.global("deepestDepth"));
    assertEquals(0, machine.global("emptyDepth"));
    int firstStart = SOURCE.indexOf("{", SOURCE.indexOf("nested()"));
    assertEquals(firstStart, machine.global("firstStart"));
    assertEquals(SOURCE.indexOf("{", SOURCE.indexOf("while")), machine.global("whileStart"));
    assertEquals(matchingClose(SOURCE, firstStart) - firstStart + 1,
        machine.global("firstLength"));
    assertEquals(2, machine.global("emptyLength"));
    assertEquals(0, machine.global("firstOwner"));
    assertEquals(1, machine.global("emptyOwner"));
    assertEquals(0, machine.global("firstOrdinal"));
    assertEquals(1, machine.global("whileOrdinal"));
    assertEquals(2, machine.global("ifOrdinal"));
    assertEquals(4, machine.global("deepestOrdinal"));
    assertEquals(0, machine.global("emptyOrdinal"));
  }

  @Test
  void rejectsAStaleBodyExtentBeforePublishingRows() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(SOURCE, /* firstBodyLengthAdjustment= */ -1, /* overlapBodies= */ false,
            /* archiveSourceStart= */ 0),
        SOURCE.getBytes(StandardCharsets.UTF_8),
        1);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("blockCount"));
    assertEquals(91, machine.global("firstStart"));
  }

  @Test
  void rejectsAPathBeyondFourNestedBlocksBeforePublishingRows() throws Exception {
    String tooDeep = SOURCE.replace(
        "cursor += 1;",
        "if (cursor < 4) { cursor += 1; }");
    VirtualMachine machine = new VirtualMachine(
        program(tooDeep, /* firstBodyLengthAdjustment= */ 0, /* overlapBodies= */ false,
            /* archiveSourceStart= */ 0),
        tooDeep.getBytes(StandardCharsets.UTF_8),
        1);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("blockCount"));
    assertEquals(91, machine.global("firstStart"));
  }

  @Test
  void rejectsOverlappingCallableBodiesBeforePublishingRows() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(SOURCE, /* firstBodyLengthAdjustment= */ 0, /* overlapBodies= */ true,
            /* archiveSourceStart= */ 0),
        SOURCE.getBytes(StandardCharsets.UTF_8),
        1);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("blockCount"));
    assertEquals(91, machine.global("firstStart"));
  }

  @Test
  void rejectsASecondRootBlockInsideTheCallableExtent() throws Exception {
    int firstStart = SOURCE.indexOf("{", SOURCE.indexOf("nested()"));
    int firstClose = matchingClose(SOURCE, firstStart);
    String detachedRoot = SOURCE.substring(0, firstClose + 1)
        + " {}"
        + SOURCE.substring(firstClose + 1);
    VirtualMachine machine = new VirtualMachine(
        program(detachedRoot, /* firstBodyLengthAdjustment= */ 3, /* overlapBodies= */ false,
            /* archiveSourceStart= */ 0),
        detachedRoot.getBytes(StandardCharsets.UTF_8),
        1);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("blockCount"));
    assertEquals(91, machine.global("firstStart"));
  }

  @Test
  void convertsArchiveBodyCoordinatesToSourceLocalExtents() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(SOURCE, /* firstBodyLengthAdjustment= */ 0, /* overlapBodies= */ false,
            /* archiveSourceStart= */ 4096),
        SOURCE.getBytes(StandardCharsets.UTF_8),
        1);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(SOURCE.indexOf("{", SOURCE.indexOf("nested()")),
        machine.global("firstStart"));
  }

  private static Program program(
      String source,
      int firstBodyLengthAdjustment,
      boolean overlapBodies,
      int archiveSourceStart) throws Exception {
    int firstStart = source.indexOf("{", source.indexOf("nested()"));
    int firstEnd = matchingClose(source, firstStart) + 1 + firstBodyLengthAdjustment;
    int secondStart = source.indexOf("{", source.indexOf("empty()"));
    int secondEnd = matchingClose(source, secondStart) + 1;
    if (overlapBodies) {
      secondStart = firstStart;
      secondEnd = firstEnd;
    }
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_statement_products"));
    sources.put("SourceBlockProductsExample.w", """
        module example.source_block_products;

        import wheeler.compiler.closure.source_statement_products;

        classical class SourceBlockProductsExample {
          state long valid = 0;
          state long blockCount = 0;
          state long firstParent = 0;
          state long whileParent = 0;
          state long ifParent = 0;
          state long deepestParent = 0;
          state long emptyParent = 0;
          state long firstDepth = 0;
          state long whileDepth = 0;
          state long ifDepth = 0;
          state long deepestDepth = 0;
          state long emptyDepth = 0;
          state long firstStart = 0;
          state long whileStart = 0;
          state long firstLength = 0;
          state long emptyLength = 0;
          state long firstOwner = 0;
          state long emptyOwner = 0;
          state long firstOrdinal = 0;
          state long whileOrdinal = 0;
          state long ifOrdinal = 0;
          state long deepestOrdinal = 0;
          state long emptyOrdinal = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 114688, /* allocations= */ 3);
            words bodyStarts = allocate(products, /* length= */ 4096);
            words bodyLengths = allocate(products, /* length= */ 4096);
            words blocks = allocate(products, /* length= */ 6144);
            set(bodyStarts, 0, %d);
            set(bodyLengths, 0, %d);
            set(bodyStarts, 1, %d);
            set(bodyLengths, 1, %d);
            set(blocks, 3072, 91);
            SourceBlockProductPlan plan = materializeSourceBlockProducts(
              input,
              /* archiveSourceStart= */ %d,
              /* firstCallable= */ 0,
              /* callableCount= */ 2,
              bodyStarts,
              bodyLengths,
              blocks
            );
            if (plan.valid) {
              valid = 1;
            }
            blockCount = plan.blockCount;
            firstParent = blocks[1024];
            whileParent = blocks[1025];
            ifParent = blocks[1026];
            deepestParent = blocks[1028];
            emptyParent = blocks[1029];
            firstDepth = blocks[2048];
            whileDepth = blocks[2049];
            ifDepth = blocks[2050];
            deepestDepth = blocks[2052];
            emptyDepth = blocks[2053];
            firstStart = blocks[3072];
            whileStart = blocks[3073];
            firstLength = blocks[4096];
            emptyLength = blocks[4101];
            firstOwner = blocks[0];
            emptyOwner = blocks[5];
            firstOrdinal = blocks[5120];
            whileOrdinal = blocks[5121];
            ifOrdinal = blocks[5122];
            deepestOrdinal = blocks[5124];
            emptyOrdinal = blocks[5125];
            setOutputLength(output, 0);
            drop(blocks);
            drop(bodyLengths);
            drop(bodyStarts);
            drop(products);
          }
        }
        """.formatted(
            firstStart + archiveSourceStart,
            firstEnd - firstStart,
            secondStart + archiveSourceStart,
            secondEnd - secondStart,
            archiveSourceStart));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_block_products");
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
