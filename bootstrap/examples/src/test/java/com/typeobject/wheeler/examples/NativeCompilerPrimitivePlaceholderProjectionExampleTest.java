package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for removing primitive aggregate-expression placeholders. */
final class NativeCompilerPrimitivePlaceholderProjectionExampleTest {
  @Test
  void removesOneExactZeroPlaceholderAndAdjustsItsSplice() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), code(0), 1);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(1, machine.global("placementValid"));
    assertEquals(1, machine.global("instructionCount"));
    assertEquals(8, machine.global("functionLength"));
    assertEquals(1, machine.global("remainingOpcode"));
    assertEquals(24, machine.global("remainingOffset"));
    assertEquals(0, machine.global("adjustedPlacement"));
  }

  @Test
  void removesAnExactAssignmentTemporaryBridge() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), bridgedCode(), 1);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(1, machine.global("instructionCount"));
    assertEquals(8, machine.global("functionLength"));
    assertEquals(1, machine.global("remainingOpcode"));
    assertEquals(48, machine.global("remainingOffset"));
  }

  @Test
  void rejectsANonzeroPlaceholderBeforeProjectionMutation() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), code(1), 1);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("placementValid"));
    assertEquals(0, machine.global("instructionCount"));
    assertEquals(91, machine.global("remainingOpcode"));
  }

  private static byte[] bridgedCode() {
    return ByteBuffer.allocate(56).order(ByteOrder.LITTLE_ENDIAN)
        .putShort((short) 0x0400).putShort((short) 2).putInt(24)
        .putLong(2).putLong(0)
        .putShort((short) 0x0403).putShort((short) 2).putInt(24)
        .putLong(3).putLong(2)
        .putShort((short) 1).putShort((short) 0).putInt(8)
        .array();
  }

  private static byte[] code(long value) {
    return ByteBuffer.allocate(32).order(ByteOrder.LITTLE_ENDIAN)
        .putShort((short) 0x0400).putShort((short) 2).putInt(24)
        .putLong(3).putLong(value)
        .putShort((short) 1).putShort((short) 0).putInt(8)
        .array();
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.primitive_placeholder_projection"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_placeholder_placements"));
    sources.put("PrimitivePlaceholderProjectionExample.w", """
        module example.primitive_placeholder_projection;

        import wheeler.compiler.closure.aggregate_placeholder_placements;
        import wheeler.compiler.closure.primitive_placeholder_projection;

        classical class PrimitivePlaceholderProjectionExample {
          state long valid = 0;
          state long placementValid = 0;
          state long instructionCount = 0;
          state long functionLength = 0;
          state long remainingOpcode = 0;
          state long remainingOffset = 0;
          state long adjustedPlacement = -1;

          entry void main(borrow byteview input, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 438272, /* allocations= */ 10);
            words functions = allocate(rows, /* length= */ 640);
            words instructions = allocate(rows, /* length= */ 24576);
            words operations = allocate(rows, /* length= */ 2048);
            words destinations = allocate(rows, /* length= */ 256);
            words operationFunctions = allocate(rows, /* length= */ 256);
            words operationDirections = allocate(rows, /* length= */ 256);
            words placements = allocate(rows, /* length= */ 768);
            words projectedFunctions = allocate(rows, /* length= */ 640);
            words projectedInstructions = allocate(rows, /* length= */ 24576);
            words projectedPlacements = allocate(rows, /* length= */ 768);
            set(functions, 0, 0);
            set(functions, 192, bufferLength(input));
            set(instructions, 0, 0);
            set(instructions, 8192, 0);
            set(instructions, 12288, 0x0400);
            set(instructions, 16384, 2);
            set(instructions, 20480, 24);
            long primitiveInstructionCount = 2;
            if (bufferLength(input) == 56) {
              set(instructions, 1, 0);
              set(instructions, 8193, 24);
              set(instructions, 12289, 0x0403);
              set(instructions, 16385, 2);
              set(instructions, 20481, 24);
              set(instructions, 2, 0);
              set(instructions, 8194, 48);
              set(instructions, 12290, 1);
              set(instructions, 16386, 0);
              set(instructions, 20482, 8);
              primitiveInstructionCount = 3;
            } else {
              set(instructions, 1, 0);
              set(instructions, 8193, 24);
              set(instructions, 12289, 1);
              set(instructions, 16385, 0);
              set(instructions, 20481, 8);
            }
            set(operations, 1280, 12);
            set(operations, 1536, 2);
            set(operations, 1281, 10);
            set(operations, 1537, 5);
            set(destinations, 0, 4);
            set(destinations, 1, 3);
            set(placements, 0, 91);
            set(projectedInstructions, 12288, 91);
            AggregatePlaceholderPlacementPlan placementPlan =
              deriveAggregatePlaceholderPlacements(
                input,
                bufferLength(input),
                /* functionCount= */ 1,
                primitiveInstructionCount,
                instructions,
                /* operationCount= */ 2,
                operations,
                destinations,
                operationFunctions,
                operationDirections,
                placements
              );
            if (placementPlan.valid) {
              placementValid = 1;
            }
            PrimitivePlaceholderProjectionPlan plan = projectPrimitiveAggregatePlaceholders(
              input,
              bufferLength(input),
              /* functionCount= */ 1,
              functions,
              primitiveInstructionCount,
              instructions,
              /* operationCount= */ 2,
              operations,
              destinations,
              placements,
              projectedFunctions,
              projectedInstructions,
              projectedPlacements
            );
            if (plan.valid) {
              valid = 1;
            }
            instructionCount = plan.instructionCount;
            functionLength = projectedFunctions[192];
            remainingOpcode = projectedInstructions[12288];
            remainingOffset = projectedInstructions[8192];
            adjustedPlacement = projectedPlacements[512];
            setOutputLength(output, 0);
            drop(projectedPlacements);
            drop(projectedInstructions);
            drop(projectedFunctions);
            drop(placements);
            drop(operationDirections);
            drop(operationFunctions);
            drop(destinations);
            drop(operations);
            drop(instructions);
            drop(functions);
            drop(rows);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.primitive_placeholder_projection");
  }
}
