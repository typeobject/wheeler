package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.ClassicalLowerer.ClassicalContent;
import com.typeobject.wheeler.compiler.SourceModel.Circuit;
import com.typeobject.wheeler.compiler.SourceModel.SourceProgram;
import com.typeobject.wheeler.compiler.SourceModel.Statement;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.proof.ProofCertificate;
import com.typeobject.wheeler.core.quantum.Gate;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.LiftedCall;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumOperation;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.core.workflow.WorkflowOpcode;
import com.typeobject.wheeler.core.workflow.WorkflowStep;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

final class QuantumLowerer {
  Program lower(SourceProgram source, ClassicalContent classical) {
    List<QuantumRegister> registers = lowerRegisters(source);
    Map<String, Integer> registerIds = indexRegisters(registers);
    Map<String, Integer> circuitIds = indexCircuits(source);
    List<QuantumCircuit> circuits = lowerCircuits(
        source, registerIds, circuitIds, classical);
    List<ProofCertificate> proofs = SourceProofLowerer.quantum(
        source, classical.proofs(), circuitIds);
    List<WorkflowStep> workflow = lowerWorkflow(
        source, registerIds, circuitIds, classical);
    ProgramKind kind = source.kind().equals("quantum") ? ProgramKind.QUANTUM : ProgramKind.HYBRID;
    return new Program(
        source.name(),
        kind,
        classical.entryId(),
        classical.globals(),
        classical.recordTypes(),
        classical.variantTypes(),
        classical.arrayTypes(),
        classical.sliceTypes(),
        classical.functions(),
        proofs,
        registers,
        circuits,
        workflow,
        Program.DEFAULT_MAX_HISTORY,
        Program.DEFAULT_MAX_STEPS);
  }

  private static List<QuantumRegister> lowerRegisters(SourceProgram source) {
    Set<String> names = new HashSet<>();
    List<QuantumRegister> result = new ArrayList<>();
    for (SourceModel.QuantumRegisterSource register : source.quantumRegisters()) {
      if (!names.add(register.name())) {
        throw new CompilerException(register.line(), "duplicate qreg: " + register.name());
      }
      result.add(new QuantumRegister(result.size(), register.name(), register.qubits()));
    }
    if (result.isEmpty()) {
      throw new CompilerException(1, "quantum and hybrid programs require at least one qreg");
    }
    return List.copyOf(result);
  }

  private static Map<String, Integer> indexRegisters(List<QuantumRegister> registers) {
    Map<String, Integer> result = new HashMap<>();
    registers.forEach(register -> result.put(register.name(), register.id()));
    return Map.copyOf(result);
  }

  private static Map<String, Integer> indexCircuits(SourceProgram source) {
    Map<String, Integer> result = new HashMap<>();
    for (int i = 0; i < source.circuits().size(); i++) {
      Circuit circuit = source.circuits().get(i);
      if (result.put(circuit.name(), i) != null) {
        throw new CompilerException(circuit.line(), "duplicate circuit: " + circuit.name());
      }
    }
    return Map.copyOf(result);
  }

  private static List<QuantumCircuit> lowerCircuits(
      SourceProgram source,
      Map<String, Integer> registers,
      Map<String, Integer> circuitIds,
      ClassicalContent classical) {
    List<QuantumCircuit> result = new ArrayList<>();
    for (Circuit sourceCircuit : source.circuits()) {
      int register = require(registers, sourceCircuit.registerName(), sourceCircuit.line(), "qreg");
      int qubits = source.quantumRegisters().stream()
          .filter(candidate -> candidate.name().equals(sourceCircuit.registerName()))
          .findFirst()
          .orElseThrow()
          .qubits();
      List<QuantumOperation> operations = new ArrayList<>();
      for (Statement statement : sourceCircuit.statements()) {
        QuantumOperation operation = lowerQuantumOperation(statement, classical);
        if (operation instanceof GateOperation gate
            && gate.qubits().stream().anyMatch(qubit -> qubit >= qubits)) {
          throw new CompilerException(
              statement.line(), "qubit index exceeds register " + sourceCircuit.registerName());
        }
        operations.add(operation);
      }
      result.add(new QuantumCircuit(
          circuitIds.get(sourceCircuit.name()), sourceCircuit.name(), register, operations));
    }
    return List.copyOf(result);
  }

