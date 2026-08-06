//! Plans bounded fixed-array descriptors in canonical declaration order.

module wheeler.compiler.fixed_array_types;

import wheeler.compiler.helper_abi;
import wheeler.compiler.ir;
import wheeler.compiler.type_codes;

classical class FixedArrayTypes {
  private long sourceArrayLength(long sourceType) {
    if (sourceType % TYPE_SOURCE_METADATA_SCALE == TYPE_ARRAY) {
      return sourceType / TYPE_SOURCE_METADATA_SCALE;
    }

    return 0;
  }

  private boolean arrayLengthSeenBefore(
    MinimalProgram program,
    long stopHelper,
    long stopParameter,
    long arrayLength
  ) {
    long helper = 0;
    while (helper < stopHelper + 1) limit MAX_SCALAR_HELPERS {
      HelperBody body = helperAt(program, helper);
      long parameterLimit = body.parameterCount;
      if (helper == stopHelper) {
        parameterLimit = stopParameter;
      }

      long parameter = 0;
      while (parameter < parameterLimit) limit MAX_SCALAR_HELPER_PARAMETERS {
        if (sourceArrayLength(body.parameterTypes[parameter]) == arrayLength) {
          return true;
        }

        parameter += 1;
      }

      helper += 1;
    }

    return false;
  }

  /// Counts unique fixed-array types in first declaration order.
  public long programArrayTypeCount(MinimalProgram program) {
    long count = 0;
    long helper = 0;
    while (helper < program.helperCount) limit MAX_SCALAR_HELPERS {
      HelperBody body = helperAt(program, helper);
      long parameter = 0;
      while (parameter < body.parameterCount) limit MAX_SCALAR_HELPER_PARAMETERS {
        long arrayLength = sourceArrayLength(body.parameterTypes[parameter]);
        if (0 < arrayLength) {
          if (arrayLengthSeenBefore(program, helper, parameter, arrayLength)) {} else {
            count += 1;
            assert(count < MAX_NATIVE_FIXED_ARRAY_TYPES + 1);
          }
        }

        parameter += 1;
      }

      helper += 1;
    }

    return count;
  }

  /// Returns one descriptor length by its canonical encounter-order identity.
  public long programArrayTypeLength(MinimalProgram program, long requestedId) {
    long descriptorId = 0;
    long helper = 0;
    while (helper < program.helperCount) limit MAX_SCALAR_HELPERS {
      HelperBody body = helperAt(program, helper);
      long parameter = 0;
      while (parameter < body.parameterCount) limit MAX_SCALAR_HELPER_PARAMETERS {
        long arrayLength = sourceArrayLength(body.parameterTypes[parameter]);
        if (0 < arrayLength) {
          if (arrayLengthSeenBefore(program, helper, parameter, arrayLength)) {} else {
            if (descriptorId == requestedId) {
              return arrayLength;
            }

            descriptorId += 1;
          }
        }

        parameter += 1;
      }

      helper += 1;
    }

    assert(0 == 1);
    return 0;
  }

  /// Removes source metadata and assigns the canonical array descriptor identity.
  public long canonicalProgramType(MinimalProgram program, long sourceType) {
    long arrayLength = sourceArrayLength(sourceType);
    if (arrayLength == 0) {
      return sourceType % TYPE_SOURCE_METADATA_SCALE;
    }

    long arrayCount = programArrayTypeCount(program);
    long descriptorId = 0;
    while (descriptorId < arrayCount) limit MAX_NATIVE_FIXED_ARRAY_TYPES {
      if (programArrayTypeLength(program, descriptorId) == arrayLength) {
        return TYPE_ARRAY + descriptorId;
      }

      descriptorId += 1;
    }

    assert(0 == 1);
    return 0;
  }
}
