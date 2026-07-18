package com.typeobject.wheeler.core.bytecode;

import com.typeobject.wheeler.core.proof.ProofKernel;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.LiftedCall;
import com.typeobject.wheeler.core.quantum.ParameterizedGateOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumOperation;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.core.workflow.WorkflowOpcode;
import com.typeobject.wheeler.core.workflow.WorkflowStep;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Verifies proof, quantum, and workflow sections after ordinary bytecode structure is checked. */
final class ProgramSectionVerifier {
  private ProgramSectionVerifier() {}

  /** Verifies canonical proof identities and delegates certificate semantics to the proof kernel. */
  static void verifyProofs(Program program) {
    Set<String> names = new HashSet<>();
    for (int index = 0; index < program.proofCertificates().size(); index++) {
      var proof = program.proofCertificates().get(index);
      if (proof.id() != index || !names.add(proof.name())) {
        fail("Noncanonical or duplicate proof " + proof.name());
      }
      ProofKernel.verify(program, proof);
    }
  }

  /** Verifies register, circuit, qubit, and coherent-lift references. */
  static void verifyQuantum(Program program) {
    if (program.kind() == ProgramKind.CLASSICAL) {
      if (!program.quantumRegisters().isEmpty()
          || !program.quantumCircuits().isEmpty()
          || !program.workflow().isEmpty()) {
        fail("Classical program contains quantum or workflow content");
      }
      return;
    }

    Set<String> registerNames = new HashSet<>();
    for (QuantumRegister register : program.quantumRegisters()) {
      if (!registerNames.add(register.name())) {
        fail("Duplicate quantum register name: " + register.name());
      }
    }
    Set<String> circuitNames = new HashSet<>();
    for (QuantumCircuit circuit : program.quantumCircuits()) {
      if (!circuitNames.add(circuit.name())) {
        fail("Duplicate quantum circuit name: " + circuit.name());
      }
      QuantumRegister register = program.quantumRegister(circuit.registerId());
      for (QuantumOperation operation : circuit.operations()) {
        if (operation instanceof GateOperation gate) {
          verifyQubits(circuit, register, gate.qubits());
        } else if (operation instanceof ParameterizedGateOperation gate) {
          verifyQubits(circuit, register, gate.qubits());
        } else if (operation instanceof LiftedCall lifted) {
          FunctionBody function = program.function(lifted.functionId());
          if (!function.coherent()) {
            fail("Lifted function is not coherent: " + function.name());
          }
        }
      }
    }
  }

  /** Verifies workflow termination, references, operands, and reversible uncalls. */
  static void verifyWorkflow(Program program) {
    if (program.kind() == ProgramKind.CLASSICAL) {
      return;
    }
    if (program.workflow().isEmpty()
        || program.workflow().getLast().opcode() != WorkflowOpcode.HALT) {
      fail("Quantum and hybrid workflows must end in HALT");
    }
    int halts = 0;
    for (WorkflowStep step : program.workflow()) {
      switch (step.opcode()) {
        case PREPARE -> {
          QuantumRegister register = program.quantumRegister(Math.toIntExact(step.first()));
          if (step.second() < 0
              || (register.qubits() < 63 && step.second() >= (1L << register.qubits()))) {
            fail("Preparation basis value does not fit register " + register.name());
          }
        }
        case APPLY, UNAPPLY -> program.quantumCircuit(Math.toIntExact(step.first()));
        case MEASURE -> {
          program.quantumRegister(Math.toIntExact(step.first()));
          verifyGlobal(program, step.second());
        }
        case CLASSICAL_CALL -> program.function(Math.toIntExact(step.first()));
        case CLASSICAL_UNCALL -> {
          FunctionBody function = program.function(Math.toIntExact(step.first()));
          if (!function.reversible()) {
            fail("Workflow uncalls nonreversible function " + function.name());
          }
        }
        case EXPECT -> verifyGlobal(program, step.first());
        case COMMIT -> requireZeroOperands(step);
        case HALT -> {
          requireZeroOperands(step);
          halts++;
        }
      }
    }
    if (halts != 1) {
      fail("Workflow must contain exactly one final HALT");
    }
  }

  private static void verifyQubits(
      QuantumCircuit circuit, QuantumRegister register, List<Integer> qubits) {
    Set<Integer> used = new HashSet<>();
    for (int qubit : qubits) {
      if (qubit < 0 || qubit >= register.qubits() || !used.add(qubit)) {
        fail("Invalid or repeated qubit in circuit " + circuit.name());
      }
    }
  }

  private static void requireZeroOperands(WorkflowStep step) {
    if (step.first() != 0 || step.second() != 0 || step.third() != 0) {
      fail(step.opcode() + " workflow record has nonzero operands");
    }
  }

  private static void verifyGlobal(Program program, long operand) {
    if (operand < 0 || operand >= program.globals().size()) {
      FunctionBody entry = program.function(program.entryFunctionId());
      fail(entry.name() + "@0 invalid global index " + operand);
    }
  }

  private static void fail(String message) {
    throw new BytecodeException(message);
  }
}
