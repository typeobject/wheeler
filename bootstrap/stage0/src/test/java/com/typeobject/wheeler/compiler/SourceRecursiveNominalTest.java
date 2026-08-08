package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Canonical lowering evidence for recursive nominal descriptor references. */
final class SourceRecursiveNominalTest {
  @Test
  void lowersSelfRecursiveRecordReferences() {
    String source = """
        module fixture.recursive_record;

        classical class RecursiveRecord {
          public record Node(Node next) {}

          public Node identity(Node value) {
            return value;
          }
        }
        """;

    var program = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("RecursiveRecord.w", source), "fixture.recursive_record");

    assertEquals(
        ValueType.record(0), program.recordTypes().getFirst().fields().getFirst().type());
    assertEquals(ValueType.record(0), program.functions().getFirst().localTypes().getFirst());
    assertArrayEquals(
        new BytecodeWriter().write(program),
        new BytecodeWriter().write(new BytecodeReader().read(new BytecodeWriter().write(program))));
  }

  @Test
  void executesFiniteValuesAcrossARecursiveDescriptorCycle() {
    String source = """
        module fixture.recursive_values;

        classical class RecursiveValues {
          state long observed = 0;

          record Link(Chain next) {}

          variant Chain {
            case End();
            case Next(Link link);
          }

          entry void main() {
            Chain end = new Chain.End();
            Link link = new Link(end);
            Chain next = new Chain.Next(link);
            match (next) {
              case Chain.End() {
                assert(false);
              }
              case Chain.Next(Link value) {
                observed = 1;
              }
            }
          }
        }
        """;
    var program = new WheelerCompiler().compileModuleFiles(
        Map.of("RecursiveValues.w", source), "fixture.recursive_values");
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(1, machine.global("observed"));
  }

  @Test
  void lowersMutuallyRecursiveRecordsAndVariants() {
    String source = """
        module fixture.mutual_nominals;

        classical class MutualNominals {
          public record Link(Chain next) {}

          public variant Chain {
            case End();
            case Next(Link link);
          }

          public Chain identity(Chain value) {
            return value;
          }
        }
        """;

    var program = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("MutualNominals.w", source), "fixture.mutual_nominals");

    assertEquals(
        ValueType.variant(0), program.recordTypes().getFirst().fields().getFirst().type());
    assertEquals(
        ValueType.record(0),
        program.variantTypes().getFirst().cases().get(1).fields().getFirst().type());
    assertEquals(ValueType.variant(0), program.functions().getFirst().resultType());
  }
}
