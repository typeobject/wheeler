package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class Utf8LexerExampleTest {
  @Test
  void explicitSourceInputIsTokenizedParsedAndExactlyRewound() throws Exception {
    var program = new WheelerCompiler().compile(
        Path.of("src/main/wheeler/Utf8Lexer.w"));
    VirtualMachine machine = new VirtualMachine(
        program, "x=123;//c\n".getBytes(StandardCharsets.UTF_8));
    var initial = machine.snapshot();

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(5, machine.global("tokenCount"));
    assertEquals(2, machine.global("numberStart"));
    assertEquals(6, machine.global("commentStart"));
    assertEquals(123, machine.global("numericValue"));
    assertEquals(10, machine.global("finalCursor"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }
}
