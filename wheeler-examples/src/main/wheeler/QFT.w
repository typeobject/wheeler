// Quantum Fourier Transform implementation
quantum class QFT {
    qureg register;
    let int size;

    // Quantum Fourier Transform circuit
    quantum void applyQFT() {
        // Apply QFT operations
        quantum {
            // First apply Hadamard and controlled rotations
            for (int i = 0; i < size; i++) {
                H(register[i]);

                for (int j = i + 1; j < size; j++) {
                    // Controlled phase rotation
                    controlledPhase(register[i], register[j], Math.PI / Math.pow(2, j-i));
                }
            }

            // Then swap qubits
            for (int i = 0; i < size/2; i++) {
                swap(register[i], register[size-1-i]);
            }
        }
    }

    // Inverse QFT
    quantum void applyInverseQFT() {
        quantum {
            // Reverse operations in opposite order
            for (int i = 0; i < size/2; i++) {
                swap(register[i], register[size-1-i]);
            }

            for (int i = size-1; i >= 0; i--) {
                for (int j = size-1; j > i; j--) {
                    controlledPhase(register[i], register[j], -Math.PI / Math.pow(2, j-i));
                }
                H(register[i]);
            }
        }
    }

    // Test QFT with known state
    quantum void testQFT() {
        quantum {
            // Prepare test state
            prepare register |1010⟩;

            // Apply QFT
            applyQFT();

            // Verify state properties
            assert checkPhaseAmplitudes(register);

            // Return to initial state
            applyInverseQFT();

            // Verify perfect reversal
            assert measure(register) == |1010⟩;
        }
    }
}