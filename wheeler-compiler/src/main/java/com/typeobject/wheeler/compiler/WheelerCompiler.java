package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.ast.ASTBuilder;
import com.typeobject.wheeler.compiler.ast.CompilationUnit;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.util.List;
import org.antlr.v4.runtime.*;

public class WheelerCompiler {
  private final CompilerOptions options;
  private final ErrorReporter errorReporter;

  public WheelerCompiler(CompilerOptions options) {
    this.options = options;
    this.errorReporter = new ErrorReporter();
  }

  public boolean compile(List<File> sourceFiles) {
    boolean success = true;

    for (File source : sourceFiles) {
      try {
        String sourceText = Files.readString(source.toPath());
        CompilationUnit ast = parseSource(source.getName(), sourceText);

        if (ast != null) {
          printAST(ast);
        } else {
          success = false;
        }
      } catch (IOException e) {
        errorReporter.reportError("Error reading file: " + source.getName());
        success = false;
      }
    }

    return success;
  }

  private CompilationUnit parseSource(String fileName, String source) {
    CharStream input = CharStreams.fromString(source);
    WheelerLexer lexer = new WheelerLexer(input);
    CommonTokenStream tokens = new CommonTokenStream(lexer);
    WheelerParser parser = new WheelerParser(tokens);

    // Set error handlers
    lexer.removeErrorListeners();
    lexer.addErrorListener(new CompilerErrorListener(errorReporter));
    parser.removeErrorListeners();
    parser.addErrorListener(new CompilerErrorListener(errorReporter));

    // Parse and build AST
    WheelerParser.CompilationUnitContext tree = parser.compilationUnit();
    if (errorReporter.hasErrors()) {
      return null;
    }

    // Convert parse tree to AST
    ASTBuilder builder = new ASTBuilder(fileName, errorReporter);
    return builder.visitCompilationUnit(tree);
  }

  private void printAST(CompilationUnit ast) {
    ASTPrinter printer = new ASTPrinter();
    System.out.println(printer.print(ast));
  }
}
