package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.EnumSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.TreeSet;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;

/** Explicit membership cannot admit a numeric hole or a newly allocated opcode by accident. */
final class NativeStaticStepPolicyExampleTest {
  @Test
  void checksEveryRegisteredOpcodeNumericGapsAndSignedExtremesAndRewinds() throws Exception {
    var rejected = EnumSet.of(Opcode.CALL, Opcode.UNCALL, Opcode.CALL_VALUE, Opcode.CALL_VOID,
        Opcode.CALL_RESULT_SLOT, Opcode.UNCALL_RESULT_SLOT, Opcode.JUMP, Opcode.JUMP_IF_ZERO,
        Opcode.NOP, Opcode.SWAP, Opcode.SET_LOGGED, Opcode.CHECKPOINT, Opcode.COMMIT,
        Opcode.OUTPUT_LENGTH);
    var accepted = EnumSet.allOf(Opcode.class);
    accepted.removeAll(rejected);
    var codes = accepted.stream().map(opcode -> (long) opcode.code()).collect(Collectors.toSet());
    assertEquals(61, codes.size());
    var candidates = new TreeSet<Long>(List.of(Long.MIN_VALUE, -1L, 65535L, 65536L, Long.MAX_VALUE));
    for (Opcode opcode : Opcode.values()) {
      candidates.add((long) opcode.code() - 1);
      candidates.add((long) opcode.code());
      candidates.add((long) opcode.code() + 1);
    }
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.static_step_opcodes"));
    CoreSources.addBinaryClosure(modules);
    modules.put("StaticStepPolicy.w", """
        module example.static_step_policy;
        import wheeler.compiler.static_step_opcodes;
        import wheeler.core.encoding.binary;
        classical class StaticStepPolicy {
          state long admitted = 0;
          entry void main(borrow byteview input) {
            if (staticStepOpcodeAllowed(readSigned(input, 0))) {
              admitted = 1;
            }
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(modules, "example.static_step_policy");
    for (long opcode : candidates) {
      byte[] input = ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN).putLong(opcode).array();
      var machine = VirtualMachine.withBinaryInput(program, input);
      var initial = machine.snapshot();
      machine.run();
      assertEquals(codes.contains(opcode) ? 1 : 0, machine.global("admitted"), "opcode " + opcode);
      while (machine.historySize() > 0) {
        machine.rewindOne();
      }
      assertEquals(initial, machine.snapshot());
    }
  }

  @Test
  void retainsTheCompletePhysicalStaticStepPolicyArtifact() throws Exception {
    var program = NativeCompilerSelfSourceExampleTest.assertImportedConstantCompilerLibrary(
        "compiler/verification/StaticStepOpcodes.w", "wheeler.compiler.static_step_opcodes");
    assertEquals(4, program.functions().size());
  }
}
