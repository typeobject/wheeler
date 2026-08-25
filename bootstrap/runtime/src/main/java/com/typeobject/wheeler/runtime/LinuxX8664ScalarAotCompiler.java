package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.runtime.aot.ScalarAotMachine;
import com.typeobject.wheeler.runtime.aot.ScalarAotProgram;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;

/** x86-64 Linux AOT leaf for a bounded Wheeler process-status program. */
public final class LinuxX8664ScalarAotCompiler {
  public static final int ARITHMETIC_TRAP_STATUS = ScalarAotMachine.ARITHMETIC_TRAP_STATUS;

  private LinuxX8664ScalarAotCompiler() {}

  /** Verifies and lowers one canonical process-status WBC into owned runtime text. */
  public static LoweredRuntime lower(byte[] artifact) {
    if (artifact == null) {
      throw new NullPointerException("Portable WBC artifact is required");
    }
    Program program = new BytecodeReader().read(artifact);
    if (!Arrays.equals(artifact, new BytecodeWriter().write(program))) {
      throw new IllegalArgumentException("AOT input WBC is not canonical");
    }
    ScalarAotProgram scalar = ScalarAotProgram.validate(program);
    return new LoweredRuntime(
        identity(artifact),
        scalar.processStatus(),
        LinuxX8664EntryShim.runtimeText(ScalarAotMachine.lower(scalar)));
  }

  private static String identity(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  /** Owned scalar AOT output and its portable semantic input identity. */
  public static final class LoweredRuntime {
    private final String portableArtifact;
    private final int processStatus;
    private final byte[] runtimeText;
    private final String runtimeIdentity;

    private LoweredRuntime(
        String portableArtifact,
        int processStatus,
        byte[] runtimeText) {
      this.portableArtifact = portableArtifact;
      this.processStatus = processStatus;
      this.runtimeText = runtimeText.clone();
      this.runtimeIdentity = identity(runtimeText);
    }

    public String portableArtifact() {
      return portableArtifact;
    }

    public int processStatus() {
      return processStatus;
    }

    public byte[] runtimeText() {
      return runtimeText.clone();
    }

    public String runtimeIdentity() {
      return runtimeIdentity;
    }
  }
}
