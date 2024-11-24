// Quantum Fourier Transform implementation
quantum class QFT {
    qureg register;
    let int size;

    // Apply QFT circuit
    quantum void applyQFT() {
        quantum {
            // Hadamard and controlled rotations
            for (int i = 0; i < size; i++) {
                H(register[i]);

                for (int j = i + 1; j < size; j++) {
                    Phase(register[i], register[j], π/(2**(j-i)));
                }
            }

            // Swap qubits
            for (int i = 0; i < size/2; i++) {
                swap(register[i], register[size-1-i]);
            }
        }
    }

    // Inverse QFT
    quantum void applyInverseQFT() {
        quantum {
            // Reverse operations
            for (int i = 0; i < size/2; i++) {
                swap(register[i], register[size-1-i]);
            }

            for (int i = size-1; i >= 0; i--) {
                for (int j = size-1; j > i; j--) {
                    Phase(register[i], register[j], -π/(2**(j-i)));
                }
                H(register[i]);
            }
        }
    }

    // Test QFT with known state
    quantum void testQFT() {
        quantum {
            // Initialize test state
            prepare register |1010⟩;

            // Apply QFT
            applyQFT();

            // Verify state
            assert checkPhaseAmplitudes(register);

            // Return to initial state
            applyInverseQFT();

            // Verify perfect reversal
            assert measure register == |1010⟩;
        }
    }
}