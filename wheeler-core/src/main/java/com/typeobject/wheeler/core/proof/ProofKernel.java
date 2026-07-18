package com.typeobject.wheeler.core.proof;

import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.ArrayList;
import java.util.List;

/** Small trusted checker for canonical proof certificates. */
public final class ProofKernel {
  private ProofKernel() {}

  public static void verify(Program program, ProofCertificate certificate) {
    switch (certificate.rule()) {
      case GENERATED_INVERSE -> verifyGeneratedInverse(program, certificate);
    }
  }

  private static void verifyGeneratedInverse(
      Program program, ProofCertificate certificate) {
    FunctionBody function = program.function(certificate.subjectFunctionId());
    verifyGeneratedInverse(function, "Proof " + certificate.name());
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
