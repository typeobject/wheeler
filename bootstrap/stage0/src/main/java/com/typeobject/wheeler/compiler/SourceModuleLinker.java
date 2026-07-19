package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.ArrayDefinition;
import com.typeobject.wheeler.compiler.SourceModel.Function;
import com.typeobject.wheeler.compiler.SourceModel.Parameter;
import com.typeobject.wheeler.compiler.SourceModel.ProofDeclaration;
import com.typeobject.wheeler.compiler.SourceModel.RecordDefinition;
import com.typeobject.wheeler.compiler.SourceModel.RecordField;
import com.typeobject.wheeler.compiler.SourceModel.SliceDefinition;
import com.typeobject.wheeler.compiler.SourceModel.SourceProgram;
import com.typeobject.wheeler.compiler.SourceModel.Statement;
import com.typeobject.wheeler.compiler.SourceModel.VariantCase;
import com.typeobject.wheeler.compiler.SourceModel.VariantDefinition;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Deterministic dependency-first linker for the initial classical source-module slice. */
final class SourceModuleLinker {
  static final int MAX_MODULES = 1_024;
  private static final Set<String> FUNCTION_REFERENCES =
      Set.of("invoke", "reverse", "call_value", "call_void");
  private static final Set<String> PRIMITIVE_TYPES = Set.of(
      "void", "long", "boolean", "region", "words", "bytes", "byteview", "utf8", "longmap");

  SourceProgram link(Map<String, SourceProgram> modules, String rootName) {
    return link(modules, rootName, true);
  }

  SourceProgram linkLibrary(Map<String, SourceProgram> modules, String rootName) {
    return link(modules, rootName, false);
  }

  private SourceProgram link(
      Map<String, SourceProgram> modules, String rootName, boolean executable) {
    if (modules.isEmpty() || modules.size() > MAX_MODULES) {
      fail("module set must contain between 1 and " + MAX_MODULES + " modules");
    }
    SourceProgram root = modules.get(rootName);
    if (root == null) {
      fail("root module is missing: " + rootName);
    }

    List<String> order = new ArrayList<>();
    visit(rootName, modules, new HashSet<>(), new HashSet<>(), order);
    if (order.size() != modules.size()) {
      Set<String> unused = new java.util.TreeSet<>(modules.keySet());
      unused.removeAll(order);
      fail("module set contains unreachable inputs: " + String.join(", ", unused));
    }

    for (String moduleName : order) {
      validateModule(
          moduleName, modules.get(moduleName), moduleName.equals(rootName), executable);
    }

    List<RecordDefinition> records = new ArrayList<>();
    List<VariantDefinition> variants = new ArrayList<>();
    List<Function> functions = new ArrayList<>();
    Map<String, ArrayDefinition> arrays = new LinkedHashMap<>();
    Map<String, SliceDefinition> slices = new LinkedHashMap<>();
    List<ProofDeclaration> proofs = new ArrayList<>();
    for (String moduleName : order) {
      SourceProgram module = modules.get(moduleName);
      Map<String, String> references = references(moduleName, module, modules);
      Map<String, String> types = typeReferences(moduleName, module, modules);
      for (RecordDefinition record : module.records()) {
        records.add(linkRecord(moduleName, record, types));
      }
      for (VariantDefinition variant : module.variants()) {
        variants.add(linkVariant(moduleName, variant, types));
      }
      for (ArrayDefinition array : module.arrays()) {
        ArrayDefinition linked = linkArray(array, types);
        arrays.putIfAbsent(linked.name(), linked);
      }
      for (SliceDefinition slice : module.slices()) {
        SliceDefinition linked = linkSlice(slice, types);
        slices.putIfAbsent(linked.name(), linked);
      }
      for (Function function : module.functions()) {
        functions.add(linkFunction(moduleName, function, references, types));
      }
      if (moduleName.equals(rootName)) {
        for (ProofDeclaration proof : module.proofs()) {
          proofs.add(new ProofDeclaration(
              proof.name(),
              proof.rule(),
              resolve(references, proof.subject(), proof.line()),
              proof.relatedSubject() == null
                  ? null : resolve(references, proof.relatedSubject(), proof.line()),
              proof.argument(),
              proof.line()));
        }
      }
    }

    return new SourceProgram(
        root.moduleName(),
        root.imports(),
        root.name(),
        root.kind(),
        root.states(),
        root.constants(),
        records,
        variants,
        List.copyOf(arrays.values()),
        List.copyOf(slices.values()),
        proofs,
        functions,
        root.quantumRegisters(),
        root.circuits());
  }

