package com.typeobject.wheeler.core.proof;

import com.typeobject.wheeler.core.bytecode.BytecodeException;

/** Trusted rule identities in the initial finite Wheeler proof kernel. */
public enum ProofRule {
  GENERATED_INVERSE(1),
  GENERATED_ADJOINT(2),
  CIRCUIT_EQUIVALENCE(3);

  private final int code;

  ProofRule(int code) {
    this.code = code;
  }

  public int code() {
    return code;
  }

  public static ProofRule fromCode(int code) {
    for (ProofRule rule : values()) {
      if (code == rule.code) {
        return rule;
      }
    }
    throw new BytecodeException("Unknown proof rule " + code);
  }
}
