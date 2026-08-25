package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.packageformat.ApplicationCapsule;
import com.typeobject.wheeler.packageformat.CapsuleEntry;
import com.typeobject.wheeler.packageformat.CapsuleRoot;
import com.typeobject.wheeler.packageformat.NativeImagePlan;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

/** Verifies and executes one embedded-VM capsule from explicit mapped bytes and launch policy. */
public final class ApplicationCapsuleLauncher {
  private static final int MAX_IO_BYTES = 16 * 1024 * 1024;

  private ApplicationCapsuleLauncher() {}

  public static CapsuleExecution launch(byte[] mappedCapsule, LaunchContext context) {
    Objects.requireNonNull(context, "context");
    ApplicationCapsule capsule = ApplicationCapsule.parse(mappedCapsule);
    requireLaunchIdentity(capsule, context);
    requireSupportedEntries(capsule);
    ApplicationCapsuleVerifier.VerifiedCapsule verified =
        ApplicationCapsuleVerifier.verify(capsule);
    Program program = verified.rootProgram();
    if (program.kind() != ProgramKind.CLASSICAL) {
      throw new IllegalArgumentException("Embedded capsule startup is classical only");
    }
    requireEntryEffects(program.function(program.entryFunctionId()), capsule.root(), context);
    WheelerRuntime runtime = new WheelerRuntime();
    ExecutionResult execution = switch (context.inputMode()) {
      case NONE, UTF8 -> runtime.execute(
          program, null, context.input(), context.outputBytes());
      case BINARY -> runtime.executeBinaryInput(
          program, context.input(), context.outputBytes());
    };
    return new CapsuleExecution(
        capsule.identity(),
        capsule.root().packageInstance(),
        capsule.root().target(),
        capsule.root().entryFunction(),
        execution);
  }

  private static void requireLaunchIdentity(
      ApplicationCapsule capsule, LaunchContext context) {
    CapsuleRoot root = capsule.root();
    if (!capsule.identity().equals(context.capsuleIdentity())
        || !root.runtimeProfile().equals(context.runtimeProfile())
        || !root.bytecodeProfile().equals(context.bytecodeProfile())
        || !root.proofProfile().equals(context.proofProfile())
        || !root.targetProfile().equals(context.targetProfile())
        || !root.platformAbi().equals(context.platformAbi())
        || !root.executionLimits().equals(context.executionLimits())) {
      throw new IllegalArgumentException("Capsule launch identity does not match mapped policy");
    }
    if (root.runtimeMode() != NativeImagePlan.RuntimeMode.EMBEDDED_VM) {
      throw new IllegalArgumentException("Capsule does not select embedded-VM startup");
    }
    if (!root.requiredCapabilities().equals(context.grantedCapabilities())) {
      throw new IllegalArgumentException("Capsule capabilities do not match the launch grant");
    }
  }

  private static void requireSupportedEntries(ApplicationCapsule capsule) {
    for (CapsuleEntry entry : capsule.entries()) {
      if (entry.kind() == CapsuleEntry.Kind.NATIVE_PROVIDER
          || entry.kind() == CapsuleEntry.Kind.PROOF) {
        throw new IllegalArgumentException(
            "Embedded capsule startup cannot verify " + entry.kind().name().toLowerCase());
      }
    }
  }

  private static void requireEntryEffects(
      FunctionBody entry, CapsuleRoot root, LaunchContext context) {
    boolean input = entry.parameterCount() > 0
        && (entry.localType(0).equals(ValueType.UTF8_BORROW)
            || entry.localType(0).equals(ValueType.BYTE_VIEW));
    boolean binary = input && entry.localType(0).equals(ValueType.BYTE_VIEW);
    boolean output = entry.parameterCount() > 0
        && entry.localType(entry.parameterCount() - 1).equals(ValueType.BYTES_BORROW);
    int effectParameters = (input ? 1 : 0) + (output ? 1 : 0);
    if (entry.parameterCount() != effectParameters) {
      throw new IllegalArgumentException("Capsule root has unsupported host parameters");
    }
    ArrayList<String> expectedCapabilities = new ArrayList<>(2);
    if (input) {
      expectedCapabilities.add("io:stdin/1");
    }
    if (output) {
      expectedCapabilities.add("io:stdout/1");
    }
    expectedCapabilities.sort(String::compareTo);
    if (!root.requiredCapabilities().equals(expectedCapabilities)) {
      throw new IllegalArgumentException(
          "Capsule root capabilities do not match its entry effects");
    }
    InputMode expectedInput = input ? (binary ? InputMode.BINARY : InputMode.UTF8) : InputMode.NONE;
    if (context.inputMode() != expectedInput || output != (context.outputBytes() >= 0)) {
      throw new IllegalArgumentException("Capsule entry effects do not match launch I/O");
    }
  }

