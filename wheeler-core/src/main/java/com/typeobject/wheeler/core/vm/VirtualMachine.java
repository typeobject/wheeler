package com.typeobject.wheeler.core.vm;

import com.typeobject.wheeler.core.bytecode.BytecodeVerifier;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.RecordType;
import com.typeobject.wheeler.core.bytecode.ValueType;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Deque;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/** Deterministic single-threaded Wheeler transition kernel. */
public final class VirtualMachine {
  public static final int MAX_CALL_DEPTH = 1024;

  private final Program program;
  private final long[] globals;
  private final List<Frame> frames = new ArrayList<>();
  private final AggregateStore aggregates = new AggregateStore();
  private final OwnedStore owned = new OwnedStore();
  private final long hostOutputHandle;
  private final TransitionObserver observer;
  private final Deque<StepRecord> history = new ArrayDeque<>();
  private MachineStatus status = MachineStatus.READY;
  private int hostOutputLength;
  private long sequence;

  public VirtualMachine(Program program) {
    this(program, null, -1, false, TransitionObserver.NONE);
  }

  public VirtualMachine(Program program, TransitionObserver observer) {
    this(program, null, -1, false, observer);
  }

  public VirtualMachine(Program program, byte[] utf8Input) {
    this(program, utf8Input, -1, false, TransitionObserver.NONE);
  }

  public VirtualMachine(Program program, byte[] utf8Input, int outputBytes) {
    this(program, utf8Input, outputBytes, false, TransitionObserver.NONE);
  }

  public static VirtualMachine withBinaryInput(Program program, byte[] input) {
    return new VirtualMachine(program, input, -1, true, TransitionObserver.NONE);
  }

  public static VirtualMachine withBinaryInput(
      Program program, byte[] input, int outputBytes) {
    return new VirtualMachine(program, input, outputBytes, true, TransitionObserver.NONE);
  }

  public static VirtualMachine withBinaryInput(
      Program program, byte[] input, int outputBytes, TransitionObserver observer) {
    return new VirtualMachine(program, input, outputBytes, true, observer);
  }

  private VirtualMachine(
      Program program,
      byte[] hostInput,
      int outputBytes,
      boolean binaryInput,
      TransitionObserver observer) {
    BytecodeVerifier.verify(program);
    this.program = program;
    this.observer = Objects.requireNonNull(observer, "observer");
    this.globals = program.globals().stream().mapToLong(global -> global.initialValue()).toArray();
    FunctionBody entry = program.function(program.entryFunctionId());
    HostEffectBinder.Effects effects =
        HostEffectBinder.bind(entry, owned, hostInput, binaryInput, outputBytes);
    hostOutputHandle = effects.outputHandle();
    hostOutputLength = Math.max(0, outputBytes);
    this.frames.add(Frame.create(
        entry.id(), false, entry.localCount(), -1, effects.arguments()));
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
    observer.observe(TransitionObserver.execution(sequence, frame, instruction));
  }

  public void rewindOne() {
    StepRecord record = history.pollFirst();
    if (record == null) {
      throw new VmTrap("No reversible history is available");
    }
    undoData(record);
    aggregates.rewind(new AggregateStore.Counts(
        record.previousRecordCount(),
        record.previousVariantCount(),
        record.previousArrayCount(),
        record.previousSliceCount()));
    owned.rewind(new OwnedStore.Change(
        record.previousRegionCount(),
        record.previousBufferCount(),
        record.changedRegion(),
        record.previousRegion(),
        record.changedBuffer(),
        record.previousBuffer()));
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
    hostOutputLength = record.previousHostOutputLength();
    status = record.previousStatus();
    sequence = record.sequence();
    observer.observe(TransitionObserver.rewind(record));
  }

  public byte[] hostOutput() {
    return hostOutputHandle == 0
        ? new byte[0]
        : Arrays.copyOf(owned.hostBytes(hostOutputHandle), hostOutputLength);
  }

  public long global(String name) {
    return globals[program.globalIndex(name)];
  }

  public long global(int index) {
    return globals[VmControlChecks.globalIndex(globals.length, index)];
  }

