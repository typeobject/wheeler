package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.packageformat.ApplicationCapsule;
import com.typeobject.wheeler.packageformat.CapsuleEntry;
import com.typeobject.wheeler.packageformat.NativeImagePlan;
import com.typeobject.wheeler.runtime.aot.ScalarAotMachine;
import com.typeobject.wheeler.runtime.aot.ScalarAotProgram;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.List;

/** x86-64 Linux AOT leaf for a bounded Wheeler process-status program. */
public final class LinuxX8664ScalarAotCompiler {
  public static final int EXECUTION_TRAP_STATUS = ScalarAotMachine.EXECUTION_TRAP_STATUS;

  private LinuxX8664ScalarAotCompiler() {}

  /** Verifies and lowers one capsule-bound process-status WBC into owned runtime text. */
  public static LoweredRuntime lower(byte[] artifact, ApplicationCapsule capsule) {
    if (artifact == null) {
      throw new NullPointerException("Portable WBC artifact is required");
    }
    ApplicationCapsuleVerifier.VerifiedCapsule verified =
        ApplicationCapsuleVerifier.verify(capsule);
    CapsuleEntry rootEntry = capsule.entries().stream()
        .filter(entry -> entry.name().equals(capsule.root().rootWbc()))
        .findFirst()
        .orElseThrow(() -> new IllegalStateException("Verified capsule root entry disappeared"));
    if (capsule.root().runtimeMode() != NativeImagePlan.RuntimeMode.AOT
        || !Arrays.equals(artifact, rootEntry.bytes())) {
      throw new IllegalArgumentException("Scalar AOT WBC does not match the capsule root");
    }
    Program program = verified.rootProgram();
    ScalarAotProgram scalar = ScalarAotProgram.validate(program);
    List<String> capabilities = switch (scalar.entry().parameterCount()) {
      case 0 -> List.of();
      case 1 -> List.of("io:stdout/1");
      case 2 -> List.of("io:stdin/1", "io:stdout/1");
      default -> throw new IllegalStateException("Validated scalar entry shape changed");
    };
    if (!capsule.root().requiredCapabilities().equals(capabilities)) {
      throw new IllegalArgumentException("Scalar AOT capsule capabilities do not match its entry");
    }
    byte[] machineCode = ScalarAotMachine.lower(scalar);
    byte[] capsuleBytes = capsule.canonicalBytes();
    byte[] runtimeText = scalar.usesDynamicApplicationIo()
        ? LinuxX8664EntryShim.boundRuntimeTextWithApplicationIo(machineCode, capsuleBytes)
        : scalar.writesApplicationOutput()
            ? LinuxX8664EntryShim.boundRuntimeText(
                machineCode, scalar.applicationOutput(), capsuleBytes)
            : LinuxX8664EntryShim.boundRuntimeText(machineCode, capsuleBytes);
    return new LoweredRuntime(
        identity(artifact),
        capsule.identity(),
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
    private final String capsuleIdentity;
    private final Integer processStatus;
    private final byte[] applicationOutput;
    private final boolean dynamicApplicationIo;
    private final byte[] runtimeText;
    private final String runtimeIdentity;

    private LoweredRuntime(
        String portableArtifact,
        String capsuleIdentity,
        Integer processStatus,
        byte[] applicationOutput,
        boolean dynamicApplicationIo,
        byte[] runtimeText) {
      this.portableArtifact = portableArtifact;
      this.capsuleIdentity = capsuleIdentity;
      this.processStatus = processStatus;
      this.applicationOutput = applicationOutput == null ? null : applicationOutput.clone();
      this.dynamicApplicationIo = dynamicApplicationIo;
      this.runtimeText = runtimeText.clone();
      this.runtimeIdentity = identity(runtimeText);
    }

    public String portableArtifact() {
      return portableArtifact;
    }

    public String capsuleIdentity() {
      return capsuleIdentity;
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
