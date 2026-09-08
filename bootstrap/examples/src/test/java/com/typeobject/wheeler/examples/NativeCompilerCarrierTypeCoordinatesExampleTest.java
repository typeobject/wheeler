package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Frame-local carrier coordinates do not include the serialized result-type prefix. */
final class NativeCompilerCarrierTypeCoordinatesExampleTest {
  @Test
  void preservesScalarResultsWhenRestoringTheFirstNominalParameter() throws Exception {
    for (String result : List.of("long", "boolean", "void", "Done", "rev long", "rev boolean")) {
      for (String nominal : List.of("Box", "Choice")) {
        assertRestored(source("long", result), source(nominal, result), 0, nominal);
      }
    }
  }

  @Test
  void relocatesNominalResultsWithoutTreatingThemAsLocalZero() throws Exception {
    for (String result : List.of("Box", "Choice")) {
      for (String nominal : List.of("Box", "Choice")) {
        assertRestored(source("long", result), source(nominal, result), 0, nominal);
      }
    }
  }

  @Test
  void relocatesNominalResultDescriptorsSeparatelyFromCarrierLocals() throws Exception {
    for (int aggregate = 0; aggregate < 2; aggregate++) {
      String result = aggregate == 0 ? "Box" : "Choice";
      String parameter = aggregate == 0 ? "Choice" : "Box";
      int sourceCode = aggregate == 0 ? ValueType.record(0).code() : ValueType.variant(0).code();
      int[] expected = NativeCarrierTypeFixture.types(source(parameter, result));
      for (int type = 0; type < expected.length; type++) {
        if (expected[type] == sourceCode) {
          expected[type] = sourceCode + 1;
        }
      }
      assertEquals(sourceCode + 1, expected[0]);
      VirtualMachine machine = NativeCarrierTypeFixture.machine(
          source("long", result), 0, 0, 1 - aggregate, -1, 0, aggregate);
      MachineSnapshot initial = machine.snapshot();
      NativeCarrierTypeFixture.publish(machine, expected);
      rewind(machine, initial);
    }
  }

  @Test
  void keeps256LocalsIndependentOfTheResultTypeWord() throws Exception {
    for (String result : List.of("long", "boolean", "void")) {
      Program narrow = source("long", result);
      List<ValueType> locals = new ArrayList<>(Collections.nCopies(256, ValueType.SIGNED));
      for (int local = 0; local < narrow.function(0).localCount(); local++) {
        locals.set(local, narrow.function(0).localType(local));
      }
      Program original = withLocals(narrow, locals);
      assertEquals(256, original.function(0).localCount());
      for (String nominal : List.of("Box", "Choice")) {
        List<ValueType> expectedLocals = new ArrayList<>(locals);
        expectedLocals.set(255, nominal.equals("Box")
            ? ValueType.record(0) : ValueType.variant(0));
        assertRestored(original, withLocals(original, expectedLocals), 255, nominal);
      }
    }
  }

  @Test
  void rejectsAPhantomLocalInTheSerializedResultPrefix() throws Exception {
    Program original = source("long", "long", "long marker = 0;");
    for (long local : new long[] {original.function(0).localCount(), -1, 256, Long.MAX_VALUE}) {
      assertRejected(NativeCarrierTypeFixture.machine(original, 0, local, 0));
    }
  }

  @Test
  void rejectsInconsistentFrameMetadataBeforePublishingAnyType() throws Exception {
    Program original = source("long", "long");
    for (long flags : new long[] {-1, 0, 16, Long.MAX_VALUE}) {
      assertRejected(NativeCarrierTypeFixture.machine(original, 0, 0, 0, 8192, flags));
    }
    for (long locals : new long[] {-1, 0, 257, Long.MAX_VALUE}) {
      assertRejected(NativeCarrierTypeFixture.machine(original, 0, 0, 0, 36864, locals));
    }
    for (long types : new long[] {-1, 0, 2, 4, Long.MAX_VALUE}) {
      assertRejected(NativeCarrierTypeFixture.machine(original, 0, 0, 0, 45056, types));
    }
  }

