//! Checks the physical helper parameter-count map through native package tests.

module wheeler.compiler.tests.native_compiler_helper_signatures;

import wheeler.compiler.helper_signatures;

classical class NativeCompilerHelperSignatureTests {
  entry void main() {
    assert(true);
  }

  test void checksSixteenParameterHelper() {
    long count = parameterCountForHelper(48);
    assert(count == 16);
  }

  test void checksSixteenParameterSignedKind() {
    long kind = signedScalarHelperKind(16);
    assert(kind == 48);
  }

  test void checksSixteenParameterBooleanKind() {
    long kind = booleanScalarHelperKind(16);
    assert(kind == 80);
  }

  test void checksTenParameterUtf8Kind() {
    long kind = utf8ScalarHelperKind(10);
    assert(kind == 82);
  }

  test void checksReversibleHelper() {
    boolean reversible = reversibleHelper(12);
    assert(reversible);
  }

  test void checksResultSlotHelper() {
    boolean resultSlot = resultSlotHelper(12);
    assert(resultSlot);
  }

  test void checksUtf8ResultHelper() {
    boolean utf8 = utf8ResultHelper(82);
    assert(utf8);
  }

  test void checksBooleanResultHelper() {
    boolean result = booleanResultHelper(80);
    assert(result);
  }

  test void checksBooleanParameterHelper() {
    boolean parameter = booleanParameterHelper(7);
    assert(parameter);
  }
}
