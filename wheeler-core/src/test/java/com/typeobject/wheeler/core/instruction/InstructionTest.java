package com.typeobject.wheeler.core.instruction;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class InstructionTest {
    @Test
    @DisplayName("Instruction encoding/decoding")
    void testInstructionEncodingDecoding() {
        byte opcode = InstructionSet.PUSH;
        byte flags = InstructionSet.Flags.FORWARD;
        short registers = (short)0x1234;
        long operand = 42L;
        int history = 0x5678;

        Instruction inst = new Instruction(opcode, flags, registers, operand, history);
        byte[] encoded = inst.toBytes();
        Instruction decoded = Instruction.fromBytes(encoded);

        assertEquals(opcode, decoded.getOpcode(), "Opcode should match");
        assertEquals(flags, decoded.getFlags(), "Flags should match");
        assertEquals(registers, decoded.getRegisters(), "Registers should match");
        assertEquals(operand, decoded.getOperand(), "Operand should match");
        assertEquals(history, decoded.getHistory(), "History should match");
    }

    @Test
    @DisplayName("Instruction flags")
    void testInstructionFlags() {
        Instruction forward = new Instruction(
                InstructionSet.ADD,
                InstructionSet.Flags.FORWARD,
                (short)0,
                0L,
                0
        );

        Instruction reverse = new Instruction(
                InstructionSet.ADD,
                InstructionSet.Flags.REVERSE,
                (short)0,
                0L,
                0
        );

        assertTrue(forward.isForward(), "Instruction should be forward");
        assertFalse(reverse.isForward(), "Instruction should be reverse");
    }
}