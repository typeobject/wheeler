package com.typeobject.wheeler.tools.wheel;

import com.typeobject.wheeler.core.WVM;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class WheelerVM {
  public static void main(String[] args) {
    if (args.length != 1) {
      System.err.println("Usage: wheel <program.wb>");
      System.exit(1);
    }

    try {
      byte[] bytecode = Files.readAllBytes(Path.of(args[0]));
      WVM vm = new WVM();
      vm.loadProgram(bytecode);
      vm.execute();
    } catch (IOException e) {
      System.err.println("Error loading program: " + e.getMessage());
      System.exit(1);
    }
  }
}
