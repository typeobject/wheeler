package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.SourceProgram;
import com.typeobject.wheeler.compiler.SourceModel.Statement;
import com.typeobject.wheeler.core.bytecode.ArrayType;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.RecordType;
import com.typeobject.wheeler.core.bytecode.SliceType;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.bytecode.VariantType;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

final class ClassicalLowerer {
  record ClassicalContent(
      List<Global> globals,
      List<RecordType> recordTypes,
      List<VariantType> variantTypes,
      List<ArrayType> arrayTypes,
      List<SliceType> sliceTypes,
      List<FunctionBody> functions,
      int entryId,
      Map<String, Integer> globalIds,
      Map<String, Integer> functionIds) {}

  private record LoweredBody(List<Instruction> instructions, List<ValueType> localTypes) {}

  private record FunctionSignature(
      int id, List<ValueType> parameterTypes, ValueType resultType) {
    int parameterCount() {
      return parameterTypes.size();
    }

    boolean returnsValue() {
      return resultType != null;
    }
  }

  ClassicalContent lower(SourceProgram source, boolean classicalEntry) {
    List<Global> globals = lowerGlobals(source);
    SourceTypeLowerer.LoweredTypes types = new SourceTypeLowerer().lower(source);
    List<RecordType> recordTypes = types.records();
    List<VariantType> variantTypes = types.variants();
    List<ArrayType> arrayTypes = types.arrays();
    List<SliceType> sliceTypes = types.slices();
    Map<String, ValueType> typeReferences = types.references();
    Map<String, Integer> globalIds = indexGlobals(globals);
    Map<String, Integer> functionIds = indexFunctions(source);
    Map<String, Boolean> reversibleFunctions = new HashMap<>();
    Map<String, FunctionSignature> signatures = new HashMap<>();
    source.functions().forEach(function -> {
      reversibleFunctions.put(function.name(), function.reversible());
      ValueType resultType = function.returnsValue()
          ? SourceTypeLowerer.resolve(function.returnType(), function.line(), typeReferences)
          : null;
      if (resultType != null && resultType.kind() == ValueType.Kind.SLICE) {
        throw new CompilerException(function.line(), "borrowed slices cannot escape as results");
      }
      signatures.put(
          function.name(),
          new FunctionSignature(
              functionIds.get(function.name()),
              function.parameters().stream()
                  .map(parameter -> SourceTypeLowerer.resolve(parameter.type(), function.line(), typeReferences))
                  .toList(),
              resultType));
    });

    List<FunctionBody> functions = new ArrayList<>();
    int entryId = -1;
    for (SourceModel.Function sourceFunction : source.functions()) {
      int id = functionIds.get(sourceFunction.name());
      if (sourceFunction.entry()) {
        entryId = id;
      }
      List<Instruction> forward;
      List<ValueType> localTypes;
      if (sourceFunction.entry() && !classicalEntry) {
        forward = List.of(Instruction.of(Opcode.HALT));
        localTypes = List.of();
      } else {
        LoweredBody lowered = lowerStatements(
            sourceFunction,
            globalIds,
            functionIds,
            reversibleFunctions,
            signatures,
            typeReferences,
            recordTypes,
            variantTypes,
            arrayTypes,
            sliceTypes);
        forward = lowered.instructions();
        localTypes = lowered.localTypes();
      }
      if (sourceFunction.entry()) {
        if (forward.stream().noneMatch(instruction -> instruction.opcode() == Opcode.HALT)) {
          throw new CompilerException(sourceFunction.line(), "entry block must contain halt");
        }
      } else {
        if (forward.stream().anyMatch(instruction -> instruction.opcode() == Opcode.HALT)) {
          throw new CompilerException(sourceFunction.line(), "only the entry block may halt");
        }
      }

      List<Instruction> inverse = List.of();
      if (sourceFunction.reversible()) {
        inverse = generateInverse(sourceFunction, forward);
        if (sourceFunction.coherent()) {
          verifyCoherent(sourceFunction, forward);
        }
      }
      functions.add(new FunctionBody(
          id,
          sourceFunction.name(),
          sourceFunction.coherent(),
          sourceFunction.parameters().size(),
          localTypes,
          sourceFunction.returnsValue()
              ? SourceTypeLowerer.resolve(
                  sourceFunction.returnType(), sourceFunction.line(), typeReferences)
              : null,
          forward,
          inverse));
    }
    return new ClassicalContent(
        globals,
        recordTypes,
        variantTypes,
        arrayTypes,
        sliceTypes,
        List.copyOf(functions),
        entryId,
        globalIds,
        functionIds);
  }

