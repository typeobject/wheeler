package com.typeobject.wheeler.runtime.quantum;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.LiftedCall;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumOperation;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

/** Bounded ideal little-endian state-vector reference target. */
final class StateVectorEngine {
  public static final int MAX_QUBITS = 20;

  private final Map<Integer, RegisterState> states = new HashMap<>();
  private final Random random;

  StateVectorEngine(long seed) {
    this.random = new Random(seed);
  }

  void prepare(QuantumRegister register, long basisState) {
    if (register.qubits() > MAX_QUBITS) {
      throw new QuantumExecutionException(
          "State-vector simulator supports at most " + MAX_QUBITS + " qubits");
    }
    int size = 1 << register.qubits();
    if (basisState < 0 || basisState >= size) {
      throw new QuantumExecutionException("Basis state does not fit register " + register.name());
    }
    RegisterState state = new RegisterState(register.qubits());
    state.real[Math.toIntExact(basisState)] = 1.0;
    states.put(register.id(), state);
  }

  void apply(Program program, QuantumCircuit circuit, boolean inverse) {
    RegisterState state = state(program.quantumRegister(circuit.registerId()));
    List<QuantumOperation> operations = inverse
        ? circuit.inverseOperations()
        : circuit.operations();
    for (QuantumOperation operation : operations) {
      if (operation instanceof GateOperation gate) {
        applyGate(state, gate);
      } else if (operation instanceof LiftedCall lifted) {
        applyLifted(state, program, lifted);
      } else {
        throw new QuantumExecutionException("Unsupported quantum operation " + operation);
      }
    }
  }

  long measure(QuantumRegister register) {
    RegisterState state = state(register);
    double sample = random.nextDouble();
    double cumulative = 0;
    int selected = state.real.length - 1;
    for (int basis = 0; basis < state.real.length; basis++) {
      cumulative += probability(state, basis);
      if (sample < cumulative) {
        selected = basis;
        break;
      }
    }
    java.util.Arrays.fill(state.real, 0);
    java.util.Arrays.fill(state.imaginary, 0);
    state.real[selected] = 1;
    return selected;
  }

  double[] probabilities(QuantumRegister register) {
    RegisterState state = state(register);
    double[] result = new double[state.real.length];
    for (int basis = 0; basis < result.length; basis++) {
      result[basis] = probability(state, basis);
    }
    return result;
  }

  private RegisterState state(QuantumRegister register) {
    RegisterState state = states.get(register.id());
    if (state == null) {
      throw new QuantumExecutionException("Register is not prepared: " + register.name());
    }
    return state;
  }

  private static double probability(RegisterState state, int basis) {
    return state.real[basis] * state.real[basis]
        + state.imaginary[basis] * state.imaginary[basis];
  }

  private static void applyGate(RegisterState state, GateOperation operation) {
    int first = operation.qubits().getFirst();
    switch (operation.gate()) {
      case H -> applySingle(state, first, 1 / Math.sqrt(2), 0, 1 / Math.sqrt(2), 0,
          1 / Math.sqrt(2), 0, -1 / Math.sqrt(2), 0);
      case X -> applySingle(state, first, 0, 0, 1, 0, 1, 0, 0, 0);
      case Z -> applySingle(state, first, 1, 0, 0, 0, 0, 0, -1, 0);
      case PHASE -> {
        double angle = operation.parameter();
        applySingle(state, first, 1, 0, 0, 0, 0, 0, Math.cos(angle), Math.sin(angle));
      }
      case CPHASE -> applyControlledPhase(
          state, first, operation.qubits().get(1), operation.parameter());
      case CNOT -> applyControlledX(state, first, operation.qubits().get(1));
      case CZ -> applyControlledZ(state, first, operation.qubits().get(1));
      case SWAP -> applySwap(state, first, operation.qubits().get(1));
    }
  }

  @SuppressWarnings("ParameterNumber")
  private static void applySingle(
      RegisterState state,
      int qubit,
      double aReal,
      double aImag,
      double bReal,
      double bImag,
      double cReal,
      double cImag,
      double dReal,
      double dImag) {
    int bit = 1 << qubit;
    for (int zero = 0; zero < state.real.length; zero++) {
      if ((zero & bit) != 0) {
        continue;
      }
      int one = zero | bit;
      double zeroReal = state.real[zero];
      double zeroImag = state.imaginary[zero];
      double oneReal = state.real[one];
      double oneImag = state.imaginary[one];
      state.real[zero] = multiplyReal(aReal, aImag, zeroReal, zeroImag)
          + multiplyReal(bReal, bImag, oneReal, oneImag);
      state.imaginary[zero] = multiplyImag(aReal, aImag, zeroReal, zeroImag)
          + multiplyImag(bReal, bImag, oneReal, oneImag);
      state.real[one] = multiplyReal(cReal, cImag, zeroReal, zeroImag)
          + multiplyReal(dReal, dImag, oneReal, oneImag);
      state.imaginary[one] = multiplyImag(cReal, cImag, zeroReal, zeroImag)
          + multiplyImag(dReal, dImag, oneReal, oneImag);
    }
  }

