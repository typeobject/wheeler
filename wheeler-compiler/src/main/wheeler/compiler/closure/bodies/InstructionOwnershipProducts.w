//! Derives bounded owner and nonescaping-loan events from canonical instructions.

module wheeler.compiler.closure.instruction_ownership_products;

import wheeler.compiler.storage_opcodes;
import wheeler.core.encoding.binary;

classical class InstructionOwnershipProducts {
  private const long EVENT_ROWS = 40960;
  private const long INSTRUCTION_ROWS = 24576;
  private const long MAX_EVENTS_PER_MODULE = 8192;
  private const long MAX_INSTRUCTIONS_PER_MODULE = 4096;
  private const long OWNER_STACK_BYTES = 65536;
  private const long OWNERSHIP_COORDINATE_ROWS = 32768;

  /// Reports one complete ownership coordinate join.
  public record OwnershipCoordinatePlan(long eventCount, boolean valid) {}

  private long eventKind(long opcode) {
    if (opcode == OPCODE_OWNED_MOVE) {
      return 1;
    }

    if (opcode == OPCODE_UTF8_BORROW) {
      return 2;
    }

    if (opcode == OPCODE_MAP_BORROW) {
      return 2;
    }

    if (opcode == OPCODE_BUFFER_BORROW) {
      return 2;
    }

    if (opcode == OPCODE_REGION_BORROW) {
      return 2;
    }

    if (opcode == OPCODE_BUFFER_DROP) {
      return 4;
    }

    if (opcode == OPCODE_REGION_DROP) {
      return 4;
    }

    if (opcode == OPCODE_RECORD_NEW) {
      return 5;
    }

    if (opcode == OPCODE_VARIANT_NEW) {
      return 5;
    }

    if (opcode == OPCODE_ARRAY_NEW) {
      return 5;
    }

    if (opcode == OPCODE_SLICE_NEW) {
      return 5;
    }

    if (opcode == OPCODE_REGION_NEW) {
      return 5;
    }

    if (opcode == OPCODE_WORDS_ALLOC) {
      return 5;
    }

    if (opcode == OPCODE_BYTES_ALLOC) {
      return 5;
    }

    if (opcode == OPCODE_MAP_ALLOC) {
      return 5;
    }

    if (opcode == OPCODE_UTF8_FREEZE) {
      return 5;
    }

    return 0;
  }

  private long readSelectedUnsigned(
    borrow byteview primitiveArtifact,
    borrow byteview supplementalArtifact,
    long selector,
    long start,
    long width
  ) {
    if (selector == 0) {
      return readUnsigned(primitiveArtifact, start, width);
    }

    assert(selector == 1);
    return readUnsigned(supplementalArtifact, start, width);
  }

  /// Publishes instruction-ordered events and function-boundary loan releases.
  public long deriveInstructionOwnershipProducts(
    borrow byteview artifact,
    long instructionCount,
    borrow mut words instructionRows,
    borrow mut words eventRows
  ) {
    assert(-1 < instructionCount);
    assert(instructionCount < MAX_INSTRUCTIONS_PER_MODULE + 1);
    assert(bufferLength(instructionRows) == INSTRUCTION_ROWS);
    assert(bufferLength(eventRows) == EVENT_ROWS);

    long expectedEvents = 0;
    long previousFunction = -1;
    long instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      long function = instructionRows[instruction];
      assert(previousFunction < function + 1);
      previousFunction = function;
      long kind = eventKind(instructionRows[12288 + instruction]);
      if (0 < kind) {
        assert(-1 < instructionRows[8192 + instruction]);
        expectedEvents += 1;
        if (kind == 2) {
          expectedEvents += 1;
        }

        assert(expectedEvents < MAX_EVENTS_PER_MODULE + 1);
      }

      instruction += 1;
    }

    region owners = new region(/* bytes= */ OWNER_STACK_BYTES, /* allocations= */ 2);
    words borrowedDestinations = allocate(owners, MAX_INSTRUCTIONS_PER_MODULE);
    words borrowedSources = allocate(owners, MAX_INSTRUCTIONS_PER_MODULE);
    long borrowCount = 0;
    long eventCount = 0;
    long activeFunction = -1;
    instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      long selectedFunction = instructionRows[instruction];
      if (activeFunction < selectedFunction) {
        while (0 < borrowCount) limit MAX_INSTRUCTIONS_PER_MODULE {
          borrowCount -= 1;
          set(eventRows, eventCount, 3);
          set(eventRows, 8192 + eventCount, instruction);
          set(eventRows, 16384 + eventCount, activeFunction);
          set(eventRows, 24576 + eventCount, borrowedDestinations[borrowCount]);
          set(eventRows, 32768 + eventCount, borrowedSources[borrowCount]);
          eventCount += 1;
        }

        activeFunction = selectedFunction;
      }

      long selectedOpcode = instructionRows[12288 + instruction];
      long selectedKind = eventKind(selectedOpcode);
      if (0 < selectedKind) {
        long start = instructionRows[8192 + instruction];
        long destination = readUnsigned(artifact, start + 8, 8);
        long source = -1;
        if (selectedKind == 1) {
          source = readUnsigned(artifact, start + 16, 8);
        }

        if (selectedKind == 2) {
          source = readUnsigned(artifact, start + 16, 8);
        }

        if (selectedKind == 4) {
          source = destination;
          destination = -1;
        }

        set(eventRows, eventCount, selectedKind);
        set(eventRows, 8192 + eventCount, instruction);
        set(eventRows, 16384 + eventCount, selectedFunction);
        set(eventRows, 24576 + eventCount, destination);
        set(eventRows, 32768 + eventCount, source);
        eventCount += 1;
        if (selectedKind == 2) {
          set(borrowedDestinations, borrowCount, destination);
          set(borrowedSources, borrowCount, source);
          borrowCount += 1;
        }
      }

      instruction += 1;
    }

    while (0 < borrowCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      borrowCount -= 1;
      set(eventRows, eventCount, 3);
      set(eventRows, 8192 + eventCount, instructionCount);
      set(eventRows, 16384 + eventCount, activeFunction);
      set(eventRows, 24576 + eventCount, borrowedDestinations[borrowCount]);
      set(eventRows, 32768 + eventCount, borrowedSources[borrowCount]);
      eventCount += 1;
    }

    assert(eventCount == expectedEvents);
    drop(borrowedSources);
    drop(borrowedDestinations);
    drop(owners);
    return eventCount;
  }

  /// Binds source effects to planned statements, instructions, and locals atomically.
  public OwnershipCoordinatePlan bindInstructionOwnershipCoordinates(
    long eventCount,
    long instructionCount,
    borrow mut words eventRows,
    borrow mut words instructionStatements,
    borrow mut words instructionPlannedRows,
    borrow mut words coordinateRows
  ) {
    assert(-1 < eventCount);
    assert(eventCount < MAX_EVENTS_PER_MODULE + 1);
    assert(-1 < instructionCount);
    assert(instructionCount < MAX_INSTRUCTIONS_PER_MODULE + 1);
    assert(bufferLength(eventRows) == EVENT_ROWS);
    assert(bufferLength(instructionStatements) == MAX_INSTRUCTIONS_PER_MODULE);
    assert(bufferLength(instructionPlannedRows) == MAX_INSTRUCTIONS_PER_MODULE);
    assert(bufferLength(coordinateRows) == OWNERSHIP_COORDINATE_ROWS);

    region staging = new region(/* bytes= */ 262144, /* allocations= */ 1);
    words stagedCoordinates = allocate(staging, OWNERSHIP_COORDINATE_ROWS);
    boolean valid = true;
    long event = 0;
    while (event < eventCount) limit MAX_EVENTS_PER_MODULE {
      long kind = eventRows[event];
      long instruction = eventRows[8192 + event];
      long statement = -1;
      long plannedInstruction = instruction;
      if (kind == 3) {
        if (instruction < 0) {
          valid = false;
        }

        if (instructionCount < instruction) {
          valid = false;
        }
      } else {
        if (instruction < 0) {
          valid = false;
        }

        if (instructionCount - 1 < instruction) {
          valid = false;
        }

        if (-1 < instruction) {
          if (instruction < instructionCount) {
            statement = instructionStatements[instruction];
            plannedInstruction = instructionPlannedRows[instruction];
            if (statement < 0) {
              valid = false;
            }

            if (MAX_INSTRUCTIONS_PER_MODULE - 1 < statement) {
              valid = false;
            }

            if (plannedInstruction < 0) {
              valid = false;
            }

            if (32767 < plannedInstruction) {
              valid = false;
            }
          }
        }
      }

      long destination = eventRows[24576 + event];
      long source = eventRows[32768 + event];
      if (255 < destination) {
        valid = false;
      }

      if (255 < source) {
        valid = false;
      }

      set(stagedCoordinates, event, statement);
      set(stagedCoordinates, 8192 + event, plannedInstruction);
      set(stagedCoordinates, 16384 + event, destination);
      set(stagedCoordinates, 24576 + event, source);
      event += 1;
    }

    if (valid == false) {
      drop(stagedCoordinates);
      drop(staging);
      return new OwnershipCoordinatePlan(0, false);
    }

    long row = 0;
    while (row < OWNERSHIP_COORDINATE_ROWS) limit OWNERSHIP_COORDINATE_ROWS {
      set(coordinateRows, row, stagedCoordinates[row]);
      row += 1;
    }

    drop(stagedCoordinates);
    drop(staging);
    return new OwnershipCoordinatePlan(eventCount, true);
  }

  /// Requires source and decoded ownership coordinates to agree exactly.
  public boolean ownershipCoordinatesAgree(
    long eventCount,
    borrow mut words sourceCoordinates,
    borrow mut words decodedCoordinates
  ) {
    assert(-1 < eventCount);
    assert(eventCount < MAX_EVENTS_PER_MODULE + 1);
    assert(bufferLength(sourceCoordinates) == OWNERSHIP_COORDINATE_ROWS);
    assert(bufferLength(decodedCoordinates) == OWNERSHIP_COORDINATE_ROWS);

    long event = 0;
    while (event < eventCount) limit MAX_EVENTS_PER_MODULE {
      if (sourceCoordinates[event] != decodedCoordinates[event]) {
        return false;
      }

      if (sourceCoordinates[8192 + event] != decodedCoordinates[8192 + event]) {
        return false;
      }

      if (sourceCoordinates[16384 + event] != decodedCoordinates[16384 + event]) {
        return false;
      }

      if (sourceCoordinates[24576 + event] != decodedCoordinates[24576 + event]) {
        return false;
      }

      event += 1;
    }

    return true;
  }

  /// Publishes events from a validated two-artifact composed instruction view.
  public long deriveComposedInstructionOwnershipProducts(
    borrow byteview primitiveArtifact,
    borrow byteview supplementalArtifact,
    long instructionCount,
    borrow mut words instructionRows,
    borrow mut words artifactSelectors,
    borrow mut words eventRows
  ) {
    assert(-1 < instructionCount);
    assert(instructionCount < MAX_INSTRUCTIONS_PER_MODULE + 1);
    assert(bufferLength(instructionRows) == INSTRUCTION_ROWS);
    assert(bufferLength(artifactSelectors) == MAX_INSTRUCTIONS_PER_MODULE);
    assert(bufferLength(eventRows) == EVENT_ROWS);

    long expectedEvents = 0;
    long previousFunction = -1;
    long instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      long function = instructionRows[instruction];
      long selector = artifactSelectors[instruction];
      assert(-1 < selector);
      assert(selector < 2);
      assert(previousFunction < function + 1);
      previousFunction = function;
      long kind = eventKind(instructionRows[12288 + instruction]);
      if (0 < kind) {
        assert(-1 < instructionRows[8192 + instruction]);
        expectedEvents += 1;
        if (kind == 2) {
          expectedEvents += 1;
        }

        assert(expectedEvents < MAX_EVENTS_PER_MODULE + 1);
      }

      instruction += 1;
    }

    region owners = new region(/* bytes= */ OWNER_STACK_BYTES, /* allocations= */ 2);
    words borrowedDestinations = allocate(owners, MAX_INSTRUCTIONS_PER_MODULE);
    words borrowedSources = allocate(owners, MAX_INSTRUCTIONS_PER_MODULE);
    long borrowCount = 0;
    long eventCount = 0;
    long activeFunction = -1;
    instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      long selectedFunction = instructionRows[instruction];
      long selectedArtifact = artifactSelectors[instruction];
      assert(-1 < selectedArtifact);
      assert(selectedArtifact < 2);
      if (activeFunction < selectedFunction) {
        while (0 < borrowCount) limit MAX_INSTRUCTIONS_PER_MODULE {
          borrowCount -= 1;
          set(eventRows, eventCount, 3);
          set(eventRows, 8192 + eventCount, instruction);
          set(eventRows, 16384 + eventCount, activeFunction);
          set(eventRows, 24576 + eventCount, borrowedDestinations[borrowCount]);
          set(eventRows, 32768 + eventCount, borrowedSources[borrowCount]);
          eventCount += 1;
        }

        activeFunction = selectedFunction;
      }

      long selectedOpcode = instructionRows[12288 + instruction];
      long selectedKind = eventKind(selectedOpcode);
      if (0 < selectedKind) {
        long start = instructionRows[8192 + instruction];
        long destination = readSelectedUnsigned(
          primitiveArtifact,
          supplementalArtifact,
          selectedArtifact,
          start + 8,
          8
        );
        long source = -1;
        if (selectedKind == 1) {
          source = readSelectedUnsigned(
            primitiveArtifact,
            supplementalArtifact,
            selectedArtifact,
            start + 16,
            8
          );
        }

        if (selectedKind == 2) {
          source = readSelectedUnsigned(
            primitiveArtifact,
            supplementalArtifact,
            selectedArtifact,
            start + 16,
            8
          );
        }

        if (selectedKind == 4) {
          source = destination;
          destination = -1;
        }

        set(eventRows, eventCount, selectedKind);
        set(eventRows, 8192 + eventCount, instruction);
        set(eventRows, 16384 + eventCount, selectedFunction);
        set(eventRows, 24576 + eventCount, destination);
        set(eventRows, 32768 + eventCount, source);
        eventCount += 1;
        if (selectedKind == 2) {
          set(borrowedDestinations, borrowCount, destination);
          set(borrowedSources, borrowCount, source);
          borrowCount += 1;
        }
      }

      instruction += 1;
    }

    while (0 < borrowCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      borrowCount -= 1;
      set(eventRows, eventCount, 3);
      set(eventRows, 8192 + eventCount, instructionCount);
      set(eventRows, 16384 + eventCount, activeFunction);
      set(eventRows, 24576 + eventCount, borrowedDestinations[borrowCount]);
      set(eventRows, 32768 + eventCount, borrowedSources[borrowCount]);
      eventCount += 1;
    }

    assert(eventCount == expectedEvents);
    drop(borrowedSources);
    drop(borrowedDestinations);
    drop(owners);
    return eventCount;
  }
}
