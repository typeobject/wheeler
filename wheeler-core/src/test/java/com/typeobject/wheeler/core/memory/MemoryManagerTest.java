package com.typeobject.wheeler.core.memory;

import static org.junit.jupiter.api.Assertions.*;

import com.typeobject.wheeler.core.exceptions.MemoryException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class MemoryManagerTest {
    private MemoryManager memory;

    @BeforeEach
    void setUp() {
        memory = new MemoryManager();
    }

    @Test
    @DisplayName("Basic memory operations")
    void testBasicMemoryOperations() {
        long address = 0x0200_0000_0000_0000L; // Data segment
        long value = 42L;

        memory.writeWord(address, value);
        assertEquals(value, memory.readWord(address), "Read value should match written value");
    }

    @Test
    @DisplayName("Memory bounds checking")
    void testMemoryBoundsChecking() {
        long invalidAddress = 0xFFFF_FFFF_FFFF_FFFFL;

        assertThrows(MemoryException.class, () -> {
            memory.readWord(invalidAddress);
        }, "Reading from invalid address should throw MemoryException");
    }

    @Test
    @DisplayName("Memory history tracking")
    void testMemoryHistory() {
        long address = 0x0200_0000_0000_0000L;
        long value1 = 42L;
        long value2 = 84L;

        // Write initial value
        memory.writeWord(address, value1);

        // Write new value (should store old value in history)
        memory.writeWord(address, value2);

        // TODO: Add history verification once history query API is implemented
        assertNotEquals(value1, memory.readWord(address), "Memory should contain updated value");
        assertEquals(value2, memory.readWord(address), "Memory should contain latest value");
    }
}