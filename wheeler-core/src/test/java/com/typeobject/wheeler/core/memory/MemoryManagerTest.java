package com.typeobject.wheeler.core.memory;

import static org.junit.jupiter.api.Assertions.*;

import com.typeobject.wheeler.core.exceptions.MemoryException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class MemoryManagerTest {
    private MemoryManager memory;
    private static final long DATA_BASE = 0x0200_0000_0000_0000L;
    private static final long STACK_BASE = 0x0300_0000_0000_0000L;

    @BeforeEach
    void setUp() {
        memory = new MemoryManager();
    }

    @Test
    @DisplayName("Basic memory operations")
    void testBasicMemoryOperations() {
        long address = DATA_BASE;
        long value = 42L;

        memory.writeWord(address, value);
        long result = memory.readWord(address);
        assertEquals(value, result, "Memory read should match written value");
    }

    @Test
    @DisplayName("Memory segment boundaries")
    void testMemoryBoundaries() {
        assertThrows(MemoryException.class, () -> memory.readWord(0L),
                "Should throw on invalid address");
        assertThrows(MemoryException.class, () -> memory.readWord(-1L),
                "Should throw on negative address");
    }

    @Test
    @DisplayName("Multiple segment access")
    void testMultipleSegments() {
        // Data segment
        memory.writeWord(DATA_BASE, 1L);
        assertEquals(1L, memory.readWord(DATA_BASE));

        // Stack segment
        memory.writeWord(STACK_BASE, 2L);
        assertEquals(2L, memory.readWord(STACK_BASE));
    }
}