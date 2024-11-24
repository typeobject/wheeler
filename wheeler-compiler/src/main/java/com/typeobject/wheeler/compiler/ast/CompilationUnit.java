package com.typeobject.wheeler.compiler.ast;

import com.typeobject.wheeler.compiler.ast.base.Declaration;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

/**
 * Represents a single Wheeler source file. Contains package declaration, imports, and type
 * declarations.
 */
public final class CompilationUnit extends Node {
  private final String sourceFile;
  private final String packageName;
  private final List<ImportDeclaration> imports;
  private final List<Declaration> declarations;

  private CompilationUnit(
      Position position,
      String sourceFile,
      String packageName,
      List<ImportDeclaration> imports,
      List<Declaration> declarations) {
    super(position);
    this.sourceFile = sourceFile;
    this.packageName = packageName;
    this.imports = Collections.unmodifiableList(imports);
    this.declarations = Collections.unmodifiableList(declarations);
  }

  public String getSourceFile() {
    return sourceFile;
  }

  public Optional<String> getPackageName() {
    return Optional.ofNullable(packageName);
  }

  public List<ImportDeclaration> getImports() {
    return imports;
  }

  public List<Declaration> getDeclarations() {
    return declarations;
  }

  @Override
  public <T> T accept(NodeVisitor<T> visitor) {
    return visitor.visitCompilationUnit(this);
  }

  /** Import declaration within a compilation unit. */
  public static final class ImportDeclaration {
    private final Position position;
    private final String qualifiedName;
    private final boolean isStatic;
    private final boolean isWildcard;

    public ImportDeclaration(
        Position position, String qualifiedName, boolean isStatic, boolean isWildcard) {
      this.position = position;
      this.qualifiedName = qualifiedName;
      this.isStatic = isStatic;
      this.isWildcard = isWildcard;
    }

    public Position getPosition() {
      return position;
    }

    public String getQualifiedName() {
      return qualifiedName;
    }

    public boolean isStatic() {
      return isStatic;
    }

    public boolean isWildcard() {
      return isWildcard;
    }

    @Override
    public String toString() {
      StringBuilder sb = new StringBuilder("import ");
      if (isStatic) {
        sb.append("static ");
      }
      sb.append(qualifiedName);
      if (isWildcard) {
        sb.append(".*");
      }
      return sb.toString();
    }
  }

  /** Builder for constructing CompilationUnit instances. */
  public static class Builder {
    private final Position position;
    private final String sourceFile;
    private String packageName;
    private final List<ImportDeclaration> imports = new ArrayList<>();
    private final List<Declaration> declarations = new ArrayList<>();

    public Builder(Position position, String sourceFile) {
      this.position = position;
      this.sourceFile = sourceFile;
    }

    public Builder setPackage(String packageName) {
      this.packageName = packageName;
      return this;
    }

    public Builder addImport(ImportDeclaration importDecl) {
      imports.add(importDecl);
      return this;
    }

    public Builder addImport(
        Position position, String qualifiedName, boolean isStatic, boolean isWildcard) {
      imports.add(new ImportDeclaration(position, qualifiedName, isStatic, isWildcard));
      return this;
    }

    public Builder addDeclaration(Declaration declaration) {
      declarations.add(declaration);
      return this;
    }

    public CompilationUnit build() {
      return new CompilationUnit(position, sourceFile, packageName, imports, declarations);
    }
  }
}
