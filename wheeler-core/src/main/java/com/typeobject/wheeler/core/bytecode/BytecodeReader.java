package com.typeobject.wheeler.core.bytecode;

import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.CODE;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.FUNCTIONS;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.MANIFEST;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.STRINGS;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.TYPES;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.VARIANTS;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.WORKFLOW;
import static com.typeobject.wheeler.core.bytecode.BytecodeFormat.QUANTUM;

import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.core.workflow.WorkflowStep;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Strict Wheeler Bytecode Container decoder. */
public final class BytecodeReader {
  private record Section(int type, int flags, int offset, int length, int alignment) {}
  private record Manifest(
      int nameId, int entryId, int maxHistory, ProgramKind kind, long maxSteps) {}
  private record TypeSection(
      List<Global> globals, List<RecordType> records, List<ArrayType> arrays) {}
  private record RawFunctionDescriptor(
      int id,
      int nameId,
      int flags,
      int forwardOffset,
      int forwardLength,
      int inverseOffset,
      int inverseLength,
      int parameterCount,
      int localCount,
      int typeOffset) {}

  private record FunctionDescriptor(
      int id,
      int nameId,
      int flags,
      int forwardOffset,
      int forwardLength,
      int inverseOffset,
      int inverseLength,
      int parameterCount,
      ValueType resultType,
      List<ValueType> localTypes) {}

  public Program read(byte[] bytes) {
    try {
      return readChecked(bytes);
    } catch (BytecodeException exception) {
      throw exception;
    } catch (ArithmeticException | IndexOutOfBoundsException | IllegalArgumentException exception) {
      throw new BytecodeException("Malformed Wheeler bytecode", exception);
    }
  }

  private Program readChecked(byte[] bytes) {
    if (bytes.length < BytecodeFormat.HEADER_SIZE
        || bytes.length > BytecodeFormat.MAX_ARTIFACT_BYTES) {
      fail("Artifact size is outside format bounds");
    }
    ByteBuffer input = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN);
    byte[] magic = new byte[BytecodeFormat.MAGIC.length];
    input.get(magic);
    if (!Arrays.equals(magic, BytecodeFormat.MAGIC)) {
      fail("Invalid Wheeler bytecode magic");
    }
    int major = Short.toUnsignedInt(input.getShort());
    int minor = Short.toUnsignedInt(input.getShort());
    int flags = input.getInt();
    long declaredLength = input.getLong();
    int sectionCount = input.getInt();
    int entrySize = input.getInt();
    long directoryOffset = input.getLong();
    if (major != BytecodeFormat.MAJOR_VERSION || minor != BytecodeFormat.MINOR_VERSION) {
      fail("Unsupported bytecode version " + major + "." + minor);
    }
    if (flags != 0 || declaredLength != bytes.length) {
      fail("Invalid header flags or file length");
    }
    if (sectionCount <= 0 || sectionCount > 64
        || entrySize != BytecodeFormat.DIRECTORY_ENTRY_SIZE) {
      fail("Invalid section directory shape");
    }
    long directoryLength = Math.multiplyExact((long) sectionCount, entrySize);
    checkRange(directoryOffset, directoryLength, bytes.length, "section directory");

    input.position(Math.toIntExact(directoryOffset));
    Map<Integer, Section> sections = new HashMap<>();
    List<Section> ordered = new ArrayList<>();
    for (int i = 0; i < sectionCount; i++) {
      int type = input.getInt();
      int sectionFlags = input.getInt();
      long offset = input.getLong();
      long length = input.getLong();
      int alignment = input.getInt();
      int reserved = input.getInt();
      if ((sectionFlags & ~BytecodeFormat.REQUIRED_SECTION) != 0 || reserved != 0) {
        fail("Unknown section flags or nonzero reserved field");
      }
      if (alignment != 8 || offset % alignment != 0) {
        fail("Invalid section alignment");
      }
      checkRange(offset, length, bytes.length, "section " + type);
      Section section = new Section(type, sectionFlags, Math.toIntExact(offset), Math.toIntExact(length), alignment);
      if (sections.put(type, section) != null) {
        fail("Duplicate section type " + type);
      }
      ordered.add(section);
    }
    verifyCanonicalOrderAndOverlap(ordered, Math.toIntExact(directoryOffset), Math.toIntExact(directoryLength));
    requireSections(sections);

