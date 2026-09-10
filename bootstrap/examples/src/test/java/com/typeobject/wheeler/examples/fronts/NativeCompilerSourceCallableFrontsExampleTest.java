package com.typeobject.wheeler.examples.fronts;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Callable syntax owns declaration coordinates, not words found inside method bodies. */
final class NativeCompilerSourceCallableFrontsExampleTest {
  private record Front(String source, long effects) {}

  @Test
  void retainsMemberCoordinatesAndIgnoresWordsInsideBodies() throws Exception {
    Program program = program();
    for (Front front : List.of(
        new Front("public static long test() { long test = 1; return test; }", 0),
        new Front("protected void tags(borrow byteview limits) {}", 0),
        new Front("entry entry void main(borrow utf8 input, borrow mut bytes output) {}", 1),
        new Front("entry void main(borrow mut bytes output) {}", 1),
        new Front("rev long value(long input) { return input; }", 2),
        new Front("coherent rev void step() {}", 6),
        new Front("test test void alpha() tags(fast) { assert(true); }", 8),
        new Front("test void rows(long n) cases(0,1) limits(steps=100,history=100) {}", 8),
        new Front("unitary void gate() {}", 16),
        new Front("dynamic void circuit() {}", 32),
        new Front("Pair helper(Pair value) { return value; }", 0))) {
      assertFront(program, "// café 𝄞\n" + front.source(), true, front.effects());
    }
  }

  @Test
  void rejectsUnknownModifiersAndMalformedSignaturesBeforePublishingCoordinates() throws Exception {
    Program program = program();
    for (String source : List.of(
        "tetU void alpha() tags(fast) {}", "test vojE alpha() tags(fast) {}",
        "publjD void alpha() {}", "public bogus void alpha() {}", "static public void alpha() {}",
        "void alpha", "void alpha( {}", "void alpha(long) {}", "void alpha(long n,) {}",
        "void alpha(long n, boolean n) {}", "void alpha(long long n) {}",
        "void alpha(borrow long n) {}", "void alpha(borrow mut utf8 n) {}",
        "void alpha(byteview n) {}", "void alpha(borrow mut bytes[] n) {}",
        "void alpha() tags(fast) {}", "test void alpha() tags(fast) cases(1) {}",
        "test void alpha() tags(fast) tags(slow) {}", "test void alpha() tags(fast {}",
        "test long alpha() { return 1; }", "test void alpha(borrow utf8 n) {}",
        "entry void other() {}", "entry long main() { return 1; }",
        "entry void main(long n) {}", "entry void main(borrow mut bytes x, borrow utf8 y) {}",
        "coherent rev void alpha(long n) {}", "rev void alpha(long n) {}",
        "rev Done alpha() {}", "unitary long alpha() { return 1; }",
        "entry test void main() {}", "void slice() {}", "void alpha() {",
        "void done() {}", "void nil() {}", "void none() {}", "void null() {}",
        "void undefined() {}", "void alpha(long done) {}", "void alpha(long null) {}")) {
      assertFront(program, source, false, 0);
      String entry = source.contains("entry") ? "" : " entry void main() {}";
      assertThrows(CompilerException.class, () -> new WheelerCompiler().compileModuleFiles(
          Map.of("Front.w", "module example.front; classical class Front { "
              + source + entry + " }"), "example.front"), source);
    }
  }

  private static void assertFront(Program program, String source, boolean valid, long effects) {
    var machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8));
    var initial = machine.snapshot();
    machine.run();
    assertEquals(valid ? 1 : 0, machine.global("accepted"), source);
    assertEquals(effects, machine.global("effects"), source);
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.source_callable_fronts"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.module_linker"));
    sources.put("CallableProbe.w", """
        module example.callable_probe;
        import wheeler.compiler.module_linker;
        import wheeler.compiler.source_callable_fronts;
        classical class CallableProbe {
          state long accepted = 0;
          state long effects = 0;
          entry void main(borrow utf8 source) {
            region arena = new region(/* bytes= */ 3072, /* allocations= */ 6);
            words kinds = allocate(arena, 64);
            words starts = allocate(arena, 64);
            words lengths = allocate(arena, 64);
            words oldKinds = allocate(arena, 64);
            words oldStarts = allocate(arena, 64);
            words oldLengths = allocate(arena, 64);
            long count = scanSemanticTokens(source, kinds, starts, lengths);
            assert(-1 < count);
            long row = 0;
            while (row < 64) limit 64 {
              set(oldKinds, row, kinds[row]);
              set(oldStarts, row, starts[row]);
              set(oldLengths, row, lengths[row]);
              row += 1;
            }
            CallableFront front = sourceCallableFront(source, kinds, starts, lengths, count, 0);
            if (front.valid) {
              assert(front.nameToken < front.parameterClose);
              assert(front.parameterClose < front.bodyOpen);
              assert(front.bodyOpen < front.nextToken);
              assert(front.nextToken == count);
              accepted = 1;
              effects = front.effects;
            } else {
              assert(front.nameToken == 0);
              assert(front.parameterClose == 0);
              assert(front.bodyOpen == 0);
              assert(front.nextToken == 0);
              assert(front.effects == 0);
            }
            row = 0;
            while (row < 64) limit 64 {
              assert(kinds[row] == oldKinds[row]);
              assert(starts[row] == oldStarts[row]);
              assert(lengths[row] == oldLengths[row]);
              row += 1;
            }
            drop(oldLengths);
            drop(oldStarts);
            drop(oldKinds);
            drop(lengths);
            drop(starts);
            drop(kinds);
            drop(arena);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.callable_probe");
  }
}
