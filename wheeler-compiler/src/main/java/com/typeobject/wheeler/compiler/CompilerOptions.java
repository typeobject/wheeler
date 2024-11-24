package com.typeobject.wheeler.compiler;

public class CompilerOptions {
  private final boolean printAST;
  private final boolean verbose;

  public CompilerOptions(boolean printAST, boolean verbose) {
    this.printAST = printAST;
    this.verbose = verbose;
  }

  public boolean shouldPrintAST() {
    return printAST;
  }

  public boolean isVerbose() {
    return verbose;
  }
}
