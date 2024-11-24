// Hybrid quantum-classical neural network
hybrid class QuantumNeuralNetwork {
    // Classical network layers
    classical let Layer[] classicalLayers;
    // Quantum circuit layers
    quantum let QuantumLayer[] quantumLayers;

    // Training history
    hist<TrainingState> history;

    // Forward pass combining classical and quantum computations
    hybrid double[] forward(double[] input) {
        // Classical pre-processing
        classical {
            input = classicalLayers[0].forward(input);
            input = activation(input);
        }

        // Quantum middle layers
        quantum {
            // Encode classical data into quantum state
            qureg state = encode(input);

            // Apply quantum layers
            for (QuantumLayer layer : quantumLayers) {
                layer.apply(state);
            }

            // Measure results
            let quantumOutput = measure state;

            // Uncompute ancilla qubits
            uncompute {
                clean state.ancilla;
            }
        }

        // Classical post-processing
        classical {
            return classicalLayers[1].forward(quantumOutput);
        }
    }

    // Hybrid training step
    hybrid void trainingStep(double[] batch) {
        // Forward pass
        let output = forward(batch);

        // Classical backward pass
        classical {
            let gradients = calculateGradients(output, batch);
            updateParameters(gradients);
        }

        // Record training history
        history.record(new TrainingState(output, gradients));
    }
}