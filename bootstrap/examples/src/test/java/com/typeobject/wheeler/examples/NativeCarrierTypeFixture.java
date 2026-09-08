package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Actual artifact descriptors feeding native nominal carrier type emission. */
final class NativeCarrierTypeFixture {
  private NativeCarrierTypeFixture() {}

  static VirtualMachine machine(Program program, long function, long local, long aggregate)
      throws Exception {
    return machine(program, function, local, aggregate, -1, 0);
  }

  static VirtualMachine machine(
      Program program, long function, long local, long aggregate, long row, long value)
      throws Exception {
    return machine(program, function, local, aggregate, row, value, -1);
  }

  static VirtualMachine machine(
      Program program, long function, long local, long aggregate, long row, long value,
      long relocatedAggregate) throws Exception {
    byte[] artifact = new BytecodeWriter().write(program);
    byte[] input = ByteBuffer.allocate(artifact.length + 48).order(ByteOrder.LITTLE_ENDIAN)
        .put(artifact).putLong(function).putLong(local).putLong(aggregate)
        .putLong(row).putLong(value).putLong(relocatedAggregate).array();
    return VirtualMachine.withBinaryInput(emitter(), input, 32_768);
  }

  static int[] types(Program program) {
    List<Integer> types = new ArrayList<>();
    for (FunctionBody function : program.functions()) {
      if (function.returnsValue()) {
        types.add(function.resultType().code());
      }
      function.localTypes().forEach(type -> types.add(type.code()));
    }
    return types.stream().mapToInt(Integer::intValue).toArray();
  }

  static Program withTypes(Program original, byte[] output) {
    ByteBuffer types = ByteBuffer.wrap(output).order(ByteOrder.LITTLE_ENDIAN);
    List<FunctionBody> functions = new ArrayList<>();
    for (FunctionBody function : original.functions()) {
      ValueType result = function.returnsValue() ? ValueType.fromCode(types.getInt()) : null;
      List<ValueType> locals = new ArrayList<>();
      for (int local = 0; local < function.localCount(); local++) {
        locals.add(ValueType.fromCode(types.getInt()));
      }
      functions.add(new FunctionBody(function.id(), function.name(), function.coherent(),
          function.parameterCount(), locals, result, function.implicitResultSlot(),
          function.forward(), function.inverse()));
    }
    assertEquals(0, types.remaining());
    return withFunctions(original, functions);
  }

  static Program withFunction(Program original, FunctionBody replacement) {
    return withFunctions(original, original.functions().stream()
        .map(function -> function.id() == replacement.id() ? replacement : function).toList());
  }

  private static Program withFunctions(Program original, List<FunctionBody> functions) {
    return new Program(original.name(), original.kind(), original.entryFunctionId(),
        original.globals(), original.recordTypes(), original.variantTypes(), original.arrayTypes(),
        original.sliceTypes(), functions, original.proofCertificates(), original.quantumRegisters(),
        original.quantumCircuits(), original.workflow(), original.requiredInstructionExtensions(),
        original.maxHistoryRecords(), original.maxSteps());
  }

  static void publish(VirtualMachine machine, int[] expectedTypes) {
    while (machine.global("published") == 0) {
      machine.step();
    }
    assertTypeTable(machine, expectedTypes);
    machine.run();
    ByteBuffer expected = ByteBuffer.allocate(expectedTypes.length * 4)
        .order(ByteOrder.LITTLE_ENDIAN);
    for (int type : expectedTypes) {
      expected.putInt(type);
    }
    assertArrayEquals(expected.array(), machine.hostOutput());
  }

  static void assertTypeTable(VirtualMachine machine, int[] expectedTypes) {
    List<BufferValue> tables = machine.snapshot().buffers().stream()
        .filter(buffer -> !buffer.dropped() && buffer.length() == 1_048_576).toList();
    assertEquals(1, tables.size());
    List<Long> cells = tables.getFirst().elements();
    for (int cell = 0; cell < cells.size(); cell++) {
      long expected = cell == 1_048_575 ? 19 : 0;
      if (expectedTypes == null && cell == 0) {
        expected = 17;
      }
      if (expectedTypes != null && cell < expectedTypes.length) {
        expected = expectedTypes[cell];
      }
      long actual = cells.get(cell);
      if (actual != expected) {
        assertEquals(expected, actual, "type cell " + cell);
      }
    }
  }

