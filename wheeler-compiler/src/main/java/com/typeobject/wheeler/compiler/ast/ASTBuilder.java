package com.typeobject.wheeler.compiler.ast;

import com.typeobject.wheeler.compiler.ErrorReporter;
import com.typeobject.wheeler.compiler.antlr.WheelerParser.CompilationUnitContext;
import com.typeobject.wheeler.compiler.ast.classical.declarations.ClassDeclaration;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

public class ASTBuilder {
    private final Path sourcePath;
    private final ErrorReporter errorReporter;

    public ASTBuilder(Path sourcePath, ErrorReporter errorReporter) {
        this.sourcePath = sourcePath;
        this.errorReporter = errorReporter;
    }

    public ClassDeclaration.Builder classDeclaration(Position position, String name) {
        return new ClassDeclaration.Builder(name).position(position);
    }

    public CompilationUnit buildCompilationUnit(CompilationUnitContext ctx) {
        // Create position from context
        Position position = new Position(
                ctx.getStart().getLine(),
                ctx.getStart().getCharPositionInLine(),
                sourcePath.toString()
        );

        // Build the compilation unit
        return new CompilationUnit(
                position,
                List.of(), // annotations
                null, // package name will be filled from context
                new ArrayList<>(), // imports will be filled from context
                new ArrayList<>() // declarations will be filled from context
        );
    }
}