package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.ClassicalLowerer.ClassicalContent;
import com.typeobject.wheeler.compiler.SourceModel.SourceProgram;
import com.typeobject.wheeler.core.bytecode.BytecodeVerifier;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/** Compiler for Wheeler's executable source profile. */
public final class WheelerCompiler {
  public Program compile(String source) {
    SourceProgram parsed = new SourceParser().parse(source);
    boolean classical = parsed.kind().equals("classical");
    if (classical && (!parsed.quantumRegisters().isEmpty() || !parsed.circuits().isEmpty())) {
      throw new CompilerException(1, "classical programs cannot declare qregs or circuits");
    }
    ClassicalContent classicalContent = new ClassicalLowerer().lower(parsed, classical);
    Program program = classical
        ? new Program(
            parsed.name(),
            classicalContent.entryId(),
            classicalContent.globals(),
            classicalContent.recordTypes(),
            classicalContent.functions())
        : new QuantumLowerer().lower(parsed, classicalContent);
    BytecodeVerifier.verify(program);
    return program;
  }

  public Program compile(Path source) throws IOException {
    return compile(Files.readString(source));
  }

  public byte[] compileToBytecode(String source) {
    return new BytecodeWriter().write(compile(source));
  }

  public byte[] compileToBytecode(Path source) throws IOException {
    return new BytecodeWriter().write(compile(source));
  }
}
