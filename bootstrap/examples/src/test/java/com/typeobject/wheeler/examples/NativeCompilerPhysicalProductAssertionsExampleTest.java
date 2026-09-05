package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Fast negative controls for physical-product body and relocation comparisons. */
final class NativeCompilerPhysicalProductAssertionsExampleTest {
  private static final String CALLER = "fixture.caller";
  private static final String LEAF = "fixture.leaf";
  private static final List<Instruction> RETURN = List.of(Instruction.of(Opcode.RETURN));
  private static final BootstrapModuleManifest MANIFEST = new BootstrapModuleManifest(
      "bootstrap-1", CALLER, List.of(), List.of(
          new BootstrapModuleManifest.Module(
              CALLER, "src/Caller.w", "00".repeat(32), List.of(LEAF)),
          new BootstrapModuleManifest.Module(
              LEAF, "src/Leaf.w", "11".repeat(32), List.of())));

  @Test
  void comparesMultipleProductsWithLocalImportedAndInverseBodies() {
    assertProducts(transport(caller()));
  }

  @Test
  void comparesASingleProductWithoutDependencyProducts() {
    byte[] artifact = new BytecodeWriter().write(caller());
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    output.writeBytes(artifact);
    product(output, 0, artifact.length, 2);
    output.writeBytes(new byte[] {0, 0, 3, 0, 1, 0});
    output.writeBytes(new byte[] {87, 80, 70, 1, 0, 1, 0, 1});
    NativeCompilerPhysicalProductAssertions.assertCallables(
        MANIFEST, Map.of(CALLER, reference()), output.toByteArray());
  }

  @Test
  void bindsImportedIdentitiesIndependentlyOfStubIds() {
    Program caller = caller();
    FunctionBody invoke = caller.functions().get(1);
    List<Instruction> body = new ArrayList<>(invoke.forward());
    body.set(1, Instruction.of(Opcode.CALL_VALUE, 3, 0, 0, 0));
    Program changed = replace(caller, 1, copy(invoke, 1, body, invoke.inverse()));

    // The other imported stub has the same signature. Its operand is only a
    // placeholder, so the transport's identity still selects the right body.
    assertProducts(transport(changed));
  }

  @Test
  void rejectsDifferentInstructionsWithTheSameCounts() {
    FunctionBody leaf = leaf().functions().getFirst();
    FunctionBody altered = copy(leaf, 0,
        List.of(Instruction.of(Opcode.LOCAL_CONST, 0, 11),
            Instruction.of(Opcode.RETURN_VALUE, 0)), List.of());
    byte[] transport = transport(caller(), replace(leaf(), 0, altered));
    assertRejected(transport);
  }

  @Test
  void rejectsDifferentLocalTypesWithTheSameCounts() {
    Program caller = caller();
    FunctionBody invoke = caller.functions().get(1);
    FunctionBody changed = new FunctionBody(
        invoke.id(), invoke.name(), invoke.coherent(), invoke.parameterCount(),
        List.of(ValueType.SIGNED, ValueType.SIGNED), invoke.resultType(),
        invoke.implicitResultSlot(), invoke.forward(), invoke.inverse());
    assertRejected(transport(replace(caller, 1, changed)));
  }

  @Test
  void rejectsAChangedInverseBody() {
    Program caller = caller();
    FunctionBody local = caller.functions().getFirst();
    assertRejected(transport(replace(caller, 0, copy(local, 0, RETURN, List.of()))));
  }

  @Test
  void rejectsAChangedLocalCallTarget() {
    Program caller = caller();
    FunctionBody invoke = caller.functions().get(1);
    List<Instruction> body = new ArrayList<>(invoke.forward());
    body.set(0, Instruction.of(Opcode.CALL, 4));
    assertRejected(transport(replace(caller, 1, copy(invoke, 1, body, List.of()))));
  }

  @Test
  void rejectsMisboundMissingAndOutOfWindowRelocations() {
    byte[] valid = transport(caller());
    int row = valid.length - 14;
    assertRejected(changed(valid, row + 5, 1)); // Another valid leaf callable.
    assertRejected(changed(valid, row + 5, 2)); // No such leaf callable.
    assertRejected(changed(valid, row, 2)); // No such caller product.
    assertRejected(changed(valid, row + 4, 2)); // No such target owner.
    assertRejected(changed(valid, row + 2, 2)); // A local call is not an import.
    assertRejected(changed(valid, row + 2, 4)); // A return has no function operand.
    assertRejected(changed(valid, row + 2, 9)); // Outside the retained window.

    byte[] missing = new byte[valid.length - 6];
    System.arraycopy(valid, 0, missing, 0, row);
    System.arraycopy(valid, valid.length - 8, missing, row, 8);
    missing[missing.length - 1] = 0;
    assertRejected(missing);
  }

  @Test
  void rejectsDuplicateOrUnorderedRelocations() {
    byte[] valid = transport(caller());
    byte[] duplicated = new byte[valid.length + 6];
    int row = valid.length - 14;
    System.arraycopy(valid, 0, duplicated, 0, valid.length - 8);
    System.arraycopy(valid, row, duplicated, valid.length - 8, 6);
    System.arraycopy(valid, valid.length - 8, duplicated, valid.length - 2, 8);
    duplicated[duplicated.length - 1] = 2;
    assertRejected(duplicated);
    assertRejected(changed(duplicated, valid.length - 8, 0));
  }

