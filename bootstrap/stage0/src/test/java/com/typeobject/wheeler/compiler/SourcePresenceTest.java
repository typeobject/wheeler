package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Conformance tests for compiler-owned completion and closed presence values. */
final class SourcePresenceTest {
  @Test
  void doneIsTheSoleTypedCompletionValue() {
    WheelerCompiler compiler = new WheelerCompiler();
    Program program = compiler.compile("""
        classical class Completion {
          record Receipt(Done completion) {}
          Done complete() { return done; }
          entry void main() {
            Receipt first = new Receipt(complete());
            Receipt second = new Receipt(done);
            assert(first == second);
          }
        }
        """);

    byte[] artifact = new BytecodeWriter().write(program);
    Program decoded = new BytecodeReader().read(artifact);
    assertArrayEquals(artifact, new BytecodeWriter().write(decoded));
    var complete = decoded.functions().stream()
        .filter(function -> function.name().equals("complete"))
        .findFirst()
        .orElseThrow();
    assertEquals(ValueType.DONE, complete.resultType());
    assertEquals(List.of(ValueType.DONE), complete.localTypes());
    assertEquals(Opcode.LOCAL_CONST, complete.forward().getFirst().opcode());
    assertEquals(Opcode.RETURN_VALUE, complete.forward().get(1).opcode());

    VirtualMachine machine = new VirtualMachine(decoded);
    machine.run();
    assertEquals(1, machine.snapshot().selectedFrames().size());
  }

  @Test
  void closedSlotsEncodePresenceWithoutAmbientNulls() {
    Program program = new WheelerCompiler().compile("""
        classical class Presence {
          state long selected = 0;

          Slot<long> choose(boolean present, long value) {
            if (present) {
              return new Slot<long>.Holding(value);
            }
            return new Slot<long>.Vacant();
          }

          entry void main() {
            Slot<long> found = choose(true, 9);
            match (found) {
              case Slot<long>.Vacant() { selected = -1; }
              case Slot<long>.Holding(long value) { selected = value; }
            }

            Slot<Slot<long>> nested =
              new Slot<Slot<long>>.Holding(new Slot<long>.Vacant());
            match (nested) {
              case Slot<Slot<long>>.Vacant() { selected = -2; }
              case Slot<Slot<long>>.Holding(Slot<long> inner) {
                if (inner == new Slot<long>.Vacant()) { selected += 1; }
              }
            }
            Slot<Done> completion = new Slot<Done>.Holding(done);
            match (completion) {
              case Slot<Done>.Vacant() { selected = -3; }
              case Slot<Done>.Holding(Done finished) { selected += 1; }
            }

            Slot<long[2]> pairSlot =
              new Slot<long[2]>.Holding(new long[2](2, 3));
            match (pairSlot) {
              case Slot<long[2]>.Vacant() { selected = -4; }
              case Slot<long[2]>.Holding(long[2] pair) { selected += pair[1]; }
            }
            assert(selected == 14);
          }
        }
        """);

    assertEquals(
        List.of("Slot<long>", "Slot<Slot<long>>", "Slot<Done>", "Slot<long[2]>"),
        program.variantTypes().stream().map(type -> type.name()).toList());
    assertEquals(
        List.of("Vacant", "Holding"),
        program.variantTypes().getFirst().cases().stream()
            .map(variantCase -> variantCase.name())
            .toList());

    VirtualMachine machine = new VirtualMachine(program);
    machine.run();
    assertEquals(14, machine.global("selected"));
  }
}
