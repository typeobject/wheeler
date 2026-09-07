package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** The seven-argument encoder retains its frame and argument contract for global stores. */
final class NativeCompilerGlobalCallEncodingExampleTest {
  @Test
  void matchesEveryInstructionForZeroThroughSevenGlobalCallArgumentsAndRewinds() throws Exception {
    Program encoder = encoder();
    for (int arity = 0; arity <= 7; arity++) {
      String parameters = String.join(", ", IntStream.range(0, arity).mapToObj(i -> "long p" + i).toList());
      String locals = String.join(" ", IntStream.range(0, arity)
          .mapToObj(i -> "long v" + i + " = 7;").toList());
      String arguments = String.join(", ", IntStream.range(0, arity).mapToObj(i -> "v" + i).toList());
      String source = "module example.call; classical class Calls { state long observed = 0; "
          + "long helper(" + parameters + ") { return " + (arity == 0 ? "7" : "p0") + "; } "
          + "entry void main() { " + locals + " observed = helper(" + arguments + "); } }";
      var artifact = new WheelerCompiler().compileModuleFiles(Map.of("Test.w", source), "example.call");
      var body = artifact.function(artifact.entryFunctionId()).forward();
      int helper = artifact.functions().stream().filter(f -> f.id() != artifact.entryFunctionId())
          .findFirst().orElseThrow().id();
      byte[] expected = NativeInstructionBytes.encode(body.subList(arity * 2, body.size() - 1));
      long first = 0;
      long last = 0;
      for (int argument = 0; argument < arity; argument++) {
        long local = argument * 2 + 1;
        if (argument < 4) { first |= local << (argument * 8); }
        else { last |= local << ((argument - 4) * 8); }
      }
      var machine = VirtualMachine.withBinaryInput(encoder, input(arity, first, last, helper), expected.length);
      var initial = machine.snapshot();
      machine.run();
      assertArrayEquals(expected, machine.hostOutput(), "arity " + arity);
      while (machine.historySize() > 0) { machine.rewindOne(); }
      assertEquals(initial, machine.snapshot());
    }
    for (long arity : List.of(-1L, 8L, Long.MIN_VALUE, Long.MAX_VALUE)) {
      var machine = VirtualMachine.withBinaryInput(encoder, input(arity, 0, 0, 0), 64);
      var initial = machine.snapshot();
      assertThrows(VmTrap.class, machine::run);
      assertArrayEquals(new byte[64], machine.hostOutput());
      while (machine.historySize() > 0) { machine.rewindOne(); }
      assertEquals(initial, machine.snapshot());
    }
  }

  private static byte[] input(long arity, long first, long last, long helper) {
    return ByteBuffer.allocate(32).order(ByteOrder.LITTLE_ENDIAN)
        .putLong(arity).putLong(first).putLong(last).putLong(helper).array();
  }

  private static Program encoder() throws Exception {
    var modules = new LinkedHashMap<String, String>();
    modules.putAll(CompilerSources.moduleClosure("wheeler.compiler.assignment_call_codegen"));
    modules.putAll(CompilerSources.moduleClosure("wheeler.compiler.assignment_call_kinds"));
    CoreSources.addBinaryClosure(modules);
    modules.put("GlobalCallEncoder.w", """
        module example.global_call_encoder;
        import wheeler.compiler.assignment_call_codegen;
        import wheeler.compiler.assignment_call_kinds;
        import wheeler.core.encoding.binary;
        classical class GlobalCallEncoder {
          entry void main(borrow byteview input, borrow mut bytes output) {
            long arity = readSigned(input, 0);
            long first = readSigned(input, 8);
            long last = readSigned(input, 16);
            long helper = readSigned(input, 24);
            long opcode = resolvedGlobalAssignmentCall(arity);
            assert(-1 < opcode);
            long length = writeAssignmentCallStatement(
              output, 0, opcode, first, last, arity * 2, helper, 1, 1, 1, 1, 1, 1, 1
            );
            assert(length == bufferLength(output));
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(modules, "example.global_call_encoder");
  }
}
