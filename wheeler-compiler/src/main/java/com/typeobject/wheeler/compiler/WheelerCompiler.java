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
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
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
    Map<String, String> ordered = new TreeMap<>();
    long totalBytes = 0;
    for (Map.Entry<String, String> entry : sources.entrySet()) {
      String name = entry.getKey();
      String source = entry.getValue();
      if (name == null || source == null
          || !name.matches("[A-Za-z_][A-Za-z0-9_]*(\\.[A-Za-z_][A-Za-z0-9_]*)*")) {
        throw new CompilerException(1, "invalid module name or source");
      }
      totalBytes = checkedModuleBytes(totalBytes, source);
      ordered.put(name, source);
    }
    return compileLinkedModules(SourceModuleSetParser.parse(ordered), rootModule);
  }

  public Program compileModuleFiles(Map<String, String> sources, String rootModule) {
    return compileLinkedModules(parseModuleFiles(sources, rootModule), rootModule);
  }

  /** Compiles a source-only package library with one inert synthetic artifact entry. */
  public Program compileLibraryModuleFiles(Map<String, String> sources, String rootModule) {
    return compileLibraryModules(parseModuleFiles(sources, rootModule), rootModule);
  }

  /** Links one exact package target against only its reachable locked library modules. */
  public Program compilePackageModuleFiles(
      Map<String, String> rootSources,
      Map<String, String> dependencySources,
      String rootModule) {
    return compileLinkedModules(
        parsePackageModuleFiles(rootSources, dependencySources, rootModule), rootModule);
  }

  /** Links one exact package library against only its reachable locked library modules. */
  public Program compilePackageLibraryModuleFiles(
      Map<String, String> rootSources,
      Map<String, String> dependencySources,
      String rootModule) {
    return compileLibraryModules(
        parsePackageModuleFiles(rootSources, dependencySources, rootModule), rootModule);
  }

  private Program compileLibraryModules(
      Map<String, SourceProgram> parsed, String rootModule) {
    SourceProgram library = new SourceModuleLinker().linkLibrary(parsed, rootModule);
    List<SourceModel.Function> functions = new java.util.ArrayList<>(library.functions());
    functions.add(new SourceModel.Function(
        "$library",
        false,
        true,
        false,
        false,
        List.of(),
        "void",
        List.of(new SourceModel.Statement("halt", List.of(), 1)),
        1));
    return compileParsed(new SourceProgram(
        library.moduleName(),
        library.imports(),
        library.name(),
        library.kind(),
        library.states(),
        library.constants(),
        library.records(),
        library.variants(),
        library.arrays(),
        library.slices(),
        library.proofs(),
        functions,
        library.quantumRegisters(),
        library.circuits()));
  }

  public byte[] compileModulesToBytecode(Map<String, String> sources, String rootModule) {
    return new BytecodeWriter().write(compileModules(sources, rootModule));
  }

  private static Map<String, SourceProgram> parseModuleFiles(
      Map<String, String> sources, String rootModule) {
    requireModuleInputs(sources, rootModule);
    return SourceModuleSetParser.parse(moduleFileSources(sources));
  }

  private static Map<String, SourceProgram> parsePackageModuleFiles(
      Map<String, String> rootSources,
      Map<String, String> dependencySources,
      String rootModule) {
    requireModuleInputs(rootSources, rootModule);
    Map<String, String> roots = moduleFileSources(rootSources);
    Map<String, String> candidates = new TreeMap<>(moduleFileSources(dependencySources));
    roots.forEach((name, source) -> {
      if (candidates.putIfAbsent(name, source) != null) {
        throw new CompilerException(1, "root module shadows locked dependency module: " + name);
      }
    });
    if (candidates.size() > 65_535) {
      throw new CompilerException(1, "package module candidate set exceeds 65,535 sources");
    }
    long totalBytes = 0;
    for (String source : candidates.values()) {
      totalBytes = checkedModuleBytes(totalBytes, source);
    }
    Map<String, String> selected = new TreeMap<>();
    collectReachableModule(rootModule, candidates, selected, new HashSet<>());
    if (!selected.keySet().containsAll(roots.keySet())) {
      Set<String> unused = new java.util.TreeSet<>(roots.keySet());
      unused.removeAll(selected.keySet());
      throw new CompilerException(
          1, "package target contains unreachable source modules: " + String.join(", ", unused));
    }
    if (selected.size() > SourceModuleLinker.MAX_MODULES) {
      throw new CompilerException(1, "reachable module set exceeds the 1,024-module limit");
    }
    return SourceModuleSetParser.parse(selected);
  }

  private static Map<String, String> moduleFileSources(Map<String, String> sources) {
    if (sources == null || sources.size() > 65_535) {
      throw new CompilerException(1, "invalid package module candidate set");
    }
    Map<String, String> ordered = new TreeMap<>();
    for (Map.Entry<String, String> entry : sources.entrySet()) {
      if (entry.getKey() == null || entry.getKey().isBlank()
          || entry.getKey().length() > 4_096 || entry.getKey().indexOf('\0') >= 0
          || entry.getValue() == null) {
        throw new CompilerException(1, "invalid module path or source");
      }
      ordered.put(entry.getKey(), entry.getValue());
    }
    Map<String, String> moduleSources = new TreeMap<>();
    long totalBytes = 0;
    for (Map.Entry<String, String> entry : ordered.entrySet()) {
      totalBytes = checkedModuleBytes(totalBytes, entry.getValue());
      String moduleName = SourceModuleHeaderParser.parseSource(entry.getValue()).moduleName();
      if (moduleName == null || moduleSources.putIfAbsent(moduleName, entry.getValue()) != null) {
        throw new CompilerException(
            1, "module files require unique module declarations: " + entry.getKey());
      }
    }
    return Map.copyOf(moduleSources);
  }

  private static void collectReachableModule(
      String name,
      Map<String, String> candidates,
      Map<String, String> selected,
      Set<String> active) {
    if (selected.containsKey(name)) {
      return;
    }
    String source = candidates.get(name);
    if (source == null) {
      throw new CompilerException(1, "imported package module is missing: " + name);
    }
    if (!active.add(name)) {
      throw new CompilerException(1, "package module import cycle includes " + name);
    }
    for (String dependency : SourceModuleHeaderParser.parseSource(source).imports()) {
      collectReachableModule(dependency, candidates, selected, active);
    }
    active.remove(name);
    selected.put(name, source);
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
