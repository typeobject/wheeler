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
  public static final int EXECUTION_TRAP_STATUS = ScalarAotMachine.EXECUTION_TRAP_STATUS;

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
    byte[] machineCode = ScalarAotMachine.lower(scalar);
    byte[] runtimeText = scalar.usesDynamicApplicationIo()
        ? LinuxX8664EntryShim.runtimeTextWithApplicationIo(machineCode)
        : scalar.writesApplicationOutput()
            ? LinuxX8664EntryShim.runtimeText(machineCode, scalar.applicationOutput())
            : LinuxX8664EntryShim.runtimeText(machineCode);
    return new LoweredRuntime(
        identity(artifact),
        scalar.hasStaticProcessStatus() ? scalar.processStatus() : null,
        scalar.writesApplicationOutput() ? scalar.applicationOutput() : null,
        scalar.usesDynamicApplicationIo(),
        runtimeText);
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
    private final Integer processStatus;
    private final byte[] applicationOutput;
    private final boolean dynamicApplicationIo;
    private final byte[] runtimeText;
    private final String runtimeIdentity;

    private LoweredRuntime(
        String portableArtifact,
        Integer processStatus,
        byte[] applicationOutput,
        boolean dynamicApplicationIo,
        byte[] runtimeText) {
      this.portableArtifact = portableArtifact;
      this.processStatus = processStatus;
      this.applicationOutput = applicationOutput == null ? null : applicationOutput.clone();
      this.dynamicApplicationIo = dynamicApplicationIo;
      this.runtimeText = runtimeText.clone();
      this.runtimeIdentity = identity(runtimeText);
    }

    public String portableArtifact() {
      return portableArtifact;
    }

    public boolean hasStaticProcessStatus() {
      return processStatus != null;
    }

    public int processStatus() {
      if (processStatus == null) {
        throw new IllegalStateException("Lowered runtime has input-dependent process status");
      }
      return processStatus;
    }

    public boolean usesDynamicApplicationIo() {
      return dynamicApplicationIo;
    }

    public boolean writesApplicationOutput() {
      return applicationOutput != null;
    }

    public byte[] applicationOutput() {
      if (applicationOutput == null) {
        throw new IllegalStateException("Lowered runtime has no application output");
      }
      return applicationOutput.clone();
    }

    public byte[] runtimeText() {
      return runtimeText.clone();
    }

    public String runtimeIdentity() {
      return runtimeIdentity;
    }
  }
}