  private static List<Global> lowerGlobals(SourceProgram source) {
    Set<String> names = new HashSet<>();
    List<Global> result = new ArrayList<>();
    for (SourceModel.State state : source.states()) {
      if (!names.add(state.name())) {
        throw new CompilerException(state.line(), "duplicate state: " + state.name());
      }
      result.add(new Global(state.name(), state.initialValue()));
    }
    return List.copyOf(result);
  }

  private static Map<String, Integer> indexGlobals(List<Global> globals) {
    Map<String, Integer> result = new HashMap<>();
    for (int i = 0; i < globals.size(); i++) {
      result.put(globals.get(i).name(), i);
    }
    return Map.copyOf(result);
  }

  private static Map<String, Integer> indexFunctions(SourceProgram source) {
    Map<String, Integer> result = new HashMap<>();
    for (int i = 0; i < source.functions().size(); i++) {
      SourceModel.Function function = source.functions().get(i);
      if (result.put(function.name(), i) != null) {
        throw new CompilerException(function.line(), "duplicate function: " + function.name());
      }
    }
    return Map.copyOf(result);
  }

  private static LoweredBody lowerStatements(
      SourceModel.Function owner,
      Map<String, Integer> globals,
      Map<String, Integer> functions,
      Map<String, Boolean> reversibleFunctions,
      Map<String, FunctionSignature> signatures,
      Map<String, ValueType> typeReferences,
      List<RecordType> recordTypes,
      List<VariantType> variantTypes,
      List<ArrayType> arrayTypes,
      List<SliceType> sliceTypes) {
    return new LocalAssembler(
        owner,
        globals,
        functions,
        reversibleFunctions,
        signatures,
        typeReferences,
        recordTypes,
        variantTypes,
        arrayTypes,
        sliceTypes).lower();
  }

  private static Instruction lowerStatement(
      Statement statement,
      Map<String, Integer> globals,
      Map<String, Integer> functions,
      Map<String, Boolean> reversibleFunctions) {
    List<String> arguments = statement.arguments();
    return switch (statement.operation()) {
      case "nop" -> noArguments(statement, Opcode.NOP);
      case "halt" -> noArguments(statement, Opcode.HALT);
      case "checkpoint" -> noArguments(statement, Opcode.CHECKPOINT);
      case "commit" -> noArguments(statement, Opcode.COMMIT);
      case "add" -> globalAndInteger(statement, Opcode.ADD_CONST, globals);
      case "sub" -> globalAndInteger(statement, Opcode.SUB_CONST, globals);
      case "xor" -> globalAndInteger(statement, Opcode.XOR_CONST, globals);
      case "set" -> globalAndInteger(statement, Opcode.SET_LOGGED, globals);
      case "expect" -> globalAndInteger(statement, Opcode.EXPECT_EQ, globals);
      case "swap" -> {
        requireArguments(statement, 2);
        yield Instruction.of(
            Opcode.SWAP,
            global(arguments.get(0), globals, statement.line()),
            global(arguments.get(1), globals, statement.line()));
      }
      case "invoke", "reverse" -> {
        requireArguments(statement, 1);
        String target = arguments.getFirst();
        Integer id = functions.get(target);
        if (id == null) {
          throw new CompilerException(statement.line(), "unknown function: " + target);
        }
        if (statement.operation().equals("reverse")
            && !reversibleFunctions.getOrDefault(target, false)) {
          throw new CompilerException(statement.line(), "function is not reversible: " + target);
        }
        yield Instruction.of(statement.operation().equals("invoke") ? Opcode.CALL : Opcode.UNCALL, id);
      }
      default -> throw new CompilerException(
          statement.line(), "unknown classical operation: " + statement.operation());
    };
  }

