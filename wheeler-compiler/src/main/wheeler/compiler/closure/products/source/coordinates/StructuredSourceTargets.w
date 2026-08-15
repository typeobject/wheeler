//! Resolves structured signature types and stable local target identities.

module wheeler.compiler.closure.structured_source_targets;

import wheeler.crypto.sha256;

classical class StructuredSourceTargets {
  private const long MAX_CALLABLES = 64;

  /// Reports one complete local target name and signature table.
  public record LocalStructuredTargetPlan(long parameterCount, boolean valid) {}

  /// Publishes local target names, signatures, effects, and stable identities.
  public LocalStructuredTargetPlan materializeLocalStructuredTargets(
    long firstCallable,
    long callableCount,
    borrow byteview strings,
    long stringBytes,
    long stringCount,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    borrow mut words functionNameIds,
    borrow mut words parameterCounts,
    borrow mut words callableEffects,
    long signatureTypeCount,
    borrow mut words signatureTypes,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableParameterCounts,
    borrow mut words targetParameterStarts,
    borrow mut words targetParameterCounts,
    borrow mut words targetParameterTypes,
    borrow mut words targetEffects,
    borrow mut bytes targetIdentities
  ) {
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(-1 < firstCallable);
    assert(-1 < stringBytes);
    assert(0 < stringCount);
    long parameterCursor = 0;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long name = functionNameIds[callable];
      assert(-1 < name);
      assert(name < stringCount);
      long nameStart = stringStarts[name];
      long nameLength = stringLengths[name];
      assert(nameStart < stringBytes);
      assert(nameLength < stringBytes - nameStart + 1);
      long simpleStart = nameStart;
      long nameByte = 0;
      while (nameByte + 1 < nameLength) limit 256 {
        if (strings[nameStart + nameByte] == 58) {
          if (strings[nameStart + nameByte + 1] == 58) {
            simpleStart = nameStart + nameByte + 2;
          }
        }

        nameByte += 1;
      }

      assert(simpleStart < nameStart + nameLength);
      set(callableNameStarts, callable, simpleStart);
      set(callableNameLengths, callable, nameStart + nameLength - simpleStart);
      set(callableParameterCounts, callable, parameterCounts[callable]);
      writeTargetIdentity(strings, nameStart, nameLength, callable, targetIdentities);
      set(targetParameterStarts, callable, parameterCursor);
      set(targetParameterCounts, callable, parameterCounts[callable]);
      set(targetEffects, callable, callableEffects[firstCallable + callable]);
      long parameter = 0;
      while (parameter < parameterCounts[callable]) limit 256 {
        long type = signatureTypeAt(callable, parameter, signatureTypeCount, signatureTypes);
        assert(-1 < type);
        set(targetParameterTypes, parameterCursor, type);
        parameterCursor += 1;
        parameter += 1;
      }

      callable += 1;
    }

    return new LocalStructuredTargetPlan(parameterCursor, true);
  }

  /// Returns the sole type at one callable-local signature coordinate.
  public long signatureTypeAt(
    long owner,
    long local,
    long signatureTypeCount,
    borrow mut words signatureTypes
  ) {
    long selected = -1;
    long matches = 0;
    long type = 0;
    while (type < signatureTypeCount) limit 4096 {
      if (signatureTypes[type] == owner) {
        if (signatureTypes[4096 + type] == local) {
          selected = signatureTypes[8192 + type];
          matches += 1;
        }
      }

      type += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  /// Publishes resolved call coordinates, owners, and stable target identities.
  public void publishStructuredCallRelocations(
    long callCount,
    borrow mut words statements,
    borrow mut words callStatements,
    borrow mut words callRelocations,
    borrow byteview callRelocationIdentities,
    borrow mut words publishedRelocations,
    borrow mut words publishedRelocationOwners,
    borrow mut bytes publishedRelocationIdentities
  ) {
    assert(-1 < callCount);
    assert(callCount < 257);
    long call = 0;
    while (call < callCount) limit 256 {
      set(publishedRelocations, call, callRelocations[call]);
      set(publishedRelocationOwners, call, statements[callStatements[call]]);
      set(publishedRelocations, 256 + call, callRelocations[256 + call]);
      set(publishedRelocations, 512 + call, callRelocations[512 + call]);
      long identityByte = 0;
      while (identityByte < 32) limit 32 {
        setByte(
          publishedRelocationIdentities,
          call * 32 + identityByte,
          callRelocationIdentities[call * 32 + identityByte]
        );
        identityByte += 1;
      }

      call += 1;
    }
  }

  /// Hashes one canonical local target name into its stable identity row.
  public void writeTargetIdentity(
    borrow byteview names,
    long start,
    long length,
    long target,
    borrow mut bytes identities
  ) {
    region hashArena = new region(/* bytes= */ 1232, /* allocations= */ 4);
    bytes digest = allocateBytes(hashArena, /* length= */ 32);
    hashSha256Range(names, start, length, digest, hashArena);
    long identityByte = 0;
    while (identityByte < 32) limit 32 {
      setByte(identities, target * 32 + identityByte, digest[identityByte]);
      identityByte += 1;
    }

    drop(digest);
    drop(hashArena);
  }
}
