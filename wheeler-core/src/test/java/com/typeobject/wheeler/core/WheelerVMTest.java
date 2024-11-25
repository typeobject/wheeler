package com.typeobject.wheeler.core;

import static org.junit.jupiter.api.Assertions.*;

import com.typeobject.wheeler.core.instruction.Instruction;
import com.typeobject.wheeler.core.instruction.InstructionSet;
import com.typeobject.wheeler.core.memory.MemoryManager;
import com.typeobject.wheeler.core.thread.WheelerThread;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class WheelerVMTest {
    private WheelerVM vm;
    private MemoryManager memory;

    @BeforeEach
    void setUp() {
        vm = new WheelerVM();
        memory = new MemoryManager();
    }

    @Test
    @DisplayName("Basic VM initialization")
    void testVMInitialization() {
        assertNotNull(vm, "VM should be initialized");
    }

    @Test
    @DisplayName("Simple program execution")
    void testSimpleProgramExecution() {
        // Create a program that pushes two numbers and adds them
        byte[] program = new byte[48]; // 3 instructions * 16 bytes each

        // PUSH 5
        Instruction push1 = new Instruction(
                InstructionSet.PUSH,
                (byte)(InstructionSet.Flags.FORWARD | InstructionSet.Flags.HISTORY),
                (short)0,
                5L,
                0
        );

        // PUSH 3
        Instruction push2 = new Instruction(
                InstructionSet.PUSH,
                (byte)(InstructionSet.Flags.FORWARD | InstructionSet.Flags.HISTORY),
                (short)0,
                3L,
                0
        );

        // ADD
        Instruction add = new Instruction(
                InstructionSet.ADD,
                (byte)(InstructionSet.Flags.FORWARD | InstructionSet.Flags.HISTORY),
                (short)0,
                0L,
                0
        );

        System.arraycopy(push1.toBytes(), 0, program, 0, 16);
        System.arraycopy(push2.toBytes(), 0, program, 16, 16);
        System.arraycopy(add.toBytes(), 0, program, 32, 16);

        // Load program into VM
        vm.loadProgram(program);

        // Create a thread and set its initial state
        WheelerThread thread = new WheelerThread(0, memory);
        thread.setPc(0x0100_0000_0000_0000L); // Set PC to start of code segment

        // Execute until completion
        while (!thread.isTerminated()) {
            Instruction inst = thread.fetchInstruction();
            executeInstruction(thread, inst);
            thread.advancePC();
        }

        // Verify result
        assertEquals(8L, thread.getStack().peek(), "Stack should contain sum of 5 + 3");
    }

    private void executeInstruction(WheelerThread thread, Instruction inst) {
        switch (inst.getOpcode()) {
            case InstructionSet.PUSH:
                thread.getStack().push(inst.getOperand());
                break;

            case InstructionSet.ADD:
                long b = thread.getStack().pop();
                long a = thread.getStack().pop();
                thread.getStack().push(a + b);
                break;

            default:
                throw new IllegalStateException("Unknown opcode: " + inst);
        }
    }
}