  private static QuantumOperation lowerQuantumOperation(
      Statement statement, ClassicalContent classical) {
    return switch (statement.operation()) {
      case "h" -> oneQubit(statement, Gate.H);
      case "x" -> oneQubit(statement, Gate.X);
      case "z" -> oneQubit(statement, Gate.Z);
      case "phase" -> {
        requireArguments(statement, 2);
        yield new GateOperation(
            Gate.PHASE,
            List.of(qubit(statement.arguments().get(0), statement.line())),
            SourceParser.parseAngle(statement.arguments().get(1), statement.line()));
      }
      case "cphase" -> {
        requireArguments(statement, 3);
        yield new GateOperation(
            Gate.CPHASE,
            List.of(
                qubit(statement.arguments().get(0), statement.line()),
                qubit(statement.arguments().get(1), statement.line())),
            SourceParser.parseAngle(statement.arguments().get(2), statement.line()));
      }
      case "cnot" -> twoQubits(statement, Gate.CNOT);
      case "cz" -> twoQubits(statement, Gate.CZ);
      case "qswap" -> twoQubits(statement, Gate.SWAP);
      case "lift", "unlift" -> {
        requireArguments(statement, 1);
        int id = require(
            classical.functionIds(), statement.arguments().getFirst(), statement.line(), "function");
        FunctionBody function = classical.functions().stream()
            .filter(candidate -> candidate.id() == id)
            .findFirst()
            .orElseThrow();
        if (!function.coherent()) {
          throw new CompilerException(
              statement.line(), "function is not coherently liftable: " + function.name());
        }
        yield new LiftedCall(id, statement.operation().equals("unlift"));
      }
      default -> throw new CompilerException(
          statement.line(), "unknown quantum operation: " + statement.operation());
    };
  }

  private static GateOperation oneQubit(Statement statement, Gate gate) {
    requireArguments(statement, 1);
    return GateOperation.of(gate, qubit(statement.arguments().getFirst(), statement.line()));
  }

  private static GateOperation twoQubits(Statement statement, Gate gate) {
    requireArguments(statement, 2);
    return GateOperation.of(
        gate,
        qubit(statement.arguments().get(0), statement.line()),
        qubit(statement.arguments().get(1), statement.line()));
  }

  private static int qubit(String text, int line) {
    long value = SourceParser.parseInteger(text, line);
    if (value < 0 || value > Integer.MAX_VALUE) {
      throw new CompilerException(line, "invalid qubit index: " + text);
    }
    return (int) value;
  }

  private static List<WorkflowStep> lowerWorkflow(
      SourceProgram source,
      Map<String, Integer> registers,
      Map<String, Integer> circuits,
      ClassicalContent classical) {
    SourceModel.Function entry = source.functions().stream()
        .filter(SourceModel.Function::entry)
        .findFirst()
        .orElseThrow();
    List<WorkflowStep> result = new ArrayList<>();
    for (Statement statement : entry.statements()) {
      List<String> arguments = statement.arguments();
      result.add(switch (statement.operation()) {
        case "prepare" -> {
          requireArguments(statement, 2);
          yield WorkflowStep.prepare(
              require(registers, arguments.get(0), statement.line(), "qreg"),
              SourceParser.parseInteger(arguments.get(1), statement.line()));
        }
        case "measure" -> {
          requireArguments(statement, 2);
          yield WorkflowStep.measure(
              require(registers, arguments.get(0), statement.line(), "qreg"),
              require(classical.globalIds(), arguments.get(1), statement.line(), "state"));
        }
        case "invoke", "reverse" -> {
          requireArguments(statement, 1);
          String target = arguments.getFirst();
          boolean inverse = statement.operation().equals("reverse");
          if (circuits.containsKey(target)) {
            yield WorkflowStep.apply(circuits.get(target), inverse);
          }
          int function = require(
              classical.functionIds(), target, statement.line(), "method");
          yield WorkflowStep.classicalCall(function, inverse);
        }
        case "expect" -> {
          requireArguments(statement, 2);
          yield WorkflowStep.expect(
              require(classical.globalIds(), arguments.get(0), statement.line(), "state"),
              SourceParser.parseInteger(arguments.get(1), statement.line()));
        }
        case "commit" -> {
          requireArguments(statement, 0);
          yield new WorkflowStep(WorkflowOpcode.COMMIT, 0, 0, 0);
        }
        case "halt" -> {
          requireArguments(statement, 0);
          yield WorkflowStep.halt();
        }
        default -> throw new CompilerException(
            statement.line(), "unknown workflow operation: " + statement.operation());
      });
    }
    return List.copyOf(result);
  }

  private static void requireArguments(Statement statement, int count) {
    if (statement.arguments().size() != count) {
      throw new CompilerException(
          statement.line(),
          "%s expects %d arguments, got %d"
              .formatted(statement.operation(), count, statement.arguments().size()));
    }
  }

  private static int require(Map<String, Integer> values, String name, int line, String kind) {
    Integer value = values.get(name);
    if (value == null) {
      throw new CompilerException(line, "unknown " + kind + ": " + name);
    }
    return value;
  }
}
