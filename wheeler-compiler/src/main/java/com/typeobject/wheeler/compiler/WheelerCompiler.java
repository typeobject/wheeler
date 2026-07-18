package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.ClassicalLowerer.ClassicalContent;
import com.typeobject.wheeler.compiler.SourceModel.SourceProgram;
import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.BytecodeVerifier;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.Map;
import java.util.TreeMap;

/** Compiler for Wheeler's executable source profile. */
public final class WheelerCompiler {
  public Program compile(String source) {
    SourceProgram parsed = new SourceParser().parse(source);
    if (parsed.moduleName() != null || !parsed.imports().isEmpty()) {
      throw new CompilerException(1, "module source requires compileModules");
    }
    return compileParsed(parsed);
  }

  public Program compileModules(Map<String, String> sources, String rootModule) {
    requireModuleInputs(sources, rootModule);
    Map<String, SourceProgram> parsed = new TreeMap<>();
    long totalBytes = 0;
    for (Map.Entry<String, String> entry : sources.entrySet()) {
      String name = entry.getKey();
      String source = entry.getValue();
      if (name == null || source == null
          || !name.matches("[A-Za-z_][A-Za-z0-9_]*(\\.[A-Za-z_][A-Za-z0-9_]*)*")) {
        throw new CompilerException(1, "invalid module name or source");
      }
      totalBytes = checkedModuleBytes(totalBytes, source);
      parsed.put(name, new SourceParser().parse(source, false));
    }
    return compileLinkedModules(parsed, rootModule);
  }

  public Program compileModuleFiles(Map<String, String> sources, String rootModule) {
    requireModuleInputs(sources, rootModule);
    Map<String, String> ordered = new TreeMap<>();
    for (Map.Entry<String, String> entry : sources.entrySet()) {
      if (entry.getKey() == null || entry.getKey().isBlank()
          || entry.getKey().length() > 4_096 || entry.getKey().indexOf('\0') >= 0
          || entry.getValue() == null) {
        throw new CompilerException(1, "invalid module path or source");
      }
      ordered.put(entry.getKey(), entry.getValue());
    }
    Map<String, SourceProgram> parsed = new TreeMap<>();
    long totalBytes = 0;
    for (Map.Entry<String, String> entry : ordered.entrySet()) {
      totalBytes = checkedModuleBytes(totalBytes, entry.getValue());
      SourceProgram module = new SourceParser().parse(entry.getValue(), false);
      if (module.moduleName() == null || parsed.putIfAbsent(module.moduleName(), module) != null) {
        throw new CompilerException(
            1, "module files require unique module declarations: " + entry.getKey());
      }
    }
    return compileLinkedModules(parsed, rootModule);
  }

  public byte[] compileModulesToBytecode(Map<String, String> sources, String rootModule) {
    return new BytecodeWriter().write(compileModules(sources, rootModule));
  }

  private static void requireModuleInputs(Map<String, String> sources, String rootModule) {
    if (sources == null || rootModule == null || sources.isEmpty()
        || sources.size() > SourceModuleLinker.MAX_MODULES) {
      throw new CompilerException(1, "invalid source module set");
    }
  }

  private static long checkedModuleBytes(long total, String source) {
    long result = Math.addExact(total, source.getBytes(StandardCharsets.UTF_8).length);
    if (result > SourceLexer.MAX_SOURCE_BYTES) {
      throw new CompilerException(1, "module sources exceed the 64 MiB input limit");
    }
    return result;
  }

  private Program compileLinkedModules(
      Map<String, SourceProgram> parsed, String rootModule) {
    return compileParsed(new SourceModuleLinker().link(parsed, rootModule));
  }

  private Program compileParsed(SourceProgram parsed) {
    boolean classical = parsed.kind().equals("classical");
    if (classical && (!parsed.quantumRegisters().isEmpty() || !parsed.circuits().isEmpty())) {
      throw new CompilerException(1, "classical programs cannot declare qregs or circuits");
    }
    ClassicalContent classicalContent = new ClassicalLowerer().lower(parsed, classical);
    Program program = classical
        ? Program.classical(
            parsed.name(),
            classicalContent.entryId(),
            classicalContent.globals(),
            classicalContent.recordTypes(),
            classicalContent.variantTypes(),
            classicalContent.arrayTypes(),
            classicalContent.sliceTypes(),
            classicalContent.functions(),
            classicalContent.proofs())
        : new QuantumLowerer().lower(parsed, classicalContent);
    try {
      BytecodeVerifier.verify(program);
    } catch (BytecodeException exception) {
      for (SourceModel.ProofDeclaration proof : parsed.proofs()) {
        if (exception.getMessage().startsWith("Proof " + proof.name() + " failed:")) {
          throw new CompilerException(proof.line(), exception.getMessage());
        }
      }
      for (SourceModel.Function function : parsed.functions()) {
        if (exception.getMessage().startsWith(function.name() + "[")) {
          throw new CompilerException(function.line(), exception.getMessage());
        }
      }
      throw exception;
    }
    return program;
  }

  public Program compile(Path source) throws IOException {
    if (Files.size(source) > SourceLexer.MAX_SOURCE_BYTES) {
      throw new CompilerException(1, "source exceeds the 64 MiB input limit");
    }
    return compile(Files.readString(source));
  }

  public byte[] compileToBytecode(String source) {
    return new BytecodeWriter().write(compile(source));
  }

  public byte[] compileToBytecode(Path source) throws IOException {
    return new BytecodeWriter().write(compile(source));
  }
}
