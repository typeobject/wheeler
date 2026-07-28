package com.typeobject.wheeler.core.bytecode;

/** Runtime compatibility gate for declared classical instruction extensions. */
public final class InstructionExtensions {
  private InstructionExtensions() {}

  public static void requireSupported(Program program) {
    InstructionExtensionCodec.requireSupported(program.requiredInstructionExtensions());
  }
}
