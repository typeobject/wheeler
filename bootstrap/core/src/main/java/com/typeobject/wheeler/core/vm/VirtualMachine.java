package com.typeobject.wheeler.core.vm;

import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ALLOCATION_LIMIT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_BASE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_COUNT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.CAPACITY;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.CONDITION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.DESCRIPTOR;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.DESTINATION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ELEMENT_BASE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ELEMENT_COUNT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.FUNCTION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.GLOBAL;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.IMMEDIATE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.INDEX;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ITERATION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.KEY;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LEFT_GLOBAL;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LEFT_SOURCE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LENGTH;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LIMIT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LOCAL;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.OWNER;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RESULT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RIGHT_GLOBAL;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RIGHT_SOURCE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.SOURCE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.START;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.TAG;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.TARGET;

import com.typeobject.wheeler.core.bytecode.BytecodeVerifier;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.InstructionExtensions;
import com.typeobject.wheeler.core.bytecode.InstructionForm;
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
  private final TaskTable tasks;
  private final TaskScheduler scheduler = new TaskScheduler();
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
    InstructionExtensions.requireSupported(program);
    this.program = program;
    this.observer = Objects.requireNonNull(observer, "observer");
    this.globals = program.globals().stream().mapToLong(global -> global.initialValue()).toArray();
    FunctionBody entry = program.function(program.entryFunctionId());
    HostEffectBinder.Effects effects =
        HostEffectBinder.bind(entry, owned, hostInput, binaryInput, outputBytes);
    hostOutputHandle = effects.outputHandle();
    hostOutputLength = Math.max(0, outputBytes);
    this.tasks = new TaskTable(Frame.create(
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
    TaskId previousSelectedTask = tasks.selected();
    TaskId previousSchedulerCursor = scheduler.cursor();
    TaskId selectedTask = scheduler.next(tasks.runnableTaskIds());
    tasks.select(selectedTask);
    TaskStatus previousTaskStatus = tasks.selectedStatus();
    Frame frame;
    Instruction instruction;
    try {
      frame = currentFrame();
      instruction = fetch(frame);
      validateBeforeMutation(instruction);
      if (instruction.opcode() != Opcode.COMMIT
          && history.size() >= program.maxHistoryRecords()) {
        trap("History record limit exceeded");
      }
    } catch (RuntimeException exception) {
      tasks.select(previousSelectedTask);
      throw exception;
    }
    scheduler.commit(selectedTask);
    tasks.setSelectedStatus(TaskStatus.RUNNING);

    MachineStatus previousStatus = status;
    status = MachineStatus.RUNNING;
    StepRecord record = execute(
        frame,
        instruction,
        previousStatus,
        previousSelectedTask,
        previousSchedulerCursor,
        previousTaskStatus);
    sequence = Math.addExact(sequence, 1);
    if (instruction.opcode() == Opcode.COMMIT) {
      history.clear();
    } else {
      history.push(record);
    }
    tasks.setSelectedStatus(
        status == MachineStatus.HALTED ? TaskStatus.COMPLETED : TaskStatus.RUNNABLE);
    observer.observe(
        TransitionObserver.execution(sequence, tasks.selected(), frame, instruction));
  }

  public void rewindOne() {
    StepRecord record = history.pollFirst();
    if (record == null) {
      throw new VmTrap("No reversible history is available");
    }
    tasks.select(record.eventId().taskId());
    replaceCurrentFrame(VmDataRewinder.undo(record, globals, currentFrame()));
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
        if (tasks.frameDepth() < 2) {
          throw new IllegalStateException("Corrupt CALL undo state");
        }
        tasks.removeLastFrame();
        replaceCurrentFrame(record.previousFrame());
      }
      case RETURN -> tasks.addFrame(record.previousFrame());
    }
    hostOutputLength = record.previousHostOutputLength();
    tasks.setSelectedStatus(record.previousTaskStatus());
    tasks.select(record.previousSelectedTask());
    scheduler.restore(record.previousSchedulerCursor());
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
      throw new VmTrap(
          "Workflow invocation requires a void zero-argument function: " + function.name());
    }
    if (inverse && !function.reversible()) {
      throw new VmTrap("Function has no inverse: " + function.name());
    }
    history.clear();
    int callerDepth = tasks.frameDepth();
    tasks.addFrame(Frame.create(functionId, inverse, function.localCount()));
    while (tasks.frameDepth() > callerDepth) {
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
        tasks.selected(),
        scheduler.cursor(),
        0,
        status,
        tasks.snapshotStatuses(),
        tasks.snapshotFrames(),
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
      Frame frame,
      Instruction instruction,
      MachineStatus previousStatus,
      TaskId previousSelectedTask,
      TaskId previousSchedulerCursor,
      TaskStatus previousTaskStatus) {
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
        int index = globalIndex(instruction, GLOBAL);
        globals[index] = Math.addExact(globals[index], instruction.operand(IMMEDIATE));
        advanceCurrentFrame();
      }
      case SUB_CONST -> {
        int index = globalIndex(instruction, GLOBAL);
        globals[index] = Math.subtractExact(globals[index], instruction.operand(IMMEDIATE));
        advanceCurrentFrame();
      }
      case XOR_CONST -> {
        int index = globalIndex(instruction, GLOBAL);
        globals[index] ^= instruction.operand(IMMEDIATE);
        advanceCurrentFrame();
      }
      case SWAP -> {
        int left = globalIndex(instruction, LEFT_GLOBAL);
        int right = globalIndex(instruction, RIGHT_GLOBAL);
        long value = globals[left];
        globals[left] = globals[right];
        globals[right] = value;
        advanceCurrentFrame();
      }
      case SET_LOGGED -> {
        changedGlobal = globalIndex(instruction, GLOBAL);
        previousValue = globals[changedGlobal];
        globals[changedGlobal] = instruction.operand(IMMEDIATE);
        advanceCurrentFrame();
      }
      case LOCAL_CONST -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION), instruction.operand(IMMEDIATE));
      case LOCAL_LOAD_GLOBAL -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION), globals[globalIndex(instruction, GLOBAL)]);
      case LOCAL_STORE_GLOBAL -> {
        changedGlobal = globalIndex(instruction, GLOBAL);
        previousValue = globals[changedGlobal];
        globals[changedGlobal] = localValue(instruction, SOURCE);
        advanceCurrentFrame();
      }
      case LOCAL_MOVE -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION), localValue(instruction, SOURCE));
      case OWNED_MOVE -> {
        int destination = localIndex(instruction, DESTINATION);
        int source = localIndex(instruction, SOURCE);
        long value = currentFrame().local(source);
        replaceCurrentFrame(
            currentFrame().withLocal(source, 0).withLocal(destination, value).advance());
      }
      case LOCAL_ADD -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION),
          Math.addExact(
              localValue(instruction, LEFT_SOURCE),
              localValue(instruction, RIGHT_SOURCE)));
      case LOCAL_SUB -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION),
          Math.subtractExact(
              localValue(instruction, LEFT_SOURCE),
              localValue(instruction, RIGHT_SOURCE)));
      case LOCAL_MUL -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION),
          Math.multiplyExact(
              localValue(instruction, LEFT_SOURCE),
              localValue(instruction, RIGHT_SOURCE)));
      case LOCAL_DIV -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION),
          localValue(instruction, LEFT_SOURCE) / localValue(instruction, RIGHT_SOURCE));
      case LOCAL_MOD -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION),
          localValue(instruction, LEFT_SOURCE) % localValue(instruction, RIGHT_SOURCE));
      case LOCAL_AND -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION),
          localValue(instruction, LEFT_SOURCE) & localValue(instruction, RIGHT_SOURCE));
      case LOCAL_ROTR32 -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION),
          Integer.toUnsignedLong(Integer.rotateRight(
              (int) localValue(instruction, LEFT_SOURCE),
              Math.toIntExact(localValue(instruction, RIGHT_SOURCE)))));
      case LOCAL_XOR -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION),
          localValue(instruction, LEFT_SOURCE) ^ localValue(instruction, RIGHT_SOURCE));
      case LOCAL_EQ -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION),
          localValue(instruction, LEFT_SOURCE) == localValue(instruction, RIGHT_SOURCE) ? 1 : 0);
      case LOCAL_LT -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION),
          localValue(instruction, LEFT_SOURCE) < localValue(instruction, RIGHT_SOURCE) ? 1 : 0);
      case JUMP -> jumpCurrentFrame(Math.toIntExact(instruction.operand(TARGET)));
      case JUMP_IF_ZERO -> {
        if (localValue(instruction, CONDITION) == 0) {
          jumpCurrentFrame(Math.toIntExact(instruction.operand(TARGET)));
        } else {
          advanceCurrentFrame();
        }
      }
      case LOCAL_LOOP_CHECK -> setLocalAndAdvance(
          localIndex(instruction, ITERATION), Math.addExact(localValue(instruction, ITERATION), 1));
      case RECORD_NEW -> {
        int destination = localIndex(instruction, DESTINATION);
        int typeId = Math.toIntExact(instruction.operand(DESCRIPTOR));
        int base = Math.toIntExact(instruction.operand(ELEMENT_BASE));
        int count = Math.toIntExact(instruction.operand(ELEMENT_COUNT));
        List<Long> fields = new ArrayList<>(count);
        for (int field = 0; field < count; field++) {
          fields.add(currentFrame().local(base + field));
        }
        RecordValue value = new RecordValue(typeId, fields);
        setLocalAndAdvance(destination, aggregates.intern(value));
      }
      case RECORD_GET -> {
        int destination = localIndex(instruction, DESTINATION);
        RecordValue value = VmAggregateChecks.record(aggregates, localValue(instruction, OWNER));
        int field = Math.toIntExact(instruction.operand(INDEX));
        setLocalAndAdvance(destination, value.fields().get(field));
      }
      case VARIANT_NEW -> {
        int destination = localIndex(instruction, DESTINATION);
        int typeId = Math.toIntExact(instruction.operand(DESCRIPTOR));
        int tag = Math.toIntExact(instruction.operand(TAG));
        int base = Math.toIntExact(instruction.operand(ELEMENT_BASE));
        int count = Math.toIntExact(instruction.operand(ELEMENT_COUNT));
        List<Long> fields = new ArrayList<>(count);
        for (int field = 0; field < count; field++) {
          fields.add(currentFrame().local(base + field));
        }
        VariantValue value = new VariantValue(typeId, tag, fields);
        setLocalAndAdvance(destination, aggregates.intern(value));
      }
      case VARIANT_TAG_EQ -> {
        VariantValue value = VmAggregateChecks.variant(aggregates, localValue(instruction, OWNER));
        setLocalAndAdvance(
            localIndex(instruction, DESTINATION), value.tag() == instruction.operand(TAG) ? 1 : 0);
      }
      case VARIANT_GET -> {
        VariantValue value = VmAggregateChecks.variant(aggregates, localValue(instruction, OWNER));
        int expectedTag = Math.toIntExact(instruction.operand(TAG));
        if (value.tag() != expectedTag) {
          throw new VmTrap("Variant payload tag mismatch");
        }
        setLocalAndAdvance(
            localIndex(instruction, DESTINATION),
            value.fields().get(Math.toIntExact(instruction.operand(INDEX))));
      }
      case ARRAY_NEW -> {
        int destination = localIndex(instruction, DESTINATION);
        int typeId = Math.toIntExact(instruction.operand(DESCRIPTOR));
        int base = Math.toIntExact(instruction.operand(ELEMENT_BASE));
        int count = Math.toIntExact(instruction.operand(ELEMENT_COUNT));
        List<Long> elements = new ArrayList<>(count);
        for (int element = 0; element < count; element++) {
          elements.add(currentFrame().local(base + element));
        }
        ArrayValue value = new ArrayValue(typeId, elements);
        setLocalAndAdvance(destination, aggregates.intern(value));
      }
      case ARRAY_GET -> {
        ArrayValue value = VmAggregateChecks.array(aggregates, localValue(instruction, OWNER));
        int index = Math.toIntExact(localValue(instruction, INDEX));
        setLocalAndAdvance(localIndex(instruction, DESTINATION), value.elements().get(index));
      }
      case SLICE_NEW -> {
        int destination = localIndex(instruction, DESTINATION);
        int typeId = Math.toIntExact(instruction.operand(DESCRIPTOR));
        long arrayHandle = localValue(instruction, OWNER);
        int start = Math.toIntExact(localValue(instruction, START));
        int length = Math.toIntExact(localValue(instruction, LENGTH));
        SliceValue value = new SliceValue(typeId, arrayHandle, start, length);
        setLocalAndAdvance(destination, aggregates.intern(value));
      }
      case SLICE_GET -> {
        SliceValue slice = VmAggregateChecks.slice(aggregates, localValue(instruction, OWNER));
        ArrayValue array = VmAggregateChecks.array(aggregates, slice.arrayHandle());
        int index = Math.toIntExact(localValue(instruction, INDEX));
        setLocalAndAdvance(
            localIndex(instruction, DESTINATION), array.elements().get(slice.start() + index));
      }
      case REGION_NEW -> {
        OwnedStore.Allocation allocation = owned.createRegion(
            instruction.operand(CAPACITY),
            Math.toIntExact(instruction.operand(ALLOCATION_LIMIT)),
            ownedChange);
        ownedChange = allocation.change();
        setLocalAndAdvance(localIndex(instruction, DESTINATION), allocation.handle());
      }
      case WORDS_ALLOC, BYTES_ALLOC -> {
        BufferKind kind = opcode == Opcode.WORDS_ALLOC
            ? BufferKind.WORDS : BufferKind.BYTES;
        OwnedStore.Allocation allocation = owned.allocate(
            localValue(instruction, OWNER),
            Math.toIntExact(localValue(instruction, CAPACITY)),
            kind,
            ownedChange);
        ownedChange = allocation.change();
        setLocalAndAdvance(localIndex(instruction, DESTINATION), allocation.handle());
      }
      case WORDS_GET, BYTES_GET -> {
        BufferKind kind = opcode == Opcode.WORDS_GET
            ? BufferKind.WORDS : BufferKind.BYTES;
        setLocalAndAdvance(
            localIndex(instruction, DESTINATION),
            owned.get(
                localValue(instruction, OWNER),
                Math.toIntExact(localValue(instruction, INDEX)),
                kind));
      }
      case WORDS_SET, BYTES_SET -> {
        BufferKind kind = opcode == Opcode.WORDS_SET
            ? BufferKind.WORDS : BufferKind.BYTES;
        ownedChange = owned.set(
            localValue(instruction, OWNER),
            Math.toIntExact(localValue(instruction, INDEX)),
            localValue(instruction, SOURCE),
            kind,
            ownedChange);
        advanceCurrentFrame();
      }
      case UTF8_VALID -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION),
          Utf8.analyze(owned.utf8Bytes(localValue(instruction, SOURCE))).valid() ? 1 : 0);
      case UTF8_COUNT -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION),
          Utf8.analyze(owned.utf8Bytes(localValue(instruction, SOURCE))).scalarCount());
      case BUFFER_LENGTH -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION), owned.length(localValue(instruction, SOURCE)));
      case UTF8_SCALAR, UTF8_WIDTH -> {
        Utf8.Scalar scalar = VmControlChecks.utf8Scalar(owned, currentFrame(), instruction);
        setLocalAndAdvance(
            localIndex(instruction, DESTINATION),
            opcode == Opcode.UTF8_SCALAR ? scalar.value() : scalar.width());
      }
      case UTF8_BORROW, MAP_BORROW, BUFFER_BORROW, REGION_BORROW -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION), localValue(instruction, SOURCE));
      case UTF8_FREEZE -> {
        int destination = localIndex(instruction, DESTINATION);
        int source = localIndex(instruction, SOURCE);
        long handle = currentFrame().local(source);
        ownedChange = owned.freezeUtf8(handle, ownedChange);
        replaceCurrentFrame(
            currentFrame().withLocal(source, 0).withLocal(destination, handle).advance());
      }
      case MAP_ALLOC -> {
        OwnedStore.Allocation allocation = owned.allocate(
            localValue(instruction, OWNER),
            Math.toIntExact(localValue(instruction, CAPACITY)),
            BufferKind.LONG_MAP,
            ownedChange);
        ownedChange = allocation.change();
        setLocalAndAdvance(localIndex(instruction, DESTINATION), allocation.handle());
      }
      case MAP_PUT -> {
        ownedChange = owned.mapPut(
            localValue(instruction, OWNER),
            localValue(instruction, KEY),
            localValue(instruction, SOURCE),
            ownedChange);
        advanceCurrentFrame();
      }
      case MAP_GET -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION),
          owned.mapGet(localValue(instruction, OWNER), localValue(instruction, KEY)));
      case MAP_HAS -> setLocalAndAdvance(
          localIndex(instruction, DESTINATION),
          owned.mapHas(localValue(instruction, OWNER), localValue(instruction, KEY)) ? 1 : 0);
      case BUFFER_DROP -> {
        int local = localIndex(instruction, LOCAL);
        ownedChange = owned.dropBuffer(currentFrame().local(local), ownedChange);
        setLocalAndAdvance(local, 0);
      }
      case REGION_DROP -> {
        int local = localIndex(instruction, LOCAL);
        ownedChange = owned.dropRegion(currentFrame().local(local), ownedChange);
        setLocalAndAdvance(local, 0);
      }
      case OUTPUT_LENGTH -> {
        hostOutputLength = Math.toIntExact(localValue(instruction, LENGTH));
        advanceCurrentFrame();
      }
      case CALL, UNCALL -> {
        int functionId = Math.toIntExact(instruction.operand(FUNCTION));
        advanceCurrentFrame();
        FunctionBody target = program.function(functionId);
        tasks.addFrame(Frame.create(functionId, opcode == Opcode.UNCALL, target.localCount()));
        control = StepRecord.ControlChange.CALL;
      }
      case CALL_VALUE, CALL_VOID -> {
        ArgumentCallBinder.Binding binding = ArgumentCallBinder.bind(
            program, currentFrame(), instruction, opcode == Opcode.CALL_VALUE);
        replaceCurrentFrame(binding.caller());
        tasks.addFrame(binding.callee());
        control = StepRecord.ControlChange.CALL;
      }
      case RETURN -> {
        tasks.removeLastFrame();
        control = StepRecord.ControlChange.RETURN;
      }
      case RETURN_VALUE -> {
        long result = localValue(instruction, RESULT);
        int destination = frame.returnDestination();
        tasks.removeLastFrame();
        changedLocal = destination;
        previousLocalValue = currentFrame().local(destination);
        replaceCurrentFrame(currentFrame().withLocal(destination, result));
        control = StepRecord.ControlChange.RETURN;
      }
      case EXPECT_EQ, EXPECT_TRUE, NOP, CHECKPOINT, COMMIT -> advanceCurrentFrame();
      case HALT -> {
        advanceCurrentFrame();
        status = MachineStatus.HALTED;
      }
    }

    return new StepRecord(
        sequence,
        new EventId(0, tasks.selected(), Math.addExact(sequence, 1)),
        previousSelectedTask,
        previousSchedulerCursor,
        previousTaskStatus,
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
            globals[globalIndex(instruction, GLOBAL)], instruction.operand(IMMEDIATE));
        case SUB_CONST -> Math.subtractExact(
            globals[globalIndex(instruction, GLOBAL)], instruction.operand(IMMEDIATE));
        case LOCAL_ADD -> {
          localIndex(instruction, DESTINATION);
          Math.addExact(
              localValue(instruction, LEFT_SOURCE),
              localValue(instruction, RIGHT_SOURCE));
        }
        case LOCAL_SUB -> {
          localIndex(instruction, DESTINATION);
          Math.subtractExact(
              localValue(instruction, LEFT_SOURCE),
              localValue(instruction, RIGHT_SOURCE));
        }
        case LOCAL_MUL -> {
          localIndex(instruction, DESTINATION);
          Math.multiplyExact(
              localValue(instruction, LEFT_SOURCE),
              localValue(instruction, RIGHT_SOURCE));
        }
        case LOCAL_DIV, LOCAL_MOD -> {
          localIndex(instruction, DESTINATION);
          long dividend = localValue(instruction, LEFT_SOURCE);
          long divisor = localValue(instruction, RIGHT_SOURCE);
          if (divisor == 0) {
            trap("Division by zero");
          }
          if (instruction.opcode() == Opcode.LOCAL_DIV
              && dividend == Long.MIN_VALUE && divisor == -1) {
            trap("Arithmetic overflow in LOCAL_DIV");
          }
        }
        case LOCAL_CONST -> localIndex(instruction, DESTINATION);
        case LOCAL_LOAD_GLOBAL -> {
          localIndex(instruction, DESTINATION);
          globalIndex(instruction, GLOBAL);
        }
        case LOCAL_STORE_GLOBAL -> {
          globalIndex(instruction, GLOBAL);
          localIndex(instruction, SOURCE);
        }
        case LOCAL_MOVE, OWNED_MOVE -> {
          localIndex(instruction, DESTINATION);
          localIndex(instruction, SOURCE);
        }
        case LOCAL_AND, LOCAL_XOR, LOCAL_EQ, LOCAL_LT -> {
          localIndex(instruction, DESTINATION);
          localIndex(instruction, LEFT_SOURCE);
          localIndex(instruction, RIGHT_SOURCE);
        }
        case LOCAL_ROTR32 -> {
          localIndex(instruction, DESTINATION);
          localIndex(instruction, LEFT_SOURCE);
          long amount = localValue(instruction, RIGHT_SOURCE);
          if (amount < 0 || amount > 31) {
            trap("32-bit rotate amount must be between 0 and 31");
          }
        }
        case JUMP -> VmControlChecks.jumpTarget(program, currentFrame(), instruction);
        case JUMP_IF_ZERO -> {
          localIndex(instruction, CONDITION);
          VmControlChecks.jumpTarget(program, currentFrame(), instruction);
        }
        case LOCAL_LOOP_CHECK -> {
          long iteration = localValue(instruction, ITERATION);
          long limit = localValue(instruction, LIMIT);
          if (iteration < 0 || limit < 0 || iteration >= limit) {
            trap("Loop iteration limit exceeded");
          }
          Math.addExact(iteration, 1);
        }
        case RECORD_NEW -> {
          localIndex(instruction, DESTINATION);
          RecordType type = program.recordType(Math.toIntExact(instruction.operand(DESCRIPTOR)));
          int base = Math.toIntExact(instruction.operand(ELEMENT_BASE));
          int count = Math.toIntExact(instruction.operand(ELEMENT_COUNT));
          List<Long> fields = new ArrayList<>(count);
          for (int field = 0; field < count; field++) {
            long value = currentFrame().local(base + field);
            fields.add(value);
            ValueType fieldType = type.fields().get(field).type();
            if (fieldType.kind() == ValueType.Kind.RECORD
                && VmAggregateChecks.record(aggregates, value).typeId()
                    != fieldType.descriptorId()) {
              trap("Nested record type mismatch");
            }
          }
          if (aggregates.fullForNew(new RecordValue(type.id(), fields))) {
            trap("Record value limit exceeded");
          }
        }
        case RECORD_GET -> {
          localIndex(instruction, DESTINATION);
          RecordValue value = VmAggregateChecks.record(
              aggregates, localValue(instruction, OWNER));
          int field = Math.toIntExact(instruction.operand(INDEX));
          if (field < 0 || field >= value.fields().size()) {
            trap("Record field index out of range");
          }
        }
        case VARIANT_NEW -> {
          localIndex(instruction, DESTINATION);
          var type = program.variantType(Math.toIntExact(instruction.operand(DESCRIPTOR)));
          int tag = Math.toIntExact(instruction.operand(TAG));
          int base = Math.toIntExact(instruction.operand(ELEMENT_BASE));
          int count = Math.toIntExact(instruction.operand(ELEMENT_COUNT));
          var variantCase = type.cases().get(tag);
          List<Long> fields = new ArrayList<>(count);
          for (int field = 0; field < count; field++) {
            long value = currentFrame().local(base + field);
            VmAggregateChecks.validateValue(
                aggregates, variantCase.fields().get(field).type(), value);
            fields.add(value);
          }
          if (aggregates.fullForNew(new VariantValue(type.id(), tag, fields))) {
            trap("Variant value limit exceeded");
          }
        }
        case VARIANT_TAG_EQ -> {
          localIndex(instruction, DESTINATION);
          VariantValue value = VmAggregateChecks.checkedVariant(
              aggregates, program, currentFrame(), instruction, OWNER);
          if (instruction.operand(TAG) < 0
              || instruction.operand(TAG) >= program.variantType(value.typeId()).cases().size()) {
            trap("Variant tag out of range");
          }
        }
        case VARIANT_GET -> {
          localIndex(instruction, DESTINATION);
          VariantValue value = VmAggregateChecks.checkedVariant(
              aggregates, program, currentFrame(), instruction, OWNER);
          int tag = Math.toIntExact(instruction.operand(TAG));
          int field = Math.toIntExact(instruction.operand(INDEX));
          if (value.tag() != tag || field < 0 || field >= value.fields().size()) {
            trap("Variant payload access mismatch");
          }
        }
        case ARRAY_NEW -> {
          localIndex(instruction, DESTINATION);
          var type = program.arrayType(Math.toIntExact(instruction.operand(DESCRIPTOR)));
          int base = Math.toIntExact(instruction.operand(ELEMENT_BASE));
          int count = Math.toIntExact(instruction.operand(ELEMENT_COUNT));
          List<Long> elements = new ArrayList<>(count);
          for (int element = 0; element < count; element++) {
            long value = currentFrame().local(base + element);
            VmAggregateChecks.validateValue(aggregates, type.elementType(), value);
            elements.add(value);
          }
          if (aggregates.fullForNew(new ArrayValue(type.id(), elements))) {
            trap("Array value limit exceeded");
          }
        }
        case ARRAY_GET -> {
          localIndex(instruction, DESTINATION);
          ArrayValue value = VmAggregateChecks.checkedArray(
              aggregates, program, currentFrame(), instruction, OWNER);
          long index = localValue(instruction, INDEX);
          if (index < 0 || index >= value.elements().size()) {
            trap("Array index out of bounds: " + index);
          }
        }
        case SLICE_NEW -> {
          localIndex(instruction, DESTINATION);
          ArrayValue array = VmAggregateChecks.checkedArray(
              aggregates, program, currentFrame(), instruction, OWNER);
          long start = localValue(instruction, START);
          long length = localValue(instruction, LENGTH);
          long end = Math.addExact(start, length);
          if (start < 0 || length < 0 || end > array.elements().size()) {
            trap("Slice range is outside its array");
          }
          SliceValue value = new SliceValue(
              Math.toIntExact(instruction.operand(DESCRIPTOR)),
              localValue(instruction, OWNER),
              Math.toIntExact(start),
              Math.toIntExact(length));
          if (aggregates.fullForNew(value)) {
            trap("Slice value limit exceeded");
          }
        }
        case SLICE_GET -> {
          localIndex(instruction, DESTINATION);
          SliceValue value = VmAggregateChecks.checkedSlice(
              aggregates, program, currentFrame(), instruction, OWNER);
          long index = localValue(instruction, INDEX);
          if (index < 0 || index >= value.length()) {
            trap("Slice index out of bounds: " + index);
          }
        }
        case OUTPUT_LENGTH -> {
          long handle = localValue(instruction, OWNER);
          long length = localValue(instruction, LENGTH);
          if (handle != hostOutputHandle || length < 0 || length > owned.length(handle)) {
            trap("Invalid host output length: " + length);
          }
        }
        case CALL -> {
          requireCallCapacity();
          program.function(Math.toIntExact(instruction.operand(FUNCTION)));
        }
        case CALL_VALUE, CALL_VOID -> {
          requireCallCapacity();
          FunctionBody target = program.function(Math.toIntExact(instruction.operand(FUNCTION)));
          int base = Math.toIntExact(instruction.operand(ARGUMENT_BASE));
          int count = Math.toIntExact(instruction.operand(ARGUMENT_COUNT));
          boolean returnsValue = instruction.opcode() == Opcode.CALL_VALUE;
          if (returnsValue) {
            localIndex(instruction, RESULT);
          }
          if (target.returnsValue() != returnsValue || target.parameterCount() != count
              || base < 0 || count < 0 || base > currentFrame().localCount() - count) {
            trap("Argument call signature mismatch for " + target.name());
          }
        }
        case UNCALL -> {
          requireCallCapacity();
          FunctionBody function = program.function(Math.toIntExact(instruction.operand(FUNCTION)));
          if (!function.reversible()) {
            trap("Function has no inverse: " + function.name());
          }
        }
        case RETURN -> {
          if (tasks.frameDepth() <= 1 || currentFrame().returnDestination() != -1) {
            trap("Invalid void return");
          }
        }
        case RETURN_VALUE -> {
          localIndex(instruction, RESULT);
          if (tasks.frameDepth() <= 1 || currentFrame().returnDestination() < 0) {
            trap("Invalid value return");
          }
        }
        case EXPECT_EQ -> VmControlChecks.requireGlobalEqual(
            program, globals, globalIndex(instruction, GLOBAL), instruction.operand(IMMEDIATE));
        case EXPECT_TRUE -> VmControlChecks.requireTrue(
            currentFrame(), localIndex(instruction, CONDITION));
        case HALT, NOP, XOR_CONST, SWAP, SET_LOGGED, CHECKPOINT, COMMIT -> {
          // The verifier and operand access establish all remaining preconditions.
        }
      }
    } catch (ArithmeticException exception) {
      trap("Arithmetic overflow in " + instruction.opcode());
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
    if (tasks.frameStackEmpty()) {
      throw new IllegalStateException("Machine has no control frame");
    }
    return tasks.currentFrame();
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
    tasks.replaceCurrentFrame(frame);
  }

  private int globalIndex(
      Instruction instruction, InstructionForm.OperandRole role) {
    return VmControlChecks.globalIndex(
        globals.length, Math.toIntExact(instruction.operand(role)));
  }

  private int localIndex(
      Instruction instruction, InstructionForm.OperandRole role) {
    int index = Math.toIntExact(instruction.operand(role));
    if (index < 0 || index >= currentFrame().localCount()) {
      throw new VmTrap("Invalid local index " + index);
    }
    return index;
  }

  private long localValue(
      Instruction instruction, InstructionForm.OperandRole role) {
    return currentFrame().local(localIndex(instruction, role));
  }

  private void requireCallCapacity() {
    if (tasks.frameDepth() >= MAX_CALL_DEPTH) {
      trap("Call depth limit exceeded");
    }
  }

  private void trap(String message) {
    status = MachineStatus.TRAPPED;
    tasks.setSelectedStatus(TaskStatus.FAILED);
    throw new VmTrap(message);
  }
}