  /** Exact host policy and I/O supplied to one mapped capsule launch. */
  public record LaunchContext(
      String capsuleIdentity,
      String runtimeProfile,
      String bytecodeProfile,
      String proofProfile,
      String targetProfile,
      String platformAbi,
      String executionLimits,
      List<String> grantedCapabilities,
      InputMode inputMode,
      byte[] input,
      int outputBytes) {
    public LaunchContext {
      requireHash(capsuleIdentity, "capsule");
      requireHash(runtimeProfile, "runtime profile");
      requireHash(bytecodeProfile, "bytecode profile");
      requireHash(proofProfile, "proof profile");
      requireHash(targetProfile, "target profile");
      requireHash(platformAbi, "platform ABI");
      requireHash(executionLimits, "execution limits");
      if (grantedCapabilities == null || grantedCapabilities.size() > 32) {
        throw new PackageFormatException("Invalid launch capability count");
      }
      Set<String> unique = new HashSet<>();
      String previous = null;
      for (String capability : grantedCapabilities) {
        if (capability == null
            || !capability.matches("[a-z0-9][a-z0-9:._/@+\\-]*")
            || capability.contains("//")
            || !unique.add(capability)
            || previous != null && previous.compareTo(capability) >= 0) {
          throw new PackageFormatException("Launch capabilities are invalid or unordered");
        }
        previous = capability;
      }
      grantedCapabilities = List.copyOf(grantedCapabilities);
      Objects.requireNonNull(inputMode, "inputMode");
      if (inputMode == InputMode.NONE && input != null
          || inputMode != InputMode.NONE && input == null
          || input != null && input.length > MAX_IO_BYTES
          || outputBytes < -1
          || outputBytes > MAX_IO_BYTES) {
        throw new IllegalArgumentException("Invalid capsule launch I/O");
      }
      input = input == null ? null : input.clone();
    }

    @Override
    public byte[] input() {
      return input == null ? null : input.clone();
    }

    private static void requireHash(String value, String description) {
      if (value == null || !value.matches("[0-9a-f]{64}")) {
        throw new PackageFormatException("Invalid launch " + description + " identity");
      }
    }
  }

  public enum InputMode {
    NONE,
    UTF8,
    BINARY
  }

  /** One successful root execution bound back to its capsule and package target. */
  public static final class CapsuleExecution {
    private final String capsuleIdentity;
    private final String packageInstance;
    private final String target;
    private final String entryFunction;
    private final ExecutionResult execution;

    private CapsuleExecution(
        String capsuleIdentity,
        String packageInstance,
        String target,
        String entryFunction,
        ExecutionResult execution) {
      this.capsuleIdentity = Objects.requireNonNull(capsuleIdentity, "capsuleIdentity");
      this.packageInstance = Objects.requireNonNull(packageInstance, "packageInstance");
      this.target = Objects.requireNonNull(target, "target");
      this.entryFunction = Objects.requireNonNull(entryFunction, "entryFunction");
      this.execution = Objects.requireNonNull(execution, "execution");
    }

    public String capsuleIdentity() {
      return capsuleIdentity;
    }

    public String packageInstance() {
      return packageInstance;
    }

    public String target() {
      return target;
    }

    public String entryFunction() {
      return entryFunction;
    }

    public ExecutionResult execution() {
      return execution;
    }
  }
}
