//! Checks every signed helper-result family through native package tests.

module wheeler.compiler.tests.native_compiler_signed_helper_result_kinds;

import wheeler.compiler.signed_helper_result_kinds;

classical class NativeCompilerSignedHelperResultKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesDirectAndArithmeticResults() tags(signed.helper.result) {
    boolean directResult = signedHelperResult(827);
    boolean arithmeticResult = signedHelperResult(830);
    assert(directResult);
    assert(arithmeticResult);
  }

  test void classifiesResolvedLocalResult() tags(signed.helper.result) {
    boolean result = signedHelperResult(14336);
    assert(result);
  }

  test void classifiesForwardedResult() tags(signed.helper.result) {
    boolean result = signedHelperResult(27648);
    assert(result);
  }

  test void classifiesBorrowedLengthResult() tags(signed.helper.result) {
    boolean result = signedHelperResult(131072);
    assert(result);
  }

  test void classifiesBorrowedIndexedResult() tags(signed.helper.result) {
    boolean result = signedHelperResult(131341);
    assert(result);
  }

  test void classifiesUtf8ScalarResult() tags(signed.helper.result) {
    boolean result = signedHelperResult(131342);
    assert(result);
  }

  test void classifiesUtf8WidthResult() tags(signed.helper.result) {
    boolean result = signedHelperResult(131343);
    assert(result);
  }

  test void classifiesMapResult() tags(signed.helper.result) {
    boolean result = signedHelperResult(131344);
    assert(result);
  }

  test void classifiesLocalPairResult() tags(signed.helper.result) {
    boolean result = signedHelperResult(836);
    assert(result);
  }

  test void rejectsBooleanResult() tags(signed.helper.result) {
    boolean result = signedHelperResult(846);
    boolean rejected = !result;
    assert(rejected);
  }

  test void rejectsUnknownResult() tags(signed.helper.result) {
    boolean result = signedHelperResult(-1);
    boolean rejected = !result;
    assert(rejected);
  }
}
