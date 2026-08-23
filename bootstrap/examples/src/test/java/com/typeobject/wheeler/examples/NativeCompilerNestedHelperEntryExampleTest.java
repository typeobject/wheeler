package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for nested native scalar helpers called from an entry. */
final class NativeCompilerNestedHelperEntryExampleTest {
  @Test
  void compilesPhysicalAssignmentCallKindsIntoEntryByteForByte() throws Exception {
    String identities = CompilerSources.read(
        "compiler/syntax/calls/assignment/AssignmentCallIdentities.w");
    String arities = CompilerSources.read(
        "compiler/syntax/calls/assignment/AssignmentCallArities.w");
    String columns = CompilerSources.read(
        "compiler/syntax/calls/assignment/AssignmentCallColumns.w");
    String kinds = CompilerSources.read(
        "compiler/syntax/calls/assignment/AssignmentCallKinds.w");
    String root = """
        module example.assignment_call_kind_entry;
        import wheeler.compiler.assignment_call_kinds;
        classical class AssignmentCallKindEntry {
          entry void main() {
            boolean source = assignmentCallSourceStatement(933);
            boolean resolved = assignmentCallStatement(41834);
            long opcode = resolvedAssignmentCall(7, 42);
            long target = assignmentCallTarget(41834);
            assert(source);
            assert(resolved);
            assert(opcode == 41834);
            assert(target == 42);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(identities, arities, columns, kinds), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of(
            "Identities.w", identities,
            "Arities.w", arities,
            "Columns.w", columns,
            "Kinds.w", kinds,
            "Entry.w", root),
        "example.assignment_call_kind_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesPhysicalAssignmentCallColumnsIntoEntryByteForByte() throws Exception {
    String identities = CompilerSources.read(
        "compiler/syntax/calls/assignment/AssignmentCallIdentities.w");
    String columns = CompilerSources.read(
        "compiler/syntax/calls/assignment/AssignmentCallColumns.w");
    String root = """
        module example.assignment_call_column_entry;
        import wheeler.compiler.assignment_call_columns;
        classical class AssignmentCallColumnEntry {
          entry void main() {
            long source = sourceKind(7);
            long resolved = resolvedBase(7);
            assert(source == 933);
            assert(resolved == 41792);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(identities, columns), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("Identities.w", identities, "Columns.w", columns, "Entry.w", root),
        "example.assignment_call_column_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesPhysicalAssignmentCallOperandsIntoEntryByteForByte() throws Exception {
    String identities = CompilerSources.read(
        "compiler/syntax/calls/assignment/AssignmentCallIdentities.w");
    String arities = CompilerSources.read(
        "compiler/syntax/calls/assignment/AssignmentCallArities.w");
    String operands = CompilerSources.read(
        "compiler/syntax/calls/assignment/AssignmentCallOperands.w");
    String root = """
        module example.assignment_call_operand_entry;
        import wheeler.compiler.assignment_call_operands;
        classical class AssignmentCallOperandEntry {
          entry void main() {
            long opcode = 933;
            long leading = 218893066;
            long trailing = 2828841;
            long source = 0;
            long decoded = assignmentCallSource(opcode, leading, trailing, source);
            assert(decoded == 10);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(identities, arities, operands), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of(
            "Identities.w", identities,
            "Arities.w", arities,
            "Operands.w", operands,
            "Entry.w", root),
        "example.assignment_call_operand_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesPhysicalVoidCallOperandsIntoEntryByteForByte() throws Exception {
    String kinds = CompilerSources.read("compiler/syntax/calls/VoidCallKinds.w");
    String operands = CompilerSources.read(
        "compiler/syntax/calls/void/VoidCallOperands.w");
    String root = """
        module example.void_call_operand_entry;
        import wheeler.compiler.void_call_operands;
        classical class VoidCallOperandEntry {
          entry void main() {
            long opcode = 31744;
            long leading = 218893066;
            long trailing = 387323156;
            long source = 6;
            long decoded = voidCallSource(opcode, leading, trailing, source);
            assert(decoded == 22);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(kinds, operands), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("Kinds.w", kinds, "Operands.w", operands, "Entry.w", root),
        "example.void_call_operand_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesPhysicalHelperSignaturesIntoEntryByteForByte() throws Exception {
    String abi = CompilerSources.read("compiler/syntax/helpers/HelperAbi.w");
    String signatures = CompilerSources.read(
        "compiler/syntax/helpers/HelperSignatures.w");
    String root = """
        module example.helper_signature_entry;
        import wheeler.compiler.helper_signatures;
        classical class HelperSignatureEntry {
          entry void main() {
            long count = parameterCountForHelper(48);
            assert(count == 16);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(abi, signatures), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("Abi.w", abi, "Signatures.w", signatures, "Entry.w", root),
        "example.helper_signature_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesPhysicalVoidCallKindsIntoEntryByteForByte() throws Exception {
    String kinds = CompilerSources.read("compiler/syntax/calls/VoidCallKinds.w");
    String root = """
        module example.void_call_kind_entry;
        import wheeler.compiler.void_call_kinds;
        classical class VoidCallKindEntry {
          entry void main() {
            boolean present = voidCallStatement(31744);
            long arity = voidCallArity(31744);
            long source = voidCallThirdSource(131124);
            assert(present);
            assert(arity == 7);
            assert(source == 42);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, List.of(kinds), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("Kinds.w", kinds, "Entry.w", root), "example.void_call_kind_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesPhysicalVoidCallSourceFormsIntoEntryByteForByte() throws Exception {
    String kinds = CompilerSources.read("compiler/syntax/calls/VoidCallKinds.w");
    String sourceKinds = CompilerSources.read(
        "compiler/syntax/calls/VoidCallSourceKinds.w");
    String forms = CompilerSources.read(
        "compiler/syntax/calls/void/VoidCallSourceForms.w");
    String root = """
        module example.void_call_source_form_entry;
        import wheeler.compiler.void_call_source_forms;
        classical class VoidCallSourceFormEntry {
          entry void main() {
            boolean present = anyVoidCallSourceStatement(925);
            long arity = voidCallSourceArity(925);
            long kind = voidCallSourceKind(7);
            assert(present);
            assert(arity == 7);
            assert(kind == 925);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(kinds, sourceKinds, forms), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of(
            "Kinds.w", kinds,
            "SourceKinds.w", sourceKinds,
            "Forms.w", forms,
            "Entry.w", root),
        "example.void_call_source_form_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesPhysicalVoidCallSourceWidthsIntoEntryByteForByte() throws Exception {
    String kinds = CompilerSources.read("compiler/syntax/calls/VoidCallKinds.w");
    String sourceKinds = CompilerSources.read(
        "compiler/syntax/calls/VoidCallSourceKinds.w");
    String widths = CompilerSources.read("compiler/syntax/calls/VoidCallSourceWidths.w");
    String root = """
        module example.void_call_source_width_entry;
        import wheeler.compiler.void_call_source_widths;
        classical class VoidCallSourceWidthEntry {
          entry void main() {
            long source = voidCallLocalCount(925);
            long resolved = voidCallLocalCount(31744);
            assert(source == 14);
            assert(resolved == 14);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(kinds, sourceKinds, widths), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of(
            "Kinds.w", kinds,
            "SourceKinds.w", sourceKinds,
            "Widths.w", widths,
            "Entry.w", root),
        "example.void_call_source_width_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesPhysicalVoidCallWidthsIntoEntryByteForByte() throws Exception {
    String kinds = CompilerSources.read("compiler/syntax/calls/VoidCallKinds.w");
    String widths = CompilerSources.read("compiler/syntax/calls/VoidCallWidths.w");
    String root = """
        module example.void_call_width_entry;
        import wheeler.compiler.void_call_widths;
        classical class VoidCallWidthEntry {
          entry void main() {
            long code = voidCallCodeLength(31744);
            long instructions = voidCallInstructionCount(31744);
            assert(code == 368);
            assert(instructions == 15);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(kinds, widths), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("Kinds.w", kinds, "Widths.w", widths, "Entry.w", root),
        "example.void_call_width_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesNestedScalarHelpersIntoEntryByteForByte() throws Exception {
    String arities = """
        module example.arities;
        classical class Arities {
          public long arity(long opcode) {
            if (opcode == 933) { return 7; }
            return -1;
          }
        }
        """;
    String widths = """
        module example.widths;
        import example.arities;
        classical class Widths {
          public long codeWidth(long opcode) {
            long arity = arity(opcode);
            if (arity < 0) { return -1; }
            long arguments = arity * 48;
            return arguments + 64;
          }
        }
        """;
    String root = """
        module example.entry;
        import example.widths;
        classical class Entry {
          entry void main() {
            long width = codeWidth(933);
            assert(width == 400);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(arities, widths), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("Arities.w", arities, "Widths.w", widths, "Entry.w", root),
        "example.entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(arities, widths),
        root.replace("codeWidth(933)", "missingWidth(933)"));
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(arities, widths),
        root.replace("codeWidth(933)", "arity(933)"));
  }
}