  private static void visit(
      String name,
      Map<String, SourceProgram> modules,
      Set<String> active,
      Set<String> complete,
      List<String> order) {
    if (complete.contains(name)) {
      return;
    }
    if (!active.add(name)) {
      fail("module import cycle includes " + name);
    }
    SourceProgram module = modules.get(name);
    if (module == null) {
      fail("imported module is missing: " + name);
    }
    for (String dependency : module.imports()) {
      visit(dependency, modules, active, complete, order);
    }
    active.remove(name);
    complete.add(name);
    order.add(name);
  }

  private static void validateModule(
      String expectedName, SourceProgram module, boolean root, boolean executable) {
    if (module.moduleName() == null || !module.moduleName().equals(expectedName)) {
      fail("module key/declaration mismatch for " + expectedName);
    }
    if (!module.kind().equals("classical")) {
      fail("source modules currently require the classical domain: " + expectedName);
    }
    long entries = module.functions().stream().filter(Function::entry).count();
    long expectedEntries = root && executable ? 1 : 0;
    if (entries != expectedEntries) {
      fail(root
          ? executable
              ? "root module must declare exactly one entry method"
              : "library root module cannot declare an entry method: " + expectedName
          : "dependency module cannot declare an entry method: " + expectedName);
    }
    for (RecordDefinition record : module.records()) {
      if (record.exported()) {
        record.fields().forEach(field ->
            requirePublicLocalType(module, field.type(), record.line()));
      }
    }
    for (VariantDefinition variant : module.variants()) {
      if (variant.exported()) {
        variant.cases().forEach(variantCase -> variantCase.fields().forEach(field ->
            requirePublicLocalType(module, field.type(), variant.line())));
      }
    }
    for (Function function : module.functions()) {
      if (function.exported()) {
        requirePublicLocalType(module, function.returnType(), function.line());
        function.parameters().forEach(parameter ->
            requirePublicLocalType(module, parameter.type(), function.line()));
      }
    }
    if (!root && (!module.states().isEmpty()
        || !module.proofs().isEmpty()
        || !module.quantumRegisters().isEmpty()
        || !module.circuits().isEmpty())) {
      fail("dependency modules currently contain functions and value types only: " + expectedName);
    }
  }

  private static void requirePublicLocalType(
      SourceProgram module, String type, int line) {
    if (PRIMITIVE_TYPES.contains(type)) {
      return;
    }
    RecordDefinition local = module.records().stream()
        .filter(record -> record.name().equals(type))
        .findFirst()
        .orElse(null);
    if (local != null) {
      if (!local.exported()) {
        throw new CompilerException(line, "public API exposes private record: " + type);
      }
      return;
    }
    VariantDefinition variant = module.variants().stream()
        .filter(candidate -> candidate.name().equals(type))
        .findFirst()
        .orElse(null);
    if (variant != null) {
      if (!variant.exported()) {
        throw new CompilerException(line, "public API exposes private variant: " + type);
      }
      return;
    }
    String element = module.arrays().stream()
        .filter(array -> array.name().equals(type))
        .map(ArrayDefinition::elementType)
        .findFirst()
        .orElseGet(() -> module.slices().stream()
            .filter(slice -> slice.name().equals(type))
            .map(SliceDefinition::elementType)
            .findFirst()
            .orElse(null));
    if (element != null) {
      requirePublicLocalType(module, element, line);
    }
  }

