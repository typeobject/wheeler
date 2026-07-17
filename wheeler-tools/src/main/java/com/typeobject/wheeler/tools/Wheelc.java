package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import java.nio.file.Files;
import java.nio.file.Path;

/** Compile one Wheeler source file to a canonical .wbc artifact. */
public final class Wheelc {
  private Wheelc() {}

  public static void main(String[] args) throws Exception {
    if (args.length != 1 && args.length != 3) {
      System.err.println("Usage: wheelc <source.w> [-o output.wbc]");
      System.exit(2);
    }
    Path source = Path.of(args[0]);
    Path output = args.length == 3
        ? outputArgument(args)
        : replaceExtension(source, ".wbc");
    byte[] bytecode = new WheelerCompiler().compileToBytecode(source);
    Path parent = output.toAbsolutePath().getParent();
    if (parent != null) {
      Files.createDirectories(parent);
    }
    Files.write(output, bytecode);
    System.out.println("wrote " + output + " (" + bytecode.length + " bytes)");
  }

  private static Path outputArgument(String[] args) {
    if (!args[1].equals("-o")) {
      throw new IllegalArgumentException("Expected -o before output path");
    }
    return Path.of(args[2]);
  }

  private static Path replaceExtension(Path source, String extension) {
    String name = source.getFileName().toString();
    int dot = name.lastIndexOf('.');
    String base = dot < 0 ? name : name.substring(0, dot);
    return source.resolveSibling(base + extension);
  }
}
