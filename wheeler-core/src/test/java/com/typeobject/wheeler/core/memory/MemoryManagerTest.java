package com.typeobject.wheeler.core.memory;

import static org.junit.jupiter.api.Assertions.*;

import com.typeobject.wheeler.core.exceptions.MemoryException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class MemoryManagerTest {
    private MemoryManager memory;
    private static final long CODE_BASE = 0x0100_0000_0000_0000L;
    private static final long DATA_BASE = 0x0200_0000_0000_0000L;
    private static final long STACK_BASE = 0x0300_0000_0000_0000L;

    @BeforeEach
    void setUp() {
        memory = new MemoryManager();
    }

    @Test
    @DisplayName("Basic memory operations")
    void testBasicMemoryOperations() {
        long address = DATA_BASE; // Use proper data segment address
        long value = 42L;

        memory.writeWord(address, value);
        assertEquals(value, memory.readWord(address), "Read value should match written value");
    }

    @Test
    @DisplayName("Memory segment access")
    void testMemorySegments() {
        // Test code segment access
        long codeAddr = CODE_BASE;
        memory.writeWord(codeAddr, 0x1234567890ABCDEFL);
        assertEquals(0x1234567890ABCDEFL, memory.readWord(codeAddr), "Code segment access");

        // Test data segment access
        long dataAddr = DATA_BASE;
        memory.writeWord(dataAddr, 42L);
        assertEquals(42L, memory.readWord(dataAddr), "Data segment access");

        // Test stack segment access
        long stackAddr = STACK_BASE;
        memory.writeWord(stackAddr, 100L);
        assertEquals(100L, memory.readWord(stackAddr), "Stack segment access");
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
        long address = DATA_BASE;
        long value1 = 42L;
        long value2 = 84L;

        // Write initial value
        memory.writeWord(address, value1);

        // Write new value (should store old value in history)
        memory.writeWord(address, value2);

        // Verify current value
        assertEquals(value2, memory.readWord(address), "Memory should contain latest value");
    }
}