package com.typeobject.wheeler.core.bytecode;

import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.CODE;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.DIRECTORY_ENTRY_SIZE;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.FUNCTIONS;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.HEADER_SIZE;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.MANIFEST;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.REQUIRED_SECTION;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.STRINGS;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.TYPES;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.VARIANTS;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.WORKFLOW;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.QUANTUM;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.PROOFS;

import com.typeobject.wheeler.core.proof.ProofCertificate;
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
    sections.add(new Section(VARIANTS, variants(program, strings), 0));
    sections.add(new Section(FUNCTIONS, functions(program, strings, offsets), 0));
    sections.add(new Section(CODE, code, 0));
    if (!program.proofCertificates().isEmpty()) {
      sections.add(new Section(PROOFS, proofs(program, strings), 0));
    }
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
      throw new BytecodeException("Artifact exceeds format size limit");
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
    program.recordTypes().forEach(record -> {
      values.add(record.name());
      record.fields().forEach(field -> values.add(field.name()));
    });
    program.variantTypes().forEach(variant -> {
      values.add(variant.name());
      variant.cases().forEach(variantCase -> {
        values.add(variantCase.name());
        variantCase.fields().forEach(field -> values.add(field.name()));
      });
    });
    program.functions().forEach(function -> values.add(function.name()));
    program.proofCertificates().forEach(proof -> values.add(proof.name()));
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
    int recordBytes = program.recordTypes().stream()
        .mapToInt(record -> 12 + record.fields().size() * 8)
        .sum();
    ByteBuffer buffer = little(
        16 + program.globals().size() * 16 + recordBytes
            + program.arrayTypes().size() * 12 + program.sliceTypes().size() * 8);
    buffer.putInt(program.globals().size());
    for (Global global : program.globals()) {
      buffer.putInt(strings.get(global.name()));
      buffer.putInt(ValueType.SIGNED.code());
      buffer.putLong(global.initialValue());
    }
    buffer.putInt(program.recordTypes().size());
    for (RecordType record : program.recordTypes()) {
      buffer.putInt(record.id());
      buffer.putInt(strings.get(record.name()));
      buffer.putInt(record.fields().size());
      for (RecordType.Field field : record.fields()) {
        buffer.putInt(strings.get(field.name()));
        buffer.putInt(field.type().code());
      }
    }
    buffer.putInt(program.arrayTypes().size());
    for (ArrayType array : program.arrayTypes()) {
      buffer.putInt(array.id());
      buffer.putInt(array.elementType().code());
      buffer.putInt(array.length());
    }
    buffer.putInt(program.sliceTypes().size());
    for (SliceType slice : program.sliceTypes()) {
      buffer.putInt(slice.id());
      buffer.putInt(slice.elementType().code());
    }
    return buffer.array();
  }

  private static byte[] variants(Program program, Map<String, Integer> strings) {
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    writeInt(output, program.variantTypes().size());
    for (VariantType variant : program.variantTypes()) {
      writeInt(output, variant.id());
      writeInt(output, strings.get(variant.name()));
      writeInt(output, variant.cases().size());
      for (VariantType.Case variantCase : variant.cases()) {
        writeInt(output, strings.get(variantCase.name()));
        writeInt(output, variantCase.fields().size());
        for (RecordType.Field field : variantCase.fields()) {
          writeInt(output, strings.get(field.name()));
          writeInt(output, field.type().code());
        }
      }
    }
    return output.toByteArray();
  }

  private static byte[] proofs(Program program, Map<String, Integer> strings) {
    ByteBuffer buffer = little(4 + program.proofCertificates().size() * 16);
    buffer.putInt(program.proofCertificates().size());
    for (ProofCertificate proof : program.proofCertificates()) {
      buffer.putInt(proof.id());
      buffer.putInt(strings.get(proof.name()));
      buffer.putInt(proof.rule().code());
      buffer.putInt(proof.subjectFunctionId());
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
    int typeCount = program.functions().stream()
        .mapToInt(function -> function.localCount() + (function.returnsValue() ? 1 : 0))
        .sum();
    ByteBuffer buffer = little(4 + program.functions().size() * 40
        + Math.multiplyExact(typeCount, Integer.BYTES));
    buffer.putInt(program.functions().size());
    int typeOffset = 0;
    for (FunctionBody function : program.functions()) {
      FunctionOffsets location = offsets.get(function.id());
      int flags = (function.reversible() ? 1 : 0)
          | (function.coherent() ? 2 : 0)
          | (function.returnsValue() ? 4 : 0);
      buffer.putInt(function.id());
      buffer.putInt(strings.get(function.name()));
      buffer.putInt(flags);
      buffer.putInt(location.forwardOffset());
      buffer.putInt(location.forwardLength());
      buffer.putInt(location.inverseOffset());
      buffer.putInt(location.inverseLength());
      buffer.putInt(function.parameterCount());
      buffer.putInt(function.localCount());
      buffer.putInt(typeOffset);
      typeOffset += function.localCount() + (function.returnsValue() ? 1 : 0);
    }
    for (FunctionBody function : program.functions()) {
      if (function.returnsValue()) {
        buffer.putInt(function.resultType().code());
      }
      function.localTypes().forEach(type -> buffer.putInt(type.code()));
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