    List<String> strings = readStrings(slice(input, sections.get(STRINGS)));
    Manifest manifest = readManifest(slice(input, sections.get(MANIFEST)), strings.size());
    TypeSection types = readTypes(slice(input, sections.get(TYPES)), strings);
    List<VariantType> variants = readVariants(slice(input, sections.get(VARIANTS)), strings);
    List<FunctionDescriptor> descriptors = readFunctionDescriptors(slice(input, sections.get(FUNCTIONS)));
    ByteBuffer code = slice(input, sections.get(CODE));
    List<FunctionBody> functions = readFunctions(descriptors, strings, code);
    List<QuantumRegister> registers = List.of();
    List<QuantumCircuit> circuits = List.of();
    List<WorkflowStep> workflow = List.of();
    if (manifest.kind() != ProgramKind.CLASSICAL) {
      if (!sections.containsKey(WORKFLOW) || !sections.containsKey(QUANTUM)) {
        fail("Quantum and hybrid artifacts require workflow and quantum sections");
      }
      QuantumSectionCodec.QuantumContent quantum =
          QuantumSectionCodec.read(slice(input, sections.get(QUANTUM)), strings);
      registers = quantum.registers();
      circuits = quantum.circuits();
      workflow = WorkflowSectionCodec.read(slice(input, sections.get(WORKFLOW)));
    }

