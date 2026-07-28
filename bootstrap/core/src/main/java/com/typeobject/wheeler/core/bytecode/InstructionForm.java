package com.typeobject.wheeler.core.bytecode;

import java.util.List;

/** Stable operand layouts for classical instructions. */
public enum InstructionForm {
  NONE(),
  FUNCTION(OperandRole.FUNCTION),
  RESULT(OperandRole.RESULT),
  GLOBAL_IMMEDIATE(OperandRole.GLOBAL, OperandRole.IMMEDIATE),
  GLOBAL_PAIR(OperandRole.LEFT_GLOBAL, OperandRole.RIGHT_GLOBAL),
  LOCAL(OperandRole.LOCAL),
  CONDITION(OperandRole.CONDITION),
  LOCAL_IMMEDIATE(OperandRole.DESTINATION, OperandRole.IMMEDIATE),
  LOCAL_GLOBAL(OperandRole.DESTINATION, OperandRole.GLOBAL),
  GLOBAL_LOCAL(OperandRole.GLOBAL, OperandRole.SOURCE),
  LOCAL_SOURCE(OperandRole.DESTINATION, OperandRole.SOURCE),
  LOCAL_BINARY(OperandRole.DESTINATION, OperandRole.LEFT_SOURCE, OperandRole.RIGHT_SOURCE),
  LOCAL_PAIR(OperandRole.LEFT_SOURCE, OperandRole.RIGHT_SOURCE),
  TARGET(OperandRole.TARGET),
  LOCAL_TARGET(OperandRole.CONDITION, OperandRole.TARGET),
  CALL_VALUE(
      OperandRole.FUNCTION,
      OperandRole.ARGUMENT_BASE,
      OperandRole.ARGUMENT_COUNT,
      OperandRole.RESULT),
  CALL_VOID(OperandRole.FUNCTION, OperandRole.ARGUMENT_BASE, OperandRole.ARGUMENT_COUNT),
  RECORD_NEW(
      OperandRole.DESTINATION,
      OperandRole.DESCRIPTOR,
      OperandRole.ELEMENT_BASE,
      OperandRole.ELEMENT_COUNT),
  RECORD_GET(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.INDEX),
  VARIANT_NEW(
      OperandRole.DESTINATION,
      OperandRole.DESCRIPTOR,
      OperandRole.TAG,
      OperandRole.ELEMENT_BASE,
      OperandRole.ELEMENT_COUNT),
  VARIANT_TAG(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.TAG),
  VARIANT_GET(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.TAG, OperandRole.INDEX),
  ARRAY_NEW(
      OperandRole.DESTINATION,
      OperandRole.DESCRIPTOR,
      OperandRole.ELEMENT_BASE,
      OperandRole.ELEMENT_COUNT),
  ARRAY_GET(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.INDEX),
  SLICE_NEW(
      OperandRole.DESTINATION,
      OperandRole.DESCRIPTOR,
      OperandRole.OWNER,
      OperandRole.START,
      OperandRole.LENGTH),
  SLICE_GET(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.INDEX),
  REGION_NEW(OperandRole.DESTINATION, OperandRole.CAPACITY, OperandRole.ALLOCATION_LIMIT),
  STORAGE_GET(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.INDEX),
  STORAGE_SET(OperandRole.OWNER, OperandRole.INDEX, OperandRole.SOURCE),
  STORAGE_ALLOC(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.CAPACITY),
  MAP_PUT(OperandRole.OWNER, OperandRole.KEY, OperandRole.SOURCE),
  MAP_GET(OperandRole.DESTINATION, OperandRole.OWNER, OperandRole.KEY),
  OUTPUT_LENGTH(OperandRole.OWNER, OperandRole.LENGTH);

  private final List<OperandRole> roles;

  InstructionForm(OperandRole... roles) {
    this.roles = List.of(roles);
  }

  public int operandCount() {
    return roles.size();
  }

  public List<OperandRole> roles() {
    return roles;
  }

  /** Semantic field roles. Position is significant and never inferred from a mnemonic. */
  public enum OperandRole {
    FUNCTION,
    RESULT,
    GLOBAL,
    LEFT_GLOBAL,
    RIGHT_GLOBAL,
    LOCAL,
    IMMEDIATE,
    DESTINATION,
    SOURCE,
    LEFT_SOURCE,
    RIGHT_SOURCE,
    CONDITION,
    TARGET,
    ARGUMENT_BASE,
    ARGUMENT_COUNT,
    DESCRIPTOR,
    OWNER,
    ELEMENT_BASE,
    ELEMENT_COUNT,
    INDEX,
    TAG,
    START,
    LENGTH,
    CAPACITY,
    ALLOCATION_LIMIT,
    KEY
  }
}
