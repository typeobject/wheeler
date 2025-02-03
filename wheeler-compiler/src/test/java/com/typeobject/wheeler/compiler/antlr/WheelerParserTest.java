package com.typeobject.wheeler.compiler.antlr;

import static org.junit.jupiter.api.Assertions.*;

import com.typeobject.wheeler.compiler.CompilerErrorListener;
import com.typeobject.wheeler.compiler.ErrorReporter;
import org.antlr.v4.runtime.CharStreams;
import org.antlr.v4.runtime.CommonTokenStream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class WheelerParserTest {
    private ErrorReporter errorReporter;

    @BeforeEach
    void setUp() {
        errorReporter = new ErrorReporter();
    }

    @Test
    void testEmptyClass() {
        String input = "class Test {}";
        WheelerParser.CompilationUnitContext ctx = parse(input);
        assertNotNull(ctx);
        assertEquals(1, ctx.typeDeclaration().size(), "Should have one class declaration");
        assertFalse(errorReporter.hasErrors(), "Should not have errors: " + errorReporter.getErrors());
    }

    @Test
    void testClassWithField() {
        String input = """
            class Test {
                private int x;
            }
            """;
        WheelerParser.CompilationUnitContext ctx = parse(input);
        assertNotNull(ctx, "Should have a valid context");
        assertFalse(errorReporter.hasErrors(), "Should not have errors: " + errorReporter.getErrors());
    }

    @Test
    void testClassWithMethod() {
        String input = """
            class Test {
                public void test() {
                    return;
                }
            }
            """;
        WheelerParser.CompilationUnitContext ctx = parse(input);
        assertNotNull(ctx, "Should have a valid context");
        assertFalse(errorReporter.hasErrors(), "Should not have errors: " + errorReporter.getErrors());
    }

    @Test
    void testQuantumBlock() {
        String input = """
            class Test {
                quantum void test() {
                    quantum {
                        H q1;
                        CNOT q1, q2;
                    }
                }
            }
            """;
        WheelerParser.CompilationUnitContext ctx = parse(input);
        assertNotNull(ctx, "Should have a valid context");
        assertFalse(errorReporter.hasErrors(), "Should not have errors: " + errorReporter.getErrors());
    }

    @Test
    void testInvalidSyntax() {
        String input = "class Test { int x }"; // Missing semicolon
        WheelerParser.CompilationUnitContext ctx = parse(input);
        assertNotNull(ctx, "Should have a valid context");
        assertTrue(errorReporter.hasErrors(), "Should have errors: " + errorReporter.getErrors());
    }

    @Test
    void testComplexClassWithImports() {
        String input = """
            package com.example;
            
            import quantum.gates.*;
            import classical.math.Complex;
            
            public class QuantumCircuit {
                private qureg register;
                
                public QuantumCircuit(int size) {
                    register = new qureg[size];
                }
                
                quantum void applyHadamard(int index) {
                    quantum {
                        H register[index];
                    }
                }
            }
            """;
        WheelerParser.CompilationUnitContext ctx = parse(input);
        assertNotNull(ctx, "Should have a valid context");
        assertFalse(errorReporter.hasErrors(), "Should not have errors: " + errorReporter.getErrors());
    }

    @Test
    void testQuantumStateDeclaration() {
        String input = """
            class Test {
                void prepare() {
                    state psi = (1/√2)|0⟩ + (1/√2)|1⟩;
                }
            }
            """;
        WheelerParser.CompilationUnitContext ctx = parse(input);
        assertNotNull(ctx, "Should have a valid context");
        assertFalse(errorReporter.hasErrors(), "Should not have errors: " + errorReporter.getErrors());
    }

    private WheelerParser.CompilationUnitContext parse(String input) {
        WheelerLexer lexer = new WheelerLexer(CharStreams.fromString(input));
        lexer.removeErrorListeners();
        lexer.addErrorListener(new CompilerErrorListener(errorReporter));

        CommonTokenStream tokens = new CommonTokenStream(lexer);
        WheelerParser parser = new WheelerParser(tokens);
        parser.removeErrorListeners();
        parser.addErrorListener(new CompilerErrorListener(errorReporter));

        return parser.compilationUnit();
    }
}