  private static Instruction noArguments(Statement statement, Opcode opcode) {
    requireArguments(statement, 0);
    return Instruction.of(opcode);
  }

  private static Instruction globalAndInteger(
      Statement statement, Opcode opcode, Map<String, Integer> globals) {
    requireArguments(statement, 2);
    return Instruction.of(
        opcode,
        global(statement.arguments().get(0), globals, statement.line()),
        SourceParser.parseInteger(statement.arguments().get(1), statement.line()));
  }

  private static long global(String name, Map<String, Integer> globals, int line) {
    Integer id = globals.get(name);
    if (id == null) {
      throw new CompilerException(line, "unknown state: " + name);
    }
    return id;
  }

  private static void requireArguments(Statement statement, int count) {
    if (statement.arguments().size() != count) {
      throw new CompilerException(
          statement.line(),
          "%s expects %d arguments, got %d"
              .formatted(statement.operation(), count, statement.arguments().size()));
    }
  }

  private static final class LocalAssembler {
    private final SourceModel.Function owner;
    private final Map<String, Integer> globals;
    private final Map<String, Integer> functions;
    private final Map<String, Boolean> reversibleFunctions;
    private final Map<String, FunctionSignature> signatures;
    private final Map<String, ValueType> typeReferences;
    private final Map<String, RecordType> records;
    private final Map<String, VariantType> variants;
    private final List<ArrayType> arrays;
    private final List<SliceType> slices;
    private final Map<String, Integer> locals = new LinkedHashMap<>();
    private final List<ValueType> localTypes = new ArrayList<>();
    private final Map<String, Integer> labels = new HashMap<>();
    private final List<Patch> patches = new ArrayList<>();
    private final List<Instruction> output = new ArrayList<>();
    private int assemblyTemporary;

    private LocalAssembler(
        SourceModel.Function owner,
        Map<String, Integer> globals,
        Map<String, Integer> functions,
        Map<String, Boolean> reversibleFunctions,
        Map<String, FunctionSignature> signatures,
        Map<String, ValueType> typeReferences,
        List<RecordType> recordTypes,
        List<VariantType> variantTypes,
        List<ArrayType> arrayTypes,
        List<SliceType> sliceTypes) {
      this.owner = owner;
      this.globals = globals;
      this.functions = functions;
      this.reversibleFunctions = reversibleFunctions;
      this.signatures = signatures;
      this.typeReferences = typeReferences;
      Map<String, RecordType> records = new HashMap<>();
      recordTypes.forEach(record -> records.put(record.name(), record));
      this.records = Map.copyOf(records);
      Map<String, VariantType> variants = new HashMap<>();
      variantTypes.forEach(variant -> variants.put(variant.name(), variant));
      this.variants = Map.copyOf(variants);
      this.arrays = List.copyOf(arrayTypes);
      this.slices = List.copyOf(sliceTypes);
      for (SourceModel.Parameter parameter : owner.parameters()) {
        declareUser(parameter.name(), owner.line(), SourceTypeLowerer.resolve(parameter.type(), owner.line(), typeReferences));
      }
    }

    private LoweredBody lower() {
      for (Statement statement : owner.statements()) {
        lower(statement);
      }
      if (!owner.entry() && !owner.returnsValue()) {
        output.add(Instruction.of(Opcode.RETURN));
      }
      for (Patch patch : patches) {
        Integer target = labels.get(patch.label());
        if (target == null) {
          throw new CompilerException(patch.line(), "unknown control-flow label");
        }
        output.set(
            patch.instructionIndex(),
            patch.conditionLocal() < 0
                ? Instruction.of(Opcode.JUMP, target)
                : Instruction.of(Opcode.JUMP_IF_ZERO, patch.conditionLocal(), target));
      }
      return new LoweredBody(List.copyOf(output), List.copyOf(localTypes));
    }

