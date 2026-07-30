package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import org.junit.jupiter.api.Test;

/** Verifies that finite enums use the canonical payload-free variant path. */
final class SourceEnumTest {
  @Test
  void finiteEnumsUseThePayloadFreeVariantPath() {
    String source = """
        classical class Directions {
          enum Direction {
            case Left;
            case Right;
          }
          state long selected = 0;
          entry void main() {
            Direction direction = new Direction.Right();
            match (direction) {
              case Direction.Left() { selected = 1; }
              case Direction.Right() { selected = 2; }
            }
            assert(selected == 2);
          }
        }
        """;
    WheelerCompiler compiler = new WheelerCompiler();
    Program program = compiler.compile(source);
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(1, program.variantTypes().size());
    assertTrue(program.variantTypes().getFirst().cases().stream()
        .allMatch(variantCase -> variantCase.fields().isEmpty()));
    byte[] enumArtifact = compiler.compileToBytecode(source);
    assertArrayEquals(
        enumArtifact,
        compiler.compileToBytecode(source.replace(
            "case Left;\n    case Right;",
            "case Right;\n    case Left;")));
    assertArrayEquals(
        enumArtifact,
        compiler.compileToBytecode(source.replace(
            "enum Direction {\n    case Left;\n    case Right;\n  }",
            "variant Direction {\n    case Left();\n    case Right();\n  }")));
    Program leftProgram = compiler.compile(source
        .replace("new Direction.Right()", "new Direction.Left()")
        .replace("assert(selected == 2)", "assert(selected == 1)"));
    VirtualMachine leftMachine = new VirtualMachine(leftProgram);
    leftMachine.run();
    assertEquals(1, leftMachine.global("selected"));
    assertEquals(2, machine.global("selected"));
  }
}
