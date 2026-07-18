package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.SourceProgram;
import com.typeobject.wheeler.compiler.SourceModel.Statement;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.ValueType;
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
    Map<String, Integer> globalIds = indexGlobals(globals);
    Map<String, Integer> functionIds = indexFunctions(source);
    Map<String, Boolean> reversibleFunctions = new HashMap<>();
    Map<String, FunctionSignature> signatures = new HashMap<>();
    source.functions().forEach(function -> {
      reversibleFunctions.put(function.name(), function.reversible());
      signatures.put(
          function.name(),
          new FunctionSignature(
              functionIds.get(function.name()),
              function.parameters().stream()
                  .map(parameter -> sourceType(parameter.type(), function.line()))
                  .toList(),
              function.returnsValue() ? sourceType(function.returnType(), function.line()) : null));
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
            sourceFunction, globalIds, functionIds, reversibleFunctions, signatures);
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
              ? sourceType(sourceFunction.returnType(), sourceFunction.line())
              : null,
          forward,
          inverse));
    }
    return new ClassicalContent(
        globals, List.copyOf(functions), entryId, globalIds, functionIds);
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
      Map<String, FunctionSignature> signatures) {
    return new LocalAssembler(
        owner, globals, functions, reversibleFunctions, signatures).lower();
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

  private static ValueType sourceType(String type, int line) {
    return switch (type) {
      case "long" -> ValueType.SIGNED;
      case "boolean" -> ValueType.BOOLEAN;
      default -> throw new CompilerException(line, "unsupported value type: " + type);
    };
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
        Map<String, FunctionSignature> signatures) {
      this.owner = owner;
      this.globals = globals;
      this.functions = functions;
      this.reversibleFunctions = reversibleFunctions;
      this.signatures = signatures;
      for (SourceModel.Parameter parameter : owner.parameters()) {
        declareUser(parameter.name(), owner.line(), sourceType(parameter.type(), owner.line()));
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
        case "local_bind" -> {
          requireArguments(statement, 3);
          int source = requireLocal(arguments.get(1), statement.line());
          ValueType declaredType = sourceType(arguments.get(2), statement.line());
          requireType(source, declaredType, statement.line());
          int destination = declareUser(arguments.get(0), statement.line(), declaredType);
          output.add(Instruction.of(Opcode.LOCAL_MOVE, destination, source));
        }
        case "assign" -> lowerAssignment(statement);
        case "call_value" -> lowerValueCall(statement);
        case "return_value" -> {
          requireArguments(statement, 1);
          int result = requireLocal(statement.arguments().getFirst(), statement.line());
          requireType(result, sourceType(owner.returnType(), statement.line()), statement.line());
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
      if (localTypes.get(local) != type) {
        throw new CompilerException(
            line, "expected " + type.name().toLowerCase(java.util.Locale.ROOT) + " expression");
      }
    }

    private void requireSameType(int left, int right, int line) {
      if (localTypes.get(left) != localTypes.get(right)) {
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
