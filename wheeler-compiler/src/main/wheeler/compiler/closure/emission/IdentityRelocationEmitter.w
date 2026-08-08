//! Resolves imported callable identities and rewrites linked code in one atomic target pass.

module wheeler.compiler.closure.identity_relocation_emitter;

import wheeler.compiler.closure.callable_function_rows;
import wheeler.compiler.closure.linked_instruction_code;

classical class IdentityRelocationEmitter {
  private const long FUNCTION_IDENTITY_BYTES = 131072;
  private const long HASH_SLOTS = 8192;
  private const long MAX_RELOCATIONS = 4096;
  private const long RELOCATION_ROWS = 131072;
  private const long TARGET_ROWS = 65536;

  /// Maps stable identities to final rows before changing a single code operand.
  public void rewriteImportedIdentityRelocations(
    long functionCount,
    long instructionCount,
    borrow mut words closureInstructionRows,
    long relocationCount,
    borrow mut words relocationRows,
    borrow byteview relocationIdentities,
    borrow byteview functionIdentities,
    borrow mut words hashSlots,
    borrow mut words hashFunctions,
    borrow mut words targetRows,
    borrow mut bytes linkedCode,
    long codeStart
  ) {
    assert(-1 < relocationCount);
    assert(relocationCount < MAX_RELOCATIONS + 1);
    assert(bufferLength(relocationRows) == RELOCATION_ROWS);
    assert(bufferLength(relocationIdentities) == FUNCTION_IDENTITY_BYTES);
    assert(bufferLength(functionIdentities) == FUNCTION_IDENTITY_BYTES);
    assert(bufferLength(hashSlots) == HASH_SLOTS);
    assert(bufferLength(hashFunctions) == HASH_SLOTS);
    assert(bufferLength(targetRows) == TARGET_ROWS);
    resolveImportedIdentityFunctionTargets(
      relocationCount,
      relocationIdentities,
      functionCount,
      functionIdentities,
      hashSlots,
      hashFunctions,
      targetRows
    );

    long relocation = 0;
    while (relocation < relocationCount) limit MAX_RELOCATIONS {
      assert(-1 < targetRows[relocation]);
      assert(targetRows[relocation] < functionCount);
      set(relocationRows, 65536 + relocation, targetRows[relocation]);
      relocation += 1;
    }

    rewriteImportedInstructionTargetsAt(
      functionCount,
      instructionCount,
      closureInstructionRows,
      relocationCount,
      relocationRows,
      linkedCode,
      codeStart
    );
  }
}
