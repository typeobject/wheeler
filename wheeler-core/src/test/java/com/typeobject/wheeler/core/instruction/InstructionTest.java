package com.typeobject.wheeler.core.instruction;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;


class InstructionTest {
    @Test
    @DisplayName("Basic instruction creation")
    void testInstructionCreation() {
        byte opcode = InstructionSet.PUSH;
        byte flags = (byte)(InstructionSet.Flags.FORWARD | InstructionSet.Flags.HISTORY);
        short registers = 0;
        long operand = 42L;
        int history = 0;

        Instruction inst = new Instruction(opcode, flags, registers, operand, history);

        assertEquals(opcode, inst.getOpcode());
        assertEquals(flags, inst.getFlags());
        assertEquals(registers, inst.getRegisters());
        assertEquals(operand, inst.getOperand());
        assertEquals(history, inst.getHistory());
    }

    @Test
    @DisplayName("Instruction encoding/decoding")
    void testEncodingDecoding() {
        Instruction original = new Instruction(
                InstructionSet.PUSH,
                (byte)(InstructionSet.Flags.FORWARD | InstructionSet.Flags.HISTORY),
                (short)0,
                42L,
                0
        );

        byte[] encoded = original.toBytes();
        Instruction decoded = Instruction.fromBytes(encoded);

        assertEquals(original.getOpcode(), decoded.getOpcode());
        assertEquals(original.getFlags(), decoded.getFlags());
        assertEquals(original.getRegisters(), decoded.getRegisters());
        assertEquals(original.getOperand(), decoded.getOperand());
        assertEquals(original.getHistory(), decoded.getHistory());
    }
}