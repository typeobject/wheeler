// Hybrid quantum-classical neural network implementation
hybrid class QuantumNeuralNetwork {
    // Classical network components
    private classical let Layer[] classicalLayers;
    private classical let Optimizer optimizer;
    private classical let double learningRate;

    // Quantum circuit components
    private quantum let QuantumLayer[] quantumLayers;
    private qureg mainRegister;
    private qureg ancillaRegister;

    // Training state
    private hist<TrainingState> history;
    private classical let int epoch = 0;

    // Layer definitions
    private static class Layer {
        let double[][] weights;
        let double[] biases;
        let ActivationType activation;

        pure Layer(int inputSize, int outputSize, ActivationType activation) {
            this.weights = new double[inputSize][outputSize];
            this.biases = new double[outputSize];
            this.activation = activation;
        }

        classical double[] forward(double[] input) {
            return applyActivation(matrixMultiply(input, weights) + biases, activation);
        }
    }

    private static class QuantumLayer {
        let int numQubits;
        let RotationType rotationType;
        let EntanglementPattern entanglement;

        quantum void apply(qureg register) {
            quantum {
                // Apply single qubit rotations
                for (int i = 0; i < numQubits; i++) {
                    applyRotation(register[i], rotationType);
                }

                // Apply entangling gates
                applyEntanglement(register, entanglement);
            }
        }
    }

    // Constructor
    hybrid QuantumNeuralNetwork(int inputSize, int[] classicalSizes, int numQubits) {
        // Initialize classical layers
        classical {
            classicalLayers = new Layer[2];
            classicalLayers[0] = new Layer(inputSize, classicalSizes[0], ActivationType.RELU);
            classicalLayers[1] = new Layer(numQubits, classicalSizes[1], ActivationType.SOFTMAX);

            optimizer = new AdamOptimizer(learningRate);
        }

        // Initialize quantum layers
        quantum {
            quantumLayers = new QuantumLayer[3];
            for (int i = 0; i < quantumLayers.length; i++) {
                quantumLayers[i] = new QuantumLayer(
                    numQubits,
                    RotationType.ARBITRARY,
                    EntanglementPattern.ALTERNATING
                );
            }

            mainRegister = new qureg(numQubits);
            ancillaRegister = new qureg(numQubits/2);
        }
    }

    // Forward pass combining classical and quantum computations
    hybrid double[] forward(double[] input, bool isTraining) {
        // Classical pre-processing
        classical {
            // First classical layer
            input = classicalLayers[0].forward(input);

            // Record intermediate state if training
            if (isTraining) {
                history.recordActivations(0, input);
            }
        }

        // Quantum processing
        quantum {
            transaction {
                // Encode classical data into quantum state
                qureg state = encode(input, mainRegister);

                // Apply quantum layers with potential for reversibility
                for (int i = 0; i < quantumLayers.length; i++) {
                    // Apply quantum layer
                    quantumLayers[i].apply(state);

                    // Use ancilla for intermediate computations
                    if (isTraining) {
                        recordLayerState(state, ancillaRegister, i);
                    }
                }

                // Measure final quantum state
                let quantumOutput = measure state;

                // Clean up ancilla if used
                if (isTraining) {
                    uncompute {
                        clean ancillaRegister;
                    }
                }

                commit;
            }
        }

        // Classical post-processing
        classical {
            let output = classicalLayers[1].forward(quantumOutput);

            if (isTraining) {
                history.recordActivations(1, output);
            }

            return output;
        }
    }

    // Training step combining forward and backward passes
    hybrid void trainingStep(double[] inputs, double[] targets, double learningRate) {
        // Forward pass with training flag
        let outputs = forward(inputs, true);

        // Compute loss
        classical {
            double loss = computeLoss(outputs, targets);

            // Compute gradients
            let gradients = calculateGradients(
                outputs,
                targets,
                history.getActivations()
            );

            // Update classical parameters
            optimizer.update(classicalLayers, gradients, learningRate);

            // Record training state
            let state = new TrainingState(
                epoch,
                loss,
                gradients,
                outputs
            );
            history.record(state);
        }

        // Update quantum parameters
        quantum {
            updateQuantumParameters(
                quantumLayers,
                history.getGradients(),
                learningRate
            );
        }

        epoch++;
    }

    // Quantum utility methods
    quantum private void recordLayerState(qureg state, qureg ancilla, int layer) {
        quantum {
            // Store layer state in ancilla
            for (int i = 0; i < ancilla.size; i++) {
                CNOT(state[i], ancilla[i]);
            }
        }
    }

    quantum private void updateQuantumParameters(
        QuantumLayer[] layers,
        double[] gradients,
        double learningRate
    ) {
        quantum {
            for (int i = 0; i < layers.length; i++) {
                // Update rotation angles
                updateRotationAngles(
                    layers[i],
                    gradients,
                    learningRate
                );

                // Update entanglement pattern if needed
                if (shouldUpdateEntanglement(gradients)) {
                    updateEntanglementPattern(layers[i]);
                }
            }
        }
    }

    // Clean up old history periodically
    pure void maintenance() {
        uncompute {
            clean history before epoch - 1000;
        }
    }
}