  /** Executes one function from a hybrid workflow boundary. WIP-0004 records this boundary. */
  public void invoke(int functionId, boolean inverse) {
    if (status == MachineStatus.HALTED || status == MachineStatus.TRAPPED) {
      throw new VmTrap("Cannot invoke a function on a finished machine");
    }
    FunctionBody function = program.function(functionId);
    if (function.parameterCount() != 0 || function.returnsValue()) {
      throw new VmTrap("Workflow invocation requires a void zero-argument function: " + function.name());
    }
    if (inverse && !function.reversible()) {
      throw new VmTrap("Function has no inverse: " + function.name());
    }
    history.clear();
    int callerDepth = frames.size();
    frames.add(Frame.create(functionId, inverse, function.localCount()));
    while (frames.size() > callerDepth) {
      step();
    }
    history.clear();
  }

  /** Applies a measured or external value and establishes an irreversible workflow boundary. */
  public void setGlobalFromEffect(int index, long value) {
    globals[VmControlChecks.globalIndex(globals.length, index)] = value;
    history.clear();
  }

  /** Restores a typed workflow checkpoint; this does not claim to reverse external effects. */
  public void restoreEffectCheckpoint(Map<String, Long> checkpoint) {
    if (checkpoint.size() != globals.length) {
      throw new VmTrap("Checkpoint global schema mismatch");
    }
    for (int i = 0; i < globals.length; i++) {
      String name = program.globals().get(i).name();
      Long value = checkpoint.get(name);
      if (value == null) {
        throw new VmTrap("Checkpoint is missing global " + name);
      }
      globals[i] = value;
    }
    history.clear();
  }

