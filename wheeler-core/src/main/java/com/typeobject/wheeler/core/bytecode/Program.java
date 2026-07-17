package com.typeobject.wheeler.core.bytecode;

import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.core.workflow.WorkflowStep;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/** Immutable decoded Wheeler program across classical and quantum regions. */
public final class Program {
  public static final int DEFAULT_MAX_HISTORY = 100_000;
  public static final long DEFAULT_MAX_STEPS = 1_000_000L;

  private final String name;
  private final ProgramKind kind;
  private final int entryFunctionId;
  private final List<Global> globals;
  private final List<FunctionBody> functions;
  private final List<QuantumRegister> quantumRegisters;
  private final List<QuantumCircuit> quantumCircuits;
  private final List<WorkflowStep> workflow;
  private final int maxHistoryRecords;
  private final long maxSteps;
  private final Map<Integer, FunctionBody> functionsById;
  private final Map<Integer, QuantumRegister> registersById;
  private final Map<Integer, QuantumCircuit> circuitsById;

  public Program(
      String name,
      ProgramKind kind,
      int entryFunctionId,
      List<Global> globals,
      List<FunctionBody> functions,
      List<QuantumRegister> quantumRegisters,
      List<QuantumCircuit> quantumCircuits,
      List<WorkflowStep> workflow,
      int maxHistoryRecords,
      long maxSteps) {
    this.name = Objects.requireNonNull(name, "name");
    this.kind = Objects.requireNonNull(kind, "kind");
    this.entryFunctionId = entryFunctionId;
    this.globals = List.copyOf(globals);
    this.functions = List.copyOf(functions);
    this.quantumRegisters = List.copyOf(quantumRegisters);
    this.quantumCircuits = List.copyOf(quantumCircuits);
    this.workflow = List.copyOf(workflow);
    this.maxHistoryRecords = maxHistoryRecords;
    this.maxSteps = maxSteps;
    this.functionsById = index(this.functions, FunctionBody::id, "function");
    this.registersById = index(this.quantumRegisters, QuantumRegister::id, "quantum register");
    this.circuitsById = index(this.quantumCircuits, QuantumCircuit::id, "quantum circuit");
  }

  public Program(
      String name,
      int entryFunctionId,
      List<Global> globals,
      List<FunctionBody> functions,
      int maxHistoryRecords,
      long maxSteps) {
    this(
        name,
        ProgramKind.CLASSICAL,
        entryFunctionId,
        globals,
        functions,
        List.of(),
        List.of(),
        List.of(),
        maxHistoryRecords,
        maxSteps);
  }

  public Program(String name, int entryFunctionId, List<Global> globals, List<FunctionBody> functions) {
    this(name, entryFunctionId, globals, functions, DEFAULT_MAX_HISTORY, DEFAULT_MAX_STEPS);
  }

  private static <T> Map<Integer, T> index(
      List<T> values, java.util.function.ToIntFunction<T> identity, String description) {
    Map<Integer, T> result = new LinkedHashMap<>();
    for (T value : values) {
      int id = identity.applyAsInt(value);
      if (result.put(id, value) != null) {
        throw new IllegalArgumentException("Duplicate " + description + " ID: " + id);
      }
    }
    return Map.copyOf(result);
  }

  public String name() {
    return name;
  }

  public ProgramKind kind() {
    return kind;
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

  public List<QuantumRegister> quantumRegisters() {
    return quantumRegisters;
  }

  public List<QuantumCircuit> quantumCircuits() {
    return quantumCircuits;
  }

  public List<WorkflowStep> workflow() {
    return workflow;
  }

  public int maxHistoryRecords() {
    return maxHistoryRecords;
  }

  public long maxSteps() {
    return maxSteps;
  }

  public FunctionBody function(int id) {
    return require(functionsById, id, "function");
  }

  public QuantumRegister quantumRegister(int id) {
    return require(registersById, id, "quantum register");
  }

  public QuantumCircuit quantumCircuit(int id) {
    return require(circuitsById, id, "quantum circuit");
  }

  private static <T> T require(Map<Integer, T> values, int id, String description) {
    T result = values.get(id);
    if (result == null) {
      throw new BytecodeException("Unknown " + description + " ID: " + id);
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