    private void lower(Statement statement) {
      List<String> arguments = statement.arguments();
      switch (statement.operation()) {
        case "local_const" -> {
          requireArguments(statement, 2);
          output.add(Instruction.of(
              Opcode.LOCAL_CONST,
              declareInternal(arguments.get(0), statement.line(), ValueType.SIGNED),
              SourceParser.parseInteger(arguments.get(1), statement.line())));
        }
        case "local_boolean" -> {
          requireArguments(statement, 2);
          output.add(Instruction.of(
              Opcode.LOCAL_CONST,
              declareInternal(arguments.get(0), statement.line(), ValueType.BOOLEAN),
              SourceParser.parseInteger(arguments.get(1), statement.line())));
        }
        case "local_read" -> lowerRead(statement);
        case "local_binary" -> lowerBinary(statement);
        case "record_new" -> lowerRecordNew(statement);
        case "record_get" -> lowerRecordGet(statement);
        case "variant_new" -> lowerVariantNew(statement);
        case "variant_tag" -> lowerVariantTag(statement);
        case "variant_get" -> lowerVariantGet(statement);
        case "array_new" -> lowerArrayNew(statement);
        case "array_get" -> lowerIndexedGet(statement);
        case "slice_new" -> lowerSliceNew(statement);
        case "local_bind" -> {
          requireArguments(statement, 3);
          int source = requireLocal(arguments.get(1), statement.line());
          ValueType declaredType = SourceTypeLowerer.resolve(arguments.get(2), statement.line(), typeReferences);
          requireType(source, declaredType, statement.line());
          int destination = declareUser(arguments.get(0), statement.line(), declaredType);
          output.add(Instruction.of(Opcode.LOCAL_MOVE, destination, source));
        }
        case "assign" -> lowerAssignment(statement);
        case "call_value" -> lowerValueCall(statement);
        case "return_value" -> {
          requireArguments(statement, 1);
          int result = requireLocal(statement.arguments().getFirst(), statement.line());
          requireType(result, SourceTypeLowerer.resolve(owner.returnType(), statement.line(), typeReferences), statement.line());
          output.add(Instruction.of(Opcode.RETURN_VALUE, result));
        }
        case "label" -> {
          requireArguments(statement, 1);
          if (labels.put(arguments.getFirst(), output.size()) != null) {
            throw new CompilerException(statement.line(), "duplicate control-flow label");
          }
        }
        case "jump" -> {
          requireArguments(statement, 1);
          patches.add(new Patch(output.size(), arguments.getFirst(), -1, statement.line()));
          output.add(Instruction.of(Opcode.JUMP, 0));
        }
        case "jump_zero" -> {
          requireArguments(statement, 2);
          int condition = requireLocal(arguments.get(0), statement.line());
          requireType(condition, ValueType.BOOLEAN, statement.line());
          patches.add(new Patch(output.size(), arguments.get(1), condition, statement.line()));
          output.add(Instruction.of(Opcode.JUMP_IF_ZERO, condition, 0));
        }
        case "loop_check" -> {
          requireArguments(statement, 2);
          int iterations = requireLocal(arguments.get(0), statement.line());
          int limit = requireLocal(arguments.get(1), statement.line());
          requireType(iterations, ValueType.SIGNED, statement.line());
          requireType(limit, ValueType.SIGNED, statement.line());
          output.add(Instruction.of(Opcode.LOCAL_LOOP_CHECK, iterations, limit));
        }
        default -> {
          if ((statement.operation().equals("invoke") || statement.operation().equals("reverse"))
              && signatures.containsKey(statement.arguments().getFirst())) {
            FunctionSignature signature = signatures.get(statement.arguments().getFirst());
            if (signature.parameterCount() != 0 || signature.returnsValue()) {
              throw new CompilerException(
                  statement.line(), "method requires a value call: " + statement.arguments().getFirst());
            }
          }
          output.add(lowerStatement(statement, globals, functions, reversibleFunctions));
        }
      }
    }

    private void lowerRead(Statement statement) {
      requireArguments(statement, 2);
      String source = statement.arguments().get(1);
      Integer local = locals.get(source);
      if (local != null) {
        int destination = declareInternal(
            statement.arguments().get(0), statement.line(), localTypes.get(local));
        output.add(Instruction.of(Opcode.LOCAL_MOVE, destination, local));
        return;
      }
      Integer global = globals.get(source);
      if (global == null) {
        throw new CompilerException(statement.line(), "unknown local or state: " + source);
      }
      int destination = declareInternal(
          statement.arguments().get(0), statement.line(), ValueType.SIGNED);
      output.add(Instruction.of(Opcode.LOCAL_LOAD_GLOBAL, destination, global));
    }

