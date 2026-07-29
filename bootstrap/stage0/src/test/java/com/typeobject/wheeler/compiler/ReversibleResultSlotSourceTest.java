package com.typeobject.wheeler.compiler;

import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.IMMEDIATE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.SOURCE;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Disassembler;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import org.junit.jupiter.api.Test;

/** Source, metadata, and runtime coverage for reversible signed result slots. */
class ReversibleResultSlotSourceTest {
  private static final String MINUS_ONE = """
      classical class ReversibleResult {
        rev long minusOne() {
          return -1;
        }

        theorem minusOneInverse proves inverse(minusOne);

        entry void main() {
          long value = minusOne();
          assert(value == -1);
        }
      }
      """;

  @Test
  void compilesAndExecutesAReversibleConstantResult() {
    WheelerCompiler compiler = new WheelerCompiler();
    byte[] artifact = compiler.compileToBytecode(MINUS_ONE);
    Program program = new BytecodeReader().read(artifact);
    var function = program.function(0);

    assertTrue(function.implicitResultSlot());
    assertEquals(Opcode.RESULT_FILL_CONSTANT, function.forward().getFirst().opcode());
    assertEquals(Opcode.RETURN_RESULT_SLOT, function.forward().getLast().opcode());
    assertEquals(function.forward(), function.inverse());
    assertEquals(1, program.proofCertificates().size());
    String disassembly = new Disassembler().disassemble(program);
    assertTrue(disassembly.contains("result=signed result-slot"));
    assertTrue(disassembly.contains("RESULT_FILL_CONSTANT result_slot=0, immediate=-1"));
    assertArrayEquals(artifact, new BytecodeWriter().write(program));

    VirtualMachine machine = new VirtualMachine(program);
    machine.run();
    assertEquals(MachineStatus.HALTED, machine.status());
  }

  @Test
  void acceptsAnEvaluatedClassConstantResult() {
    String source = "classical class ConstantResult { const long RESULT = -1; "
        + "rev long answer() { return RESULT; } entry void main() { "
        + "long value = answer(); assert(value == -1); } }";
    Program program = new WheelerCompiler().compile(source);
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(-1, program.function(0).forward().getFirst().operand(IMMEDIATE));
  }

  @Test
  void passesOneSignedParameterBesideTheResultSlot() {
    String source = "classical class ParameterResult { rev long answer(long ignored) { "
        + "return -1; } entry void main() { long value = answer(42); "
        + "assert(value == -1); } }";
    Program program = new WheelerCompiler().compile(source);
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(1, program.function(0).parameterCount());
    assertTrue(program.function(0).implicitResultSlot());
  }

  @Test
  void preservesASignedParameterAsTheResultRelation() {
    String source = "classical class PreservedResult { rev long identity(long value) { "
        + "return value; } entry void main() { long answer = identity(42); "
        + "assert(answer == 42); } }";
    Program program = new WheelerCompiler().compile(source);
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(Opcode.RESULT_FILL_SOURCE, program.function(0).forward().getFirst().opcode());
    assertEquals(0, program.function(0).forward().getFirst().operand(SOURCE));
  }

  @Test
  void rejectsResultsOutsideTheFirstClosedProfile() {
    WheelerCompiler compiler = new WheelerCompiler();
    CompilerException booleanResult = assertThrows(
        CompilerException.class,
        () -> compiler.compile("classical class Bad { rev boolean answer() { return true; } "
            + "entry void main() {} }"));
    CompilerException computedResult = assertThrows(
        CompilerException.class,
        () -> compiler.compile("classical class Bad { rev long answer() { return 1 + 2; } "
            + "entry void main() {} }"));
    CompilerException erasingBody = assertThrows(
        CompilerException.class,
        () -> compiler.compile("classical class Bad { state long value = 0; "
            + "rev long answer() { value = 1; return -1; } entry void main() {} }"));
    CompilerException voidParameter = assertThrows(
        CompilerException.class,
        () -> compiler.compile("classical class Bad { rev void step(long value) {} "
            + "entry void main() {} }"));
    CompilerException booleanSource = assertThrows(
        CompilerException.class,
        () -> compiler.compile("classical class Bad { rev long answer(boolean value) { "
            + "return value; } entry void main() {} }"));

    assertTrue(booleanResult.getMessage().contains("first reversible result-slot profile"));
    assertTrue(computedResult.getMessage().contains("return one signed constant"));
    assertTrue(erasingBody.getMessage().contains("return one signed constant"));
    assertTrue(voidParameter.getMessage().contains("reversible void parameters"));
    assertTrue(booleanSource.getMessage().contains("preserve one signed parameter"));
  }
}
