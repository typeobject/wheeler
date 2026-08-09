//! Appends validated function products into bounded closure-wide windows.

module wheeler.compiler.closure.counted_function_products;

classical class CountedFunctionProducts {
  private const long ARTIFACT_SELECTOR_ROWS = 4096;
  private const long CLOSURE_FUNCTION_ROWS = 49152;
  private const long CLOSURE_INSTRUCTION_ROWS = 917504;
  private const long LOCAL_FUNCTION_ROWS = 640;
  private const long LOCAL_INSTRUCTION_ROWS = 24576;
  private const long MAX_CLOSURE_FUNCTIONS = 4096;
  private const long MAX_CLOSURE_INSTRUCTIONS = 131072;
  private const long MAX_FUNCTIONS_PER_MODULE = 64;
  private const long MAX_INSTRUCTIONS_PER_MODULE = 4096;
  private const long MAX_MODULES = 512;

  /// Identifies one appended module product without source allocation addresses.
  public record CountedFunctionWindow(
    long firstFunction,
    long functionCount,
    long firstInstruction,
    long instructionCount
  ) {}

  /// Appends one source-local product after validating every source index and capacity.
  public CountedFunctionWindow appendFunctionProduct(
    long moduleOwner,
    long artifactRank,
    long functionCount,
    long instructionCount,
    borrow mut words localFunctionRows,
    borrow mut words localInstructionRows,
    long closureFunctionCount,
    long closureInstructionCount,
    borrow mut words moduleFirstFunctions,
    borrow mut words moduleFunctionCounts,
    borrow mut words closureFunctionRows,
    borrow mut words closureInstructionRows
  ) {
    assert(-1 < moduleOwner);
    assert(moduleOwner < MAX_MODULES);
    assert(-1 < artifactRank);
    assert(0 < functionCount);
    assert(functionCount < MAX_FUNCTIONS_PER_MODULE + 1);
    assert(-1 < instructionCount);
    assert(instructionCount < MAX_INSTRUCTIONS_PER_MODULE + 1);
    assert(-1 < closureFunctionCount);
    assert(functionCount < MAX_CLOSURE_FUNCTIONS - closureFunctionCount + 1);
    assert(-1 < closureInstructionCount);
    assert(instructionCount < MAX_CLOSURE_INSTRUCTIONS - closureInstructionCount + 1);
    assert(bufferLength(localFunctionRows) == LOCAL_FUNCTION_ROWS);
    assert(bufferLength(localInstructionRows) == LOCAL_INSTRUCTION_ROWS);
    assert(bufferLength(moduleFirstFunctions) == MAX_MODULES);
    assert(bufferLength(moduleFunctionCounts) == MAX_MODULES);
    assert(bufferLength(closureFunctionRows) == CLOSURE_FUNCTION_ROWS);
    assert(bufferLength(closureInstructionRows) == CLOSURE_INSTRUCTION_ROWS);
    assert(moduleFunctionCounts[moduleOwner] == 0);

    long function = 0;
    while (function < functionCount) limit MAX_FUNCTIONS_PER_MODULE {
      assert(localFunctionRows[function] == function);
      long firstType = localFunctionRows[512 + function];
      long typeCount = localFunctionRows[576 + function];
      assert(-1 < firstType);
      assert(-1 < typeCount);
      function += 1;
    }

    long instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      long localFunction = localInstructionRows[instruction];
      assert(-1 < localFunction);
      assert(localFunction < functionCount);
      assert(-1 < localInstructionRows[8192 + instruction]);
      instruction += 1;
    }

    function = 0;
    while (function < functionCount) limit MAX_FUNCTIONS_PER_MODULE {
      long functionTarget = closureFunctionCount + function;
      set(closureFunctionRows, functionTarget, moduleOwner);
      set(closureFunctionRows, 4096 + functionTarget, function);
      set(closureFunctionRows, 8192 + functionTarget, localFunctionRows[64 + function]);
      set(closureFunctionRows, 12288 + functionTarget, artifactRank);
      set(closureFunctionRows, 16384 + functionTarget, localFunctionRows[128 + function]);
      set(closureFunctionRows, 20480 + functionTarget, localFunctionRows[192 + function]);
      set(closureFunctionRows, 24576 + functionTarget, localFunctionRows[256 + function]);
      set(closureFunctionRows, 28672 + functionTarget, localFunctionRows[320 + function]);
      set(closureFunctionRows, 32768 + functionTarget, localFunctionRows[384 + function]);
      set(closureFunctionRows, 36864 + functionTarget, localFunctionRows[448 + function]);
      set(closureFunctionRows, 40960 + functionTarget, localFunctionRows[512 + function]);
      set(closureFunctionRows, 45056 + functionTarget, localFunctionRows[576 + function]);
      function += 1;
    }

    instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      long instructionTarget = closureInstructionCount + instruction;
      set(
        closureInstructionRows,
        instructionTarget,
        closureFunctionCount + localInstructionRows[instruction]
      );
      set(
        closureInstructionRows,
        131072 + instructionTarget,
        localInstructionRows[4096 + instruction]
      );
      set(closureInstructionRows, 262144 + instructionTarget, artifactRank);
      set(
        closureInstructionRows,
        393216 + instructionTarget,
        localInstructionRows[8192 + instruction]
      );
      set(
        closureInstructionRows,
        524288 + instructionTarget,
        localInstructionRows[12288 + instruction]
      );
      set(
        closureInstructionRows,
        655360 + instructionTarget,
        localInstructionRows[16384 + instruction]
      );
      set(
        closureInstructionRows,
        786432 + instructionTarget,
        localInstructionRows[20480 + instruction]
      );
      instruction += 1;
    }

    set(moduleFirstFunctions, moduleOwner, closureFunctionCount);
    set(moduleFunctionCounts, moduleOwner, functionCount);
    return new CountedFunctionWindow(
      closureFunctionCount,
      functionCount,
      closureInstructionCount,
      instructionCount
    );
  }

  /// Appends a validated two-artifact source-local instruction product.
  public CountedFunctionWindow appendComposedFunctionProduct(
    long moduleOwner,
    long primitiveArtifactRank,
    long aggregateArtifactRank,
    long functionCount,
    long instructionCount,
    borrow mut words localFunctionRows,
    borrow mut words localInstructionRows,
    borrow mut words artifactSelectors,
    long closureFunctionCount,
    long closureInstructionCount,
    borrow mut words moduleFirstFunctions,
    borrow mut words moduleFunctionCounts,
    borrow mut words closureFunctionRows,
    borrow mut words closureInstructionRows
  ) {
    assert(-1 < primitiveArtifactRank);
    assert(-1 < aggregateArtifactRank);
    assert(primitiveArtifactRank != aggregateArtifactRank);
    assert(bufferLength(artifactSelectors) == ARTIFACT_SELECTOR_ROWS);
    long instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      long selector = artifactSelectors[instruction];
      assert(-1 < selector);
      assert(selector < 2);
      instruction += 1;
    }

    CountedFunctionWindow window = appendFunctionProduct(
      moduleOwner,
      primitiveArtifactRank,
      functionCount,
      instructionCount,
      localFunctionRows,
      localInstructionRows,
      closureFunctionCount,
      closureInstructionCount,
      moduleFirstFunctions,
      moduleFunctionCounts,
      closureFunctionRows,
      closureInstructionRows
    );
    instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      if (artifactSelectors[instruction] == 1) {
        set(
          closureInstructionRows,
          262144 + closureInstructionCount + instruction,
          aggregateArtifactRank
        );
      }

      instruction += 1;
    }

    return window;
  }
}
