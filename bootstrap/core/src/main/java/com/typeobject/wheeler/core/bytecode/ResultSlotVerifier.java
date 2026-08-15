package com.typeobject.wheeler.core.bytecode;

import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_BASE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_COUNT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.FUNCTION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.IMMEDIATE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.OPERATION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RESULT_SLOT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RIGHT_SOURCE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.SOURCE;
import static com.typeobject.wheeler.core.bytecode.InstructionOperandVerifier.failOperand;
import static com.typeobject.wheeler.core.bytecode.InstructionOperandVerifier.requireType;
import static com.typeobject.wheeler.core.bytecode.InstructionOperandVerifier.verifyLocal;
import static com.typeobject.wheeler.core.bytecode.InstructionOperandVerifier.verifyLocalWindow;
import static com.typeobject.wheeler.core.bytecode.InstructionOperandVerifier.verifyReference;

import java.util.List;

/** Verifies the first implicit reversible scalar result-slot ABI. */
final class ResultSlotVerifier {
  private ResultSlotVerifier() {}

  static void verifyFunction(FunctionBody function) {
    if (function.coherent()
        || !function.localType(function.resultSlotBase()).equals(ValueType.BOOLEAN)
        || !function.localType(function.resultSlotBase() + 1).equals(function.resultType())) {
      throw new BytecodeException("Invalid implicit result slot: " + function.name());
    }
    verifyBody(function, function.forward(), "forward");
    verifyBody(function, function.inverse(), "inverse");
    if (!function.forward().getFirst().equals(function.inverse().getFirst())) {
      throw new BytecodeException("Result slot relation has no exact inverse: " + function.name());
    }
  }

  static void verifyCall(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    FunctionBody target = program.function(verifyReference(
        owner, instruction, FUNCTION, pc, program.functions().size(), "function"));
    var arguments = verifyLocalWindow(
        owner, instruction, ARGUMENT_BASE, ARGUMENT_COUNT, pc);
    int slot = verifyLocal(owner, instruction, RESULT_SLOT, pc);
    if (!target.implicitResultSlot()
        || arguments.count() != target.parameterCount()
        || slot + 1 >= owner.localCount()
        || overlaps(arguments, slot)) {
      failOperand(
          owner, instruction, RESULT_SLOT, pc,
          "result slot call signature mismatch for " + target.name());
    }
    requireType(owner, instruction, slot, RESULT_SLOT, ValueType.BOOLEAN, pc);
    requireType(owner, instruction, slot + 1, RESULT_SLOT, target.resultType(), pc);
    for (int argument = 0; argument < arguments.count(); argument++) {
      if (!owner.localType(arguments.base() + argument).equals(target.localType(argument))) {
        failOperand(
            owner, instruction, ARGUMENT_BASE, pc,
            "argument " + argument + " type mismatch for " + target.name());
      }
    }
  }

  private static boolean overlaps(
      InstructionOperandVerifier.LocalWindow arguments, int slot) {
    int argumentEnd = arguments.base() + arguments.count();
    int slotEnd = slot + 2;
    return arguments.count() > 0
        && arguments.base() < slotEnd
        && slot < argumentEnd;
  }

  static void verifyFillConstant(FunctionBody owner, Instruction instruction, int pc) {
    verifyFill(owner, instruction, pc);
    long value = instruction.operand(IMMEDIATE);
    if (owner.resultType().equals(ValueType.BOOLEAN) && value != 0 && value != 1) {
      failOperand(owner, instruction, IMMEDIATE, pc, "invalid Boolean result constant");
    }
  }

  private static void verifyFill(FunctionBody owner, Instruction instruction, int pc) {
    int slot = verifyLocal(owner, instruction, RESULT_SLOT, pc);
    boolean scalarResult = owner.resultType().equals(ValueType.SIGNED)
        || owner.resultType().equals(ValueType.BOOLEAN);
    if (!owner.implicitResultSlot() || slot != owner.resultSlotBase() || !scalarResult) {
      failOperand(owner, instruction, RESULT_SLOT, pc, "invalid scalar result slot");
    }
  }

  static void verifyFillSource(FunctionBody owner, Instruction instruction, int pc) {
    verifyFill(owner, instruction, pc);
    int source = verifyLocal(owner, instruction, SOURCE, pc);
    if (source >= owner.parameterCount()) {
      failOperand(owner, instruction, SOURCE, pc, "result source is not a preserved parameter");
    }
    requireType(owner, instruction, source, SOURCE, owner.resultType(), pc);
  }

  static void verifyFillBinary(FunctionBody owner, Instruction instruction, int pc) {
    verifyFillSource(owner, instruction, pc);
    requireSignedBinaryResult(owner, instruction, pc);
    verifyBinaryOperation(owner, instruction, pc);
  }

  static void verifyFillBinarySources(FunctionBody owner, Instruction instruction, int pc) {
    verifyFillSource(owner, instruction, pc);
    int right = verifyLocal(owner, instruction, RIGHT_SOURCE, pc);
    if (right >= owner.parameterCount()) {
      failOperand(
          owner, instruction, RIGHT_SOURCE, pc,
          "right result source is not a preserved parameter");
    }
    requireType(owner, instruction, right, RIGHT_SOURCE, owner.resultType(), pc);
    requireSignedBinaryResult(owner, instruction, pc);
    verifyBinaryOperation(owner, instruction, pc);
  }

  private static void requireSignedBinaryResult(
      FunctionBody owner, Instruction instruction, int pc) {
    if (!owner.resultType().equals(ValueType.SIGNED)) {
      failOperand(owner, instruction, RESULT_SLOT, pc, "binary result requires a signed payload");
    }
  }

  private static void verifyBinaryOperation(
      FunctionBody owner, Instruction instruction, int pc) {
    if (!ResultBinaryOperation.supported(instruction.operand(OPERATION))) {
      failOperand(owner, instruction, OPERATION, pc, "unsupported result binary operation");
    }
  }

  static void verifyReturn(
      Program program, FunctionBody owner, Instruction instruction, int pc) {
    int slot = verifyLocal(owner, instruction, RESULT_SLOT, pc);
    if (owner.id() == program.entryFunctionId()
        || !owner.implicitResultSlot() || slot != owner.resultSlotBase()) {
      failOperand(owner, instruction, RESULT_SLOT, pc, "invalid result slot return");
    }
  }

  private static void verifyBody(
      FunctionBody function, List<Instruction> body, String direction) {
    Opcode transition = body.isEmpty() ? null : body.getFirst().opcode();
    if (body.size() != 2
        || (transition != Opcode.RESULT_FILL_CONSTANT
            && transition != Opcode.RESULT_FILL_SOURCE
            && transition != Opcode.RESULT_FILL_BINARY
            && transition != Opcode.RESULT_FILL_BINARY_SOURCES)
        || body.getLast().opcode() != Opcode.RETURN_RESULT_SLOT
        || body.getFirst().operand(RESULT_SLOT) != function.resultSlotBase()
        || body.getLast().operand(RESULT_SLOT) != function.resultSlotBase()) {
      throw new BytecodeException(
          "Invalid " + direction + " result slot body: " + function.name());
    }
  }
}
