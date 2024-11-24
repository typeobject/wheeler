package com.typeobject.wheeler.compiler.ast.quantum;

/**
 * Represents a complex number for quantum state amplitudes.
 */
public class ComplexNumber {
    private final double real;
    private final double imaginary;

    public ComplexNumber(double real, double imaginary) {
        this.real = real;
        this.imaginary = imaginary;
    }

    public double getReal() {
        return real;
    }

    public double getImaginary() {
        return imaginary;
    }

    public ComplexNumber add(ComplexNumber other) {
        return new ComplexNumber(
                this.real + other.real,
                this.imaginary + other.imaginary
        );
    }

    public ComplexNumber multiply(ComplexNumber other) {
        return new ComplexNumber(
                this.real * other.real - this.imaginary * other.imaginary,
                this.real * other.imaginary + this.imaginary * other.real
        );
    }

    public ComplexNumber conjugate() {
        return new ComplexNumber(real, -imaginary);
    }

    public double magnitude() {
        return Math.sqrt(real * real + imaginary * imaginary);
    }

    public double phase() {
        return Math.atan2(imaginary, real);
    }

    @Override
    public String toString() {
        if (imaginary == 0) return String.valueOf(real);
        if (real == 0) return imaginary + "i";
        return String.format("%f%+fi", real, imaginary);
    }
}