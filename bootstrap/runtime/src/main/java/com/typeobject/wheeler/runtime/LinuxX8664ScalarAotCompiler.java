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
        LinuxX8664EntryShim.runtimeText(machineCode(entry)));
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
        || entry.localTypes().stream().anyMatch(type ->
            !type.equals(ValueType.SIGNED) && !type.equals(ValueType.BOOLEAN))
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
    validateInstructions(entry);
    long[] values = new long[entry.localCount()];
    boolean[] assigned = new boolean[entry.localCount()];
    long status = 0;
    boolean stored = false;
    int pc = 0;
    while (pc < entry.forward().size()) {
      Instruction instruction = entry.forward().get(pc);
      try {
        switch (instruction.opcode()) {
          case LOCAL_CONST -> {
            int destination = freshDestination(instruction, assigned);
            values[destination] = instruction.operands().get(1);
            assigned[destination] = true;
            pc++;
          }
          case LOCAL_MOVE -> {
            int destination = freshDestination(instruction, assigned);
            int source = assignedLocal(instruction, 1, assigned);
            values[destination] = values[source];
            assigned[source] = false;
            assigned[destination] = true;
            pc++;
          }
          case LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND, LOCAL_XOR,
              LOCAL_EQ, LOCAL_LT -> {
            int destination = freshDestination(instruction, assigned);
            int left = assignedLocal(instruction, 1, assigned);
            int right = assignedLocal(instruction, 2, assigned);
            values[destination] = evaluate(
                instruction.opcode(), values[left], values[right]);
            assigned[destination] = true;
            pc++;
          }
          case JUMP -> pc = Math.toIntExact(instruction.operands().get(0));
          case JUMP_IF_ZERO -> {
            int condition = assignedLocal(instruction, 0, assigned);
            pc = values[condition] == 0
                ? Math.toIntExact(instruction.operands().get(1))
                : pc + 1;
          }
          case LOCAL_STORE_GLOBAL -> {
            status = values[assignedLocal(instruction, 1, assigned)];
            stored = true;
            pc++;
          }
          case HALT -> pc = entry.forward().size();
          default -> throw new IllegalStateException("Validated scalar AOT opcode changed");
        }
      } catch (ArithmeticException exception) {
        throw new IllegalArgumentException("Scalar AOT arithmetic traps", exception);
      }
    }
    if (!stored || status < 0 || status >= LinuxX8664EntryShim.MALFORMED_IMAGE_STATUS) {
      throw new IllegalArgumentException("AOT process status must be between 0 and 124");
    }
    return new ScalarPlan(Math.toIntExact(status));
  }

  private static void validateInstructions(FunctionBody entry) {
    int stores = 0;
    int last = entry.forward().size() - 1;
    for (int pc = 0; pc < entry.forward().size(); pc++) {
      Instruction instruction = entry.forward().get(pc);
      switch (instruction.opcode()) {
        case LOCAL_CONST, LOCAL_MOVE -> {
          requireOperands(instruction, 2);
          local(instruction.operands().get(0), entry.localCount());
          if (instruction.opcode() == Opcode.LOCAL_MOVE) {
            local(instruction.operands().get(1), entry.localCount());
          }
        }
        case LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND, LOCAL_XOR,
            LOCAL_EQ, LOCAL_LT -> {
          requireOperands(instruction, 3);
          local(instruction.operands().get(0), entry.localCount());
          local(instruction.operands().get(1), entry.localCount());
          local(instruction.operands().get(2), entry.localCount());
        }
        case JUMP -> {
          requireOperands(instruction, 1);
          forwardTarget(instruction.operands().get(0), pc, last);
        }
        case JUMP_IF_ZERO -> {
          requireOperands(instruction, 2);
          local(instruction.operands().get(0), entry.localCount());
          forwardTarget(instruction.operands().get(1), pc, last);
        }
        case LOCAL_STORE_GLOBAL -> {
          requireOperands(instruction, 2);
          if (instruction.operands().get(0) != 0) {
            throw new IllegalArgumentException("Scalar AOT store targets an unknown global");
          }
          local(instruction.operands().get(1), entry.localCount());
          stores++;
        }
        case HALT -> {
          if (pc != last || !instruction.operands().isEmpty()) {
            throw new IllegalArgumentException("Scalar AOT halt must be terminal");
          }
        }
        default -> throw new IllegalArgumentException(
            "Unsupported scalar AOT opcode " + instruction.opcode());
      }
    }
    if (stores == 0 || entry.forward().getLast().opcode() != Opcode.HALT) {
      throw new IllegalArgumentException("Scalar AOT entry has no status store and halt");
    }
  }

  private static int freshDestination(Instruction instruction, boolean[] assigned) {
    int destination = local(instruction.operands().get(0), assigned.length);
    if (assigned[destination]) {
      throw new IllegalArgumentException("Scalar AOT destination is already assigned");
    }
    return destination;
  }

  private static int forwardTarget(long value, int pc, int last) {
    int target = Math.toIntExact(value);
    if (target <= pc || target > last) {
      throw new IllegalArgumentException("Scalar AOT branch is not forward and bounded");
    }
    return target;
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
      case LOCAL_EQ -> left == right ? 1 : 0;
      case LOCAL_LT -> left < right ? 1 : 0;
      default -> throw new IllegalArgumentException("Unsupported scalar AOT arithmetic");
    };
  }

  private static byte[] machineCode(FunctionBody entry) {
    X86 code = new X86();
    int globalSlot = entry.localCount();
    int frameBytes = Math.multiplyExact(globalSlot + 1, Long.BYTES);
    code.stack(-frameBytes);
    code.bytes(0x31, 0xc0);
    code.storeRax(globalSlot);
    int[] instructionOffsets = new int[entry.forward().size()];
    ArrayList<MachineBranch> branches = new ArrayList<>();
    ArrayList<Integer> trapBranches = new ArrayList<>();
    for (int pc = 0; pc < entry.forward().size(); pc++) {
      instructionOffsets[pc] = code.position();
      Instruction instruction = entry.forward().get(pc);
      switch (instruction.opcode()) {
        case LOCAL_CONST -> {
          code.moveImmediateToRax(instruction.operands().get(1));
          code.storeRax(Math.toIntExact(instruction.operands().get(0)));
        }
        case LOCAL_MOVE -> {
          code.loadRax(Math.toIntExact(instruction.operands().get(1)));
          code.storeRax(Math.toIntExact(instruction.operands().get(0)));
        }
        case LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND, LOCAL_XOR -> {
          code.loadRax(Math.toIntExact(instruction.operands().get(1)));
          code.loadRcx(Math.toIntExact(instruction.operands().get(2)));
          code.arithmetic(instruction.opcode(), trapBranches);
          code.storeRax(Math.toIntExact(instruction.operands().get(0)));
        }
        case LOCAL_EQ, LOCAL_LT -> {
          code.loadRax(Math.toIntExact(instruction.operands().get(1)));
          code.loadRcx(Math.toIntExact(instruction.operands().get(2)));
          code.comparison(instruction.opcode());
          code.storeRax(Math.toIntExact(instruction.operands().get(0)));
        }
        case JUMP -> {
          code.bytes(0xe9);
          branches.add(new MachineBranch(
              code.reserveInt(), Math.toIntExact(instruction.operands().get(0))));
        }
        case JUMP_IF_ZERO -> {
          code.loadRax(Math.toIntExact(instruction.operands().get(0)));
          code.bytes(0x48, 0x85, 0xc0, 0x0f, 0x84);
          branches.add(new MachineBranch(
              code.reserveInt(), Math.toIntExact(instruction.operands().get(1))));
        }
        case LOCAL_STORE_GLOBAL -> {
          code.loadRax(Math.toIntExact(instruction.operands().get(1)));
          code.storeRax(globalSlot);
        }
        case HALT -> {
          // The terminal instruction falls into process-status validation.
        }
        default -> throw new IllegalStateException("Validated scalar AOT opcode changed");
      }
    }
    code.loadRax(globalSlot);
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
    for (MachineBranch branch : branches) {
      code.patchRelativeInt(branch.displacement(), instructionOffsets[branch.target()]);
    }
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

  private record ScalarPlan(int processStatus) {}

  private record MachineBranch(int displacement, int target) {}

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

    void comparison(Opcode opcode) {
      bytes(0x48, 0x39, 0xc8);
      if (opcode == Opcode.LOCAL_EQ) {
        bytes(0x0f, 0x94, 0xc0);
      } else if (opcode == Opcode.LOCAL_LT) {
        bytes(0x0f, 0x9c, 0xc0);
      } else {
        throw new IllegalStateException("Validated scalar AOT comparison changed");
      }
      bytes(0x48, 0x0f, 0xb6, 0xc0);
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
