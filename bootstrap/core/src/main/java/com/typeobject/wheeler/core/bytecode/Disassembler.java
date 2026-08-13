package com.typeobject.wheeler.core.bytecode;

import com.typeobject.wheeler.core.quantum.ConditionalGateOperation;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.LiftedCall;
import com.typeobject.wheeler.core.quantum.MeasureOperation;
import com.typeobject.wheeler.core.quantum.ParameterizedGateOperation;
import com.typeobject.wheeler.core.quantum.PrepareOperation;
import com.typeobject.wheeler.core.quantum.QuantumOperation;
import com.typeobject.wheeler.core.quantum.ResetOperation;
import java.util.Locale;
import java.util.StringJoiner;

/** Produces deterministic human-readable Wheeler assembly. */
public final class Disassembler {
  public String disassemble(Program program) {
    StringBuilder output = new StringBuilder();
    output.append("program ").append(program.name()).append('\n');
    output.append("kind ").append(program.kind().name().toLowerCase(Locale.ROOT)).append('\n');
    output.append("entry ").append(program.entryFunctionId()).append("\n\n");
    for (int i = 0; i < program.globals().size(); i++) {
      Global global = program.globals().get(i);
      output.append("global ").append(i).append(' ')
          .append(global.name()).append(" = ").append(global.initialValue()).append('\n');
    }
    for (RecordType record : program.recordTypes()) {
      output.append("\nrecord ").append(record.id()).append(' ').append(record.name());
      record.fields().forEach(field -> output.append(" ")
          .append(field.name()).append(':').append(field.type().displayName()));
      output.append('\n');
    }
    for (VariantType variant : program.variantTypes()) {
      output.append("\nvariant ").append(variant.id()).append(' ').append(variant.name());
      variant.cases().forEach(variantCase -> {
        output.append(" ").append(variantCase.name()).append('(');
        for (int field = 0; field < variantCase.fields().size(); field++) {
          if (field > 0) {
            output.append(",");
          }
          RecordType.Field payload = variantCase.fields().get(field);
          output.append(payload.name()).append(':').append(payload.type().displayName());
        }
        output.append(')');
      });
      output.append('\n');
    }
    for (ArrayType array : program.arrayTypes()) {
      output.append("\narray ").append(array.id())
          .append(" element=").append(array.elementType().displayName())
          .append(" length=").append(array.length()).append('\n');
    }
    for (SliceType slice : program.sliceTypes()) {
      output.append("\nslice ").append(slice.id())
          .append(" element=").append(slice.elementType().displayName()).append('\n');
    }
    for (FunctionBody function : program.functions()) {
      output.append("\nfunction ").append(function.id()).append(' ').append(function.name());
      if (function.returnsValue()) {
        output.append(" result=")
            .append(function.resultType().displayName());
      }
      if (function.implicitResultSlot()) {
        output.append(" result-slot");
      }
      if (function.coherent()) {
        output.append(" coherent");
      }
      if (function.reversible()) {
        output.append(" reversible");
      }
      if (function.localCount() > 0) {
        output.append(" parameters=").append(function.parameterCount())
            .append(" locals=")
            .append(function.localTypes().stream()
                .map(ValueType::displayName)
                .toList());
      }
      output.append('\n');
      appendBody(output, "forward", function.forward());
      if (function.reversible()) {
        appendBody(output, "inverse", function.inverse());
      }
    }
    for (var proof : program.proofCertificates()) {
      output.append("\nproof ").append(proof.id()).append(' ')
          .append(proof.name()).append(" rule=").append(proof.rule())
          .append(" subject=").append(proof.subjectId());
      if (proof.argument() >= 0) {
        output.append(" argument=").append(proof.argument());
      }
      output.append('\n');
    }
    if (!program.quantumRegisters().isEmpty()) {
      output.append("\nquantum registers:\n");
      program.quantumRegisters().forEach(register -> output.append("  ")
          .append(register.id()).append(' ').append(register.name())
          .append(" qubits=").append(register.qubits()).append('\n'));
      for (var circuit : program.quantumCircuits()) {
        output.append("\ncircuit ").append(circuit.id()).append(' ')
            .append(circuit.name()).append(" register=").append(circuit.registerId()).append('\n');
        for (QuantumOperation operation : circuit.operations()) {
          output.append("  ").append(quantumOperation(operation)).append('\n');
        }
      }
      output.append("\nworkflow:\n");
      for (int step = 0; step < program.workflow().size(); step++) {
        var operation = program.workflow().get(step);
        output.append("  %04d  %-18s %d, %d, %d%n".formatted(
            step, operation.opcode(), operation.first(), operation.second(), operation.third()));
      }
    }
    return output.toString();
  }

  private static String quantumOperation(QuantumOperation operation) {
    if (operation instanceof GateOperation gate) {
      return gate.gate() + " " + gate.qubits() + (gate.parameter() == 0 ? "" : " " + gate.parameter());
    }
    if (operation instanceof ParameterizedGateOperation gate) {
      return gate.gate() + " " + gate.qubits() + " "
          + gate.scale() + "*" + gate.parameterName();
    }
    if (operation instanceof LiftedCall lifted) {
      return (lifted.inverseDirection() ? "UNLIFT " : "LIFT ") + lifted.functionId();
    }
    if (operation instanceof PrepareOperation preparation) {
      return "PREPARE " + preparation.basisState();
    }
    if (operation instanceof MeasureOperation measurement) {
      return "MEASURE " + measurement.qubit() + " -> " + measurement.resultSlot();
    }
    if (operation instanceof ResetOperation reset) {
      return "RESET " + reset.qubit();
    }
    ConditionalGateOperation conditional = (ConditionalGateOperation) operation;
    return "IF " + conditional.resultSlot() + " == " + conditional.expected()
        + " APPLY " + conditional.gate().gate() + " " + conditional.gate().qubits();
  }

  private static void appendBody(StringBuilder output, String label, java.util.List<Instruction> body) {
    output.append("  ").append(label).append(':').append('\n');
    for (int pc = 0; pc < body.size(); pc++) {
      Instruction instruction = body.get(pc);
      StringJoiner operands = new StringJoiner(", ");
      var roles = instruction.opcode().form().roles();
      for (int operand = 0; operand < instruction.operands().size(); operand++) {
        String role = roles.get(operand).label();
        operands.add(role + "=" + instruction.operand(roles.get(operand)));
      }
      output.append("    %04d  %-12s %s%n".formatted(pc, instruction.opcode(), operands));
    }
  }
}
