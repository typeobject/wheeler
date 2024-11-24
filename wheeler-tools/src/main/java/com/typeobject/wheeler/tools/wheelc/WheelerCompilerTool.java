package com.typeobject.wheeler.tools.wheelc;

import com.typeobject.wheeler.compiler.WheelerCompiler;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class WheelerCompilerTool {
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: wheelc <source.w>");
            System.exit(1);
        }

        try {
            String source = Files.readString(Path.of(args[0]));
            WheelerCompiler compiler = new WheelerCompiler();
            byte[] bytecode = compiler.compile(source);

            String outputFile = args[0].replace(".w", ".wb");
            Files.write(Path.of(outputFile), bytecode);
        } catch (IOException e) {
            System.err.println("Compilation failed: " + e.getMessage());
            System.exit(1);
        }
    }
}