    Program program = new Program(
        strings.get(manifest.nameId()),
        manifest.kind(),
        manifest.entryId(),
        types.globals(),
        types.records(),
        variants,
        types.arrays(),
        functions,
        registers,
        circuits,
        workflow,
        manifest.maxHistory(),
        manifest.maxSteps());
    BytecodeVerifier.verify(program);
    return program;
  }

  private static void requireSections(Map<Integer, Section> sections) {
    Set<Integer> known = Set.of(
        MANIFEST, STRINGS, TYPES, VARIANTS, FUNCTIONS, CODE, WORKFLOW, QUANTUM);
    Set<Integer> base = Set.of(MANIFEST, STRINGS, TYPES, VARIANTS, FUNCTIONS, CODE);
    for (int required : base) {
      if (!sections.containsKey(required)) {
        fail("Missing required section " + required);
      }
    }
    for (Section section : sections.values()) {
      if (!known.contains(section.type())
          && (section.flags() & BytecodeFormat.REQUIRED_SECTION) != 0) {
        fail("Unsupported required section " + section.type());
      }
    }
  }

  private static void verifyCanonicalOrderAndOverlap(
      List<Section> sections, int directoryOffset, int directoryLength) {
    int previousType = -1;
    List<Section> byOffset = new ArrayList<>(sections);
    for (Section section : sections) {
      if (section.type() <= previousType) {
        fail("Section directory is not in canonical type order");
      }
      previousType = section.type();
    }
    byOffset.sort(java.util.Comparator.comparingInt(Section::offset));
    int previousEnd = Math.addExact(directoryOffset, directoryLength);
    for (Section section : byOffset) {
      if (section.offset() < previousEnd) {
        fail("Sections overlap header, directory, or each other");
      }
      previousEnd = Math.addExact(section.offset(), section.length());
    }
  }

  private static Manifest readManifest(ByteBuffer section, int stringCount) {
    if (section.remaining() != 24) {
      fail("Invalid manifest length");
    }
    int nameId = section.getInt();
    int entry = section.getInt();
    int history = section.getInt();
    ProgramKind kind = ProgramKind.fromCode(section.getInt());
    long steps = section.getLong();
    checkStringId(nameId, stringCount);
    return new Manifest(nameId, entry, history, kind, steps);
  }

  private static List<String> readStrings(ByteBuffer section) {
    int count = readBoundedCount(section, "string", 65_535);
    List<String> strings = new ArrayList<>(count);
    for (int i = 0; i < count; i++) {
      if (section.remaining() < Integer.BYTES) {
        fail("Truncated string length");
      }
      int length = section.getInt();
      if (length < 0 || length > 1_048_576 || length > section.remaining()) {
        fail("Invalid UTF-8 string length");
      }
      ByteBuffer value = section.slice(section.position(), length);
      section.position(section.position() + length);
      try {
        strings.add(
            StandardCharsets.UTF_8.newDecoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT)
                .decode(value)
                .toString());
      } catch (CharacterCodingException exception) {
        throw new BytecodeException("Invalid UTF-8 string", exception);
      }
    }
    if (section.hasRemaining()) {
      fail("Trailing data in string section");
    }
    return List.copyOf(strings);
  }

  private static TypeSection readTypes(ByteBuffer section, List<String> strings) {
    int count = readBoundedCount(section, "global", 65_535);
    if (section.remaining() < Math.multiplyExact(count, 16) + Integer.BYTES) {
      fail("Invalid global descriptor section length");
    }
    List<Global> globals = new ArrayList<>(count);
    for (int i = 0; i < count; i++) {
      int nameId = section.getInt();
      int type = section.getInt();
      long initial = section.getLong();
      checkStringId(nameId, strings.size());
      if (type != ValueType.SIGNED.code()) {
        fail("Unsupported global type " + type);
      }
      globals.add(new Global(strings.get(nameId), initial));
    }
    int recordCount = readBoundedCount(section, "record type", 65_535);
    List<RecordType> records = new ArrayList<>(recordCount);
    for (int index = 0; index < recordCount; index++) {
      if (section.remaining() < 12) {
        fail("Truncated record type descriptor");
      }
      int id = section.getInt();
      int nameId = section.getInt();
      int fieldCount = section.getInt();
      checkStringId(nameId, strings.size());
      if (id < 0 || fieldCount <= 0 || fieldCount > 65_535
          || section.remaining() < Math.multiplyExact(fieldCount, 8)) {
        fail("Invalid record type descriptor");
      }
      List<RecordType.Field> fields = new ArrayList<>(fieldCount);
      for (int field = 0; field < fieldCount; field++) {
        int fieldName = section.getInt();
        checkStringId(fieldName, strings.size());
        fields.add(new RecordType.Field(
            strings.get(fieldName), ValueType.fromCode(section.getInt())));
      }
      records.add(new RecordType(id, strings.get(nameId), fields));
    }
    int arrayCount = readBoundedCount(section, "array type", 65_535);
    List<ArrayType> arrays = new ArrayList<>(arrayCount);
    for (int index = 0; index < arrayCount; index++) {
      if (section.remaining() < 12) {
        fail("Truncated array type descriptor");
      }
      arrays.add(new ArrayType(section.getInt(), ValueType.fromCode(section.getInt()), section.getInt()));
    }
    if (section.hasRemaining()) {
      fail("Trailing data in type descriptor section");
    }
    return new TypeSection(List.copyOf(globals), List.copyOf(records), List.copyOf(arrays));
  }

  private static List<VariantType> readVariants(
      ByteBuffer section, List<String> strings) {
    int count = readBoundedCount(section, "variant type", 65_535);
    List<VariantType> variants = new ArrayList<>(count);
    for (int index = 0; index < count; index++) {
      if (section.remaining() < 12) {
        fail("Truncated variant type descriptor");
      }
      int id = section.getInt();
      int nameId = section.getInt();
      int caseCount = section.getInt();
      checkStringId(nameId, strings.size());
      if (id < 0 || caseCount <= 0 || caseCount > 65_535) {
        fail("Invalid variant type descriptor");
      }
      List<VariantType.Case> cases = new ArrayList<>(caseCount);
      for (int variantCase = 0; variantCase < caseCount; variantCase++) {
        if (section.remaining() < 8) {
          fail("Truncated variant case descriptor");
        }
        int caseName = section.getInt();
        int fieldCount = section.getInt();
        checkStringId(caseName, strings.size());
        if (fieldCount < 0 || fieldCount > 65_535
            || section.remaining() < Math.multiplyExact(fieldCount, 8)) {
          fail("Invalid variant case descriptor");
        }
        List<RecordType.Field> fields = new ArrayList<>(fieldCount);
        for (int field = 0; field < fieldCount; field++) {
          int fieldName = section.getInt();
          checkStringId(fieldName, strings.size());
          fields.add(new RecordType.Field(
              strings.get(fieldName), ValueType.fromCode(section.getInt())));
        }
        cases.add(new VariantType.Case(strings.get(caseName), fields));
      }
      variants.add(new VariantType(id, strings.get(nameId), cases));
    }
    if (section.hasRemaining()) {
      fail("Trailing data in variant descriptor section");
    }
    return List.copyOf(variants);
  }

  private static List<FunctionDescriptor> readFunctionDescriptors(ByteBuffer section) {
    int count = readBoundedCount(section, "function", 65_535);
    int descriptorBytes = Math.multiplyExact(count, 40);
    if (section.remaining() < descriptorBytes) {
      fail("Invalid function descriptor section length");
    }
    List<RawFunctionDescriptor> raw = new ArrayList<>(count);
    Set<Integer> ids = new HashSet<>();
    int expectedTypeOffset = 0;
    for (int i = 0; i < count; i++) {
      int id = section.getInt();
      int nameId = section.getInt();
      int flags = section.getInt();
      int forwardOffset = section.getInt();
      int forwardLength = section.getInt();
      int inverseOffset = section.getInt();
      int inverseLength = section.getInt();
      int parameters = section.getInt();
      int frameSlots = section.getInt();
      int typeOffset = section.getInt();
      if (id < 0 || !ids.add(id) || (flags & ~7) != 0
          || parameters < 0 || frameSlots < parameters || frameSlots > 65_535
          || typeOffset != expectedTypeOffset) {
        fail("Invalid function descriptor");
      }
      raw.add(new RawFunctionDescriptor(
          id,
          nameId,
          flags,
          forwardOffset,
          forwardLength,
          inverseOffset,
          inverseLength,
          parameters,
          frameSlots,
          typeOffset));
      expectedTypeOffset = Math.addExact(
          expectedTypeOffset, frameSlots + ((flags & 4) != 0 ? 1 : 0));
    }
    if (section.remaining() != Math.multiplyExact(expectedTypeOffset, Integer.BYTES)) {
      fail("Invalid local type table length");
    }
    List<ValueType> types = new ArrayList<>(expectedTypeOffset);
    while (section.hasRemaining()) {
      types.add(ValueType.fromCode(section.getInt()));
    }
    List<FunctionDescriptor> result = new ArrayList<>(count);
    for (RawFunctionDescriptor descriptor : raw) {
      int localOffset = descriptor.typeOffset();
      ValueType resultType = null;
      if ((descriptor.flags() & 4) != 0) {
        resultType = types.get(localOffset++);
      }
      List<ValueType> locals = List.copyOf(types.subList(
          localOffset, localOffset + descriptor.localCount()));
      result.add(new FunctionDescriptor(
          descriptor.id(),
          descriptor.nameId(),
          descriptor.flags(),
          descriptor.forwardOffset(),
          descriptor.forwardLength(),
          descriptor.inverseOffset(),
          descriptor.inverseLength(),
          descriptor.parameterCount(),
          resultType,
          locals));
    }
    return List.copyOf(result);
  }

  private static List<FunctionBody> readFunctions(
      List<FunctionDescriptor> descriptors, List<String> strings, ByteBuffer code) {
    List<FunctionBody> functions = new ArrayList<>(descriptors.size());
    for (FunctionDescriptor descriptor : descriptors) {
      checkStringId(descriptor.nameId(), strings.size());
      boolean reversible = (descriptor.flags() & 1) != 0;
      boolean coherent = (descriptor.flags() & 2) != 0;
      ValueType resultType = descriptor.resultType();
      List<Instruction> forward = readBody(code, descriptor.forwardOffset(), descriptor.forwardLength());
      List<Instruction> inverse = List.of();
      if (reversible) {
        inverse = readBody(code, descriptor.inverseOffset(), descriptor.inverseLength());
      } else if (descriptor.inverseOffset() != -1 || descriptor.inverseLength() != 0) {
        fail("Nonreversible function has an inverse body");
      }
      functions.add(new FunctionBody(
          descriptor.id(),
          strings.get(descriptor.nameId()),
          coherent,
          descriptor.parameterCount(),
          descriptor.localTypes(),
          resultType,
          forward,
          inverse));
    }
    return List.copyOf(functions);
  }

  private static List<Instruction> readBody(ByteBuffer code, int offset, int length) {
    checkRange(offset, length, code.limit(), "function code");
    if (length == 0 || offset % 8 != 0 || length % 8 != 0) {
      fail("Invalid function body range");
    }
    ByteBuffer body = code.slice(offset, length).order(ByteOrder.LITTLE_ENDIAN);
    List<Instruction> result = new ArrayList<>();
    while (body.hasRemaining()) {
      if (body.remaining() < 8) {
        fail("Truncated instruction header");
      }
      int opcodeCode = Short.toUnsignedInt(body.getShort());
      int form = Short.toUnsignedInt(body.getShort());
      int byteLength = body.getInt();
      Opcode opcode = Opcode.fromCode(opcodeCode);
      int expectedLength = 8 + opcode.operandCount() * Long.BYTES;
      if (form != opcode.operandCount() || byteLength != expectedLength || byteLength > body.remaining() + 8) {
        fail("Noncanonical " + opcode + " instruction record");
      }
      List<Long> operands = new ArrayList<>(opcode.operandCount());
      for (int i = 0; i < opcode.operandCount(); i++) {
        operands.add(body.getLong());
      }
      result.add(new Instruction(opcode, operands));
    }
    return List.copyOf(result);
  }

  private static int readBoundedCount(ByteBuffer section, String kind, int maximum) {
    if (section.remaining() < Integer.BYTES) {
      fail("Missing " + kind + " count");
    }
    int count = section.getInt();
    if (count < 0 || count > maximum) {
      fail("Invalid " + kind + " count");
    }
    return count;
  }

  private static ByteBuffer slice(ByteBuffer input, Section section) {
    return input.slice(section.offset(), section.length()).order(ByteOrder.LITTLE_ENDIAN);
  }

  private static void checkStringId(int id, int count) {
    if (id < 0 || id >= count) {
      fail("Invalid string ID " + id);
    }
  }

  private static void checkRange(long offset, long length, long limit, String description) {
    if (offset < 0 || length < 0 || offset > limit || length > limit - offset) {
      fail("Invalid " + description + " range");
    }
  }

  private static void fail(String message) {
    throw new BytecodeException(message);
  }
}
