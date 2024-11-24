package com.typeobject.wheeler.compiler;

public class ASTPrinter implements NodeVisitor<String> {
  private int indentLevel = 0;

  public String print(Node node) {
    return node.accept(this);
  }

  private String indent() {
    return "  ".repeat(indentLevel);
  }

  @Override
  public String visitCompilationUnit(CompilationUnit node) {
    StringBuilder sb = new StringBuilder();

    if (node.getPackage() != null) {
      sb.append(indent()).append("package ").append(node.getPackage()).append("\n");
    }

    for (String imp : node.getImports()) {
      sb.append(indent()).append("import ").append(imp).append("\n");
    }

    for (Declaration decl : node.getDeclarations()) {
      sb.append("\n").append(decl.accept(this));
    }

    return sb.toString();
  }

  @Override
  public String visitClassDeclaration(ClassDeclaration node) {
    indentLevel++;
    StringBuilder sb = new StringBuilder();

    // Print modifiers
    node.getModifiers().forEach(mod -> sb.append(indent()).append(mod).append(" "));

    // Print class header
    sb.append("class ").append(node.getName());
    if (node.getSuperClass() != null) {
      sb.append(" extends ").append(node.getSuperClass().accept(this));
    }
    sb.append(" {\n");

    // Print members
    for (Declaration member : node.getMembers()) {
      sb.append("\n").append(member.accept(this));
    }

    indentLevel--;
    sb.append(indent()).append("}\n");
    return sb.toString();
  }

  @Override
  public String visitQuantumBlock(QuantumBlock node) {
    indentLevel++;
    StringBuilder sb = new StringBuilder();

    sb.append(indent()).append("quantum {\n");
    for (Statement stmt : node.getStatements()) {
      sb.append(stmt.accept(this)).append("\n");
    }

    indentLevel--;
    sb.append(indent()).append("}");
    return sb.toString();
  }

  // Add more visitor methods for other node types...
}
