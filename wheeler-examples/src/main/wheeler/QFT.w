// QFT.wheeler - Implementation
quantum class QFT {
    qureg register;
    let int size;

    // Apply QFT circuit
    quantum void applyQFT() {
        quantum {
            for (int i = 0; i < size; i++) {
                H(register[i]);
                for (int j = i + 1; j < size; j++) {
                    Phase(register[i], register[j], π/(2**(j-i)));
                }
            }

            for (int i = 0; i < size/2; i++) {
                swap(register[i], register[size-1-i]);
            }
        }
    }

    quantum void applyInverseQFT() {
        quantum {
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
}