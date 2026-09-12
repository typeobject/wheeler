//! Binds an explicit package target to one counted ordinary classical entry.

module wheeler.compiler.closure.source_entry_products;

import wheeler.compiler.closure.callable_signature_products;
import wheeler.compiler.entry_signatures;
import wheeler.compiler.packages.manifest_kinds;
import wheeler.compiler.source_identifier_ranges;
import wheeler.compiler.source_member_modifiers;
import wheeler.compiler.type_codes;

classical class SourceEntryProducts {
  private const long MAX_CALLABLES = 64;
  private const long MAX_CLOSURE_CALLABLES = 4096;
  private const long ENTRY_NAME_BYTES = 4;
  private const long INPUT_LOAN = 1;
  private const long OUTPUT_LOAN = 2;

  /// Selects a source-local entry ordinal, or minus one for a library target.
  public record SourceEntryPlan(long targetKind, long entryCallable, boolean valid) {}

  private boolean entryName(borrow byteview names, long start, long length) {
    if (length != ENTRY_NAME_BYTES) {
      return false;
    }

    if (names[start] != 109) {
      return false;
    }

    if (names[start + 1] != 97) {
      return false;
    }

    if (names[start + 2] != 105) {
      return false;
    }

    return names[start + 3] == 110;
  }

  private long entryParameterType(long type, long mode) {
    if (mode == INPUT_LOAN) {
      if (type == TYPE_UTF8) {
        return TYPE_UTF8_BORROW;
      }

      if (type == TYPE_BYTE_VIEW) {
        return TYPE_BYTE_VIEW;
      }
    }

    if (mode == OUTPUT_LOAN) {
      if (type == TYPE_BYTES) {
        return TYPE_BYTES_BORROW;
      }
    }

    return -1;
  }

  private boolean entryParameters(
    long first,
    long count,
    borrow mut words types,
    borrow mut words modes
  ) {
    if (MAX_ENTRY_PARAMETERS < count) {
      return false;
    }

    long firstType = 0;
    long secondType = 0;
    if (0 < count) {
      firstType = entryParameterType(types[first], modes[first]);
    }

    if (1 < count) {
      secondType = entryParameterType(types[first + 1], modes[first + 1]);
    }

    return entryParameterTypesValid(count, firstType, secondType);
  }

  /// Validates the complete callable window before returning a target binding.
  /// Binding does not prove a body or select its lowering policy.
  public SourceEntryPlan bindSourceEntry(
    long targetKind,
    long firstCallable,
    long callableCount,
    borrow byteview names,
    borrow mut words nameStarts,
    borrow mut words nameLengths,
    borrow mut words effects,
    borrow mut words firstParameters,
    borrow mut words parameterCounts,
    borrow mut words resultTypes,
    borrow mut words parameterTypes,
    borrow mut words parameterModes
  ) {
    boolean executable = targetKind == PACKAGE_TARGET_DEPLOYABLE;
    if (targetKind == PACKAGE_TARGET_TOOL) {
      executable = true;
    }

    if (executable == false) {
      if (targetKind != PACKAGE_TARGET_LIBRARY) {
        return new SourceEntryPlan(targetKind, -1, false);
      }
    }

    boolean valid = -1 < firstCallable;
    if (MAX_CLOSURE_CALLABLES < firstCallable) {
      valid = false;
    }

    if (callableCount < 0) {
      valid = false;
    }

    if (MAX_CALLABLES < callableCount) {
      valid = false;
    }

    if (valid == false) {
      return new SourceEntryPlan(targetKind, -1, false);
    }

    if (MAX_CLOSURE_CALLABLES - firstCallable < callableCount) {
      valid = false;
    }

    if (bufferLength(nameStarts) != MAX_CLOSURE_CALLABLES) {
      valid = false;
    }

    if (bufferLength(nameLengths) != MAX_CLOSURE_CALLABLES) {
      valid = false;
    }

    if (bufferLength(effects) != MAX_CLOSURE_CALLABLES) {
      valid = false;
    }

    if (bufferLength(firstParameters) != MAX_CLOSURE_CALLABLES) {
      valid = false;
    }

    if (bufferLength(parameterCounts) != MAX_CLOSURE_CALLABLES) {
      valid = false;
    }

    if (bufferLength(resultTypes) != MAX_CLOSURE_CALLABLES) {
      valid = false;
    }

    if (bufferLength(parameterTypes) != MAX_CLOSURE_PARAMETERS) {
      valid = false;
    }

    if (bufferLength(parameterModes) != MAX_CLOSURE_PARAMETERS) {
      valid = false;
    }

    if (valid == false) {
      return new SourceEntryPlan(targetKind, -1, false);
    }

    long selected = -1;
    long mainNames = 0;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long row = firstCallable + callable;
      if (
        copiedSourceIdentifierValid(names, nameStarts[row], nameLengths[row]) == false
      ) {
        return new SourceEntryPlan(targetKind, -1, false);
      }

      long first = firstParameters[row];
      long count = parameterCounts[row];
      if (first < 0) {
        valid = false;
      }

      if (MAX_CLOSURE_PARAMETERS < first) {
        valid = false;
      }

      if (count < 0) {
        valid = false;
      }

      if (MAX_CALLABLE_PARAMETERS < count) {
        valid = false;
      }

      if (valid == false) {
        return new SourceEntryPlan(targetKind, -1, false);
      }

      if (MAX_CLOSURE_PARAMETERS - first < count) {
        return new SourceEntryPlan(targetKind, -1, false);
      }

      boolean main = entryName(names, nameStarts[row], nameLengths[row]);
      if (main) {
        mainNames += 1;
      }

      long effect = effects[row];
      if (effect == MEMBER_ENTRY) {
        if (executable == false) {
          valid = false;
        }

        if (-1 < selected) {
          valid = false;
        }

        if (main == false) {
          valid = false;
        }

        if (resultTypes[row] != 0) {
          valid = false;
        }

        if (entryParameters(first, count, parameterTypes, parameterModes) == false) {
          valid = false;
        }

        selected = callable;
      } else {
        if (effect != 0) {
          if (effect != MEMBER_REV) {
            valid = false;
          }
        }
      }

      if (valid == false) {
        return new SourceEntryPlan(targetKind, -1, false);
      }

      callable += 1;
    }

    if (executable) {
      if (selected < 0) {
        valid = false;
      }

      if (mainNames != 1) {
        valid = false;
      }
    }

    if (valid == false) {
      selected = -1;
    }

    return new SourceEntryPlan(targetKind, selected, valid);
  }
}