    private void lowerBinary(Statement statement) {
      requireArguments(statement, 4);
      List<String> arguments = statement.arguments();
      int left = requireLocal(arguments.get(2), statement.line());
      int right = requireLocal(arguments.get(3), statement.line());
      String operator = arguments.get(1);
      ValueType resultType;
      switch (operator) {
        case "add", "sub", "lt" -> {
          requireType(left, ValueType.SIGNED, statement.line());
          requireType(right, ValueType.SIGNED, statement.line());
          resultType = operator.equals("lt") ? ValueType.BOOLEAN : ValueType.SIGNED;
        }
        case "xor" -> {
          requireSameType(left, right, statement.line());
          resultType = localTypes.get(left);
          if (resultType.kind() == ValueType.Kind.RECORD
              || resultType.kind() == ValueType.Kind.VARIANT
              || resultType.kind() == ValueType.Kind.ARRAY
              || resultType.kind() == ValueType.Kind.SLICE) {
            throw new CompilerException(statement.line(), "XOR does not accept aggregates");
          }
        }
        case "eq" -> {
          requireSameType(left, right, statement.line());
          resultType = ValueType.BOOLEAN;
        }
        default -> throw new CompilerException(
            statement.line(), "unsupported local operator: " + operator);
      }
      int destination = declareInternal(arguments.get(0), statement.line(), resultType);
      output.add(Instruction.of(
          binaryOpcode(operator, statement.line()), destination, left, right));
    }

    private void lowerRecordNew(Statement statement) {
      if (statement.arguments().size() < 2) {
        throw new CompilerException(statement.line(), "malformed record construction");
      }
      String destinationName = statement.arguments().get(0);
      RecordType record = records.get(statement.arguments().get(1));
      int fieldCount = statement.arguments().size() - 2;
      if (record == null || fieldCount != record.fields().size()) {
        throw new CompilerException(statement.line(), "record construction signature mismatch");
      }
      int fieldBase = locals.size();
      for (int field = 0; field < fieldCount; field++) {
        int source = requireLocal(statement.arguments().get(field + 2), statement.line());
        ValueType fieldType = record.fields().get(field).type();
        requireType(source, fieldType, statement.line());
        int window = declareInternal(
            "$record" + assemblyTemporary++, statement.line(), fieldType);
        output.add(Instruction.of(Opcode.LOCAL_MOVE, window, source));
      }
      int destination = declareInternal(
          destinationName, statement.line(), ValueType.record(record.id()));
      output.add(Instruction.of(
          Opcode.RECORD_NEW, destination, record.id(), fieldBase, fieldCount));
    }

    private void lowerRecordGet(Statement statement) {
      requireArguments(statement, 3);
      int source = requireLocal(statement.arguments().get(1), statement.line());
      ValueType sourceType = localTypes.get(source);
      if (sourceType.kind() != ValueType.Kind.RECORD) {
        throw new CompilerException(statement.line(), "field access requires a record");
      }
      RecordType record = records.values().stream()
          .filter(candidate -> candidate.id() == sourceType.descriptorId())
          .findFirst()
          .orElseThrow(() -> new CompilerException(statement.line(), "unknown record type"));
      int fieldIndex = -1;
      for (int index = 0; index < record.fields().size(); index++) {
        if (record.fields().get(index).name().equals(statement.arguments().get(2))) {
          fieldIndex = index;
          break;
        }
      }
      if (fieldIndex < 0) {
        throw new CompilerException(
            statement.line(), "unknown field " + statement.arguments().get(2));
      }
      int destination = declareInternal(
          statement.arguments().get(0), statement.line(), record.fields().get(fieldIndex).type());
      output.add(Instruction.of(Opcode.RECORD_GET, destination, source, fieldIndex));
    }

