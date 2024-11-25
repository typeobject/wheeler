package com.typeobject.wheeler.core;

import com.typeobject.wheeler.core.instruction.Instruction;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class WheelerVMTest {
    private WheelerVM vm;

    @BeforeEach
    void setUp() {
        vm = new WheelerVM();
    }

    @Test
    @DisplayName("Basic program loading")
    void testProgramLoading() {
        byte[] bytecode = new byte[Instruction.SIZE];
        vm.loadProgram(bytecode);
    }
}