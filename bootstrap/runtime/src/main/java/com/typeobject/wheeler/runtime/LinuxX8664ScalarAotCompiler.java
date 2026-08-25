package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.bytecode.ValueType;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HexFormat;

/** First x86-64 Linux AOT leaf for a bounded Wheeler process-status program. */
public final class LinuxX8664ScalarAotCompiler {
  public static final int ARITHMETIC_TRAP_STATUS = 126;
  private static final int MAX_LOCALS = 32;
  private static final int MAX_INSTRUCTIONS = 128;

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
    FunctionBody entry = requireProgram(program);
    ScalarPlan plan = scalarPlan(entry);
    return new LoweredRuntime(
        identity(artifact),
        plan.processStatus(),
        LinuxX8664EntryShim.runtimeText(machineCode(entry, plan.resultLocal())));
  }

  private static FunctionBody requireProgram(Program program) {
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
        || entry.localCount() == 0
        || entry.localCount() > MAX_LOCALS
        || entry.localTypes().stream().anyMatch(type -> !type.equals(ValueType.SIGNED))
        || entry.resultType() != null
        || entry.implicitResultSlot()
        || !entry.inverse().isEmpty()
        || entry.forward().size() < 3
        || entry.forward().size() > MAX_INSTRUCTIONS) {
      throw new IllegalArgumentException("AOT entry signature is outside the scalar profile");
    }
    return entry;
  }

  private static ScalarPlan scalarPlan(FunctionBody entry) {
    long[] values = new long[entry.localCount()];
    boolean[] assigned = new boolean[entry.localCount()];
    for (int index = 0; index < entry.forward().size() - 2; index++) {
      Instruction instruction = entry.forward().get(index);
      int operandCount = switch (instruction.opcode()) {
        case LOCAL_CONST, LOCAL_MOVE -> 2;
        case LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND, LOCAL_XOR -> 3;
        default -> throw new IllegalArgumentException(
            "Unsupported scalar AOT opcode " + instruction.opcode());
      };
      requireOperands(instruction, operandCount);
      int destination = local(instruction.operands().get(0), entry.localCount());
      if (assigned[destination]) {
        throw new IllegalArgumentException("Scalar AOT destination is already assigned");
      }
      try {
        switch (instruction.opcode()) {
          case LOCAL_CONST -> {
            values[destination] = instruction.operands().get(1);
          }
          case LOCAL_MOVE -> {
            int source = assignedLocal(instruction, 1, assigned);
            values[destination] = values[source];
            assigned[source] = false;
          }
          case LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND, LOCAL_XOR -> {
            int left = assignedLocal(instruction, 1, assigned);
            int right = assignedLocal(instruction, 2, assigned);
            values[destination] = evaluate(
                instruction.opcode(), values[left], values[right]);
          }
          default -> throw new IllegalArgumentException(
              "Unsupported scalar AOT opcode " + instruction.opcode());
        }
      } catch (ArithmeticException exception) {
        throw new IllegalArgumentException("Scalar AOT arithmetic traps", exception);
      }
      assigned[destination] = true;
    }
    Instruction store = entry.forward().get(entry.forward().size() - 2);
    Instruction halt = entry.forward().getLast();
    requireOperands(store, 2);
    if (store.opcode() != Opcode.LOCAL_STORE_GLOBAL
        || store.operands().get(0) != 0
        || halt.opcode() != Opcode.HALT
        || !halt.operands().isEmpty()) {
      throw new IllegalArgumentException("Scalar AOT entry has no terminal status store");
    }
    int result = assignedLocal(store, 1, assigned);
    long status = values[result];
    if (status < 0 || status >= LinuxX8664EntryShim.MALFORMED_IMAGE_STATUS) {
      throw new IllegalArgumentException("AOT process status must be between 0 and 124");
    }
    return new ScalarPlan(Math.toIntExact(status), result);
  }

  private static long evaluate(Opcode opcode, long left, long right) {
    return switch (opcode) {
      case LOCAL_ADD -> Math.addExact(left, right);
      case LOCAL_SUB -> Math.subtractExact(left, right);
      case LOCAL_MUL -> Math.multiplyExact(left, right);
      case LOCAL_DIV -> {
        if (right == 0 || left == Long.MIN_VALUE && right == -1) {
          throw new ArithmeticException("Invalid bounded division");
        }
        yield left / right;
      }
      case LOCAL_MOD -> {
        if (right == 0 || left == Long.MIN_VALUE && right == -1) {
          throw new ArithmeticException("Invalid bounded remainder");
        }
        yield left % right;
      }
      case LOCAL_AND -> left & right;
      case LOCAL_XOR -> left ^ right;
      default -> throw new IllegalArgumentException("Unsupported scalar AOT arithmetic");
    };
  }

  private static byte[] machineCode(FunctionBody entry, int resultLocal) {
    X86 code = new X86();
    int frameBytes = Math.multiplyExact(entry.localCount(), Long.BYTES);
    code.stack(-frameBytes);
    ArrayList<Integer> trapBranches = new ArrayList<>();
    for (int index = 0; index < entry.forward().size() - 2; index++) {
      Instruction instruction = entry.forward().get(index);
      int destination = Math.toIntExact(instruction.operands().get(0));
      switch (instruction.opcode()) {
        case LOCAL_CONST -> {
          code.moveImmediateToRax(instruction.operands().get(1));
          code.storeRax(destination);
        }
        case LOCAL_MOVE -> {
          code.loadRax(Math.toIntExact(instruction.operands().get(1)));
          code.storeRax(destination);
        }
        case LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND, LOCAL_XOR -> {
          code.loadRax(Math.toIntExact(instruction.operands().get(1)));
          code.loadRcx(Math.toIntExact(instruction.operands().get(2)));
          code.arithmetic(instruction.opcode(), trapBranches);
          code.storeRax(destination);
        }
        default -> throw new IllegalStateException("Validated scalar AOT opcode changed");
      }
    }
    code.loadRax(resultLocal);
    code.bytes(0x48, 0x85, 0xc0, 0x0f, 0x88);
    trapBranches.add(code.reserveInt());
    code.bytes(0x48, 0x83, 0xf8, 124, 0x0f, 0x8f);
    trapBranches.add(code.reserveInt());
    code.stack(frameBytes);
    code.bytes(0x89, 0xc7, 0xe9);
    int successJump = code.reserveInt();
    int trap = code.position();
    code.stack(frameBytes);
    code.bytes(0xbf);
    code.integer(ARITHMETIC_TRAP_STATUS);
    int end = code.position();
    for (int branch : trapBranches) {
      code.patchRelativeInt(branch, trap);
    }
    code.patchRelativeInt(successJump, end);
    return code.finish();
  }

  private static int local(long value, int count) {
    int result = Math.toIntExact(value);
    if (result < 0 || result >= count) {
      throw new IllegalArgumentException("Scalar AOT local is out of range");
    }
    return result;
  }

  private static int assignedLocal(
      Instruction instruction, int operand, boolean[] assigned) {
    int result = local(instruction.operands().get(operand), assigned.length);
    if (!assigned[result]) {
      throw new IllegalArgumentException("Scalar AOT reads an unassigned local");
    }
    return result;
  }

  private static void requireOperands(Instruction instruction, int count) {
    if (instruction.operands().size() != count) {
      throw new IllegalArgumentException("Scalar AOT operand count changed");
    }
  }

  private static String identity(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private record ScalarPlan(int processStatus, int resultLocal) {}

  private static final class X86 {
    private final ByteArrayOutputStream output = new ByteArrayOutputStream(1024);
    private byte[] finished;

    int position() {
      return output.size();
    }

    void bytes(int... values) {
      for (int value : values) {
        output.write(value);
      }
    }

    int reserveInt() {
      int result = position();
      integer(0);
      return result;
    }

    void integer(int value) {
      for (int shift = 0; shift < Integer.SIZE; shift += Byte.SIZE) {
        output.write(value >>> shift);
      }
    }

    void word(long value) {
      for (int shift = 0; shift < Long.SIZE; shift += Byte.SIZE) {
        output.write((int) (value >>> shift));
      }
    }

    void stack(int delta) {
      bytes(0x48, 0x81, delta < 0 ? 0xec : 0xc4);
      integer(Math.abs(delta));
    }

    void moveImmediateToRax(long value) {
      bytes(0x48, 0xb8);
      word(value);
    }

    void loadRax(int local) {
      bytes(0x48, 0x8b, 0x84, 0x24);
      integer(local * Long.BYTES);
    }

    void loadRcx(int local) {
      bytes(0x48, 0x8b, 0x8c, 0x24);
      integer(local * Long.BYTES);
    }

    void storeRax(int local) {
      bytes(0x48, 0x89, 0x84, 0x24);
      integer(local * Long.BYTES);
    }

    void arithmetic(Opcode opcode, ArrayList<Integer> traps) {
      switch (opcode) {
        case LOCAL_ADD -> {
          bytes(0x48, 0x01, 0xc8, 0x0f, 0x80);
          traps.add(reserveInt());
        }
        case LOCAL_SUB -> {
          bytes(0x48, 0x29, 0xc8, 0x0f, 0x80);
          traps.add(reserveInt());
        }
        case LOCAL_MUL -> {
          bytes(0x48, 0x0f, 0xaf, 0xc1, 0x0f, 0x80);
          traps.add(reserveInt());
        }
        case LOCAL_DIV, LOCAL_MOD -> division(opcode);
        case LOCAL_AND -> bytes(0x48, 0x21, 0xc8);
        case LOCAL_XOR -> bytes(0x48, 0x31, 0xc8);
        default -> throw new IllegalStateException("Validated scalar AOT arithmetic changed");
      }
    }

    void division(Opcode opcode) {
      bytes(0x48, 0x99, 0x48, 0xf7, 0xf9);
      if (opcode == Opcode.LOCAL_MOD) {
        bytes(0x48, 0x89, 0xd0);
      }
    }

    void patchRelativeInt(int displacementOffset, int target) {
      finishBytes();
      int displacement = target - displacementOffset - Integer.BYTES;
      ByteBuffer.wrap(finished)
          .order(ByteOrder.LITTLE_ENDIAN)
          .putInt(displacementOffset, displacement);
    }

    byte[] finish() {
      finishBytes();
      return finished;
    }

    private void finishBytes() {
      if (finished == null) {
        finished = output.toByteArray();
      }
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
