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
            long signedKind = signedScalarHelperKind(16);
            long booleanKind = booleanScalarHelperKind(16);
            long utf8Kind = utf8ScalarHelperKind(10);
            boolean reversible = reversibleHelper(12);
            boolean resultSlot = resultSlotHelper(12);
            boolean utf8 = utf8ResultHelper(82);
            boolean booleanResult = booleanResultHelper(80);
            boolean booleanParameter = booleanParameterHelper(7);
            assert(count == 16);
            assert(signedKind == 48);
            assert(booleanKind == 80);
            assert(utf8Kind == 82);
            assert(reversible);
            assert(resultSlot);
            assert(utf8);
            assert(booleanResult);
            assert(booleanParameter);
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
  void compilesPhysicalResolvedLocalEqualityIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/ResolvedStatements.w");
    String equality = CompilerSources.read("compiler/syntax/locals/ResolvedLocalEqualityKinds.w");
    String root = """
        module example.resolved_local_equality_entry;
        import wheeler.compiler.resolved_local_equality_kinds;
        classical class ResolvedLocalEqualityEntry {
          entry void main() {
            boolean present = resolvedLocalEquality(5119);
            boolean signed = resolvedLocalEqualitySigned(4864);
            long source = resolvedLocalEqualitySource(4608);
            assert(present);
            assert(signed);
            assert(source == 0);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(opcodes, equality), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("Opcodes.w", opcodes, "Equality.w", equality, "Entry.w", root),
        "example.resolved_local_equality_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesPhysicalResolvedLocalInequalityIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/ResolvedStatements.w");
    String inequality = CompilerSources.read(
        "compiler/syntax/locals/ResolvedLocalInequalityKinds.w");
    String root = """
        module example.resolved_local_inequality_entry;
        import wheeler.compiler.resolved_local_inequality_kinds;
        classical class ResolvedLocalInequalityEntry {
          entry void main() {
            boolean present = resolvedLocalInequality(15871);
            boolean signed = resolvedLocalInequalitySigned(15616);
            long source = resolvedLocalInequalitySource(15360);
            assert(present);
            assert(signed);
            assert(source == 0);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(opcodes, inequality), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("Opcodes.w", opcodes, "Inequality.w", inequality, "Entry.w", root),
        "example.resolved_local_inequality_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesPhysicalResolvedLocalAssignmentsIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/ResolvedStatements.w");
    String assignments = CompilerSources.read(
        "compiler/syntax/assignments/ResolvedLocalAssignments.w");
    String root = """
        module example.resolved_local_assignment_entry;
        import wheeler.compiler.resolved_local_assignments;
        classical class ResolvedLocalAssignmentEntry {
          entry void main() {
            boolean present = resolvedLocalAssignment(18687);
            boolean named = resolvedLocalAssignmentNamed(17920);
            boolean typed = resolvedLocalAssignmentBoolean(18176);
            long target = resolvedLocalAssignmentTarget(18432);
            assert(present);
            assert(named);
            assert(typed);
            assert(target == 0);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(opcodes, assignments), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("Opcodes.w", opcodes, "Assignments.w", assignments, "Entry.w", root),
        "example.resolved_local_assignment_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesPhysicalResolvedLocalReturnsIntoEntryByteForByte() throws Exception {
    String returns = CompilerSources.read("compiler/syntax/returns/ResolvedLocalReturns.w");
    String root = """
        module example.resolved_local_return_entry;
        import wheeler.compiler.resolved_local_returns;
        classical class ResolvedLocalReturnEntry {
          entry void main() {
            boolean present = resolvedLocalReturn(14847);
            boolean signed = resolvedSignedLocalReturn(14591);
            long source = resolvedLocalReturnSource(14592);
            assert(present);
            assert(signed);
            assert(source == 0);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, List.of(returns), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("Returns.w", returns, "Entry.w", root),
        "example.resolved_local_return_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesPhysicalIdentifierStartsIntoEntryByteForByte() throws Exception {
    String starts = CompilerSources.read("compiler/syntax/IdentifierStarts.w");
    String root = """
        module example.identifier_start_entry;
        import wheeler.compiler.identifier_starts;
        classical class IdentifierStartEntry {
          entry void main() {
            boolean lower = identifierStart(122);
            assert(lower);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, List.of(starts), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("Starts.w", starts, "Entry.w", root),
        "example.identifier_start_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesPhysicalOpcodeKindsIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/Opcodes.w");
    String kinds = CompilerSources.read("compiler/ir/OpcodeKinds.w");
    String root = """
        module example.opcode_kind_entry;
        import wheeler.compiler.opcode_kinds;
        classical class OpcodeKindEntry {
          entry void main() {
            boolean global = isGlobalConstantOpcode(258);
            boolean fill = isResultFillOpcode(523);
            boolean binary = isResultBinaryOperation(1046);
            boolean math = isLocalMathOpcode(1047);
            assert(global);
            assert(fill);
            assert(binary);
            assert(math);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(opcodes, kinds), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of("Opcodes.w", opcodes, "Kinds.w", kinds, "Entry.w", root),
        "example.opcode_kind_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesPhysicalInstructionFormsIntoEntryByteForByte() throws Exception {
    String opcodes = CompilerSources.read("compiler/ir/Opcodes.w");
    String storageOpcodes = CompilerSources.read("compiler/ir/StorageOpcodes.w");
    String forms = CompilerSources.read("compiler/ir/InstructionForms.w");
    String root = """
        module example.instruction_form_entry;
        import wheeler.compiler.instruction_forms;
        classical class InstructionFormEntry {
          entry void main() {
            long operands = expectedOperandCount(1362);
            long unknown = expectedOperandCount(99999);
            assert(operands == 3);
            assert(unknown == -1);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler, List.of(opcodes, storageOpcodes, forms), root);
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileModuleFiles(
        Map.of(
            "Opcodes.w", opcodes,
            "StorageOpcodes.w", storageOpcodes,
            "Forms.w", forms,
            "Entry.w", root),
        "example.instruction_form_entry"));
    assertArrayEquals(expected, artifact);
    new VirtualMachine(new BytecodeReader().read(artifact)).run();
  }

  @Test
  void compilesPhysicalWideReturnSourcesIntoEntryByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    compileWideReturnSource(compiler, """
        long first = 10;
        long second = 11;
        long third = 12;
        long fourth = 13;
        long result = packWideReturnFirstSources(first, second, third, fourth);
        assert(result == 168496141);
        """);
    compileWideReturnSource(compiler, """
        long fifth = 14;
        long sixth = 15;
        long seventh = 16;
        long result = packWideReturnLastSources(fifth, sixth, seventh);
        assert(result == 921360);
        """);
    compileWideReturnSource(compiler, """
        long result = wideReturnFirstSource(168496141);
        assert(result == 10);
        """);
    compileWideReturnSource(compiler, """
        long result = wideReturnSecondSource(168496141);
        assert(result == 11);
        """);
    compileWideReturnSource(compiler, """
        long result = wideReturnThirdSource(168496141);
        assert(result == 12);
        """);
    compileWideReturnSource(compiler, """
        long result = wideReturnFourthSource(168496141);
        assert(result == 13);
        """);
    compileWideReturnSource(compiler, """
        long result = wideReturnFifthSource(921360);
        assert(result == 14);
        """);
    compileWideReturnSource(compiler, """
        long result = wideReturnSixthSource(921360);
        assert(result == 15);
        """);
    compileWideReturnSource(compiler, """
        long result = wideReturnSeventhSource(921360);
        assert(result == 16);
        """);
  }

  private static void compileWideReturnSource(Program compiler, String statements)
      throws Exception {
    String sources =
        CompilerSources.read("compiler/resolution/returns/WideReturnSources.w");
    String root = """
        module example.wide_return_source_entry;
        import wheeler.compiler.wide_return_sources;
        classical class WideReturnSourceEntry {
          entry void main() {
        """ + statements.indent(4) + """
          }
        }
        """;
    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, List.of(sources), root);
    byte[] expected =
        new BytecodeWriter()
            .write(
                new WheelerCompiler()
                    .compileModuleFiles(
                        Map.of("Sources.w", sources, "Entry.w", root),
                        "example.wide_return_source_entry"));
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
