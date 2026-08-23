//! Resolves source-call identities onto retained closure instruction products.

module wheeler.compiler.closure.source_call_relocation_link_products;

import wheeler.compiler.closure.callable_function_rows;
import wheeler.compiler.closure.imported_callable_stubs;
import wheeler.compiler.opcodes;

classical class SourceCallRelocationLinkProducts {
  private const long MAX_CLOSURE_INSTRUCTIONS = 131072;
  private const long MAX_RELOCATIONS = 256;

  /// Reports the retained local prefix and every resolved source relocation.
  public record SourceCallRelocationLinkPlan(
    long functionCount,
    long instructionCount,
    long excludedFunctionCount,
    long relocationCount
  ) {}

  private long inverseCallOpcode(long opcode) {
    if (opcode == OPCODE_CALL) {
      return OPCODE_UNCALL;
    }

    if (opcode == OPCODE_UNCALL) {
      return OPCODE_CALL;
    }

    if (opcode == OPCODE_CALL_RESULT_SLOT) {
      return OPCODE_UNCALL_RESULT_SLOT;
    }

    if (opcode == OPCODE_UNCALL_RESULT_SLOT) {
      return OPCODE_CALL_RESULT_SLOT;
    }

    return -1;
  }

  private boolean callOpcode(long opcode) {
    if (opcode == OPCODE_CALL) {
      return true;
    }

    if (opcode == OPCODE_UNCALL) {
      return true;
    }

    if (opcode == OPCODE_CALL_VALUE) {
      return true;
    }

    if (opcode == OPCODE_CALL_VOID) {
      return true;
    }

    if (opcode == OPCODE_CALL_RESULT_SLOT) {
      return true;
    }

    return opcode == OPCODE_UNCALL_RESULT_SLOT;
  }

  /// Excludes suffixes and maps each stable identity into a fresh zero target table.
  public SourceCallRelocationLinkPlan materializeSourceCallRelocationLinkProducts(
    long localFunctionCount,
    long compiledFunctionCount,
    long compiledInstructionCount,
    borrow mut words instructionRows,
    long relocationCount,
    borrow mut words relocationRows,
    borrow mut words relocationOwners,
    borrow byteview relocationIdentities,
    long finalFunctionCount,
    borrow byteview functionIdentities,
    borrow mut words hashSlots,
    borrow mut words hashFunctions,
    borrow mut words resolvedInstructionTargets
  ) {
    assert(-1 < relocationCount);
    assert(relocationCount < MAX_RELOCATIONS + 1);
    assert(bufferLength(relocationRows) == 768);
    assert(bufferLength(relocationOwners) == MAX_RELOCATIONS);
    assert(bufferLength(resolvedInstructionTargets) == MAX_CLOSURE_INSTRUCTIONS);
    RetainedFunctionProduct retained = retainLocalFunctionProduct(
      localFunctionCount,
      compiledFunctionCount,
      compiledInstructionCount,
      instructionRows
    );
    region staging = new region(/* bytes= */ 1576960, /* allocations= */ 3);
    words identityTargets = allocate(staging, /* length= */ 65536);
    words stagedTargets = allocate(staging, MAX_CLOSURE_INSTRUCTIONS);
    words stagedTargetRows = allocate(staging, /* length= */ 512);
    long stagedTargetCount = 0;
    resolveImportedIdentityFunctionTargets(
      relocationCount,
      relocationIdentities,
      finalFunctionCount,
      functionIdentities,
      hashSlots,
      hashFunctions,
      identityTargets
    );
    long relocation = 0;
    while (relocation < relocationCount) limit MAX_RELOCATIONS {
      long owner = relocationOwners[relocation];
      long ownerInstruction = relocationRows[relocation];
      assert(-1 < owner);
      assert(owner < localFunctionCount);
      assert(-1 < ownerInstruction);
      long selected = -1;
      long ownerOrdinal = 0;
      long instruction = 0;
      while (instruction < retained.instructionCount) limit 4096 {
        if (instructionRows[instruction] == owner) {
          if (instructionRows[4096 + instruction] == 0) {
            if (ownerOrdinal == ownerInstruction) {
              assert(selected == -1);
              selected = instruction;
            }

            ownerOrdinal += 1;
          }
        }

        instruction += 1;
      }

      assert(-1 < selected);
      assert(callOpcode(instructionRows[12288 + selected]));
      long prior = 0;
      while (prior < relocation) limit MAX_RELOCATIONS {
        long priorOwner = relocationOwners[prior];
        long priorInstruction = relocationRows[prior];
        if (priorOwner == owner) {
          assert(priorInstruction != ownerInstruction);
        }

        prior += 1;
      }

      set(stagedTargets, selected, identityTargets[relocation]);
      set(stagedTargetRows, stagedTargetCount, selected);
      stagedTargetCount += 1;
      long inverseOpcode = inverseCallOpcode(instructionRows[12288 + selected]);
      if (-1 < inverseOpcode) {
        long forwardCount = 0;
        long inverseCount = 0;
        long directionInstruction = 0;
        while (directionInstruction < retained.instructionCount) limit 4096 {
          if (instructionRows[directionInstruction] == owner) {
            if (instructionRows[4096 + directionInstruction] == 0) {
              forwardCount += 1;
            } else {
              inverseCount += 1;
            }
          }

          directionInstruction += 1;
        }

        assert(forwardCount == inverseCount);
        assert(ownerInstruction < forwardCount - 1);
        long inverseOwnerInstruction = forwardCount - ownerInstruction - 2;
        long inverseOrdinal = 0;
        long inverseSelected = -1;
        directionInstruction = 0;
        while (directionInstruction < retained.instructionCount) limit 4096 {
          if (instructionRows[directionInstruction] == owner) {
            if (instructionRows[4096 + directionInstruction] == 1) {
              if (inverseOrdinal == inverseOwnerInstruction) {
                assert(inverseSelected == -1);
                inverseSelected = directionInstruction;
              }

              inverseOrdinal += 1;
            }
          }

          directionInstruction += 1;
        }

        assert(-1 < inverseSelected);
        assert(instructionRows[12288 + inverseSelected] == inverseOpcode);
        set(stagedTargets, inverseSelected, identityTargets[relocation]);
        set(stagedTargetRows, stagedTargetCount, inverseSelected);
        stagedTargetCount += 1;
      }

      relocation += 1;
    }

    long target = 0;
    while (target < stagedTargetCount) limit 512 {
      assert(resolvedInstructionTargets[stagedTargetRows[target]] == 0);
      target += 1;
    }

    target = 0;
    while (target < stagedTargetCount) limit 512 {
      long targetRow = stagedTargetRows[target];
      set(resolvedInstructionTargets, targetRow, stagedTargets[targetRow]);
      target += 1;
    }

    drop(stagedTargetRows);
    drop(stagedTargets);
    drop(identityTargets);
    drop(staging);
    return new SourceCallRelocationLinkPlan(
      retained.functionCount,
      retained.instructionCount,
      retained.excludedFunctionCount,
      relocationCount
    );
  }
}
