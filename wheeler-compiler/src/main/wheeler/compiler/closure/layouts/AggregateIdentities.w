//! Binds validated aggregate layouts to package, module, and artifact identities.

module wheeler.compiler.closure.aggregate_identities;

import wheeler.crypto.sha256;

classical class AggregateIdentities {
  private const long AGGREGATE_ROWS = 576;
  private const long CASE_ROWS = 512;
  private const long DEPENDENCY_IDENTITY_BYTES = 2048;
  private const long IDENTITY_BYTES = 32;
  private const long IDENTITY_ARENA_BYTES = 20032;
  private const long IDENTITY_INPUT_BYTES = 20000;
  private const long MAX_AGGREGATES_PER_MODULE = 64;
  private const long MAX_DIRECT_DEPENDENCIES = 64;
  private const long MAX_CASES_PER_MODULE = 128;
  private const long MAX_MEMBERS_PER_MODULE = 256;
  private const long MEMBER_ROWS = 1024;

  private long writeSigned(long value, borrow mut bytes input, long cursor) {
    long remaining = value;
    long index = 0;
    while (index < 8) limit 8 {
      long octet = remaining % 256;
      if (octet < 0) {
        octet += 256;
      }

      setByte(input, cursor + index, octet);
      remaining = (remaining - octet) / 256;
      index += 1;
    }

    return cursor + 8;
  }

  private long copyIdentity(borrow byteview identity, borrow mut bytes input, long cursor) {
    assert(bufferLength(identity) == IDENTITY_BYTES);
    long index = 0;
    while (index < IDENTITY_BYTES) limit IDENTITY_BYTES {
      setByte(input, cursor + index, identity[index]);
      index += 1;
    }

    return cursor + IDENTITY_BYTES;
  }

  private boolean validWindow(long first, long count, long total) {
    boolean valid = true;
    if (first < 0) {
      valid = false;
    }

    if (count < 0) {
      valid = false;
    }

    if (total < first) {
      valid = false;
    }

    if (valid) {
      if (total - first < count) {
        valid = false;
      }
    }

    return valid;
  }

  /// Publishes one stable identity after every packed layout row validates.
  public void publishAggregateModuleIdentity(
    borrow byteview artifact,
    long artifactLength,
    borrow byteview packageIdentity,
    borrow byteview moduleIdentity,
    long dependencyCount,
    borrow byteview dependencyIdentities,
    long owner,
    long aggregateCount,
    long caseCount,
    long memberCount,
    borrow mut words aggregateRows,
    borrow mut words caseRows,
    borrow mut words memberRows,
    borrow mut bytes identity
  ) {
    assert(0 < artifactLength);
    assert(artifactLength < bufferLength(artifact) + 1);
    assert(bufferLength(packageIdentity) == IDENTITY_BYTES);
    assert(bufferLength(moduleIdentity) == IDENTITY_BYTES);
    assert(-1 < dependencyCount);
    assert(dependencyCount < MAX_DIRECT_DEPENDENCIES + 1);
    assert(bufferLength(dependencyIdentities) == DEPENDENCY_IDENTITY_BYTES);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(bufferLength(caseRows) == CASE_ROWS);
    assert(bufferLength(memberRows) == MEMBER_ROWS);
    assert(bufferLength(identity) == IDENTITY_BYTES);
    assert(-1 < owner);
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_AGGREGATES_PER_MODULE + 1);
    assert(-1 < caseCount);
    assert(caseCount < MAX_CASES_PER_MODULE + 1);
    assert(-1 < memberCount);
    assert(memberCount < MAX_MEMBERS_PER_MODULE + 1);

    region inputArena = new region(/* bytes= */ IDENTITY_ARENA_BYTES, /* allocations= */ 2);
    bytes input = allocateBytes(inputArena, IDENTITY_INPUT_BYTES);
    bytes artifactIdentity = allocateBytes(inputArena, IDENTITY_BYTES);
    region artifactHashArena = new region(/* bytes= */ 1200, /* allocations= */ 3);
    hashSha256Range(artifact, 0, artifactLength, artifactIdentity, artifactHashArena);

    writeAscii(input, 0, "wheeler-aggregate-module-product-1");
    long cursor = 34;
    cursor = copyIdentity(packageIdentity, input, cursor);
    cursor = copyIdentity(moduleIdentity, input, cursor);
    cursor = copyIdentity(artifactIdentity, input, cursor);
    cursor = writeSigned(dependencyCount, input, cursor);
    long dependencyByte = 0;
    while (dependencyByte < dependencyCount * IDENTITY_BYTES) limit DEPENDENCY_IDENTITY_BYTES {
      setByte(input, cursor + dependencyByte, dependencyIdentities[dependencyByte]);
      dependencyByte += 1;
    }

    cursor += dependencyCount * IDENTITY_BYTES;
    cursor = writeSigned(aggregateCount, input, cursor);
    cursor = writeSigned(caseCount, input, cursor);
    cursor = writeSigned(memberCount, input, cursor);

    long aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES_PER_MODULE {
      long kind = aggregateRows[aggregate];
      assert(0 < kind);
      assert(kind < 5);
      assert(aggregateRows[64 + aggregate] == owner);
      long firstCase = aggregateRows[256 + aggregate];
      long aggregateCases = aggregateRows[320 + aggregate];
      long firstMember = aggregateRows[384 + aggregate];
      long aggregateMembers = aggregateRows[448 + aggregate];
      assert(validWindow(firstCase, aggregateCases, caseCount));
      assert(validWindow(firstMember, aggregateMembers, memberCount));
      if (kind == 1) {
        assert(aggregateCases == 0);
      }

      if (kind == 2) {
        assert(aggregateMembers == 1);
        assert(0 < aggregateRows[512 + aggregate]);
      }

      if (kind == 3) {
        assert(aggregateMembers == 1);
        assert(aggregateRows[512 + aggregate] == -1);
      }

      if (kind == 4) {
        assert(0 < aggregateCases);
      }

      cursor = writeSigned(kind, input, cursor);
      cursor = writeSigned(aggregateRows[128 + aggregate], input, cursor);
      cursor = writeSigned(aggregateRows[192 + aggregate], input, cursor);
      cursor = writeSigned(firstCase, input, cursor);
      cursor = writeSigned(aggregateCases, input, cursor);
      cursor = writeSigned(firstMember, input, cursor);
      cursor = writeSigned(aggregateMembers, input, cursor);
      cursor = writeSigned(aggregateRows[512 + aggregate], input, cursor);
      aggregate += 1;
    }

    long nextCase = 0;
    while (nextCase < caseCount) limit MAX_CASES_PER_MODULE {
      long caseAggregate = caseRows[nextCase];
      assert(-1 < caseAggregate);
      assert(caseAggregate < aggregateCount);
      assert(aggregateRows[caseAggregate] == 4);
      long caseFirstMember = caseRows[256 + nextCase];
      long caseMembers = caseRows[384 + nextCase];
      assert(validWindow(caseFirstMember, caseMembers, memberCount));
      cursor = writeSigned(caseAggregate, input, cursor);
      cursor = writeSigned(caseRows[128 + nextCase], input, cursor);
      cursor = writeSigned(caseFirstMember, input, cursor);
      cursor = writeSigned(caseMembers, input, cursor);
      nextCase += 1;
    }

    long member = 0;
    while (member < memberCount) limit MAX_MEMBERS_PER_MODULE {
      long memberAggregate = memberRows[member];
      assert(-1 < memberAggregate);
      assert(memberAggregate < aggregateCount);
      long memberCase = memberRows[256 + member];
      if (aggregateRows[memberAggregate] == 4) {
        assert(-1 < memberCase);
        assert(memberCase < caseCount);
        assert(caseRows[memberCase] == memberAggregate);
      } else {
        assert(memberCase == -1);
      }

      cursor = writeSigned(memberAggregate, input, cursor);
      cursor = writeSigned(memberCase, input, cursor);
      cursor = writeSigned(memberRows[512 + member], input, cursor);
      cursor = writeSigned(memberRows[768 + member], input, cursor);
      member += 1;
    }

    assert(cursor < IDENTITY_INPUT_BYTES + 1);
    region productHashArena = new region(/* bytes= */ 1200, /* allocations= */ 3);
    hashSha256Range(input, 0, cursor, identity, productHashArena);
    drop(productHashArena);
    drop(artifactHashArena);
    drop(artifactIdentity);
    drop(input);
    drop(inputArena);
  }
}