  public void expectGlobal(int index, long expected) {
    long actual = globals[VmControlChecks.globalIndex(globals.length, index)];
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
        status,
        List.copyOf(frames),
        Map.copyOf(values),
        aggregates.records(),
        aggregates.variants(),
        aggregates.arrays(),
        aggregates.slices(),
        owned.regions(),
        owned.buffers(),
        hostOutputLength,
        history.size(),
        sequence);
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
    int changedLocal = StepRecord.NO_LOCAL;
    long previousLocalValue = 0;
    StepRecord.ControlChange control = StepRecord.ControlChange.ADVANCE;
    AggregateStore.Counts previousCounts = aggregates.counts();
    OwnedStore.Change ownedChange = owned.mark();
    int previousHostOutputLength = hostOutputLength;

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
      case LOCAL_CONST -> setLocalAndAdvance(
          localIndex(instruction, 0), operand(instruction, 1));
      case LOCAL_LOAD_GLOBAL -> setLocalAndAdvance(
          localIndex(instruction, 0), globals[globalIndex(instruction, 1)]);
      case LOCAL_STORE_GLOBAL -> {
        changedGlobal = globalIndex(instruction, 0);
        previousValue = globals[changedGlobal];
        globals[changedGlobal] = localValue(instruction, 1);
        advanceCurrentFrame();
      }
      case LOCAL_MOVE -> setLocalAndAdvance(
          localIndex(instruction, 0), localValue(instruction, 1));
      case OWNED_MOVE -> {
        int destination = localIndex(instruction, 0);
        int source = localIndex(instruction, 1);
        long value = currentFrame().local(source);
        replaceCurrentFrame(
            currentFrame().withLocal(source, 0).withLocal(destination, value).advance());
      }
      case LOCAL_ADD -> setLocalAndAdvance(
          localIndex(instruction, 0),
          Math.addExact(localValue(instruction, 1), localValue(instruction, 2)));
      case LOCAL_SUB -> setLocalAndAdvance(
          localIndex(instruction, 0),
          Math.subtractExact(localValue(instruction, 1), localValue(instruction, 2)));
      case LOCAL_MUL -> setLocalAndAdvance(
          localIndex(instruction, 0),
          Math.multiplyExact(localValue(instruction, 1), localValue(instruction, 2)));
      case LOCAL_DIV -> setLocalAndAdvance(
          localIndex(instruction, 0),
          localValue(instruction, 1) / localValue(instruction, 2));
      case LOCAL_MOD -> setLocalAndAdvance(
          localIndex(instruction, 0),
          localValue(instruction, 1) % localValue(instruction, 2));
      case LOCAL_AND -> setLocalAndAdvance(
          localIndex(instruction, 0), localValue(instruction, 1) & localValue(instruction, 2));
      case LOCAL_ROTR32 -> setLocalAndAdvance(
          localIndex(instruction, 0),
          Integer.toUnsignedLong(Integer.rotateRight(
              (int) localValue(instruction, 1), Math.toIntExact(localValue(instruction, 2)))));
      case LOCAL_XOR -> setLocalAndAdvance(
          localIndex(instruction, 0), localValue(instruction, 1) ^ localValue(instruction, 2));
      case LOCAL_EQ -> setLocalAndAdvance(
          localIndex(instruction, 0),
          localValue(instruction, 1) == localValue(instruction, 2) ? 1 : 0);
      case LOCAL_LT -> setLocalAndAdvance(
          localIndex(instruction, 0),
          localValue(instruction, 1) < localValue(instruction, 2) ? 1 : 0);
      case JUMP -> jumpCurrentFrame(Math.toIntExact(operand(instruction, 0)));
      case JUMP_IF_ZERO -> {
        if (localValue(instruction, 0) == 0) {
          jumpCurrentFrame(Math.toIntExact(operand(instruction, 1)));
        } else {
          advanceCurrentFrame();
        }
      }
      case LOCAL_LOOP_CHECK -> setLocalAndAdvance(
          localIndex(instruction, 0), Math.addExact(localValue(instruction, 0), 1));
      case RECORD_NEW -> {
        int destination = localIndex(instruction, 0);
        int typeId = Math.toIntExact(operand(instruction, 1));
        int base = Math.toIntExact(operand(instruction, 2));
        int count = Math.toIntExact(operand(instruction, 3));
        List<Long> fields = new ArrayList<>(count);
        for (int field = 0; field < count; field++) {
          fields.add(currentFrame().local(base + field));
        }
        RecordValue value = new RecordValue(typeId, fields);
        setLocalAndAdvance(destination, aggregates.intern(value));
      }
      case RECORD_GET -> {
        int destination = localIndex(instruction, 0);
        RecordValue value = recordValue(localValue(instruction, 1));
        int field = Math.toIntExact(operand(instruction, 2));
        setLocalAndAdvance(destination, value.fields().get(field));
      }
      case VARIANT_NEW -> {
        int destination = localIndex(instruction, 0);
        int typeId = Math.toIntExact(operand(instruction, 1));
        int tag = Math.toIntExact(operand(instruction, 2));
        int base = Math.toIntExact(operand(instruction, 3));
        int count = Math.toIntExact(operand(instruction, 4));
        List<Long> fields = new ArrayList<>(count);
        for (int field = 0; field < count; field++) {
          fields.add(currentFrame().local(base + field));
        }
        VariantValue value = new VariantValue(typeId, tag, fields);
        setLocalAndAdvance(destination, aggregates.intern(value));
      }
      case VARIANT_TAG_EQ -> {
        VariantValue value = variantValue(localValue(instruction, 1));
        setLocalAndAdvance(
            localIndex(instruction, 0), value.tag() == operand(instruction, 2) ? 1 : 0);
      }
      case VARIANT_GET -> {
        VariantValue value = variantValue(localValue(instruction, 1));
        int expectedTag = Math.toIntExact(operand(instruction, 2));
        if (value.tag() != expectedTag) {
          throw new VmTrap("Variant payload tag mismatch");
        }
        setLocalAndAdvance(
            localIndex(instruction, 0),
            value.fields().get(Math.toIntExact(operand(instruction, 3))));
      }
      case ARRAY_NEW -> {
        int destination = localIndex(instruction, 0);
        int typeId = Math.toIntExact(operand(instruction, 1));
        int base = Math.toIntExact(operand(instruction, 2));
        int count = Math.toIntExact(operand(instruction, 3));
        List<Long> elements = new ArrayList<>(count);
        for (int element = 0; element < count; element++) {
          elements.add(currentFrame().local(base + element));
        }
        ArrayValue value = new ArrayValue(typeId, elements);
        setLocalAndAdvance(destination, aggregates.intern(value));
      }
      case ARRAY_GET -> {
        ArrayValue value = arrayValue(localValue(instruction, 1));
        int index = Math.toIntExact(localValue(instruction, 2));
        setLocalAndAdvance(localIndex(instruction, 0), value.elements().get(index));
      }
      case SLICE_NEW -> {
        int destination = localIndex(instruction, 0);
        int typeId = Math.toIntExact(operand(instruction, 1));
        long arrayHandle = localValue(instruction, 2);
        int start = Math.toIntExact(localValue(instruction, 3));
        int length = Math.toIntExact(localValue(instruction, 4));
        SliceValue value = new SliceValue(typeId, arrayHandle, start, length);
        setLocalAndAdvance(destination, aggregates.intern(value));
      }
      case SLICE_GET -> {
        SliceValue slice = sliceValue(localValue(instruction, 1));
        ArrayValue array = arrayValue(slice.arrayHandle());
        int index = Math.toIntExact(localValue(instruction, 2));
        setLocalAndAdvance(
            localIndex(instruction, 0), array.elements().get(slice.start() + index));
      }
      case REGION_NEW -> {
        OwnedStore.Allocation allocation = owned.createRegion(
            operand(instruction, 1), Math.toIntExact(operand(instruction, 2)), ownedChange);
        ownedChange = allocation.change();
        setLocalAndAdvance(localIndex(instruction, 0), allocation.handle());
      }
      case WORDS_ALLOC, BYTES_ALLOC -> {
        BufferKind kind = opcode == Opcode.WORDS_ALLOC
            ? BufferKind.WORDS : BufferKind.BYTES;
        OwnedStore.Allocation allocation = owned.allocate(
            localValue(instruction, 1),
            Math.toIntExact(localValue(instruction, 2)),
            kind,
            ownedChange);
        ownedChange = allocation.change();
        setLocalAndAdvance(localIndex(instruction, 0), allocation.handle());
      }
      case WORDS_GET, BYTES_GET -> {
        BufferKind kind = opcode == Opcode.WORDS_GET
            ? BufferKind.WORDS : BufferKind.BYTES;
        setLocalAndAdvance(
            localIndex(instruction, 0),
            owned.get(
                localValue(instruction, 1),
                Math.toIntExact(localValue(instruction, 2)),
                kind));
      }
      case WORDS_SET, BYTES_SET -> {
        BufferKind kind = opcode == Opcode.WORDS_SET
            ? BufferKind.WORDS : BufferKind.BYTES;
        ownedChange = owned.set(
            localValue(instruction, 0),
            Math.toIntExact(localValue(instruction, 1)),
            localValue(instruction, 2),
            kind,
            ownedChange);
        advanceCurrentFrame();
      }
      case UTF8_VALID -> setLocalAndAdvance(
          localIndex(instruction, 0),
          Utf8.analyze(owned.utf8Bytes(localValue(instruction, 1))).valid() ? 1 : 0);
      case UTF8_COUNT -> setLocalAndAdvance(
          localIndex(instruction, 0),
          Utf8.analyze(owned.utf8Bytes(localValue(instruction, 1))).scalarCount());
      case BUFFER_LENGTH -> setLocalAndAdvance(
          localIndex(instruction, 0), owned.length(localValue(instruction, 1)));
      case UTF8_SCALAR, UTF8_WIDTH -> {
        Utf8.Scalar scalar = VmControlChecks.utf8Scalar(owned, currentFrame(), instruction);
        setLocalAndAdvance(
            localIndex(instruction, 0),
            opcode == Opcode.UTF8_SCALAR ? scalar.value() : scalar.width());
      }
      case UTF8_BORROW, MAP_BORROW, BUFFER_BORROW, REGION_BORROW -> setLocalAndAdvance(
          localIndex(instruction, 0), localValue(instruction, 1));
      case UTF8_FREEZE -> {
        int destination = localIndex(instruction, 0);
        int source = localIndex(instruction, 1);
        long handle = currentFrame().local(source);
        ownedChange = owned.freezeUtf8(handle, ownedChange);
        replaceCurrentFrame(
            currentFrame().withLocal(source, 0).withLocal(destination, handle).advance());
      }
      case MAP_ALLOC -> {
        OwnedStore.Allocation allocation = owned.allocate(
            localValue(instruction, 1),
            Math.toIntExact(localValue(instruction, 2)),
            BufferKind.LONG_MAP,
            ownedChange);
        ownedChange = allocation.change();
        setLocalAndAdvance(localIndex(instruction, 0), allocation.handle());
      }
      case MAP_PUT -> {
        ownedChange = owned.mapPut(
            localValue(instruction, 0),
            localValue(instruction, 1),
            localValue(instruction, 2),
            ownedChange);
        advanceCurrentFrame();
      }
      case MAP_GET -> setLocalAndAdvance(
          localIndex(instruction, 0),
          owned.mapGet(localValue(instruction, 1), localValue(instruction, 2)));
      case MAP_HAS -> setLocalAndAdvance(
          localIndex(instruction, 0),
          owned.mapHas(localValue(instruction, 1), localValue(instruction, 2)) ? 1 : 0);
      case BUFFER_DROP -> {
        int local = localIndex(instruction, 0);
        ownedChange = owned.dropBuffer(currentFrame().local(local), ownedChange);
        setLocalAndAdvance(local, 0);
      }
      case REGION_DROP -> {
        int local = localIndex(instruction, 0);
        ownedChange = owned.dropRegion(currentFrame().local(local), ownedChange);
        setLocalAndAdvance(local, 0);
      }
      case OUTPUT_LENGTH -> {
        hostOutputLength = Math.toIntExact(localValue(instruction, 1));
        advanceCurrentFrame();
      }
      case CALL, UNCALL -> {
        int functionId = Math.toIntExact(operand(instruction, 0));
        advanceCurrentFrame();
        FunctionBody target = program.function(functionId);
        frames.add(Frame.create(functionId, opcode == Opcode.UNCALL, target.localCount()));
        control = StepRecord.ControlChange.CALL;
      }
      case CALL_VALUE, CALL_VOID -> {
        ArgumentCallBinder.Binding binding = ArgumentCallBinder.bind(
            program, currentFrame(), instruction, opcode == Opcode.CALL_VALUE);
        replaceCurrentFrame(binding.caller());
        frames.add(binding.callee());
        control = StepRecord.ControlChange.CALL;
      }
      case RETURN -> {
        frames.removeLast();
        control = StepRecord.ControlChange.RETURN;
      }
      case RETURN_VALUE -> {
        long result = localValue(instruction, 0);
        int destination = frame.returnDestination();
        frames.removeLast();
        changedLocal = destination;
        previousLocalValue = currentFrame().local(destination);
        replaceCurrentFrame(currentFrame().withLocal(destination, result));
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
        previousValue,
        changedLocal,
        previousLocalValue,
        previousCounts.records(),
        previousCounts.variants(),
        previousCounts.arrays(),
        previousCounts.slices(),
        ownedChange.previousRegionCount(),
        ownedChange.previousBufferCount(),
        ownedChange.changedRegion(),
        ownedChange.previousRegion(),
        ownedChange.changedBuffer(),
        ownedChange.previousBuffer(),
        previousHostOutputLength);
  }

  private void validateBeforeMutation(Instruction instruction) {
    try {
      if (OwnedInstructionValidator.handles(instruction.opcode())) {
        OwnedInstructionValidator.validate(instruction, currentFrame(), owned);
        return;
      }
      switch (instruction.opcode()) {
        case ADD_CONST -> Math.addExact(
            globals[globalIndex(instruction, 0)], operand(instruction, 1));
        case SUB_CONST -> Math.subtractExact(
            globals[globalIndex(instruction, 0)], operand(instruction, 1));
        case LOCAL_ADD -> {
          localIndex(instruction, 0);
          Math.addExact(localValue(instruction, 1), localValue(instruction, 2));
        }
        case LOCAL_SUB -> {
          localIndex(instruction, 0);
          Math.subtractExact(localValue(instruction, 1), localValue(instruction, 2));
        }
        case LOCAL_MUL -> {
          localIndex(instruction, 0);
          Math.multiplyExact(localValue(instruction, 1), localValue(instruction, 2));
        }
        case LOCAL_DIV, LOCAL_MOD -> {
          localIndex(instruction, 0);
          long dividend = localValue(instruction, 1);
          long divisor = localValue(instruction, 2);
          if (divisor == 0) {
            trap("Division by zero");
          }
          if (instruction.opcode() == Opcode.LOCAL_DIV
              && dividend == Long.MIN_VALUE && divisor == -1) {
            trap("Arithmetic overflow in LOCAL_DIV");
          }
        }
        case LOCAL_CONST -> localIndex(instruction, 0);
        case LOCAL_LOAD_GLOBAL -> {
          localIndex(instruction, 0);
          globalIndex(instruction, 1);
        }
        case LOCAL_STORE_GLOBAL -> {
          globalIndex(instruction, 0);
          localIndex(instruction, 1);
        }
        case LOCAL_MOVE, OWNED_MOVE -> {
          localIndex(instruction, 0);
          localIndex(instruction, 1);
        }
        case LOCAL_AND, LOCAL_XOR, LOCAL_EQ, LOCAL_LT -> {
          localIndex(instruction, 0);
          localIndex(instruction, 1);
          localIndex(instruction, 2);
        }
        case LOCAL_ROTR32 -> {
          localIndex(instruction, 0);
          localIndex(instruction, 1);
          long amount = localValue(instruction, 2);
          if (amount < 0 || amount > 31) {
            trap("32-bit rotate amount must be between 0 and 31");
          }
        }
        case JUMP -> VmControlChecks.jumpTarget(program, currentFrame(), instruction, 0);
        case JUMP_IF_ZERO -> {
          localIndex(instruction, 0);
          VmControlChecks.jumpTarget(program, currentFrame(), instruction, 1);
        }
        case LOCAL_LOOP_CHECK -> {
          long iteration = localValue(instruction, 0);
          long limit = localValue(instruction, 1);
          if (iteration < 0 || limit < 0 || iteration >= limit) {
            trap("Loop iteration limit exceeded");
          }
          Math.addExact(iteration, 1);
        }
        case RECORD_NEW -> {
          localIndex(instruction, 0);
          RecordType type = program.recordType(Math.toIntExact(operand(instruction, 1)));
          int base = Math.toIntExact(operand(instruction, 2));
          int count = Math.toIntExact(operand(instruction, 3));
          List<Long> fields = new ArrayList<>(count);
          for (int field = 0; field < count; field++) {
            long value = currentFrame().local(base + field);
            fields.add(value);
            ValueType fieldType = type.fields().get(field).type();
            if (fieldType.kind() == ValueType.Kind.RECORD
                && recordValue(value).typeId() != fieldType.descriptorId()) {
              trap("Nested record type mismatch");
            }
          }
          if (aggregates.fullForNew(new RecordValue(type.id(), fields))) {
            trap("Record value limit exceeded");
          }
        }
        case RECORD_GET -> {
          localIndex(instruction, 0);
          RecordValue value = recordValue(localValue(instruction, 1));
          int field = Math.toIntExact(operand(instruction, 2));
          if (field < 0 || field >= value.fields().size()) {
            trap("Record field index out of range");
          }
        }
        case VARIANT_NEW -> {
          localIndex(instruction, 0);
          var type = program.variantType(Math.toIntExact(operand(instruction, 1)));
          int tag = Math.toIntExact(operand(instruction, 2));
          int base = Math.toIntExact(operand(instruction, 3));
          int count = Math.toIntExact(operand(instruction, 4));
          var variantCase = type.cases().get(tag);
          List<Long> fields = new ArrayList<>(count);
          for (int field = 0; field < count; field++) {
            long value = currentFrame().local(base + field);
            validateAggregateValue(variantCase.fields().get(field).type(), value);
            fields.add(value);
          }
          if (aggregates.fullForNew(new VariantValue(type.id(), tag, fields))) {
            trap("Variant value limit exceeded");
          }
        }
        case VARIANT_TAG_EQ -> {
          localIndex(instruction, 0);
          VariantValue value = checkedVariantSource(instruction, 1);
          if (operand(instruction, 2) < 0
              || operand(instruction, 2) >= program.variantType(value.typeId()).cases().size()) {
            trap("Variant tag out of range");
          }
        }
        case VARIANT_GET -> {
          localIndex(instruction, 0);
          VariantValue value = checkedVariantSource(instruction, 1);
          int tag = Math.toIntExact(operand(instruction, 2));
          int field = Math.toIntExact(operand(instruction, 3));
          if (value.tag() != tag || field < 0 || field >= value.fields().size()) {
            trap("Variant payload access mismatch");
          }
        }
        case ARRAY_NEW -> {
          localIndex(instruction, 0);
          var type = program.arrayType(Math.toIntExact(operand(instruction, 1)));
          int base = Math.toIntExact(operand(instruction, 2));
          int count = Math.toIntExact(operand(instruction, 3));
          List<Long> elements = new ArrayList<>(count);
          for (int element = 0; element < count; element++) {
            long value = currentFrame().local(base + element);
            validateAggregateValue(type.elementType(), value);
            elements.add(value);
          }
          if (aggregates.fullForNew(new ArrayValue(type.id(), elements))) {
            trap("Array value limit exceeded");
          }
        }
        case ARRAY_GET -> {
          localIndex(instruction, 0);
          ArrayValue value = checkedArraySource(instruction, 1);
          long index = localValue(instruction, 2);
          if (index < 0 || index >= value.elements().size()) {
            trap("Array index out of bounds: " + index);
          }
        }
        case SLICE_NEW -> {
          localIndex(instruction, 0);
          ArrayValue array = checkedArraySource(instruction, 2);
          long start = localValue(instruction, 3);
          long length = localValue(instruction, 4);
          long end = Math.addExact(start, length);
          if (start < 0 || length < 0 || end > array.elements().size()) {
            trap("Slice range is outside its array");
          }
          SliceValue value = new SliceValue(
              Math.toIntExact(operand(instruction, 1)),
              localValue(instruction, 2),
              Math.toIntExact(start),
              Math.toIntExact(length));
          if (aggregates.fullForNew(value)) {
            trap("Slice value limit exceeded");
          }
        }
        case SLICE_GET -> {
          localIndex(instruction, 0);
          SliceValue value = checkedSliceSource(instruction, 1);
          long index = localValue(instruction, 2);
          if (index < 0 || index >= value.length()) {
            trap("Slice index out of bounds: " + index);
          }
        }
        case OUTPUT_LENGTH -> {
          long handle = localValue(instruction, 0);
          long length = localValue(instruction, 1);
          if (handle != hostOutputHandle || length < 0 || length > owned.length(handle)) {
            trap("Invalid host output length: " + length);
          }
        }
        case CALL -> {
          requireCallCapacity();
          program.function(Math.toIntExact(operand(instruction, 0)));
        }
        case CALL_VALUE, CALL_VOID -> {
          requireCallCapacity();
          FunctionBody target = program.function(Math.toIntExact(operand(instruction, 0)));
          int base = Math.toIntExact(operand(instruction, 1));
          int count = Math.toIntExact(operand(instruction, 2));
          boolean returnsValue = instruction.opcode() == Opcode.CALL_VALUE;
          if (returnsValue) {
            localIndex(instruction, 3);
          }
          if (target.returnsValue() != returnsValue || target.parameterCount() != count
              || base < 0 || count < 0 || base > currentFrame().localCount() - count) {
            trap("Argument call signature mismatch for " + target.name());
          }
        }
        case UNCALL -> {
          requireCallCapacity();
          FunctionBody function = program.function(Math.toIntExact(operand(instruction, 0)));
          if (!function.reversible()) {
            trap("Function has no inverse: " + function.name());
          }
        }
        case RETURN -> {
          if (frames.size() <= 1 || currentFrame().returnDestination() != -1) {
            trap("Invalid void return");
          }
        }
        case RETURN_VALUE -> {
          localIndex(instruction, 0);
          if (frames.size() <= 1 || currentFrame().returnDestination() < 0) {
            trap("Invalid value return");
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
      case SET_LOGGED, LOCAL_STORE_GLOBAL ->
          globals[record.changedGlobal()] = record.previousValue();
      case NOP, HALT, RETURN, RETURN_VALUE, CALL, UNCALL, CALL_VALUE, CALL_VOID,
          OUTPUT_LENGTH,
          EXPECT_EQ, CHECKPOINT, COMMIT,
          LOCAL_CONST, LOCAL_LOAD_GLOBAL, LOCAL_MOVE, LOCAL_ADD, LOCAL_SUB,
          LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND, LOCAL_ROTR32, LOCAL_XOR, LOCAL_EQ, LOCAL_LT,
          JUMP, JUMP_IF_ZERO, LOCAL_LOOP_CHECK,
          RECORD_NEW, RECORD_GET -> {
        // These instructions alter only control or status state.
      }
    }
    if (record.changedLocal() != StepRecord.NO_LOCAL) {
      replaceCurrentFrame(
          currentFrame().withLocal(record.changedLocal(), record.previousLocalValue()));
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

  private void setLocalAndAdvance(int index, long value) {
    replaceCurrentFrame(currentFrame().withLocal(index, value).advance());
  }

  private void jumpCurrentFrame(int target) {
    replaceCurrentFrame(currentFrame().jump(target));
  }

  private void replaceCurrentFrame(Frame frame) {
    frames.set(frames.size() - 1, frame);
  }

  private int globalIndex(Instruction instruction, int operandIndex) {
    return VmControlChecks.globalIndex(
        globals.length, Math.toIntExact(operand(instruction, operandIndex)));
  }

  private int localIndex(Instruction instruction, int operandIndex) {
    int index = Math.toIntExact(operand(instruction, operandIndex));
    if (index < 0 || index >= currentFrame().localCount()) {
      throw new VmTrap("Invalid local index " + index);
    }
    return index;
  }

  private long localValue(Instruction instruction, int operandIndex) {
    return currentFrame().local(localIndex(instruction, operandIndex));
  }

  private RecordValue recordValue(long handle) {
    return aggregates.record(handle);
  }

  private VariantValue variantValue(long handle) {
    return aggregates.variant(handle);
  }

  private VariantValue checkedVariantSource(Instruction instruction, int operandIndex) {
    int source = localIndex(instruction, operandIndex);
    VariantValue value = variantValue(currentFrame().local(source));
    ValueType type = program.function(currentFrame().functionId()).localType(source);
    if (type.kind() != ValueType.Kind.VARIANT || value.typeId() != type.descriptorId()) {
      trap("Variant handle type mismatch");
    }
    return value;
  }

  private void validateAggregateValue(ValueType type, long value) {
    if (type.kind() == ValueType.Kind.RECORD
        && recordValue(value).typeId() != type.descriptorId()) {
      trap("Nested record type mismatch");
    }
    if (type.kind() == ValueType.Kind.VARIANT
        && variantValue(value).typeId() != type.descriptorId()) {
      trap("Nested variant type mismatch");
    }
    if (type.kind() == ValueType.Kind.ARRAY
        && arrayValue(value).typeId() != type.descriptorId()) {
      trap("Nested array type mismatch");
    }
  }

  private ArrayValue arrayValue(long handle) {
    return aggregates.array(handle);
  }

  private ArrayValue checkedArraySource(Instruction instruction, int operandIndex) {
    int source = localIndex(instruction, operandIndex);
    ArrayValue value = arrayValue(currentFrame().local(source));
    ValueType type = program.function(currentFrame().functionId()).localType(source);
    if (type.kind() != ValueType.Kind.ARRAY || value.typeId() != type.descriptorId()) {
      trap("Array handle type mismatch");
    }
    return value;
  }

  private SliceValue sliceValue(long handle) {
    return aggregates.slice(handle);
  }

  private SliceValue checkedSliceSource(Instruction instruction, int operandIndex) {
    int source = localIndex(instruction, operandIndex);
    SliceValue value = sliceValue(currentFrame().local(source));
    ValueType type = program.function(currentFrame().functionId()).localType(source);
    if (type.kind() != ValueType.Kind.SLICE || value.typeId() != type.descriptorId()) {
      trap("Slice handle type mismatch");
    }
    return value;
  }

  private void requireCallCapacity() {
    if (frames.size() >= MAX_CALL_DEPTH) {
      trap("Call depth limit exceeded");
    }
  }

  private static long operand(Instruction instruction, int index) {
    return instruction.operands().get(index);
  }

  private void trap(String message) {
    status = MachineStatus.TRAPPED;
    throw new VmTrap(message);
  }
}
