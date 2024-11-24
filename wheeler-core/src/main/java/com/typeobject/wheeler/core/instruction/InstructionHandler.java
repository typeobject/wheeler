package com.typeobject.wheeler.core.instruction;

import com.typeobject.wheeler.core.thread.WheelerThread;

public interface InstructionHandler {
    /**
     * Execute the instruction in forward direction.
     * @param thread Current execution thread
     * @param inst Instruction to execute
     * @throws WheelerExecutionException if execution fails
     */
    void executeForward(WheelerThread thread, Instruction inst);

    /**
     * Execute the instruction in reverse direction.
     * @param thread Current execution thread
     * @param inst Instruction to execute
     * @throws WheelerExecutionException if execution fails
     */
    void executeReverse(WheelerThread thread, Instruction inst);

    /**
     * Verify instruction format is valid.
     * @param inst Instruction to verify
     * @throws InvalidInstructionException if instruction is malformed
     */
    default void verify(Instruction inst) throws InvalidInstructionException {
        // Default implementation accepts all instructions
    }
}