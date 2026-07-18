package com.typeobject.wheeler.core.proof;

import com.typeobject.wheeler.core.bytecode.BytecodeException;

/** Trusted rule identities in the initial finite Wheeler proof kernel. */
public enum ProofRule {
  GENERATED_INVERSE(1);

  private final int code;

  ProofRule(int code) {
    this.code = code;
  }

  public int code() {
    return code;
  }

  public static ProofRule fromCode(int code) {
    if (code == GENERATED_INVERSE.code) {
      return GENERATED_INVERSE;
    }
    throw new BytecodeException("Unknown proof rule " + code);
  }
}
