package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for bounded canonical graph-source copying. */
final class NativeCompilerGraphSourcesExampleTest {
  @Test
  void ownsPhysicalAndLinkedSourcesInOneCountedTable() throws Exception {
    String table = CompilerSources.read("compiler/graphs/plans/SourceTable.w");
    String root = """
        module example.counted_source_table;

        import wheeler.compiler.graphs.source_table;

        classical class CountedSourceTable {
          entry void main(borrow utf8 replacement, borrow mut bytes output) {
            region tableArena = new region(/* bytes= */ 229432, /* allocations= */ 2);
            bytes storage = allocateBytes(tableArena, SOURCE_TABLE_BYTES);
            words lengths = allocate(tableArena, SOURCE_TABLE_LENGTH_WORDS);
            region physicalArena = new region(/* bytes= */ 1, /* allocations= */ 1);
            bytes physicalBytes = allocateBytes(physicalArena, 1);
            setByte(physicalBytes, 0, 120);
            utf8 physical = freezeUtf8(physicalBytes);
            boolean initialized = initializeSourceTable(
              /* sourceCount= */ 2,
              physical,
              physical,
              physical,
              physical,
              physical,
              physical,
              physical,
              storage,
              lengths
            );
            assert(initialized);
            boolean replaced = replaceSourceTableSlot(
              /* index= */ 1,
              /* sourceCount= */ 2,
              replacement,
              storage,
              lengths
            );
            assert(replaced);
            long length = sourceTableSlotLength(1, 2, lengths);
            region copyArena = new region(/* bytes= */ 32768, /* allocations= */ 1);
            bytes copiedBytes = allocateBytes(copyArena, length);
            long written = copySourceTableSlot(1, 2, storage, lengths, copiedBytes);
            assert(written == length);
            utf8 copied = freezeUtf8(copiedBytes);
            assert(bufferLength(copied) == bufferLength(replacement));
            assert(utf8Scalar(copied, 0) == utf8Scalar(replacement, 0));
            setByte(output, 0, 1);
            drop(copied);
            drop(copyArena);
            drop(physical);
            drop(physicalArena);
            drop(lengths);
            drop(storage);
            drop(tableArena);
          }
        }
        """;
    Program acceptedProgram = new WheelerCompiler().compileModuleFiles(
        Map.of("CountedSourceTable.w", root, "SourceTable.w", table),
        "example.counted_source_table");
    VirtualMachine accepted = new VirtualMachine(
        acceptedProgram,
        "linked".getBytes(StandardCharsets.UTF_8),
        1);

    accepted.run();

    assertArrayEquals(new byte[] {1}, accepted.hostOutput());

    String rejectedRoot = root
        .replace("assert(replaced);", "assert(replaced == false);")
        .replace(
            "assert(bufferLength(copied) == bufferLength(replacement));",
            "assert(bufferLength(copied) == 1);")
        .replace(
            "assert(utf8Scalar(copied, 0) == utf8Scalar(replacement, 0));",
            "assert(utf8Scalar(copied, 0) == 120);");
    Program rejectedProgram = new WheelerCompiler().compileModuleFiles(
        Map.of("CountedSourceTable.w", rejectedRoot, "SourceTable.w", table),
        "example.counted_source_table");
    VirtualMachine oversized = new VirtualMachine(
        rejectedProgram,
        "x".repeat(32_769).getBytes(StandardCharsets.UTF_8),
        1);

    oversized.run();

    assertArrayEquals(new byte[] {1}, oversized.hostOutput());

    Program invalidIndexProgram = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "CountedSourceTable.w", rejectedRoot.replace("/* index= */ 1", "/* index= */ 2"),
            "SourceTable.w", table),
        "example.counted_source_table");
    VirtualMachine invalidIndex = new VirtualMachine(
        invalidIndexProgram,
        "linked".getBytes(StandardCharsets.UTF_8),
        1);

    invalidIndex.run();

    assertArrayEquals(new byte[] {1}, invalidIndex.hostOutput());
  }

  @Test
  void rejectsAnEighthSourceBeforeTableMutation() throws Exception {
    String table = CompilerSources.read("compiler/graphs/plans/SourceTable.w");
    String root = """
        module example.source_table_count;

        import wheeler.compiler.graphs.source_table;

        classical class SourceTableCount {
          entry void main(borrow utf8 source, borrow mut bytes output) {
            region tableArena = new region(/* bytes= */ 229432, /* allocations= */ 2);
            bytes storage = allocateBytes(tableArena, SOURCE_TABLE_BYTES);
            words lengths = allocate(tableArena, SOURCE_TABLE_LENGTH_WORDS);
            boolean initialized = initializeSourceTable(
              8,
              source,
              source,
              source,
              source,
              source,
              source,
              source,
              storage,
              lengths
            );
            assert(initialized == false);
            assert(lengths[0] == 0);
            setByte(output, 0, 1);
            drop(lengths);
            drop(storage);
            drop(tableArena);
          }
        }
        """;
    Program program = new WheelerCompiler().compileModuleFiles(
        Map.of("SourceTableCount.w", root, "SourceTable.w", table),
        "example.source_table_count");
    VirtualMachine machine = new VirtualMachine(
        program,
        "physical".getBytes(StandardCharsets.UTF_8),
        1);

    machine.run();

    assertArrayEquals(new byte[] {1}, machine.hostOutput());
  }

  @Test
  void exposesOneCompleteValidatedGraphPlan() throws Exception {
    String matrix = CompilerSources.read("compiler/graphs/Matrix.w");
    String root = """
        module example.graph_plan_access;

        import wheeler.compiler.graphs.matrix;

        classical class GraphPlanAccess {
          entry void main() {
            region arena = new region(/* bytes= */ 96, /* allocations= */ 5);
            words graph = allocate(arena, 4);
            words rootDirect = allocate(arena, 2);
            words rootRanks = allocate(arena, 2);
            words order = allocate(arena, 2);
            words reachable = allocate(arena, 2);
            set(graph, 1, 1);
            set(rootDirect, 1, 1);
            set(rootRanks, 0, -1);
            set(rootRanks, 1, 0);
            BoundedGraphPlan plan = planBoundedGraph(
              graph,
              rootDirect,
              rootRanks,
              2,
              order,
              reachable
            );
            assert(plan.valid);
            assert(plannedNodeAt(plan, 0) == 0);
            assert(plannedNodeAt(plan, 1) == 1);
            assert(plannedRootRankAt(plan, 0) == -1);
            assert(plannedRootRankAt(plan, 1) == 0);
            assert(plannedRootDirect(plan, 0) == false);
            assert(plannedRootDirect(plan, 1));
            assert(plannedPrivate(plan, 0));
            assert(plannedPrivate(plan, 1) == false);
            assert(plannedShared(plan, 0) == false);
            assert(plannedEdge(plan, 0, 1));
            assert(plannedEdge(plan, 1, 0) == false);

            set(graph, 1, 0);
            set(rootDirect, 0, 1);
            set(rootRanks, 0, 0);
            BoundedGraphPlan duplicateRank = planBoundedGraph(
              graph,
              rootDirect,
              rootRanks,
              2,
              order,
              reachable
            );
            assert(duplicateRank.valid == false);
            drop(reachable);
            drop(order);
            drop(rootRanks);
            drop(rootDirect);
            drop(graph);
            drop(arena);
          }
        }
        """;
    Program accessor = new WheelerCompiler().compileModuleFiles(
        Map.of("Matrix.w", matrix, "GraphPlanAccess.w", root),
        "example.graph_plan_access");
    VirtualMachine machine = new VirtualMachine(accessor);

    machine.run();
  }


}
