package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.TreeSet;

/** Framed source-link probes separate private emission from host publication. */
final class NativeSourceLinkFixture {
  private NativeSourceLinkFixture() {}

  static Program sharedHelperProgram() throws Exception {
    return program(List.of("wheeler.compiler.imported_helpers", "wheeler.compiler.canonical_helper_linking"),
        "planSharedResolvedHelperImport", "writeCanonicalHelperImport");
  }

  static Program constantProgram(boolean privateExports) throws Exception {
    return program(List.of(), privateExports ? "planPrivateConstantImport" : "planConstantImport",
        "writeConstantImport");
  }

  private static Program program(List<String> owners, String planner, String writer) throws Exception {
    var imports = new TreeSet<>(owners);
    imports.add("wheeler.compiler.module_linker");
    var modules = new LinkedHashMap<String, String>();
    for (String owner : imports) {
      modules.putAll(CompilerSources.moduleClosure(owner));
    }
    CoreSources.addBinaryClosure(modules);
    String importText = String.join("\n", imports.stream().map(name -> "import " + name + ";").toList());
    modules.put("SourceLinkProbe.w", """
        module example.source_link_probe;
        %s
        import wheeler.core.encoding.binary;
        classical class SourceLinkProbe {
          state long published = 0;
          state long phase = 0;
          private void copyWindow(borrow byteview input, long start, borrow mut bytes output) {
            long index = 0;
            while (index < bufferLength(output)) limit 32768 {
              setByte(output, index, input[start + index]);
              index += 1;
            }
          }
          entry void main(borrow byteview input, borrow mut bytes output) {
            assert(readUnsigned(input, 0, 4) == 1);
            long importedLength = readUnsigned(input, 4, 4);
            long rootStart = 8 + importedLength;
            long rootLength = bufferLength(input) - rootStart;
            assert(0 < importedLength);
            assert(importedLength < 32769);
            assert(0 < rootLength);
            assert(rootLength < 32769);
            region sources = new region(/* bytes= */ 65536, /* allocations= */ 2);
            bytes importedBytes = allocateBytes(sources, importedLength);
            bytes rootBytes = allocateBytes(sources, rootLength);
            copyWindow(input, 8, importedBytes);
            copyWindow(input, rootStart, rootBytes);
            utf8 imported = freezeUtf8(importedBytes);
            utf8 root = freezeUtf8(rootBytes);
            LinkPlan plan = %s(imported, root, 1);
            assert(plan.valid);
            region emission = new region(/* bytes= */ 36864, /* allocations= */ 1);
            bytes linked = allocateBytes(emission, plan.linkedLength);
            phase = 1;
            long written = %s(imported, root, plan, linked);
            assert(written == plan.linkedLength);
            phase = 2;
            long index = 0;
            while (index < written) limit 36864 {
              setByte(output, index, linked[index]);
              index += 1;
            }
            setOutputLength(output, written);
            published = 1;
            drop(linked);
            drop(emission);
            drop(root);
            drop(imported);
            drop(sources);
          }
        }
        """.formatted(importText, planner, writer));
    return new WheelerCompiler().compileModuleFiles(modules, "example.source_link_probe");
  }
}
