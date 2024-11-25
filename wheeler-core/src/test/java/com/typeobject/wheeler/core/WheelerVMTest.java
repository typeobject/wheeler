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
        // Create a simple program that pushes two numbers and adds them
        byte[] program = new byte[48]; // 3 instructions * 16 bytes each

        // PUSH 5
        Instruction push1 = new Instruction(
                InstructionSet.PUSH,
                InstructionSet.Flags.FORWARD,
                (short)0,
                5L,
                0
        );

        // PUSH 3
        Instruction push2 = new Instruction(
                InstructionSet.PUSH,
                InstructionSet.Flags.FORWARD,
                (short)0,
                3L,
                0
        );

        // ADD
        Instruction add = new Instruction(
                InstructionSet.ADD,
                InstructionSet.Flags.FORWARD,
                (short)0,
                0L,
                0
        );

        System.arraycopy(push1.toBytes(), 0, program, 0, 16);
        System.arraycopy(push2.toBytes(), 0, program, 16, 16);
        System.arraycopy(add.toBytes(), 0, program, 32, 16);

        vm.loadProgram(program);
        vm.execute();

        WheelerThread mainThread = new WheelerThread(0, memory);
        assertEquals(8L, mainThread.getStack().peek(), "Stack should contain sum of 5 + 3");
    }
}