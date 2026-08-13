package com.typeobject.wheeler.core.bytecode;

import com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole;
import java.util.List;

/** Generated from registry/instructions.wreg. Do not edit this view. */
final class GeneratedInstructionRegistry {
  private static final List<Entry> ENTRIES = List.of(
      new Entry(
          "NOP", 0x0000, "NONE",
          List.of(), Reversibility.INTRINSIC),
      new Entry(
          "HALT", 0x0001, "NONE",
          List.of(), Reversibility.CHECKED),
      new Entry(
          "RETURN", 0x0002, "NONE",
          List.of(), Reversibility.CHECKED),
      new Entry(
          "ADD_CONST", 0x0100, "GLOBAL_IMMEDIATE",
          List.of(OperandRole.GLOBAL, OperandRole.IMMEDIATE), Reversibility.INTRINSIC),
      new Entry(
          "SUB_CONST", 0x0101, "GLOBAL_IMMEDIATE",
          List.of(OperandRole.GLOBAL, OperandRole.IMMEDIATE), Reversibility.INTRINSIC),
      new Entry(
          "XOR_CONST", 0x0102, "GLOBAL_IMMEDIATE",
          List.of(OperandRole.GLOBAL, OperandRole.IMMEDIATE), Reversibility.INTRINSIC),
      new Entry(
          "SWAP", 0x0103, "GLOBAL_PAIR",
          List.of(OperandRole.LEFT_GLOBAL, OperandRole.RIGHT_GLOBAL), Reversibility.INTRINSIC),
      new Entry(
          "SET_LOGGED", 0x0104, "GLOBAL_IMMEDIATE",
          List.of(OperandRole.GLOBAL, OperandRole.IMMEDIATE), Reversibility.LOGGED),
      new Entry(
          "CALL", 0x0200, "FUNCTION",
          List.of(OperandRole.FUNCTION), Reversibility.CHECKED),
      new Entry(
          "UNCALL", 0x0201, "FUNCTION",
          List.of(OperandRole.FUNCTION), Reversibility.CHECKED),
      new Entry(
          "CALL_VALUE", 0x0202, "CALL_VALUE",
          List.of(OperandRole.FUNCTION, OperandRole.ARGUMENT_BASE, OperandRole.ARGUMENT_COUNT, OperandRole.RESULT), Reversibility.CHECKED),
      new Entry(
          "RETURN_VALUE", 0x0203, "RESULT",
          List.of(OperandRole.RESULT), Reversibility.CHECKED),
      new Entry(
          "CALL_VOID", 0x0204, "CALL_VOID",
          List.of(OperandRole.FUNCTION, OperandRole.ARGUMENT_BASE, OperandRole.ARGUMENT_COUNT), Reversibility.CHECKED),
      new Entry(
          "CALL_RESULT_SLOT", 0x0205, "CALL_RESULT_SLOT",
          List.of(OperandRole.FUNCTION, OperandRole.ARGUMENT_BASE, OperandRole.ARGUMENT_COUNT, OperandRole.RESULT_SLOT), Reversibility.CHECKED),
      new Entry(
          "UNCALL_RESULT_SLOT", 0x0206, "CALL_RESULT_SLOT",
          List.of(OperandRole.FUNCTION, OperandRole.ARGUMENT_BASE, OperandRole.ARGUMENT_COUNT, OperandRole.RESULT_SLOT), Reversibility.CHECKED),
      new Entry(
          "RESULT_FILL_CONSTANT", 0x0207, "RESULT_CONSTANT",
          List.of(OperandRole.RESULT_SLOT, OperandRole.IMMEDIATE), Reversibility.INTRINSIC),
      new Entry(
          "RETURN_RESULT_SLOT", 0x0208, "RESULT_SLOT",
          List.of(OperandRole.RESULT_SLOT), Reversibility.CHECKED),
      new Entry(
          "RESULT_FILL_SOURCE", 0x0209, "RESULT_SOURCE",
          List.of(OperandRole.RESULT_SLOT, OperandRole.SOURCE), Reversibility.INTRINSIC),
      new Entry(
          "RESULT_FILL_BINARY", 0x020a, "RESULT_BINARY",
          List.of(OperandRole.RESULT_SLOT, OperandRole.SOURCE, OperandRole.OPERATION, OperandRole.IMMEDIATE), Reversibility.INTRINSIC),
      new Entry(
          "RESULT_FILL_BINARY_SOURCES", 0x020b, "RESULT_BINARY_SOURCES",
          List.of(OperandRole.RESULT_SLOT, OperandRole.SOURCE, OperandRole.OPERATION, OperandRole.RIGHT_SOURCE), Reversibility.INTRINSIC),
      new Entry(
          "EXPECT_EQ", 0x0300, "GLOBAL_IMMEDIATE",
          List.of(OperandRole.GLOBAL, OperandRole.IMMEDIATE), Reversibility.CHECKED),
      new Entry(
          "CHECKPOINT", 0x0301, "NONE",
          List.of(), Reversibility.INTRINSIC),
      new Entry(
          "COMMIT", 0x0302, "NONE",
          List.of(), Reversibility.BARRIER),
      new Entry(
          "EXPECT_TRUE", 0x0303, "CONDITION",
          List.of(OperandRole.CONDITION), Reversibility.CHECKED),
      new Entry(
          "LOCAL_CONST", 0x0400, "LOCAL_IMMEDIATE",
          List.of(OperandRole.DESTINATION, OperandRole.IMMEDIATE), Reversibility.CHECKED),
      new Entry(
          "LOCAL_LOAD_GLOBAL", 0x0401, "LOCAL_GLOBAL",
          List.of(OperandRole.DESTINATION, OperandRole.GLOBAL), Reversibility.CHECKED),
      new Entry(
          "LOCAL_STORE_GLOBAL", 0x0402, "GLOBAL_LOCAL",
          List.of(OperandRole.GLOBAL, OperandRole.SOURCE), Reversibility.LOGGED),
      new Entry(
          "LOCAL_MOVE", 0x0403, "LOCAL_SOURCE",
          List.of(OperandRole.DESTINATION, OperandRole.SOURCE), Reversibility.CHECKED),
      new Entry(
          "LOCAL_ADD", 0x0410, "LOCAL_BINARY",
          List.of(OperandRole.DESTINATION, OperandRole.LEFT_SOURCE, OperandRole.RIGHT_SOURCE), Reversibility.CHECKED),
      new Entry(
          "LOCAL_SUB", 0x0411, "LOCAL_BINARY",
          List.of(OperandRole.DESTINATION, OperandRole.LEFT_SOURCE, OperandRole.RIGHT_SOURCE), Reversibility.CHECKED),
      new Entry(
          "LOCAL_XOR", 0x0412, "LOCAL_BINARY",
          List.of(OperandRole.DESTINATION, OperandRole.LEFT_SOURCE, OperandRole.RIGHT_SOURCE), Reversibility.CHECKED),
      new Entry(
          "LOCAL_MUL", 0x0413, "LOCAL_BINARY",
          List.of(OperandRole.DESTINATION, OperandRole.LEFT_SOURCE, OperandRole.RIGHT_SOURCE), Reversibility.CHECKED),
      new Entry(
          "LOCAL_DIV", 0x0414, "LOCAL_BINARY",
          List.of(OperandRole.DESTINATION, OperandRole.LEFT_SOURCE, OperandRole.RIGHT_SOURCE), Reversibility.CHECKED),
      new Entry(
          "LOCAL_MOD", 0x0415, "LOCAL_BINARY",
          List.of(OperandRole.DESTINATION, OperandRole.LEFT_SOURCE, OperandRole.RIGHT_SOURCE), Reversibility.CHECKED),
      new Entry(
          "LOCAL_AND", 0x0416, "LOCAL_BINARY",
          List.of(OperandRole.DESTINATION, OperandRole.LEFT_SOURCE, OperandRole.RIGHT_SOURCE), Reversibility.CHECKED),
      new Entry(
          "LOCAL_ROTR32", 0x0417, "LOCAL_BINARY",
          List.of(OperandRole.DESTINATION, OperandRole.LEFT_SOURCE, OperandRole.RIGHT_SOURCE), Reversibility.CHECKED),
      new Entry(
          "LOCAL_EQ", 0x0420, "LOCAL_BINARY",
          List.of(OperandRole.DESTINATION, OperandRole.LEFT_SOURCE, OperandRole.RIGHT_SOURCE), Reversibility.CHECKED),
      new Entry(
          "LOCAL_LT", 0x0421, "LOCAL_BINARY",
          List.of(OperandRole.DESTINATION, OperandRole.LEFT_SOURCE, OperandRole.RIGHT_SOURCE), Reversibility.CHECKED),
      new Entry(
          "JUMP", 0x0430, "TARGET",
          List.of(OperandRole.TARGET), Reversibility.CHECKED),
      new Entry(
          "JUMP_IF_ZERO", 0x0431, "LOCAL_TARGET",
          List.of(OperandRole.CONDITION, OperandRole.TARGET), Reversibility.CHECKED),
      new Entry(
          "LOCAL_LOOP_CHECK", 0x0432, "LOOP_CHECK",
          List.of(OperandRole.ITERATION, OperandRole.LIMIT), Reversibility.CHECKED),
      new Entry(
          "RECORD_NEW", 0x0500, "RECORD_NEW",
          List.of(OperandRole.DESTINATION, OperandRole.DESCRIPTOR, OperandRole.ELEMENT_BASE, OperandRole.ELEMENT_COUNT), Reversibility.CHECKED),
      new Entry(
          "RECORD_GET", 0x0501, "RECORD_GET",
          List.of(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.INDEX), Reversibility.CHECKED),
      new Entry(
          "VARIANT_NEW", 0x0510, "VARIANT_NEW",
          List.of(OperandRole.DESTINATION, OperandRole.DESCRIPTOR, OperandRole.TAG, OperandRole.ELEMENT_BASE, OperandRole.ELEMENT_COUNT), Reversibility.CHECKED),
      new Entry(
          "VARIANT_TAG_EQ", 0x0511, "VARIANT_TAG",
          List.of(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.TAG), Reversibility.CHECKED),
      new Entry(
          "VARIANT_GET", 0x0512, "VARIANT_GET",
          List.of(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.TAG, OperandRole.INDEX), Reversibility.CHECKED),
      new Entry(
          "ARRAY_NEW", 0x0520, "ARRAY_NEW",
          List.of(OperandRole.DESTINATION, OperandRole.DESCRIPTOR, OperandRole.ELEMENT_BASE, OperandRole.ELEMENT_COUNT), Reversibility.CHECKED),
      new Entry(
          "ARRAY_GET", 0x0521, "ARRAY_GET",
          List.of(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.INDEX), Reversibility.CHECKED),
      new Entry(
          "SLICE_NEW", 0x0530, "SLICE_NEW",
          List.of(OperandRole.DESTINATION, OperandRole.DESCRIPTOR, OperandRole.OWNER, OperandRole.START, OperandRole.LENGTH), Reversibility.CHECKED),
      new Entry(
          "SLICE_GET", 0x0531, "SLICE_GET",
          List.of(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.INDEX), Reversibility.CHECKED),
      new Entry(
          "OWNED_MOVE", 0x0540, "LOCAL_SOURCE",
          List.of(OperandRole.DESTINATION, OperandRole.SOURCE), Reversibility.CHECKED),
      new Entry(
          "REGION_NEW", 0x0541, "REGION_NEW",
          List.of(OperandRole.DESTINATION, OperandRole.CAPACITY, OperandRole.ALLOCATION_LIMIT), Reversibility.CHECKED),
      new Entry(
          "WORDS_ALLOC", 0x0542, "STORAGE_ALLOC",
          List.of(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.CAPACITY), Reversibility.CHECKED),
      new Entry(
          "WORDS_GET", 0x0543, "STORAGE_GET",
          List.of(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.INDEX), Reversibility.CHECKED),
      new Entry(
          "WORDS_SET", 0x0544, "STORAGE_SET",
          List.of(OperandRole.OWNER, OperandRole.INDEX, OperandRole.SOURCE), Reversibility.LOGGED),
      new Entry(
          "BUFFER_DROP", 0x0545, "LOCAL",
          List.of(OperandRole.LOCAL), Reversibility.CHECKED),
      new Entry(
          "REGION_DROP", 0x0546, "LOCAL",
          List.of(OperandRole.LOCAL), Reversibility.CHECKED),
      new Entry(
          "BYTES_ALLOC", 0x0547, "STORAGE_ALLOC",
          List.of(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.CAPACITY), Reversibility.CHECKED),
      new Entry(
          "BYTES_GET", 0x0548, "STORAGE_GET",
          List.of(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.INDEX), Reversibility.CHECKED),
      new Entry(
          "BYTES_SET", 0x0549, "STORAGE_SET",
          List.of(OperandRole.OWNER, OperandRole.INDEX, OperandRole.SOURCE), Reversibility.LOGGED),
      new Entry(
          "UTF8_VALID", 0x054a, "LOCAL_SOURCE",
          List.of(OperandRole.DESTINATION, OperandRole.SOURCE), Reversibility.CHECKED),
      new Entry(
          "UTF8_COUNT", 0x054b, "LOCAL_SOURCE",
          List.of(OperandRole.DESTINATION, OperandRole.SOURCE), Reversibility.CHECKED),
      new Entry(
          "BUFFER_LENGTH", 0x054c, "LOCAL_SOURCE",
          List.of(OperandRole.DESTINATION, OperandRole.SOURCE), Reversibility.CHECKED),
      new Entry(
          "UTF8_SCALAR", 0x054d, "STORAGE_GET",
          List.of(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.INDEX), Reversibility.CHECKED),
      new Entry(
          "UTF8_WIDTH", 0x054e, "STORAGE_GET",
          List.of(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.INDEX), Reversibility.CHECKED),
      new Entry(
          "MAP_ALLOC", 0x054f, "STORAGE_ALLOC",
          List.of(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.CAPACITY), Reversibility.CHECKED),
      new Entry(
          "MAP_PUT", 0x0550, "MAP_PUT",
          List.of(OperandRole.OWNER, OperandRole.KEY, OperandRole.SOURCE), Reversibility.LOGGED),
      new Entry(
          "MAP_GET", 0x0551, "MAP_GET",
          List.of(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.KEY), Reversibility.CHECKED),
      new Entry(
          "MAP_HAS", 0x0552, "MAP_GET",
          List.of(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.KEY), Reversibility.CHECKED),
      new Entry(
          "UTF8_FREEZE", 0x0553, "LOCAL_SOURCE",
          List.of(OperandRole.DESTINATION, OperandRole.SOURCE), Reversibility.LOGGED),
      new Entry(
          "UTF8_BORROW", 0x0554, "LOCAL_SOURCE",
          List.of(OperandRole.DESTINATION, OperandRole.SOURCE), Reversibility.CHECKED),
      new Entry(
          "MAP_BORROW", 0x0555, "LOCAL_SOURCE",
          List.of(OperandRole.DESTINATION, OperandRole.SOURCE), Reversibility.CHECKED),
      new Entry(
          "BUFFER_BORROW", 0x0556, "LOCAL_SOURCE",
          List.of(OperandRole.DESTINATION, OperandRole.SOURCE), Reversibility.CHECKED),
      new Entry(
          "REGION_BORROW", 0x0557, "LOCAL_SOURCE",
          List.of(OperandRole.DESTINATION, OperandRole.SOURCE), Reversibility.CHECKED),
      new Entry(
          "OUTPUT_LENGTH", 0x0558, "OUTPUT_LENGTH",
          List.of(OperandRole.OWNER, OperandRole.LENGTH), Reversibility.LOGGED));

  static List<Entry> entries() {
    return ENTRIES;
  }

  record Entry(
      String name,
      int identity,
      String form,
      List<OperandRole> roles,
      Reversibility reversibility) {
    Entry {
      roles = List.copyOf(roles);
    }
  }

  private GeneratedInstructionRegistry() {}
}
