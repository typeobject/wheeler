proof class QFTProof for QFT {
    // Prove QFT is unitary
    quantum theorem unitarity
        given: size > 0
        shows: isUnitary(getCircuit(applyQFT))
    {
        proof {
            let circuit = getCircuit(applyQFT);

            // Each gate is unitary
            quantum {
                for (int i = 0; i < size; i++) {
                    verify isUnitary(H) because HadamardUnitary;
                    for (int j = i + 1; j < size; j++) {
                        verify isUnitary(Phase(π/(2**(j-i))))
                            because PhaseUnitary;
                    }
                }
            }

            // Composition preserves unitarity
            verify isUnitary(circuit) because UnitaryComposition;
            qed;
        }
    }

    // Prove QFT correctly transforms basis states
    quantum theorem basisTransform
        given: let x = measure(register)
        shows: applyQFT(|x⟩) == 1/√(2^n) ∑_{y=0}^{2^n-1} e^{2πixy/2^n}|y⟩
    {
        proof {
            // Verify initial state
            let initial = |x⟩;
            verify isComputationalBasis(initial);

            // Track state through circuit
            quantum {
                let afterHadamards = applyHadamards(initial);
                verify stateEquals(afterHadamards,
                    1/√(2^n) ∑ e^{iφ(x)}|y⟩)
                    because HadamardEffect;

                let afterPhases = applyPhases(afterHadamards);
                verify stateEquals(afterPhases,
                    1/√(2^n) ∑ e^{2πixy/2^n}|y⟩)
                    because PhaseAccumulation;
            }
            qed;
        }
    }

    // Prove inverse QFT reverses QFT
    quantum theorem perfectInverse
        given: let ψ = currentState(register)
        shows: applyInverseQFT(applyQFT(|ψ⟩)) == |ψ⟩
    {
        proof {
            let initial = |ψ⟩;

            quantum {
                applyQFT();
                let middle = currentState(register);

                applyInverseQFT();
                let final = currentState(register);

                verify stateEquals(final, initial)
                    because InverseProperties;
            }
            qed;
        }
    }

    // Prove complexity bounds
    classical theorem complexity {
        proof {
            // Gate count
            let hadamardCount = size;
            let phaseCount = size * (size - 1) / 2;
            let swapCount = size / 2;

            verify complexity(gates) == O(size^2)
                because "Sum of gate counts";

            // Circuit depth
            verify complexity(depth) == O(size)
                because "Sequential Hadamard layers";

            // Space complexity
            verify complexity(space) == O(size)
                because "Only uses input register";
            qed;
        }
    }
}