    private void lowerVariantNew(Statement statement) {
      if (statement.arguments().size() < 3) {
        throw new CompilerException(statement.line(), "malformed variant construction");
      }
      String destinationName = statement.arguments().get(0);
      VariantType variant = variants.get(statement.arguments().get(1));
      int tag = variantCase(variant, statement.arguments().get(2), statement.line());
      VariantType.Case variantCase = variant.cases().get(tag);
      int fieldCount = statement.arguments().size() - 3;
      if (fieldCount != variantCase.fields().size()) {
        throw new CompilerException(statement.line(), "variant construction signature mismatch");
      }
      int fieldBase = locals.size();
      for (int field = 0; field < fieldCount; field++) {
        int source = requireLocal(statement.arguments().get(field + 3), statement.line());
        ValueType fieldType = variantCase.fields().get(field).type();
        requireType(source, fieldType, statement.line());
        int window = declareInternal(
            "$variant" + assemblyTemporary++, statement.line(), fieldType);
        output.add(Instruction.of(Opcode.LOCAL_MOVE, window, source));
      }
      int destination = declareInternal(
          destinationName, statement.line(), ValueType.variant(variant.id()));
      output.add(Instruction.of(
          Opcode.VARIANT_NEW, destination, variant.id(), tag, fieldBase, fieldCount));
    }

    private void lowerVariantTag(Statement statement) {
      requireArguments(statement, 4);
      int source = requireLocal(statement.arguments().get(1), statement.line());
      VariantType variant = variants.get(statement.arguments().get(2));
      int tag = variantCase(variant, statement.arguments().get(3), statement.line());
      requireType(source, ValueType.variant(variant.id()), statement.line());
      int destination = declareInternal(
          statement.arguments().get(0), statement.line(), ValueType.BOOLEAN);
      output.add(Instruction.of(Opcode.VARIANT_TAG_EQ, destination, source, tag));
    }

    private void lowerVariantGet(Statement statement) {
      requireArguments(statement, 5);
      int source = requireLocal(statement.arguments().get(1), statement.line());
      VariantType variant = variants.get(statement.arguments().get(2));
      int tag = variantCase(variant, statement.arguments().get(3), statement.line());
      int field = Math.toIntExact(
          SourceParser.parseInteger(statement.arguments().get(4), statement.line()));
      VariantType.Case variantCase = variant.cases().get(tag);
      if (field < 0 || field >= variantCase.fields().size()) {
        throw new CompilerException(statement.line(), "variant payload index out of range");
      }
      requireType(source, ValueType.variant(variant.id()), statement.line());
      int destination = declareUser(
          statement.arguments().get(0), statement.line(), variantCase.fields().get(field).type());
      output.add(Instruction.of(Opcode.VARIANT_GET, destination, source, tag, field));
    }

    private static int variantCase(VariantType variant, String name, int line) {
      if (variant == null) {
        throw new CompilerException(line, "unknown variant type");
      }
      for (int index = 0; index < variant.cases().size(); index++) {
        if (variant.cases().get(index).name().equals(name)) {
          return index;
        }
      }
      throw new CompilerException(line, "unknown variant case " + name);
    }

    private void lowerArrayNew(Statement statement) {
      if (statement.arguments().size() < 2) {
        throw new CompilerException(statement.line(), "malformed array construction");
      }
      ValueType arrayType = typeReferences.get(statement.arguments().get(1));
      if (arrayType == null || arrayType.kind() != ValueType.Kind.ARRAY) {
        throw new CompilerException(statement.line(), "unknown fixed array type");
      }
      ArrayType descriptor = arrays.get(arrayType.descriptorId());
      int count = statement.arguments().size() - 2;
      if (count != descriptor.length()) {
        throw new CompilerException(statement.line(), "array construction length mismatch");
      }
      int elementBase = locals.size();
      for (int element = 0; element < count; element++) {
        int source = requireLocal(statement.arguments().get(element + 2), statement.line());
        requireType(source, descriptor.elementType(), statement.line());
        int window = declareInternal(
            "$array" + assemblyTemporary++, statement.line(), descriptor.elementType());
        output.add(Instruction.of(Opcode.LOCAL_MOVE, window, source));
      }
      int destination = declareInternal(
          statement.arguments().get(0), statement.line(), arrayType);
      output.add(Instruction.of(
          Opcode.ARRAY_NEW, destination, descriptor.id(), elementBase, count));
    }