  @Test
  void rejectsNonsignedCarriersAndMissingFunctionOrDescriptorCoordinates() throws Exception {
    for (String type : List.of("boolean", "Box", "Choice")) {
      assertRejected(NativeCarrierTypeFixture.machine(source(type, "long"), 0, 0, 0));
    }
    Program original = source("long", "long");
    for (long function : new long[] {-1, 1, 2, 64, Long.MAX_VALUE}) {
      assertRejected(NativeCarrierTypeFixture.machine(original, function, 0, 0));
    }
    for (long aggregate : new long[] {-1, 2, Long.MAX_VALUE}) {
      assertRejected(NativeCarrierTypeFixture.machine(original, 0, 0, aggregate));
    }
  }

  @Test
  void executesTypedCallsThroughTheRestoredCalleeAndRewinds() throws Exception {
    for (String nominal : List.of("Box", "Choice")) {
      Program restored = assertRestored(source("long", "long"), source(nominal, "long"),
          0, nominal);
      String constructor = nominal.equals("Box") ? "new Box(1)" : "new Choice.Empty()";
      Program expected = source(nominal, "long", """
          %s carrier = %s;
          long value = checked(carrier);
          observed = value;
          """.formatted(nominal, constructor));
      Program executable = NativeCarrierTypeFixture.withFunction(expected, restored.function(0));
      byte[] artifact = new BytecodeWriter().write(executable);
      assertArrayEquals(new BytecodeWriter().write(expected), artifact);
      VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(artifact));
      MachineSnapshot initial = machine.snapshot();
      machine.run();
      assertEquals(7, machine.global("observed"));
      rewind(machine, initial);
    }
  }

  private static Program assertRestored(
      Program original, Program expected, int local, String nominal) throws Exception {
    VirtualMachine machine = NativeCarrierTypeFixture.machine(
        original, 0, local, nominal.equals("Box") ? 0 : 1);
    MachineSnapshot initial = machine.snapshot();
    NativeCarrierTypeFixture.publish(machine, NativeCarrierTypeFixture.types(expected));
    Program restored = NativeCarrierTypeFixture.withTypes(original, machine.hostOutput());
    byte[] artifact = new BytecodeWriter().write(restored);
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    new BytecodeReader().read(artifact);
    rewind(machine, initial);
    return restored;
  }

  private static void assertRejected(VirtualMachine machine) {
    MachineSnapshot initial = machine.snapshot();
    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertArrayEquals(new byte[32_768], machine.hostOutput());
    NativeCarrierTypeFixture.assertTypeTable(machine, null);
    rewind(machine, initial);
  }

  private static void rewind(VirtualMachine machine, MachineSnapshot initial) {
    while (machine.historySize() != 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  private static Program withLocals(Program original, List<ValueType> locals) {
    FunctionBody function = original.function(0);
    return NativeCarrierTypeFixture.withFunction(original,
        new FunctionBody(function.id(), function.name(), function.coherent(),
            function.parameterCount(), locals, function.resultType(), function.implicitResultSlot(),
            function.forward(), function.inverse()));
  }

  private static Program source(String parameterType, String resultType) {
    return source(parameterType, resultType, "");
  }

  private static Program source(String parameterType, String resultType, String entry) {
    String body = switch (resultType) {
      case "long", "rev long" -> "return 7;";
      case "boolean", "rev boolean" -> "return true;";
      case "Done" -> "return done;";
      case "Box" -> "return new Box(7);";
      case "Choice" -> "return new Choice.Empty();";
      case "void" -> "";
      default -> throw new IllegalArgumentException(resultType);
    };
    return new WheelerCompiler().compile("""
        classical class CarrierTypes {
          state long observed = 0;
          record Box(long value) {}
          variant Choice { case Empty(); }
          public %s checked(%s carrier) { %s }
          entry void main() { %s }
        }
        """.formatted(resultType, parameterType, body, entry));
  }
}
