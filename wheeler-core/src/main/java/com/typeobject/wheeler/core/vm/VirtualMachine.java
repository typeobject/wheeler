package com.typeobject.wheeler.core.vm;

import com.typeobject.wheeler.core.bytecode.BytecodeVerifier;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Deterministic single-threaded Wheeler version-1 transition kernel. */
public final class VirtualMachine {
  private final Program program;
  private final long[] globals;
  private final List<Frame> frames = new ArrayList<>();
  private final Deque<StepRecord> history = new ArrayDeque<>();
  private MachineStatus status = MachineStatus.READY;
  private long sequence;

  public VirtualMachine(Program program) {
    BytecodeVerifier.verify(program);
    this.program = program;
    this.globals = program.globals().stream().mapToLong(global -> global.initialValue()).toArray();
    this.frames.add(new Frame(program.entryFunctionId(), false, 0));
  }

  public void run() {
    long start = sequence;
    while (status != MachineStatus.HALTED) {
      if (status == MachineStatus.TRAPPED) {
        throw new VmTrap("Cannot run a trapped machine");
      }
      if (sequence - start >= program.maxSteps()) {
        trap("Step limit exceeded");
      }
      step();
    }
  }

  public void step() {
    if (status == MachineStatus.HALTED) {
      throw new VmTrap("Cannot step a halted machine");
    }
    if (status == MachineStatus.TRAPPED) {
      throw new VmTrap("Cannot step a trapped machine");
    }
    Frame frame = currentFrame();
    Instruction instruction = fetch(frame);
    validateBeforeMutation(instruction);
    if (instruction.opcode() != Opcode.COMMIT
        && history.size() >= program.maxHistoryRecords()) {
      trap("History record limit exceeded");
    }

    MachineStatus previousStatus = status;
    status = MachineStatus.RUNNING;
    StepRecord record = execute(frame, instruction, previousStatus);
    sequence = Math.addExact(sequence, 1);
    if (instruction.opcode() == Opcode.COMMIT) {
      history.clear();
    } else {
      history.push(record);
    }
  }

  public void rewindOne() {
    StepRecord record = history.pollFirst();
    if (record == null) {
      throw new VmTrap("No reversible history is available");
    }
    undoData(record);
    switch (record.controlChange()) {
      case ADVANCE -> replaceCurrentFrame(record.previousFrame());
      case CALL -> {
        if (frames.size() < 2) {
          throw new IllegalStateException("Corrupt CALL undo state");
        }
        frames.removeLast();
        replaceCurrentFrame(record.previousFrame());
      }
      case RETURN -> frames.add(record.previousFrame());
    }
    status = record.previousStatus();
    sequence = record.sequence();
  }

  public long global(String name) {
    return globals[program.globalIndex(name)];
  }

  public long global(int index) {
    return globals[checkedGlobalIndex(index)];
  }

  /** Executes one function from a hybrid workflow boundary. WIP-0004 records this boundary. */
  public void invoke(int functionId, boolean inverse) {
    if (status == MachineStatus.HALTED || status == MachineStatus.TRAPPED) {
      throw new VmTrap("Cannot invoke a function on a finished machine");
    }
    FunctionBody function = program.function(functionId);
    if (inverse && !function.reversible()) {
      throw new VmTrap("Function has no inverse: " + function.name());
    }
    history.clear();
    int callerDepth = frames.size();
    frames.add(new Frame(functionId, inverse, 0));
    while (frames.size() > callerDepth) {
      step();
    }
    history.clear();
  }

  /** Applies a measured or external value and establishes an irreversible workflow boundary. */
  public void setGlobalFromEffect(int index, long value) {
    globals[checkedGlobalIndex(index)] = value;
    history.clear();
  }

  public void expectGlobal(int index, long expected) {
    long actual = globals[checkedGlobalIndex(index)];
    if (actual != expected) {
      trap("Expectation failed: expected %d, got %d".formatted(expected, actual));
    }
  }

  public void commitHistory() {
    history.clear();
  }

  public MachineSnapshot snapshot() {
    Map<String, Long> values = new LinkedHashMap<>();
    for (int i = 0; i < globals.length; i++) {
      values.put(program.globals().get(i).name(), globals[i]);
    }
    return new MachineSnapshot(
        status, List.copyOf(frames), Map.copyOf(values), history.size(), sequence);
  }

  public MachineStatus status() {
    return status;
  }

  public int historySize() {
    return history.size();
  }