    private void lowerIndexedGet(Statement statement) {
      requireArguments(statement, 3);
      int source = requireLocal(statement.arguments().get(1), statement.line());
      int index = requireLocal(statement.arguments().get(2), statement.line());
      ValueType sourceType = localTypes.get(source);
      ValueType elementType;
      Opcode opcode;
      if (sourceType.kind() == ValueType.Kind.ARRAY) {
        elementType = arrays.get(sourceType.descriptorId()).elementType();
        opcode = Opcode.ARRAY_GET;
      } else if (sourceType.kind() == ValueType.Kind.SLICE) {
        elementType = slices.get(sourceType.descriptorId()).elementType();
        opcode = Opcode.SLICE_GET;
      } else {
        throw new CompilerException(statement.line(), "indexing requires an array or slice");
      }
      requireType(index, ValueType.SIGNED, statement.line());
      int destination = declareInternal(
          statement.arguments().get(0), statement.line(), elementType);
      output.add(Instruction.of(opcode, destination, source, index));
    }

    private void lowerSliceNew(Statement statement) {
      requireArguments(statement, 5);
      int array = requireLocal(statement.arguments().get(2), statement.line());
      int start = requireLocal(statement.arguments().get(3), statement.line());
      int length = requireLocal(statement.arguments().get(4), statement.line());
      ValueType arrayType = localTypes.get(array);
      if (arrayType.kind() != ValueType.Kind.ARRAY) {
        throw new CompilerException(statement.line(), "slice origin must be a fixed array");
      }
      requireType(start, ValueType.SIGNED, statement.line());
      requireType(length, ValueType.SIGNED, statement.line());
      ValueType elementType = arrays.get(arrayType.descriptorId()).elementType();
      SliceType descriptor = slices.stream()
          .filter(slice -> slice.elementType().equals(elementType))
          .findFirst()
          .orElseThrow(() -> new CompilerException(
              statement.line(), "slice element type is not declared"));
      int destination = declareInternal(
          statement.arguments().get(0), statement.line(), ValueType.slice(descriptor.id()));
      output.add(Instruction.of(
          Opcode.SLICE_NEW, destination, descriptor.id(), array, start, length));
    }

    private void lowerValueCall(Statement statement) {
      if (statement.arguments().size() < 2) {
        throw new CompilerException(statement.line(), "malformed value call");
      }
      String destinationName = statement.arguments().get(0);
      String functionName = statement.arguments().get(1);
      FunctionSignature signature = signatures.get(functionName);
      int argumentCount = statement.arguments().size() - 2;
      if (signature == null
          || !signature.returnsValue()
          || signature.parameterCount() != argumentCount) {
        throw new CompilerException(statement.line(), "value call signature mismatch: " + functionName);
      }
      int argumentBase = 0;
      if (argumentCount > 0) {
        argumentBase = locals.size();
        for (int index = 0; index < argumentCount; index++) {
          int source = requireLocal(statement.arguments().get(index + 2), statement.line());
          ValueType parameterType = signature.parameterTypes().get(index);
          requireType(source, parameterType, statement.line());
          int window = declareInternal(
              "$call" + assemblyTemporary++, statement.line(), parameterType);
          output.add(Instruction.of(Opcode.LOCAL_MOVE, window, source));
        }
      }
      int destination = declareInternal(
          destinationName, statement.line(), signature.resultType());
      output.add(Instruction.of(
          Opcode.CALL_VALUE,
          signature.id(),
          argumentBase,
          argumentCount,
          destination));
    }

