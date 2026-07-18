package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class HostBinaryInputExampleTest {
  @Test
  void immutableBinaryInputExecutesPublishesAndRewinds() throws Exception {
    WheelerCompiler compiler = new WheelerCompiler();
    var program = compiler.compile(Path.of("src/main/wheeler/HostBinaryInput.w"));
    byte[] encoded = new BytecodeWriter().write(program);
    var decoded = new BytecodeReader().read(encoded);
    assertArrayEquals(encoded, new BytecodeWriter().write(decoded));
    assertEquals(
        ValueType.BYTE_VIEW,
        decoded.function(decoded.entryFunctionId()).localType(0));
    assertThrows(VmTrap.class, () -> new VirtualMachine(decoded));
    assertThrows(
        VmTrap.class,
        () -> new VirtualMachine(decoded, new byte[] {0, 1, 2, 3}, 2));

    byte[] input = {0, (byte) 255, 127, (byte) 128};
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoded, input, 2);
    var initial = machine.snapshot();
    input[1] = 1;

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(4, machine.global("byteLength"));
    assertEquals(0, machine.global("firstByte"));
    assertEquals(255, machine.global("middleByte"));
    assertEquals(128, machine.global("lastByte"));
    assertEquals(510, machine.global("checksum"));
    assertArrayEquals(new byte[] {0, (byte) 128}, machine.hostOutput());
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    var emptyProgram = compiler.compile("""
        classical class EmptyBinary {
          state long length = 1;
          entry void main(byteview source) {
            length = bufferLength(source);
            assert length == 0;
          }
        }
        """);
    VirtualMachine empty = VirtualMachine.withBinaryInput(
        emptyProgram, new byte[0]);
    empty.run();
    assertEquals(0, empty.global("length"));

    assertThrows(
        CompilerException.class,
        () -> compiler.compile("""
            classical class BadBinaryWrite {
              entry void main(byteview input) { setByte(input, 0, 1); }
            }
            """));
    assertThrows(
        CompilerException.class,
        () -> compiler.compile("""
            classical class BadBinaryEscape {
              byteview expose(byteview input) { return input; }
              entry void main() {}
            }
            """));
  }
}