  @Test
  void rejectsMissingRepeatedOrMisframedProducts() {
    byte[] valid = transport(caller());
    int metadata = valid.length - 8 - 6 - 12;
    assertRejected(changed(valid, metadata + 7, 1)); // Repeats the leaf owner.
    assertRejected(changed(valid, metadata + 11, 1)); // Drops a retained function.
    assertRejected(changed(valid, metadata + 4, 0)); // Breaks an artifact extent.
    assertRejected(changed(valid, valid.length - 8, 0));
    assertRejected(changed(valid, valid.length - 3, 3));
    assertRejected(new byte[0]);
    assertThrows(AssertionError.class, () -> NativeCompilerPhysicalProductAssertions.assertCallables(
        MANIFEST, Map.of(), valid));
    assertThrows(AssertionError.class, () -> NativeCompilerPhysicalProductAssertions.assertCallables(
        MANIFEST, Map.of("fixture.absent", reference()), valid));
  }

  private static void assertProducts(byte[] transport) {
    NativeCompilerPhysicalProductAssertions.assertCallables(
        MANIFEST, Map.of(CALLER, reference(), LEAF, leaf()), transport);
  }

  private static void assertRejected(byte[] transport) {
    assertThrows(AssertionError.class, () -> assertProducts(transport));
  }

  private static byte[] changed(byte[] source, int index, int value) {
    byte[] result = source.clone();
    result[index] = (byte) value;
    return result;
  }

  private static Program reference() {
    FunctionBody local = new FunctionBody(
        2, CALLER + "::local", false, 0, List.of(), null, RETURN, RETURN);
    FunctionBody invoke = new FunctionBody(
        3, CALLER + "::invoke", false, 0, List.of(ValueType.SIGNED, ValueType.BOOLEAN),
        ValueType.SIGNED, List.of(
            Instruction.of(Opcode.CALL, 2),
            Instruction.of(Opcode.CALL_VALUE, 0, 0, 0, 0),
            Instruction.of(Opcode.RETURN_VALUE, 0)), List.of());
    return new Program("Caller", 4, List.of(),
        List.of(value(0, "first", 10), value(1, "second", 20), local, invoke, entry(4)));
  }

  private static Program leaf() {
    return new Program("Leaf", 2, List.of(),
        List.of(value(0, "first", 10), value(1, "second", 20), entry(2)));
  }

  private static Program caller() {
    Program reference = reference();
    FunctionBody local = reference.functions().get(2);
    FunctionBody invoke = reference.functions().get(3);
    FunctionBody first = reference.functions().get(0);
    FunctionBody second = reference.functions().get(1);
    List<Instruction> calls = List.of(
        Instruction.of(Opcode.CALL, 0),
        Instruction.of(Opcode.CALL_VALUE, 2, 0, 0, 0),
        Instruction.of(Opcode.RETURN_VALUE, 0));
    return new Program("Caller", 4, List.of(), List.of(
        copy(local, 0, local.forward(), local.inverse()),
        copy(invoke, 1, calls, List.of()),
        copy(first, 2, first.forward(), List.of()),
        copy(second, 3, second.forward(), List.of()), entry(4)));
  }

  private static FunctionBody value(int id, String name, long value) {
    return new FunctionBody(id, LEAF + "::" + name, false, 0,
        List.of(ValueType.SIGNED), ValueType.SIGNED,
        List.of(Instruction.of(Opcode.LOCAL_CONST, 0, value),
            Instruction.of(Opcode.RETURN_VALUE, 0)), List.of());
  }

  private static FunctionBody entry(int id) {
    return new FunctionBody(id, "$library", false, 0, List.of(), null,
        List.of(Instruction.of(Opcode.HALT)), List.of());
  }

  private static FunctionBody copy(
      FunctionBody function, int id, List<Instruction> forward, List<Instruction> inverse) {
    return new FunctionBody(id, function.name(), function.coherent(), function.parameterCount(),
        function.localTypes(), function.resultType(), function.implicitResultSlot(), forward, inverse);
  }

  private static Program replace(Program program, int index, FunctionBody function) {
    List<FunctionBody> functions = new ArrayList<>(program.functions());
    functions.set(index, function);
    return new Program(program.name(), program.entryFunctionId(), program.globals(), functions);
  }

  private static byte[] transport(Program caller) {
    return transport(caller, leaf());
  }

  private static byte[] transport(Program caller, Program leaf) {
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    byte[] leafBytes = new BytecodeWriter().write(leaf);
    byte[] callerBytes = new BytecodeWriter().write(caller);
    output.writeBytes(leafBytes);
    output.writeBytes(callerBytes);
    product(output, 1, leafBytes.length, 2);
    product(output, 0, callerBytes.length, 2);
    output.writeBytes(new byte[] {1, 0, 3, 0, 1, 0});
    output.writeBytes(new byte[] {87, 80, 70, 1, 0, 2, 0, 1});
    return output.toByteArray();
  }

  private static void product(ByteArrayOutputStream output, int owner, int length, int functions) {
    output.write(owner >>> 8);
    output.write(owner);
    output.write(length >>> 16);
    output.write(length >>> 8);
    output.write(length);
    output.write(functions);
  }
}
