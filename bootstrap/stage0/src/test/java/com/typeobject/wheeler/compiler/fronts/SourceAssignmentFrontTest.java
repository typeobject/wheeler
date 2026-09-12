package com.typeobject.wheeler.compiler.fronts;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/** An assignment operator disambiguates an uppercase binding from a nominal declaration. */
final class SourceAssignmentFrontTest {
  @ParameterizedTest
  @CsvSource({"=,5", "+=,6", "-=,-4", "^=,4"})
  void assignsUppercaseStateWithoutParsingANominalLocal(String operator, long result) {
    String source = "module example.front; classical class Front { state long Seen = 1; "
        + "entry void main() { long Value = 5; Seen " + operator + " Value; } }";
    var program = new WheelerCompiler().compileModuleFiles(Map.of("Source.w", source), "example.front");
    var machine = new VirtualMachine(program);
    machine.run();
    assertEquals(result, machine.global("Seen"));
  }

  @Test
  void keepsNominalDeclarationsAndAssignmentDestinationsDistinct() {
    String source = "module example.front; classical class Front { state long Seen = 0; "
        + "record Pair(long value) {} entry void main() { Pair value = new Pair(5); Seen = value.value; } }";
    var program = new WheelerCompiler().compileModuleFiles(Map.of("Source.w", source), "example.front");
    var machine = new VirtualMachine(program);
    machine.run();
    assertEquals(5, machine.global("Seen"));
    assertThrows(CompilerException.class, () -> new WheelerCompiler().compileModuleFiles(
        Map.of("Source.w", source.replace("Seen = value.value", "Missing = value.value")), "example.front"));
  }
}
