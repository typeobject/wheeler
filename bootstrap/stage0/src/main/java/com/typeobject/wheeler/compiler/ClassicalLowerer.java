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
import com.typeobject.wheeler.core.proof.ProofCertificate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Lowers typed classical source IR to verified functions and canonical metadata. */
final class ClassicalLowerer {
  record ClassicalContent(
      List<Global> globals,
      List<RecordType> recordTypes,
      List<VariantType> variantTypes,
      List<ArrayType> arrayTypes,
      List<SliceType> sliceTypes,
      List<FunctionBody> functions,
      List<ProofCertificate> proofs,
      int entryId,
      Map<String, Integer> globalIds,
      Map<String, Integer> functionIds) {}

  record LoweredBody(List<Instruction> instructions, List<ValueType> localTypes) {}

  record FunctionSignature(
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
      if (resultType != null && (resultType.kind() == ValueType.Kind.SLICE
          || borrowed(resultType))) {
        throw new CompilerException(
            function.line(), "borrowed values cannot escape as results");
      }
      List<ValueType> parameterTypes = function.parameters().stream()
          .map(parameter -> {
            ValueType type = SourceTypeLowerer.resolve(
                parameter.type(), function.line(), typeReferences);
            return SourceCallArgumentLowerer.parameterType(type);
          })
          .toList();
      if (parameterTypes.stream().anyMatch(ClassicalLowerer::owned)) {
        throw new CompilerException(
            function.line(), "mutable owned values are currently local to one function");
      }
      signatures.put(
          function.name(),
          new FunctionSignature(
              functionIds.get(function.name()), parameterTypes, resultType));
    });

    List<FunctionBody> functions = new ArrayList<>();
    String rootNamespace = source.functions().stream()
        .filter(SourceModel.Function::entry)
        .map(function -> namespace(function.name()))
        .findFirst()
        .orElse("");
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
            !namespace(sourceFunction.name()).equals(rootNamespace),
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
    List<ProofCertificate> proofs = SourceProofLowerer.classical(
        source, functionIds, reversibleFunctions, classicalEntry);
    return new ClassicalContent(
        globals,
        recordTypes,
        variantTypes,
        arrayTypes,
        sliceTypes,
        List.copyOf(functions),
        proofs,
        entryId,
        globalIds,
        functionIds);
  }

  private static String namespace(String functionName) {
    int separator = functionName.indexOf("::");
    return separator < 0 ? "" : functionName.substring(0, separator);
  }

  static boolean owned(ValueType type) {
    return type.kind() == ValueType.Kind.REGION
        || type.kind() == ValueType.Kind.WORDS
        || type.kind() == ValueType.Kind.BYTES
        || type.kind() == ValueType.Kind.LONG_MAP
        || type.kind() == ValueType.Kind.UTF8;
  }

  private static boolean borrowed(ValueType type) {
    return type.equals(ValueType.UTF8_BORROW)
        || type.equals(ValueType.LONG_MAP_BORROW)
        || type.equals(ValueType.WORDS_BORROW)
        || type.equals(ValueType.BYTES_BORROW)
        || type.equals(ValueType.REGION_BORROW)
        || type.equals(ValueType.BYTE_VIEW);
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
      boolean isolatedModule,
      Map<String, Integer> globals,
      Map<String, Integer> functions,
      Map<String, Boolean> reversibleFunctions,
      Map<String, FunctionSignature> signatures,
      Map<String, ValueType> typeReferences,
      List<RecordType> recordTypes,
      List<VariantType> variantTypes,
      List<ArrayType> arrayTypes,
      List<SliceType> sliceTypes) {
    return new ClassicalLocalAssembler(
        owner,
        isolatedModule,
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

  static Instruction lowerStatement(
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

  static void requireArguments(Statement statement, int count) {
    if (statement.arguments().size() != count) {
      throw new CompilerException(
          statement.line(),
          "%s expects %d arguments, got %d"
              .formatted(statement.operation(), count, statement.arguments().size()));
    }
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
