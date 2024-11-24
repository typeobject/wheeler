package com.typeobject.wheeler.tools.wheelc;

import com.typeobject.wheeler.compiler.CompilerOptions;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class WheelerCompilerTool {
  public static void main(String[] args) {
    if (args.length == 0) {
      System.err.println("Usage: wheelc [options] <source files>");
      System.exit(1);
    }

    // Parse command line arguments
    List<File> sourceFiles = new ArrayList<>();
    boolean printAST = false;
    boolean verbose = false;

    for (String arg : args) {
      if (arg.startsWith("-")) {
        switch (arg) {
          case "--print-ast" -> printAST = true;
          case "--verbose" -> verbose = true;
          default -> {
            System.err.println("Unknown option: " + arg);
            System.exit(1);
          }
        }
      } else {
        sourceFiles.add(new File(arg));
      }
    }

    // Create and run compiler
    CompilerOptions options = new CompilerOptions(printAST, verbose);
    WheelerCompiler compiler = new WheelerCompiler(options);
    boolean success = compiler.compile(sourceFiles);

    System.exit(success ? 0 : 1);
  }
}
