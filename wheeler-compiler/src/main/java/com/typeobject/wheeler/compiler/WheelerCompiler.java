package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.analysis.FlowAnalyzer;
import com.typeobject.wheeler.compiler.analysis.TypeChecker;
import com.typeobject.wheeler.compiler.antlr.WheelerLexer;
import com.typeobject.wheeler.compiler.antlr.WheelerParser;
import com.typeobject.wheeler.compiler.ast.ASTBuilder;
import com.typeobject.wheeler.compiler.ast.CompilationUnit;
import com.typeobject.wheeler.compiler.bytecode.BytecodeGenerator;
import com.typeobject.wheeler.compiler.bytecode.ClassWriter;
import org.antlr.v4.runtime.CharStream;
import org.antlr.v4.runtime.CharStreams;
import org.antlr.v4.runtime.CommonTokenStream;

import java.io.IOException;
import java.nio.file.Path;
import java.util.List;

public class WheelerCompiler {
    private final CompilerOptions options;
    private final ErrorReporter errorReporter;

    public WheelerCompiler(CompilerOptions options) {
        this.options = options;
        this.errorReporter = new ErrorReporter();
    }

    public boolean compile(String source, String fileName) {
        try {
            // 1. Lexical and Syntax Analysis
            CompilationUnit ast = parse(source, fileName);
            if (errorReporter.hasErrors()) {
                return false;
            }

            // 2. Semantic Analysis
            if (!performSemanticAnalysis(ast)) {
                return false;
            }

            // 3. Code Generation
            if (!generateCode(ast)) {
                return false;
            }

            return !errorReporter.hasErrors();
        } catch (Exception e) {
            errorReporter.report("Internal compiler error: " + e.getMessage(), null);
            if (options.isDebugMode()) {
                e.printStackTrace();
            }
            return false;
        }
    }

    private CompilationUnit parse(String source, String fileName) {
        // Create char stream from input
        CharStream input = CharStreams.fromString(source);

        // Create lexer
        WheelerLexer lexer = new WheelerLexer(input);
        lexer.removeErrorListeners();
        lexer.addErrorListener(new CompilerErrorListener(errorReporter));

        // Create token stream
        CommonTokenStream tokens = new CommonTokenStream(lexer);

        // Create parser
        WheelerParser parser = new WheelerParser(tokens);
        parser.removeErrorListeners();
        parser.addErrorListener(new CompilerErrorListener(errorReporter));

        // Parse the input
        WheelerParser.CompilationUnitContext parseTree = parser.compilationUnit();

        if (errorReporter.hasErrors()) {
            return null;
        }

        // Build AST
        ASTBuilder builder = new ASTBuilder(Path.of(fileName), errorReporter);
        return builder.buildCompilationUnit(parseTree);
    }

    private boolean performSemanticAnalysis(CompilationUnit ast) {
        // Type checking
        TypeChecker typeChecker = new TypeChecker(errorReporter);
        typeChecker.check(ast);
        if (errorReporter.hasErrors()) {
            return false;
        }

        // Control flow analysis
        FlowAnalyzer flowAnalyzer = new FlowAnalyzer(errorReporter);
        flowAnalyzer.analyze(ast);
        if (errorReporter.hasErrors()) {
            return false;
        }

        return true;
    }

    private boolean generateCode(CompilationUnit ast) {
        try {
            // Generate bytecode
            BytecodeGenerator generator = new BytecodeGenerator(options, errorReporter);
            byte[] bytecode = generator.generate(ast);

            // Write class file
            ClassWriter writer = new ClassWriter(options.getOutputPath());
            writer.writeClass(ast.getPackage(), ast.getDeclarations().get(0).getName(), bytecode);

            return true;
        } catch (IOException e) {
            errorReporter.report("Failed to write class file: " + e.getMessage(), null);
            return false;
        } catch (Exception e) {
            errorReporter.report("Code generation error: " + e.getMessage(), null);
            return false;
        }
    }

    public List<CompilerError> getErrors() {
        return errorReporter.getErrors();
    }

    public List<CompilerError> getWarnings() {
        return errorReporter.getWarnings();
    }

    // Helper method to print the AST (useful for debugging)
    private void printAST(CompilationUnit ast) {
        if (options.isPrintAST()) {
            ASTPrinter printer = new ASTPrinter();
            System.out.println(printer.print(ast));
        }
    }
}