  private static double multiplyReal(double leftReal, double leftImag, double rightReal, double rightImag) {
    return leftReal * rightReal - leftImag * rightImag;
  }

  private static double multiplyImag(double leftReal, double leftImag, double rightReal, double rightImag) {
    return leftReal * rightImag + leftImag * rightReal;
  }

  private static void applyControlledX(RegisterState state, int control, int target) {
    int controlBit = 1 << control;
    int targetBit = 1 << target;
    for (int basis = 0; basis < state.real.length; basis++) {
      if ((basis & controlBit) != 0 && (basis & targetBit) == 0) {
        swapAmplitude(state, basis, basis | targetBit);
      }
    }
  }

  private static void applyControlledPhase(
      RegisterState state, int control, int target, double angle) {
    int mask = (1 << control) | (1 << target);
    double phaseReal = Math.cos(angle);
    double phaseImaginary = Math.sin(angle);
    for (int basis = 0; basis < state.real.length; basis++) {
      if ((basis & mask) == mask) {
        double real = state.real[basis];
        double imaginary = state.imaginary[basis];
        state.real[basis] = multiplyReal(phaseReal, phaseImaginary, real, imaginary);
        state.imaginary[basis] = multiplyImag(phaseReal, phaseImaginary, real, imaginary);
      }
    }
  }

  private static void applyControlledZ(RegisterState state, int control, int target) {
    int mask = (1 << control) | (1 << target);
    for (int basis = 0; basis < state.real.length; basis++) {
      if ((basis & mask) == mask) {
        state.real[basis] = -state.real[basis];
        state.imaginary[basis] = -state.imaginary[basis];
      }
    }
  }

  private static void applySwap(RegisterState state, int first, int second) {
    int firstBit = 1 << first;
    int secondBit = 1 << second;
    for (int basis = 0; basis < state.real.length; basis++) {
      boolean firstValue = (basis & firstBit) != 0;
      boolean secondValue = (basis & secondBit) != 0;
      if (!firstValue && secondValue) {
        int swapped = (basis | firstBit) & ~secondBit;
        swapAmplitude(state, basis, swapped);
      }
    }
  }

  private static void swapAmplitude(RegisterState state, int left, int right) {
    double real = state.real[left];
    double imaginary = state.imaginary[left];
    state.real[left] = state.real[right];
    state.imaginary[left] = state.imaginary[right];
    state.real[right] = real;
    state.imaginary[right] = imaginary;
  }

  private static void applyLifted(RegisterState state, Program program, LiftedCall call) {
    double[] real = new double[state.real.length];
    double[] imaginary = new double[state.imaginary.length];
    for (int basis = 0; basis < state.real.length; basis++) {
      int target = applyPermutation(
          program, program.function(call.functionId()), call.inverseDirection(), basis, state.qubits);
      real[target] = state.real[basis];
      imaginary[target] = state.imaginary[basis];
    }
    state.real = real;
    state.imaginary = imaginary;
  }

  private static int applyPermutation(
      Program program, FunctionBody function, boolean inverse, int basis, int qubits) {
    long value = basis;
    long mask = (1L << qubits) - 1;
    for (Instruction instruction : function.body(inverse)) {
      Opcode opcode = instruction.opcode();
      if (opcode == Opcode.XOR_CONST) {
        value = (value ^ instruction.operands().get(1)) & mask;
      } else if (opcode == Opcode.CALL || opcode == Opcode.UNCALL) {
        FunctionBody target = program.function(Math.toIntExact(instruction.operands().getFirst()));
        value = applyPermutation(program, target, opcode == Opcode.UNCALL, Math.toIntExact(value), qubits);
      } else if (opcode != Opcode.NOP && opcode != Opcode.RETURN) {
        throw new QuantumExecutionException("Coherent lowering cannot execute " + opcode);
      }
    }
    return Math.toIntExact(value);
  }

  private static final class RegisterState {
    private final int qubits;
    private double[] real;
    private double[] imaginary;

    private RegisterState(int qubits) {
      this.qubits = qubits;
      int size = 1 << qubits;
      this.real = new double[size];
      this.imaginary = new double[size];
    }
  }
}
