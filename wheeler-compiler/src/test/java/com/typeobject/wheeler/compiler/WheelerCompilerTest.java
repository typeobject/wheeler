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
      classical class Counter {
        state long count = 0;

        rev void increment() {
          count += 1;
        }

        entry void main() {
          increment();
          increment();
          assert count == 2;
          reverse {
            increment();
            increment();
          }
          assert count == 0;
        }
      }
      """;

  @Test
  void compactFormattingHasTheSameSemantics() {
    String compact = "classical class Tiny{state long x=0;rev void flip(){x^=1;}"
        + "entry void main(){flip();reverse flip();assert x==0;}}";

    Program program = new WheelerCompiler().compile(compact);
    VirtualMachine machine = new VirtualMachine(program);
    machine.run();

    assertEquals(0, machine.global("x"));
  }

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
  void rejectsCheckedArithmeticFromTheCoherentSubset() {
    CompilerException exception = assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compile(COUNTER.replace("rev void increment", "coherent rev void increment")));

    assertTrue(exception.getMessage().contains("coherent function contains ADD_CONST"));
  }

  @Test
  void reportsSourceErrorsWithLines() {
    CompilerException unknown = assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compile(COUNTER.replace("count += 1", "missing += 1")));
    CompilerException irreversible = assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compile(COUNTER.replace("count += 1", "count = 1")));

    assertTrue(unknown.getMessage().contains("line 5"));
    assertTrue(irreversible.getMessage().contains("no generated inverse"));
  }
}
