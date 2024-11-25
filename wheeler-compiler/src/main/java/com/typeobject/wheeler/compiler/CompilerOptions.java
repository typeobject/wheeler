package com.typeobject.wheeler.compiler;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

public class CompilerOptions {
    private Path outputPath = Path.of(".");
    private boolean debugMode = false;
    private boolean printAST = false;
    private boolean optimizationEnabled = true;
    private int optimizationLevel = 1;
    private final List<String> includePaths = new ArrayList<>();
    private final List<String> defines = new ArrayList<>();

    // Support for quantum simulation mode
    private boolean simulationMode = false;
    private int numQubits = 32; // Maximum number of qubits to simulate

    public CompilerOptions() {
    }

    public CompilerOptions addIncludePath(String path) {
        includePaths.add(path);
        return this;
    }

    public CompilerOptions addDefine(String define) {
        defines.add(define);
        return this;
    }

    // Getters
    public Path getOutputPath() {
        return outputPath;
    }

    // Builder pattern for fluent API
    public CompilerOptions setOutputPath(Path outputPath) {
        this.outputPath = outputPath;
        return this;
    }

    public boolean isDebugMode() {
        return debugMode;
    }

    public CompilerOptions setDebugMode(boolean debugMode) {
        this.debugMode = debugMode;
        return this;
    }

    public boolean isPrintAST() {
        return printAST;
    }

    public CompilerOptions setPrintAST(boolean printAST) {
        this.printAST = printAST;
        return this;
    }

    public boolean isOptimizationEnabled() {
        return optimizationEnabled;
    }

    public CompilerOptions setOptimizationEnabled(boolean enabled) {
        this.optimizationEnabled = enabled;
        return this;
    }

    public int getOptimizationLevel() {
        return optimizationLevel;
    }

    public CompilerOptions setOptimizationLevel(int level) {
        if (level < 0 || level > 3) {
            throw new IllegalArgumentException("Optimization level must be between 0 and 3");
        }
        this.optimizationLevel = level;
        return this;
    }

    public List<String> getIncludePaths() {
        return includePaths;
    }

    public List<String> getDefines() {
        return defines;
    }

    public boolean isSimulationMode() {
        return simulationMode;
    }

    public CompilerOptions setSimulationMode(boolean simulationMode) {
        this.simulationMode = simulationMode;
        return this;
    }

    public int getMaxQubits() {
        return numQubits;
    }

    public CompilerOptions setMaxQubits(int numQubits) {
        if (numQubits <= 0) {
            throw new IllegalArgumentException("Number of qubits must be positive");
        }
        this.numQubits = numQubits;
        return this;
    }
}