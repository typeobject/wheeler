package com.typeobject.wheeler.core.instruction;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;


class InstructionTest {
    @Test
    @DisplayName("Instruction encoding/decoding")
    void testInstructionEncodingDecoding() {
        byte opcode = InstructionSet.PUSH;
        byte flags = (byte)(InstructionSet.Flags.FORWARD | InstructionSet.Flags.HISTORY);
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
        byte forwardFlags = (byte)(InstructionSet.Flags.FORWARD | InstructionSet.Flags.HISTORY);
        byte reverseFlags = (byte)(InstructionSet.Flags.REVERSE | InstructionSet.Flags.HISTORY);

        Instruction forward = new Instruction(
                InstructionSet.ADD,
                forwardFlags,
                (short)0,
                0L,
                0
        );

        Instruction reverse = new Instruction(
                InstructionSet.ADD,
                reverseFlags,
                (short)0,
                0L,
                0
        );

        assertTrue(forward.isForward(), "Instruction should be forward");
        assertFalse(reverse.isForward(), "Instruction should be reverse");
    }

    @Test
    @DisplayName("History flag verification")
    void testHistoryFlags() {
        byte noHistoryFlags = InstructionSet.Flags.FORWARD;
        byte withHistoryFlags = (byte)(InstructionSet.Flags.FORWARD | InstructionSet.Flags.HISTORY);

        Instruction noHistory = new Instruction(
                InstructionSet.ADD,
                noHistoryFlags,
                (short)0,
                0L,
                0
        );

        Instruction withHistory = new Instruction(
                InstructionSet.ADD,
                withHistoryFlags,
                (short)0,
                0L,
                0
        );

        assertFalse(noHistory.tracksHistory(), "Instruction should not track history");
        assertTrue(withHistory.tracksHistory(), "Instruction should track history");
    }
}