    private void lowerAssignment(Statement statement) {
      requireArguments(statement, 3);
      String target = statement.arguments().get(0);
      String operator = statement.arguments().get(1);
      int value = requireLocal(statement.arguments().get(2), statement.line());
      Integer local = locals.get(target);
      if (local != null) {
        requireSameType(local, value, statement.line());
        if (operator.equals("ASSIGN")) {
          output.add(Instruction.of(Opcode.LOCAL_MOVE, local, value));
        } else {
          if (!operator.equals("XOR_ASSIGN")) {
            requireType(local, ValueType.SIGNED, statement.line());
          }
          output.add(Instruction.of(
              assignmentOpcode(operator, statement.line()), local, local, value));
        }
        return;
      }
      Integer global = globals.get(target);
      if (global == null) {
        throw new CompilerException(statement.line(), "unknown assignment target: " + target);
      }
      requireType(value, ValueType.SIGNED, statement.line());
      if (operator.equals("ASSIGN")) {
        output.add(Instruction.of(Opcode.LOCAL_STORE_GLOBAL, global, value));
        return;
      }
      int temporary = declareInternal(
          "$a" + assemblyTemporary++, statement.line(), ValueType.SIGNED);
      output.add(Instruction.of(Opcode.LOCAL_LOAD_GLOBAL, temporary, global));
      output.add(Instruction.of(
          assignmentOpcode(operator, statement.line()), temporary, temporary, value));
      output.add(Instruction.of(Opcode.LOCAL_STORE_GLOBAL, global, temporary));
    }

    private static Opcode binaryOpcode(String operator, int line) {
      return switch (operator) {
        case "add" -> Opcode.LOCAL_ADD;
        case "sub" -> Opcode.LOCAL_SUB;
        case "xor" -> Opcode.LOCAL_XOR;
        case "eq" -> Opcode.LOCAL_EQ;
        case "lt" -> Opcode.LOCAL_LT;
        default -> throw new CompilerException(line, "unsupported local operator: " + operator);
      };
    }

    private static Opcode assignmentOpcode(String operator, int line) {
      return switch (operator) {
        case "PLUS_ASSIGN" -> Opcode.LOCAL_ADD;
        case "MINUS_ASSIGN" -> Opcode.LOCAL_SUB;
        case "XOR_ASSIGN" -> Opcode.LOCAL_XOR;
        default -> throw new CompilerException(line, "unsupported assignment operator: " + operator);
      };
    }

    private int declareInternal(String name, int line, ValueType type) {
      if (!name.startsWith("$")) {
        throw new CompilerException(line, "invalid compiler temporary");
      }
      return declare(name, line, type);
    }

    private int declareUser(String name, int line, ValueType type) {
      if (globals.containsKey(name) || functions.containsKey(name)) {
        throw new CompilerException(line, "local shadows class member: " + name);
      }
      return declare(name, line, type);
    }

    private int declare(String name, int line, ValueType type) {
      if (locals.containsKey(name)) {
        throw new CompilerException(line, "duplicate local: " + name);
      }
      int index = locals.size();
      locals.put(name, index);
      localTypes.add(type);
      return index;
    }

    private int requireLocal(String name, int line) {
      Integer index = locals.get(name);
      if (index == null) {
        throw new CompilerException(line, "unknown local: " + name);
      }
      return index;
    }

    private void requireType(int local, ValueType type, int line) {
      if (!localTypes.get(local).equals(type)) {
        throw new CompilerException(
            line, "expected " + type.displayName() + " expression");
      }
    }

    private void requireSameType(int left, int right, int line) {
      if (!localTypes.get(left).equals(localTypes.get(right))) {
        throw new CompilerException(line, "expression type mismatch");
      }
    }

    private record Patch(
        int instructionIndex, String label, int conditionLocal, int line) {}
  }

  private static List<Instruction> generateInverse(
      SourceModel.Function function, List<Instruction> forward) {
    List<Instruction> result = new ArrayList<>();
    for (int i = forward.size() - 2; i >= 0; i--) {
      Instruction instruction = forward.get(i);
      if (!instruction.opcode().supportsGeneratedInverse()) {
        throw new CompilerException(
            function.line(),
            "reversible function contains " + instruction.opcode() + ", which has no generated inverse");
      }
      result.add(instruction.inverse());
    }
    result.add(Instruction.of(Opcode.RETURN));
    return List.copyOf(result);
  }

  private static void verifyCoherent(
      SourceModel.Function function, List<Instruction> forward) {
    Set<Opcode> coherent = Set.of(
        Opcode.NOP, Opcode.XOR_CONST, Opcode.CALL, Opcode.UNCALL, Opcode.RETURN);
    for (Instruction instruction : forward) {
      if (!coherent.contains(instruction.opcode())) {
        throw new CompilerException(
            function.line(), "coherent function contains " + instruction.opcode());
      }
    }
  }
}
