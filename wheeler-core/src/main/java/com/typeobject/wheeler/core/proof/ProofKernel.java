package com.typeobject.wheeler.core.proof;

import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.quantum.QuantumOperation;
import java.util.ArrayList;
import java.util.List;

/** Small trusted checker for canonical proof certificates. */
public final class ProofKernel {
  private ProofKernel() {}

  public static void verify(Program program, ProofCertificate certificate) {
    switch (certificate.rule()) {
      case GENERATED_INVERSE -> verifyGeneratedInverse(program, certificate);
      case GENERATED_ADJOINT -> verifyGeneratedAdjoint(program, certificate);
      case CIRCUIT_EQUIVALENCE -> verifyCircuitEquivalence(program, certificate);
    }
  }

  private static void verifyGeneratedInverse(
      Program program, ProofCertificate certificate) {
    FunctionBody function = program.function(certificate.subjectId());
    verifyGeneratedInverse(function, "Proof " + certificate.name());
  }

  private static void verifyCircuitEquivalence(
      Program program, ProofCertificate certificate) {
    var left = program.quantumCircuit(certificate.subjectId());
    var right = program.quantumCircuit(certificate.relatedSubjectId());
    if (left.registerId() != right.registerId()
        || !cancelAdjacentInverses(left.operations())
            .equals(cancelAdjacentInverses(right.operations()))) {
      fail("Proof " + certificate.name(),
          "circuit bodies differ after adjacent inverse cancellation");
    }
  }

  private static List<QuantumOperation> cancelAdjacentInverses(
      List<QuantumOperation> operations) {
    List<QuantumOperation> result = new ArrayList<>();
    for (QuantumOperation operation : operations) {
      int last = result.size() - 1;
      if (last >= 0 && result.get(last).equals(operation.inverse())) {
        result.remove(last);
      } else {
        result.add(operation);
      }
    }
    return List.copyOf(result);
  }

  private static void verifyGeneratedAdjoint(
      Program program, ProofCertificate certificate) {
    var circuit = program.quantumCircuit(certificate.subjectId());
    for (var operation : circuit.operations()) {
      if (!operation.equals(operation.inverse().inverse())) {
        fail("Proof " + certificate.name(), "quantum operation adjoint is not involutive");
      }
    }
    var inverse = circuit.inverseOperations();
    List<QuantumOperation> restored = new ArrayList<>();
    for (int index = inverse.size() - 1; index >= 0; index--) {
      restored.add(inverse.get(index).inverse());
    }
    if (!restored.equals(circuit.operations())) {
      fail("Proof " + certificate.name(), "generated circuit adjoint does not restore the body");
    }
  }

  public static void verifyGeneratedInverse(FunctionBody function) {
    verifyGeneratedInverse(function, "Function " + function.name());
  }

  private static void verifyGeneratedInverse(FunctionBody function, String context) {
    if (!function.reversible() || function.forward().isEmpty()) {
      fail(context, "subject is not reversible");
    }
    List<Instruction> expected = new ArrayList<>();
    for (int index = function.forward().size() - 2; index >= 0; index--) {
      Opcode opcode = function.forward().get(index).opcode();
      if (!opcode.supportsGeneratedInverse()) {
        fail(context, "subject contains an unsupported inverse operation");
      }
      expected.add(function.forward().get(index).inverse());
    }
    expected.add(Instruction.of(Opcode.RETURN));
    if (!expected.equals(function.inverse())) {
      fail(context, "inverse body does not match the finite rule");
    }
  }

  private static void fail(String context, String message) {
    throw new BytecodeException(context + " failed: " + message);
  }
}
