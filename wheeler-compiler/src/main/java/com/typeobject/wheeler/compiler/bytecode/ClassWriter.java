package com.typeobject.wheeler.compiler.bytecode;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class ClassWriter {
    private final Path outputPath;

    public ClassWriter(Path outputPath) {
        this.outputPath = outputPath;
    }

    public void writeClass(String packageName, String className, byte[] bytecode) throws IOException {
        Path packagePath = outputPath;
        if (packageName != null && !packageName.isEmpty()) {
            packagePath = packagePath.resolve(packageName.replace('.', '/'));
            Files.createDirectories(packagePath);
        }

        Path classFile = packagePath.resolve(className + ".class");
        Files.write(classFile, bytecode);
    }
}