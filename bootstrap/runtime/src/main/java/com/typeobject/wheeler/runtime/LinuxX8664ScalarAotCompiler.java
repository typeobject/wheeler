package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.bytecode.ValueType;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.List;

/** First x86-64 Linux AOT leaf for a bounded Wheeler process-status program. */
public final class LinuxX8664ScalarAotCompiler {
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
    int status = processStatus(program);
    return new LoweredRuntime(
        identity(artifact),
        status,
        LinuxX8664EntryShim.runtimeText(status));
  }

  private static int processStatus(Program program) {
    if (program.kind() != ProgramKind.CLASSICAL
        || !program.recordTypes().isEmpty()
        || !program.variantTypes().isEmpty()
        || !program.arrayTypes().isEmpty()
        || !program.sliceTypes().isEmpty()
        || !program.proofCertificates().isEmpty()
        || !program.quantumRegisters().isEmpty()
        || !program.quantumCircuits().isEmpty()
        || !program.workflow().isEmpty()
        || !program.requiredInstructionExtensions().isEmpty()
        || program.globals().size() != 1
        || !program.globals().getFirst().name().equals("status")
        || program.globals().getFirst().initialValue() != 0
        || program.functions().size() != 1) {
      throw new IllegalArgumentException("WBC is outside the scalar AOT process-status profile");
    }
    FunctionBody entry = program.function(program.entryFunctionId());
    if (entry.id() != program.functions().getFirst().id()
        || entry.coherent()
        || entry.parameterCount() != 0
        || !entry.localTypes().equals(List.of(ValueType.SIGNED))
        || entry.resultType() != null
        || entry.implicitResultSlot()
        || !entry.inverse().isEmpty()
        || entry.forward().size() != 3) {
      throw new IllegalArgumentException("AOT entry signature is outside the scalar profile");
    }
    Instruction value = entry.forward().get(0);
    Instruction store = entry.forward().get(1);
    Instruction halt = entry.forward().get(2);
    if (value.opcode() != Opcode.LOCAL_CONST
        || value.operands().size() != 2
        || value.operands().get(0) != 0
        || store.opcode() != Opcode.LOCAL_STORE_GLOBAL
        || !store.operands().equals(List.of(0L, 0L))
        || halt.opcode() != Opcode.HALT
        || !halt.operands().isEmpty()) {
      throw new IllegalArgumentException("AOT entry code is outside the scalar profile");
    }
    long status = value.operands().get(1);
    if (status < 0 || status >= LinuxX8664EntryShim.MALFORMED_IMAGE_STATUS) {
      throw new IllegalArgumentException("AOT process status must be between 0 and 124");
    }
    return Math.toIntExact(status);
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
