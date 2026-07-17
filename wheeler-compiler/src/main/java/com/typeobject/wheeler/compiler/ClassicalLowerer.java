package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.SourceProgram;
import com.typeobject.wheeler.compiler.SourceModel.Statement;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
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

  ClassicalContent lower(SourceProgram source, boolean classicalEntry) {
    List<Global> globals = lowerGlobals(source);
    Map<String, Integer> globalIds = indexGlobals(globals);
    Map<String, Integer> functionIds = indexFunctions(source);
    Map<String, Boolean> reversibleFunctions = new HashMap<>();
    source.functions().forEach(function -> reversibleFunctions.put(function.name(), function.reversible()));

    List<FunctionBody> functions = new ArrayList<>();
    int entryId = -1;
    for (SourceModel.Function sourceFunction : source.functions()) {
      int id = functionIds.get(sourceFunction.name());
      if (sourceFunction.entry()) {
        entryId = id;
      }
      List<Instruction> forward;
      if (sourceFunction.entry() && !classicalEntry) {
        forward = List.of(Instruction.of(Opcode.HALT));
      } else {
        forward = lowerStatements(sourceFunction, globalIds, functionIds, reversibleFunctions);
      }
      if (sourceFunction.entry()) {
        if (forward.stream().noneMatch(instruction -> instruction.opcode() == Opcode.HALT)) {
          throw new CompilerException(sourceFunction.line(), "entry block must contain halt");
        }
      } else {
        if (forward.stream().anyMatch(instruction -> instruction.opcode() == Opcode.HALT)) {
          throw new CompilerException(sourceFunction.line(), "only the entry block may halt");
        }
        forward = appendReturn(forward);
      }

      List<Instruction> inverse = List.of();
      if (sourceFunction.reversible()) {
        inverse = generateInverse(sourceFunction, forward);
        if (sourceFunction.coherent()) {
          verifyCoherent(sourceFunction, forward);
        }
      }
      functions.add(new FunctionBody(
          id, sourceFunction.name(), sourceFunction.coherent(), forward, inverse));
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

  private static List<Instruction> lowerStatements(
      SourceModel.Function owner,
      Map<String, Integer> globals,
      Map<String, Integer> functions,
      Map<String, Boolean> reversibleFunctions) {
    List<Instruction> result = new ArrayList<>();
    for (Statement statement : owner.statements()) {
      result.add(lowerStatement(statement, globals, functions, reversibleFunctions));
    }
    return List.copyOf(result);
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

  private static List<Instruction> appendReturn(List<Instruction> body) {
    List<Instruction> result = new ArrayList<>(body);
    result.add(Instruction.of(Opcode.RETURN));
    return List.copyOf(result);
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