  private static Program emitter() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_function_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_local_types"));
    sources.put("CarrierTypeEmitter.w", """
        module example.carrier_type_emitter;

        import wheeler.compiler.closure.compiled_function_products;
        import wheeler.compiler.closure.linked_local_types;
        import wheeler.core.encoding.binary;

        classical class CarrierTypeEmitter {
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            long artifactBytes = bufferLength(source) - 48;
            long carrierFunction = readSigned(source, artifactBytes);
            long carrierLocal = readSigned(source, artifactBytes + 8);
            long carrierAggregate = readSigned(source, artifactBytes + 16);
            long changedRow = readSigned(source, artifactBytes + 24);
            long changedValue = readSigned(source, artifactBytes + 32);
            long relocatedAggregate = readSigned(source, artifactBytes + 40);
            region rows = new region(/* bytes= */ 10236928, /* allocations= */ 10);
            words artifactStarts = allocate(rows, 512);
            words artifactLengths = allocate(rows, 512);
            words functions = allocate(rows, 49152);
            words aggregates = allocate(rows, 36864);
            words finalDescriptors = allocate(rows, 4096);
            words projections = allocate(rows, 49152);
            words carriers = allocate(rows, 65536);
            words outputTypes = allocate(rows, 1048576);
            words localFunctions = allocate(rows, 640);
            words localInstructions = allocate(rows, 24576);
            CompiledFunctionPlan plan = indexCompiledFunctionProducts(
              source, artifactBytes, localFunctions, localInstructions
            );
            set(artifactLengths, 0, artifactBytes);
            long function = 0;
            while (function < plan.functionCount) limit 64 {
              set(functions, 4096 + function, localFunctions[function]);
              set(functions, 8192 + function, localFunctions[64 + function]);
              long column = 2;
              while (column < 10) limit 8 {
                set(functions, (column + 2) * 4096 + function,
                  localFunctions[column * 64 + function]);
                column += 1;
              }
              function += 1;
            }
            if (-1 < changedRow) {
              set(functions, changedRow, changedValue);
            }
            set(aggregates, 0, 1);
            set(aggregates, 1, 4);
            long aggregateCount = 2;
            if (-1 < relocatedAggregate) {
              assert(relocatedAggregate < 2);
              // Another module sorts before this module's selected descriptor.
              set(aggregates, 2, aggregates[relocatedAggregate]);
              set(aggregates, 4098, 1);
              set(finalDescriptors, relocatedAggregate, 1);
              aggregateCount = 3;
            }
            set(carriers, 16384, carrierFunction);
            set(carriers, 32768, carrierLocal);
            set(carriers, 49152, carrierAggregate);
            set(outputTypes, 0, 17);
            set(outputTypes, 1048575, 19);
            long count = emitLinkedLocalTypes(
              source, artifactBytes, artifactStarts, artifactLengths,
              plan.functionCount, functions, aggregateCount, aggregates, finalDescriptors,
              0, projections, 1, carriers, outputTypes
            );
            long type = 0;
            while (type < count) limit 1048576 {
              long code = outputTypes[type];
              long octet = 0;
              while (octet < 4) limit 4 {
                setByte(output, type * 4 + octet, code % 256);
                code = code / 256;
                octet += 1;
              }
              type += 1;
            }
            setOutputLength(output, count * 4);
            published = 1;
            drop(localInstructions);
            drop(localFunctions);
            drop(outputTypes);
            drop(carriers);
            drop(projections);
            drop(finalDescriptors);
            drop(aggregates);
            drop(functions);
            drop(artifactLengths);
            drop(artifactStarts);
            drop(rows);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.carrier_type_emitter");
  }
}
