package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import org.junit.jupiter.api.Test;

class WheelerCompilerTest {
  private static final String COUNTER = """
      wheeler 1
      program Counter
      kind classical
      state count = 0

      rev coherent increment {
        add count 1
      }

      entry {
        call increment
        call increment
        expect count 2
        uncall increment
        uncall increment
        expect count 0
        halt
      }
      """;

  @Test
  void compilesAndRunsCounter() {
    WheelerCompiler compiler = new WheelerCompiler();
    Program program = compiler.compile(COUNTER);
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(0, machine.global("count"));
    assertEquals(Opcode.ADD_CONST, program.function(0).forward().getFirst().opcode());
    assertEquals(Opcode.SUB_CONST, program.function(0).inverse().getFirst().opcode());
  }

  @Test
  void sourceProducesCanonicalBytecode() {
    WheelerCompiler compiler = new WheelerCompiler();
    byte[] encoded = compiler.compileToBytecode(COUNTER);
    byte[] reencoded = new BytecodeWriter().write(new BytecodeReader().read(encoded));

    assertArrayEquals(encoded, reencoded);
  }

  @Test
  void reportsSourceErrorsWithLines() {
    CompilerException unknown = assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compile(COUNTER.replace("add count 1", "add missing 1")));
    CompilerException irreversible = assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compile(COUNTER.replace("add count 1", "set count 1")));

    assertTrue(unknown.getMessage().contains("line 7"));
    assertTrue(irreversible.getMessage().contains("no generated inverse"));
  }
}