  private static Map<String, String> references(
      String moduleName,
      SourceProgram module,
      Map<String, SourceProgram> modules) {
    Map<String, String> result = new LinkedHashMap<>();
    Set<String> localNames = new HashSet<>();
    Set<String> ambiguous = new HashSet<>();
    for (Function function : module.functions()) {
      localNames.add(function.name());
      String linked = linkedName(moduleName, function.name());
      result.put(function.name(), linked);
      result.put(linked, linked);
    }
    for (String importedName : module.imports()) {
      SourceProgram imported = modules.get(importedName);
      for (Function function : imported.functions()) {
        if (!function.exported()) {
          continue;
        }
        String linked = linkedName(importedName, function.name());
        result.put(linked, linked);
        if (localNames.contains(function.name())) {
          continue;
        }
        if (ambiguous.contains(function.name())) {
          continue;
        }
        String prior = result.putIfAbsent(function.name(), linked);
        if (prior != null && !prior.equals(linked)) {
          result.remove(function.name());
          ambiguous.add(function.name());
        }
      }
    }
    return Map.copyOf(result);
  }

  private static Map<String, String> typeReferences(
      String moduleName,
      SourceProgram module,
      Map<String, SourceProgram> modules) {
    Map<String, String> result = new LinkedHashMap<>();
    Set<String> localNames = new HashSet<>();
    Set<String> ambiguous = new HashSet<>();
    for (RecordDefinition record : module.records()) {
      localNames.add(record.name());
      String linked = linkedName(moduleName, record.name());
      result.put(record.name(), linked);
      result.put(linked, linked);
    }
    for (VariantDefinition variant : module.variants()) {
      localNames.add(variant.name());
      String linked = linkedName(moduleName, variant.name());
      result.put(variant.name(), linked);
      result.put(linked, linked);
    }
    for (String importedName : module.imports()) {
      SourceProgram imported = modules.get(importedName);
      for (RecordDefinition record : imported.records()) {
        addImportedType(result, localNames, ambiguous, importedName,
            record.name(), record.exported());
      }
      for (VariantDefinition variant : imported.variants()) {
        addImportedType(result, localNames, ambiguous, importedName,
            variant.name(), variant.exported());
      }
      imported.arrays().forEach(array -> {
        String element = importedElementType(importedName, imported, array.elementType());
        if (element != null) {
          String linked = element + "[" + array.length() + "]";
          result.putIfAbsent(array.name(), linked);
          result.put(importedName + "::" + array.name(), linked);
        }
      });
      imported.slices().forEach(slice -> {
        String element = importedElementType(importedName, imported, slice.elementType());
        if (element != null) {
          String linked = element + "[]";
          result.putIfAbsent(slice.name(), linked);
          result.put(importedName + "::" + slice.name(), linked);
        }
      });
    }
    module.arrays().forEach(array -> {
      String element = resolveType(result, array.elementType(), array.line());
      result.put(array.name(), element + "[" + array.length() + "]");
    });
    module.slices().forEach(slice -> {
      String element = resolveType(result, slice.elementType(), slice.line());
      result.put(slice.name(), element + "[]");
    });
    return Map.copyOf(result);
  }

  private static String importedElementType(
      String moduleName, SourceProgram module, String element) {
    if (PRIMITIVE_TYPES.contains(element)) {
      return element;
    }
    boolean exportedRecord = module.records().stream()
        .anyMatch(record -> record.name().equals(element) && record.exported());
    boolean exportedVariant = module.variants().stream()
        .anyMatch(variant -> variant.name().equals(element) && variant.exported());
    return exportedRecord || exportedVariant ? linkedName(moduleName, element) : null;
  }

  private static void addImportedType(
      Map<String, String> result,
      Set<String> localNames,
      Set<String> ambiguous,
      String importedName,
      String typeName,
      boolean exported) {
    if (!exported) {
      return;
    }
    String linked = linkedName(importedName, typeName);
    result.put(linked, linked);
    if (localNames.contains(typeName) || ambiguous.contains(typeName)) {
      return;
    }
    String prior = result.putIfAbsent(typeName, linked);
    if (prior != null && !prior.equals(linked)) {
      result.remove(typeName);
      ambiguous.add(typeName);
    }
  }