  private StepRecord execute(
      Frame frame, Instruction instruction, MachineStatus previousStatus) {
    Opcode opcode = instruction.opcode();
    int changedGlobal = StepRecord.NO_GLOBAL;
    long previousValue = 0;
    StepRecord.ControlChange control = StepRecord.ControlChange.ADVANCE;

    switch (opcode) {
      case ADD_CONST -> {
        int index = globalIndex(instruction, 0);
        globals[index] = Math.addExact(globals[index], operand(instruction, 1));
        advanceCurrentFrame();
      }
      case SUB_CONST -> {
        int index = globalIndex(instruction, 0);
        globals[index] = Math.subtractExact(globals[index], operand(instruction, 1));
        advanceCurrentFrame();
      }
      case XOR_CONST -> {
        int index = globalIndex(instruction, 0);
        globals[index] ^= operand(instruction, 1);
        advanceCurrentFrame();
      }
      case SWAP -> {
        int left = globalIndex(instruction, 0);
        int right = globalIndex(instruction, 1);
        long value = globals[left];
        globals[left] = globals[right];
        globals[right] = value;
        advanceCurrentFrame();
      }
      case SET_LOGGED -> {
        changedGlobal = globalIndex(instruction, 0);
        previousValue = globals[changedGlobal];
        globals[changedGlobal] = operand(instruction, 1);
        advanceCurrentFrame();
      }
      case CALL, UNCALL -> {
        int functionId = Math.toIntExact(operand(instruction, 0));
        advanceCurrentFrame();
        frames.add(new Frame(functionId, opcode == Opcode.UNCALL, 0));
        control = StepRecord.ControlChange.CALL;
      }
      case RETURN -> {
        frames.removeLast();
        control = StepRecord.ControlChange.RETURN;
      }
      case EXPECT_EQ, NOP, CHECKPOINT, COMMIT -> advanceCurrentFrame();
      case HALT -> {
        advanceCurrentFrame();
        status = MachineStatus.HALTED;
      }
    }

    return new StepRecord(
        sequence,
        instruction,
        previousStatus,
        control,
        frame,
        changedGlobal,
        previousValue);
  }

  private void validateBeforeMutation(Instruction instruction) {
    try {
      switch (instruction.opcode()) {
        case ADD_CONST -> Math.addExact(
            globals[globalIndex(instruction, 0)], operand(instruction, 1));
        case SUB_CONST -> Math.subtractExact(
            globals[globalIndex(instruction, 0)], operand(instruction, 1));
        case CALL -> program.function(Math.toIntExact(operand(instruction, 0)));
        case UNCALL -> {
          FunctionBody function = program.function(Math.toIntExact(operand(instruction, 0)));
          if (!function.reversible()) {
            trap("Function has no inverse: " + function.name());
          }
        }
        case RETURN -> {
          if (frames.size() <= 1) {
            trap("Entry function cannot return");
          }
        }
        case EXPECT_EQ -> {
          int index = globalIndex(instruction, 0);
          long expected = operand(instruction, 1);
          if (globals[index] != expected) {
            trap("Expectation failed for %s: expected %d, got %d"
                .formatted(program.globals().get(index).name(), expected, globals[index]));
          }
        }
        case HALT, NOP, XOR_CONST, SWAP, SET_LOGGED, CHECKPOINT, COMMIT -> {
          // The verifier and operand access establish all remaining preconditions.
        }
      }
    } catch (ArithmeticException exception) {
      trap("Arithmetic overflow in " + instruction.opcode());
    }
  }

  private void undoData(StepRecord record) {
    Instruction instruction = record.instruction();
    switch (instruction.opcode()) {
      case ADD_CONST -> {
        int index = globalIndex(instruction, 0);
        globals[index] = Math.subtractExact(globals[index], operand(instruction, 1));
      }
      case SUB_CONST -> {
        int index = globalIndex(instruction, 0);
        globals[index] = Math.addExact(globals[index], operand(instruction, 1));
      }
      case XOR_CONST -> globals[globalIndex(instruction, 0)] ^= operand(instruction, 1);
      case SWAP -> {
        int left = globalIndex(instruction, 0);
        int right = globalIndex(instruction, 1);
        long value = globals[left];
        globals[left] = globals[right];
        globals[right] = value;
      }
      case SET_LOGGED -> globals[record.changedGlobal()] = record.previousValue();
      case NOP, HALT, RETURN, CALL, UNCALL, EXPECT_EQ, CHECKPOINT, COMMIT -> {
        // These instructions alter only control or status state.
      }
    }
  }

  private Instruction fetch(Frame frame) {
    List<Instruction> body = program.function(frame.functionId()).body(frame.inverse());
    if (frame.programCounter() >= body.size()) {
      trap("Instruction pointer escaped function body");
    }
    return body.get(frame.programCounter());
  }

  private Frame currentFrame() {
    if (frames.isEmpty()) {
      throw new IllegalStateException("Machine has no control frame");
    }
    return frames.getLast();
  }

  private void advanceCurrentFrame() {
    replaceCurrentFrame(currentFrame().advance());
  }

  private void replaceCurrentFrame(Frame frame) {
    frames.set(frames.size() - 1, frame);
  }

  private int globalIndex(Instruction instruction, int operandIndex) {
    return checkedGlobalIndex(Math.toIntExact(operand(instruction, operandIndex)));
  }

  private int checkedGlobalIndex(int index) {
    if (index < 0 || index >= globals.length) {
      throw new VmTrap("Invalid global index " + index);
    }
    return index;
  }

  private static long operand(Instruction instruction, int index) {
    return instruction.operands().get(index);
  }

  private void trap(String message) {
    status = MachineStatus.TRAPPED;
    throw new VmTrap(message);
  }
}
