package com.typeobject.wheeler.examples.globals;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Reversible return emission retains result-slot forms and refuses global locations. */
final class NativeDirectReturnInstructionsExampleTest {
  private static final int CODE_BYTES = 262144;
  private static final int SOURCE = 1;
  private static final int BINARY = 2;
  private static final int BINARY_SOURCES = 3;
  private static final int MOVE = Opcode.LOCAL_MOVE.code();
  private static final int LOAD = Opcode.LOCAL_LOAD_GLOBAL.code();

  @Test
  void preservesSourceImmediateAndTwoSourceResultSlots() throws Exception {
    check(SOURCE, MOVE, MOVE, 0, true);
    check(BINARY, MOVE, MOVE, 0, true);
    check(BINARY_SOURCES, MOVE, MOVE, 0, true);
    int terminal = CODE_BYTES - reference(BINARY).stream().mapToInt(Instruction::encodedLength).sum();
    check(BINARY, MOVE, MOVE, terminal, true);
    check(BINARY, MOVE, MOVE, terminal + 1, false);
  }

  @Test
  void rejectsGlobalSourcesAndOrdinaryLiteralFormsBeforePublishingSlotCode() throws Exception {
    check(SOURCE, LOAD, MOVE, 0, false);
    check(BINARY, LOAD, MOVE, 0, false);
    check(BINARY_SOURCES, MOVE, LOAD, 0, false);
    check(BINARY_SOURCES, LOAD, LOAD, 0, false);
    check(5, MOVE, MOVE, 0, false);
  }

  private static void check(int kind, int leftOpcode, int rightOpcode, int cursor, boolean accepted)
      throws Exception {
    List<Instruction> expectedInstructions = accepted ? reference(kind) : List.of();
    byte[] expected = new byte[CODE_BYTES];
    var bytes = ByteBuffer.wrap(expected).order(ByteOrder.LITTLE_ENDIAN).position(cursor);
    for (var instruction : expectedInstructions) {
      bytes.putShort((short) instruction.opcode().code()).putShort((short) instruction.operands().size())
          .putInt(instruction.encodedLength());
      for (long operand : instruction.operands()) bytes.putLong(operand);
    }
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.closure.direct_return_instructions"));
    sources.put("Sha256.w", Files.readString(Path.of("../wheeler-core/src/main/wheeler/crypto/Sha256.w")));
    sources.put("Driver.w", """
        module example.return_slots;
        import wheeler.compiler.closure.direct_return_instructions;
        import wheeler.compiler.closure.direct_scalar_encoding;
        import wheeler.compiler.closure.direct_scalar_relations;
        import wheeler.compiler.keyword_tokens;
        classical class Driver {
          const long CODE_BYTES = %d;
          state long prepared = 0;
          state long completed = 0;
          state long valid = 0;
          state long next = 0;
          state long count = 0;
          state long width = 0;
          entry void main() {
            region arena = new region(CODE_BYTES, 1);
            bytes code = allocateBytes(arena, CODE_BYTES);
            DirectScalarRelationProduct relation = new DirectScalarRelationProduct(
              %d, %d, 0, 1, -7, TOKEN_LONG, TOKEN_LONG, %d, %d, true);
            prepared = 1;
            DirectScalarExtent result = writeDirectReturnInstructions(relation, 1, code, %d, 2);
            if (result.valid) { valid = 1; }
            next = result.next; count = result.instructionCount; width = result.localCount;
            completed = 1;
            drop(code); drop(arena);
          }
        }
        """.formatted(CODE_BYTES, kind, kind == SOURCE ? 0 : Opcode.LOCAL_ADD.code(), leftOpcode, rightOpcode, cursor));
    var program = new WheelerCompiler().compileModuleFiles(sources, "example.return_slots");
    var machine = new VirtualMachine(program);
    while (machine.global("prepared") == 0) machine.stepWithoutRewindHistory();
    var before = machine.snapshot();
    while (machine.global("completed") == 0) machine.step();
    var after = machine.snapshot();
    assertEquals(accepted ? 1 : 0, machine.global("valid"));
    assertEquals(accepted ? bytes.position() : 0, machine.global("next"));
    assertEquals(expectedInstructions.size(), machine.global("count"));
    assertEquals(accepted ? 1 : 0, machine.global("width"));
    byte[] actual = new byte[CODE_BYTES];
    var buffer = after.buffers().getFirst();
    for (int index = 0; index < CODE_BYTES; index++) actual[index] = buffer.elements().get(index).byteValue();
    assertArrayEquals(expected, actual);
    assertEquals(before.regions(), after.regions());
    assertEquals(before.buffers().size(), after.buffers().size());
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
    while (machine.global("completed") == 0) machine.step();
    assertEquals(after, machine.snapshot());
    machine.run();
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
  }

  private static List<Instruction> reference(int kind) {
    Instruction fill = switch (kind) {
      case SOURCE -> Instruction.of(Opcode.RESULT_FILL_SOURCE, 2, 0);
      case BINARY -> Instruction.of(Opcode.RESULT_FILL_BINARY, 2, 0, Opcode.LOCAL_ADD.code(), -7);
      case BINARY_SOURCES -> Instruction.of(Opcode.RESULT_FILL_BINARY_SOURCES, 2, 0, Opcode.LOCAL_ADD.code(), 1);
      default -> throw new IllegalArgumentException("Not a result-slot relation: " + kind);
    };
    return List.of(fill, Instruction.of(Opcode.RETURN_RESULT_SLOT, 2));
  }
}