  private static ArrayDefinition linkArray(
      ArrayDefinition array, Map<String, String> types) {
    String element = resolveType(types, array.elementType(), array.line());
    return new ArrayDefinition(
        element + "[" + array.length() + "]", element, array.length(), array.line());
  }

  private static SliceDefinition linkSlice(
      SliceDefinition slice, Map<String, String> types) {
    String element = resolveType(types, slice.elementType(), slice.line());
    return new SliceDefinition(element + "[]", element, slice.line());
  }

  private static VariantDefinition linkVariant(
      String moduleName, VariantDefinition variant, Map<String, String> types) {
    List<VariantCase> cases = variant.cases().stream()
        .map(variantCase -> new VariantCase(
            variantCase.name(),
            variantCase.fields().stream()
                .map(field -> new RecordField(
                    field.name(), resolveType(types, field.type(), variant.line())))
                .toList()))
        .toList();
    return new VariantDefinition(
        linkedName(moduleName, variant.name()),
        variant.exported(),
        cases,
        variant.line());
  }

  private static RecordDefinition linkRecord(
      String moduleName, RecordDefinition record, Map<String, String> types) {
    List<RecordField> fields = record.fields().stream()
        .map(field -> new RecordField(
            field.name(), resolveType(types, field.type(), record.line())))
        .toList();
    return new RecordDefinition(
        linkedName(moduleName, record.name()), record.exported(), fields, record.line());
  }

  private static Function linkFunction(
      String moduleName,
      Function function,
      Map<String, String> references,
      Map<String, String> types) {
    List<Statement> statements = new ArrayList<>(function.statements().size());
    for (Statement statement : function.statements()) {
      List<String> arguments = new ArrayList<>(statement.arguments());
      if (FUNCTION_REFERENCES.contains(statement.operation())) {
        int target = statement.operation().equals("call_value") ? 1 : 0;
        arguments.set(target, resolve(references, arguments.get(target), statement.line()));
      } else if (statement.operation().equals("local_bind")) {
        arguments.set(2, resolveType(types, arguments.get(2), statement.line()));
      } else if (statement.operation().equals("record_new")
          || statement.operation().equals("variant_new")
          || statement.operation().equals("array_new")) {
        arguments.set(1, resolveType(types, arguments.get(1), statement.line()));
      } else if (statement.operation().equals("variant_tag")
          || statement.operation().equals("variant_get")) {
        arguments.set(2, resolveType(types, arguments.get(2), statement.line()));
      }
      statements.add(new Statement(statement.operation(), arguments, statement.line()));
    }
    return new Function(
        linkedName(moduleName, function.name()),
        function.exported(),
        function.entry(),
        function.test(),
        function.reversible(),
        function.coherent(),
        function.parameters().stream()
            .map(parameter -> new Parameter(
                parameter.name(),
                resolveType(types, parameter.type(), function.line()),
                parameter.mode()))
            .toList(),
        function.testCases(),
        resolveType(types, function.returnType(), function.line()),
        statements,
        function.line());
  }

  private static String resolveType(
      Map<String, String> references, String name, int line) {
    if (PRIMITIVE_TYPES.contains(name)) {
      return name;
    }
    String resolved = references.get(name);
    if (resolved == null) {
      throw new CompilerException(line, "unresolved or non-public module type: " + name);
    }
    return resolved;
  }

  private static String resolve(Map<String, String> references, String name, int line) {
    String resolved = references.get(name);
    if (resolved == null) {
      throw new CompilerException(line, "unresolved or non-public module function: " + name);
    }
    return resolved;
  }

  private static String linkedName(String module, String function) {
    return module + "::" + function;
  }

  private static void fail(String message) {
    throw new CompilerException(1, message);
  }
}
