package com.typeobject.wheeler.core.bytecode;

import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.CODE;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.DIRECTORY_ENTRY_SIZE;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.FUNCTIONS;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.HEADER_SIZE;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.MANIFEST;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.REQUIRED_SECTION;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.STRINGS;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.TYPES;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.WORKFLOW;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.QUANTUM;

import com.typeobject.wheeler.core.quantum.ParameterizedGateOperation;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;

/** Canonical Wheeler Bytecode Container encoder. */
public final class BytecodeWriter {
  private record FunctionOffsets(int forwardOffset, int forwardLength, int inverseOffset, int inverseLength) {}
  private record Section(int type, byte[] data, int offset) {}

  public byte[] write(Program program) {
    BytecodeVerifier.verify(program);
    Map<String, Integer> strings = stringTable(program);
    Map<Integer, FunctionOffsets> offsets = new LinkedHashMap<>();
    byte[] code = encodeCode(program, offsets);

    List<Section> sections = new ArrayList<>();
    sections.add(new Section(MANIFEST, manifest(program, strings), 0));
    sections.add(new Section(STRINGS, strings(strings), 0));
    sections.add(new Section(TYPES, types(program, strings), 0));
    sections.add(new Section(FUNCTIONS, functions(program, strings, offsets), 0));
    sections.add(new Section(CODE, code, 0));
    if (program.kind() != ProgramKind.CLASSICAL) {
      sections.add(new Section(WORKFLOW, WorkflowSectionCodec.write(program.workflow()), 0));
      sections.add(new Section(QUANTUM, QuantumSectionCodec.write(program, strings), 0));
    }
    sections.sort(Comparator.comparingInt(Section::type));

    int directoryOffset = HEADER_SIZE;
    int cursor = BytecodeFormat.align8(HEADER_SIZE + sections.size() * DIRECTORY_ENTRY_SIZE);
    List<Section> laidOut = new ArrayList<>();
    for (Section section : sections) {
      cursor = BytecodeFormat.align8(cursor);
      laidOut.add(new Section(section.type(), section.data(), cursor));
      cursor = Math.addExact(cursor, section.data().length);
    }
    int fileLength = BytecodeFormat.align8(cursor);
    if (fileLength > BytecodeFormat.MAX_ARTIFACT_BYTES) {
      throw new BytecodeException("Artifact exceeds version-1 size limit");
    }

    ByteBuffer output = ByteBuffer.allocate(fileLength).order(ByteOrder.LITTLE_ENDIAN);
    output.put(BytecodeFormat.MAGIC);
    output.putShort((short) BytecodeFormat.MAJOR_VERSION);
    output.putShort((short) BytecodeFormat.MINOR_VERSION);
    output.putInt(0);
    output.putLong(fileLength);
    output.putInt(laidOut.size());
    output.putInt(DIRECTORY_ENTRY_SIZE);
    output.putLong(directoryOffset);

    for (Section section : laidOut) {
      output.putInt(section.type());
      output.putInt(REQUIRED_SECTION);
      output.putLong(section.offset());
      output.putLong(section.data().length);
      output.putInt(8);
      output.putInt(0);
    }
    for (Section section : laidOut) {
      output.position(section.offset());
      output.put(section.data());
    }
    return output.array();
  }

  private static Map<String, Integer> stringTable(Program program) {
    TreeSet<String> values = new TreeSet<>();
    values.add(program.name());
    program.globals().forEach(global -> values.add(global.name()));
    program.functions().forEach(function -> values.add(function.name()));
    program.quantumRegisters().forEach(register -> values.add(register.name()));
    program.quantumCircuits().forEach(circuit -> {
      values.add(circuit.name());
      circuit.operations().stream()
          .filter(ParameterizedGateOperation.class::isInstance)
          .map(ParameterizedGateOperation.class::cast)
          .map(ParameterizedGateOperation::parameterName)
          .forEach(values::add);
    });
    Map<String, Integer> result = new LinkedHashMap<>();
    values.forEach(value -> result.put(value, result.size()));
    return result;
  }

  private static byte[] manifest(Program program, Map<String, Integer> strings) {
    ByteBuffer buffer = little(24);
    buffer.putInt(strings.get(program.name()));
    buffer.putInt(program.entryFunctionId());
    buffer.putInt(program.maxHistoryRecords());
    buffer.putInt(program.kind().code());
    buffer.putLong(program.maxSteps());
    return buffer.array();
  }

  private static byte[] strings(Map<String, Integer> strings) {
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    writeInt(output, strings.size());
    strings.entrySet().stream()
        .sorted(Map.Entry.comparingByValue())
        .forEach(entry -> {
          byte[] utf8 = entry.getKey().getBytes(StandardCharsets.UTF_8);
          writeInt(output, utf8.length);
          output.writeBytes(utf8);
        });
    return output.toByteArray();
  }

  private static byte[] types(Program program, Map<String, Integer> strings) {
    ByteBuffer buffer = little(4 + program.globals().size() * 16);
    buffer.putInt(program.globals().size());
    for (Global global : program.globals()) {
      buffer.putInt(strings.get(global.name()));
      buffer.putInt(1); // Version-1 I64 type.
      buffer.putLong(global.initialValue());
    }
    return buffer.array();
  }

  private static byte[] encodeCode(Program program, Map<Integer, FunctionOffsets> offsets) {
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    for (FunctionBody function : program.functions()) {
      int forwardOffset = output.size();
      function.forward().forEach(instruction -> output.writeBytes(encodeInstruction(instruction)));
      int forwardLength = output.size() - forwardOffset;
      int inverseOffset = -1;
      int inverseLength = 0;
      if (function.reversible()) {
        inverseOffset = output.size();
        function.inverse().forEach(instruction -> output.writeBytes(encodeInstruction(instruction)));
        inverseLength = output.size() - inverseOffset;
      }
      offsets.put(function.id(), new FunctionOffsets(forwardOffset, forwardLength, inverseOffset, inverseLength));
    }
    return output.toByteArray();
  }

  private static byte[] encodeInstruction(Instruction instruction) {
    ByteBuffer buffer = little(instruction.encodedLength());
    buffer.putShort((short) instruction.opcode().code());
    buffer.putShort((short) instruction.operands().size());
    buffer.putInt(instruction.encodedLength());
    instruction.operands().forEach(buffer::putLong);
    return buffer.array();
  }

  private static byte[] functions(
      Program program,
      Map<String, Integer> strings,
      Map<Integer, FunctionOffsets> offsets) {
    ByteBuffer buffer = little(4 + program.functions().size() * 32);
    buffer.putInt(program.functions().size());
    for (FunctionBody function : program.functions()) {
      FunctionOffsets location = offsets.get(function.id());
      int flags = (function.reversible() ? 1 : 0) | (function.coherent() ? 2 : 0);
      buffer.putInt(function.id());
      buffer.putInt(strings.get(function.name()));
      buffer.putInt(flags);
      buffer.putInt(location.forwardOffset());
      buffer.putInt(location.forwardLength());
      buffer.putInt(location.inverseOffset());
      buffer.putInt(location.inverseLength());
      buffer.putInt(function.localCount());
    }
    return buffer.array();
  }

  private static ByteBuffer little(int size) {
    return ByteBuffer.allocate(size).order(ByteOrder.LITTLE_ENDIAN);
  }

  private static void writeInt(ByteArrayOutputStream output, int value) {
    output.write(value);
    output.write(value >>> 8);
    output.write(value >>> 16);
    output.write(value >>> 24);
  }
}
