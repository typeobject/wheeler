package com.typeobject.wheeler.core.bytecode;

import com.typeobject.wheeler.core.proof.ProofCertificate;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.core.workflow.WorkflowStep;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/** Immutable decoded Wheeler program across classical, quantum, and proof regions. */
public final class Program {
  public static final int DEFAULT_MAX_HISTORY = 100_000;
  public static final long DEFAULT_MAX_STEPS = 1_000_000L;

  private final String name;
  private final ProgramKind kind;
  private final int entryFunctionId;
  private final List<Global> globals;
  private final List<RecordType> recordTypes;
  private final List<VariantType> variantTypes;
  private final List<ArrayType> arrayTypes;
  private final List<SliceType> sliceTypes;
  private final List<FunctionBody> functions;
  private final List<ProofCertificate> proofCertificates;
  private final List<QuantumRegister> quantumRegisters;
  private final List<QuantumCircuit> quantumCircuits;
  private final List<WorkflowStep> workflow;
  private final int maxHistoryRecords;
  private final long maxSteps;
  private final Map<Integer, RecordType> recordTypesById;
  private final Map<Integer, VariantType> variantTypesById;
  private final Map<Integer, ArrayType> arrayTypesById;
  private final Map<Integer, SliceType> sliceTypesById;
  private final Map<Integer, FunctionBody> functionsById;
  private final Map<Integer, ProofCertificate> proofsById;
  private final Map<Integer, QuantumRegister> registersById;
  private final Map<Integer, QuantumCircuit> circuitsById;

  public Program(
      String name,
      ProgramKind kind,
      int entryFunctionId,
      List<Global> globals,
      List<RecordType> recordTypes,
      List<VariantType> variantTypes,
      List<ArrayType> arrayTypes,
      List<SliceType> sliceTypes,
      List<FunctionBody> functions,
      List<ProofCertificate> proofCertificates,
      List<QuantumRegister> quantumRegisters,
      List<QuantumCircuit> quantumCircuits,
      List<WorkflowStep> workflow,
      int maxHistoryRecords,
      long maxSteps) {
    this.name = Objects.requireNonNull(name, "name");
    this.kind = Objects.requireNonNull(kind, "kind");
    this.entryFunctionId = entryFunctionId;
    this.globals = List.copyOf(globals);
    this.recordTypes = List.copyOf(recordTypes);
    this.variantTypes = List.copyOf(variantTypes);
    this.arrayTypes = List.copyOf(arrayTypes);
    this.sliceTypes = List.copyOf(sliceTypes);
    this.functions = List.copyOf(functions);
    this.proofCertificates = List.copyOf(proofCertificates);
    this.quantumRegisters = List.copyOf(quantumRegisters);
    this.quantumCircuits = List.copyOf(quantumCircuits);
    this.workflow = List.copyOf(workflow);
    this.maxHistoryRecords = maxHistoryRecords;
    this.maxSteps = maxSteps;
    this.recordTypesById = index(this.recordTypes, RecordType::id, "record type");
    this.variantTypesById = index(this.variantTypes, VariantType::id, "variant type");
    this.arrayTypesById = index(this.arrayTypes, ArrayType::id, "array type");
    this.sliceTypesById = index(this.sliceTypes, SliceType::id, "slice type");
    this.functionsById = index(this.functions, FunctionBody::id, "function");
    this.proofsById = index(this.proofCertificates, ProofCertificate::id, "proof");
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
        List.of(),
        List.of(),
        List.of(),
        List.of(),
        functions,
        List.of(),
        List.of(),
        List.of(),
        List.of(),
        maxHistoryRecords,
        maxSteps);
  }

  public Program(String name, int entryFunctionId, List<Global> globals, List<FunctionBody> functions) {
    this(name, entryFunctionId, globals, functions, DEFAULT_MAX_HISTORY, DEFAULT_MAX_STEPS);
  }

  public static Program classical(
      String name,
      int entryFunctionId,
      List<Global> globals,
      List<RecordType> recordTypes,
      List<VariantType> variantTypes,
      List<ArrayType> arrayTypes,
      List<SliceType> sliceTypes,
      List<FunctionBody> functions,
      List<ProofCertificate> proofCertificates) {
    return new Program(
        name,
        ProgramKind.CLASSICAL,
        entryFunctionId,
        globals,
        recordTypes,
        variantTypes,
        arrayTypes,
        sliceTypes,
        functions,
        proofCertificates,
        List.of(),
        List.of(),
        List.of(),
        DEFAULT_MAX_HISTORY,
        DEFAULT_MAX_STEPS);
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

  public List<RecordType> recordTypes() {
    return recordTypes;
  }

  public List<VariantType> variantTypes() {
    return variantTypes;
  }

  public List<ArrayType> arrayTypes() {
    return arrayTypes;
  }

  public List<SliceType> sliceTypes() {
    return sliceTypes;
  }

  public List<FunctionBody> functions() {
    return functions;
  }

  public List<ProofCertificate> proofCertificates() {
    return proofCertificates;
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

  public RecordType recordType(int id) {
    return require(recordTypesById, id, "record type");
  }

  public VariantType variantType(int id) {
    return require(variantTypesById, id, "variant type");
  }

  public ArrayType arrayType(int id) {
    return require(arrayTypesById, id, "array type");
  }

  public SliceType sliceType(int id) {
    return require(sliceTypesById, id, "slice type");
  }

  public FunctionBody function(int id) {
    return require(functionsById, id, "function");
  }

  public ProofCertificate proofCertificate(int id) {
    return require(proofsById, id, "proof");
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
    for (int index = 0; index < globals.size(); index++) {
      if (globals.get(index).name().equals(globalName)) {
        return index;
      }
    }
    throw new BytecodeException("Unknown global: " + globalName);
  }
}
