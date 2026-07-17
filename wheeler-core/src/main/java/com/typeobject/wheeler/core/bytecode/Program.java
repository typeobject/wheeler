package com.typeobject.wheeler.core.bytecode;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/** Immutable decoded Wheeler program. */
public final class Program {
  public static final int DEFAULT_MAX_HISTORY = 100_000;
  public static final long DEFAULT_MAX_STEPS = 1_000_000L;

  private final String name;
  private final int entryFunctionId;
  private final List<Global> globals;
  private final List<FunctionBody> functions;
  private final int maxHistoryRecords;
  private final long maxSteps;
  private final Map<Integer, FunctionBody> functionsById;

  public Program(
      String name,
      int entryFunctionId,
      List<Global> globals,
      List<FunctionBody> functions,
      int maxHistoryRecords,
      long maxSteps) {
    this.name = Objects.requireNonNull(name, "name");
    this.entryFunctionId = entryFunctionId;
    this.globals = List.copyOf(globals);
    this.functions = List.copyOf(functions);
    this.maxHistoryRecords = maxHistoryRecords;
    this.maxSteps = maxSteps;
    this.functionsById = indexFunctions(this.functions);
  }

  public Program(String name, int entryFunctionId, List<Global> globals, List<FunctionBody> functions) {
    this(name, entryFunctionId, globals, functions, DEFAULT_MAX_HISTORY, DEFAULT_MAX_STEPS);
  }

  private static Map<Integer, FunctionBody> indexFunctions(List<FunctionBody> functions) {
    Map<Integer, FunctionBody> result = new LinkedHashMap<>();
    for (FunctionBody function : functions) {
      if (result.put(function.id(), function) != null) {
        throw new IllegalArgumentException("Duplicate function ID: " + function.id());
      }
    }
    return Map.copyOf(result);
  }

  public String name() {
    return name;
  }

  public int entryFunctionId() {
    return entryFunctionId;
  }

  public List<Global> globals() {
    return globals;
  }

  public List<FunctionBody> functions() {
    return functions;
  }

  public int maxHistoryRecords() {
    return maxHistoryRecords;
  }

  public long maxSteps() {
    return maxSteps;
  }

  public FunctionBody function(int id) {
    FunctionBody result = functionsById.get(id);
    if (result == null) {
      throw new BytecodeException("Unknown function ID: " + id);
    }
    return result;
  }

  public int globalIndex(String globalName) {
    for (int i = 0; i < globals.size(); i++) {
      if (globals.get(i).name().equals(globalName)) {
        return i;
      }
    }
    throw new BytecodeException("Unknown global: " + globalName);
  }
}
