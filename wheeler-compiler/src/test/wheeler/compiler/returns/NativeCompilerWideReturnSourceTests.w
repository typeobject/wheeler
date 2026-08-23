//! Checks physical wide-return source packing through native package tests.

module wheeler.compiler.tests.native_compiler_wide_return_sources;

import wheeler.compiler.wide_return_sources;

classical class NativeCompilerWideReturnSourceTests {
  entry void main() {
    assert(true);
  }

  test void checksLeadingWideReturnSources() {
    long first = 10;
    long second = 11;
    long third = 12;
    long fourth = 13;
    long sources = packWideReturnFirstSources(first, second, third, fourth);
    assert(sources == 168496141);
  }

  test void checksTrailingWideReturnSources() {
    long fifth = 14;
    long sixth = 15;
    long seventh = 16;
    long sources = packWideReturnLastSources(fifth, sixth, seventh);
    assert(sources == 921360);
  }

  test void checksFirstWideReturnSource() {
    long source = wideReturnFirstSource(168496141);
    assert(source == 10);
  }

  test void checksSecondWideReturnSource() {
    long source = wideReturnSecondSource(168496141);
    assert(source == 11);
  }

  test void checksThirdWideReturnSource() {
    long source = wideReturnThirdSource(168496141);
    assert(source == 12);
  }

  test void checksFourthWideReturnSource() {
    long source = wideReturnFourthSource(168496141);
    assert(source == 13);
  }

  test void checksFifthWideReturnSource() {
    long source = wideReturnFifthSource(921360);
    assert(source == 14);
  }

  test void checksSixthWideReturnSource() {
    long source = wideReturnSixthSource(921360);
    assert(source == 15);
  }

  test void checksSeventhWideReturnSource() {
    long source = wideReturnSeventhSource(921360);
    assert(source == 16);
  }
}
