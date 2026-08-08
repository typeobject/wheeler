//! Emits canonical global and aggregate sections from counted closure products.

module wheeler.compiler.closure.linked_aggregate_sections;

import wheeler.compiler.closure.linked_local_types;

classical class LinkedAggregateSections {
  private const long AGGREGATE_ROWS = 36864;
  private const long CASE_ROWS = 32768;
  private const long GLOBAL_ROWS = 20480;
  private const long MEMBER_ROWS = 65536;
  private const long MAX_AGGREGATES = 4096;
  private const long MAX_CASES = 8192;
  private const long MAX_GLOBALS = 4096;
  private const long MAX_MEMBERS = 16384;
  private const long MAX_MODULES = 512;
  private const long MAX_STRINGS = 16384;

  private void writeUnsigned(borrow mut bytes output, long cursor, long width, long value) {
    assert(-1 < value);
    long remaining = value;
    long outputByte = 0;
    while (outputByte < width) limit 8 {
      setByte(output, cursor + outputByte, remaining % 256);
      remaining = remaining / 256;
      outputByte += 1;
    }

    assert(remaining == 0);
  }

  private long finalString(
    long owner,
    long localString,
    long closureStringCount,
    borrow mut words moduleStringBases,
    borrow mut words finalStringRows
  ) {
    assert(-1 < owner);
    assert(owner < MAX_MODULES);
    assert(-1 < localString);
    long closureString = moduleStringBases[owner] + localString;
    assert(-1 < closureString);
    assert(closureString < closureStringCount);
    long selected = finalStringRows[closureString];
    assert(-1 < selected);
    assert(selected < closureStringCount);
    return selected;
  }

  /// Emits section type 3: globals, records, arrays, and slices.
  public long emitLinkedTypeSection(
    long globalCount,
    borrow mut words globalRows,
    long aggregateCount,
    long closureStringCount,
    borrow mut words moduleStringBases,
    borrow mut words finalStringRows,
    borrow mut words aggregateRows,
    borrow mut words memberRows,
    borrow mut words finalDescriptorRows,
    borrow mut bytes output,
    long outputStart
  ) {
    assert(-1 < outputStart);
    assert(-1 < globalCount);
    assert(globalCount < MAX_GLOBALS + 1);
    assert(bufferLength(globalRows) == GLOBAL_ROWS);
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_AGGREGATES + 1);
    assert(-1 < closureStringCount);
    assert(closureStringCount < MAX_STRINGS + 1);
    assert(bufferLength(moduleStringBases) == MAX_MODULES);
    assert(bufferLength(finalStringRows) == MAX_STRINGS);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(bufferLength(memberRows) == MEMBER_ROWS);
    assert(bufferLength(finalDescriptorRows) == MAX_AGGREGATES);

    long recordCount = 0;
    long arrayCount = 0;
    long sliceCount = 0;
    long sectionBytes = 16 + globalCount * 16;
    long aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES {
      long kind = aggregateRows[aggregate];
      long owner = aggregateRows[4096 + aggregate];
      long firstMember = aggregateRows[24576 + aggregate];
      long memberCount = aggregateRows[28672 + aggregate];
      assert(-1 < finalDescriptorRows[aggregate]);
      assert(firstMember < MAX_MEMBERS + 1);
      assert(memberCount < MAX_MEMBERS - firstMember + 1);
      if (kind == 1) {
        assert(-1 < aggregateRows[12288 + aggregate]);
        assert(
          -1 < finalString(
            owner,
            aggregateRows[12288 + aggregate],
            closureStringCount,
            moduleStringBases,
            finalStringRows
          )
        );
        recordCount += 1;
        sectionBytes += 12 + memberCount * 8;
      } else {
        if (kind == 2) {
          assert(memberCount == 1);
          arrayCount += 1;
          sectionBytes += 12;
        } else {
          if (kind == 3) {
            assert(memberCount == 1);
            sliceCount += 1;
            sectionBytes += 8;
          } else {
            assert(kind == 4);
          }
        }
      }

      long member = 0;
      while (member < memberCount) limit MAX_MEMBERS {
        long memberRow = firstMember + member;
        assert(memberRows[memberRow] == aggregate);
        assert(
          0 < linkedTypeCode(
            memberRows[49152 + memberRow],
            owner,
            aggregateCount,
            aggregateRows,
            finalDescriptorRows
          )
        );
        if (kind == 1) {
          assert(
            -1 < finalString(
              owner,
              memberRows[32768 + memberRow],
              closureStringCount,
              moduleStringBases,
              finalStringRows
            )
          );
        }

        member += 1;
      }

      aggregate += 1;
    }

    assert(outputStart < bufferLength(output) + 1);
    assert(sectionBytes < bufferLength(output) - outputStart + 1);

    long global = 0;
    while (global < globalCount) limit MAX_GLOBALS {
      long nameRow = globalRows[global];
      assert(-1 < nameRow);
      assert(nameRow < closureStringCount);
      assert(-1 < finalStringRows[nameRow]);
      assert(finalStringRows[nameRow] < closureStringCount);
      assert(
        0 < linkedTypeCode(
          globalRows[4096 + global],
          globalRows[16384 + global],
          aggregateCount,
          aggregateRows,
          finalDescriptorRows
        )
      );
      global += 1;
    }

    writeUnsigned(output, outputStart, 4, globalCount);
    long cursor = outputStart + 4;
    global = 0;
    while (global < globalCount) limit MAX_GLOBALS {
      writeUnsigned(output, cursor, 4, finalStringRows[globalRows[global]]);
      writeUnsigned(
        output,
        cursor + 4,
        4,
        linkedTypeCode(
          globalRows[4096 + global],
          globalRows[16384 + global],
          aggregateCount,
          aggregateRows,
          finalDescriptorRows
        )
      );
      writeUnsigned(output, cursor + 8, 4, globalRows[8192 + global]);
      writeUnsigned(output, cursor + 12, 4, globalRows[12288 + global]);
      cursor += 16;
      global += 1;
    }

    writeUnsigned(output, cursor, 4, recordCount);
    cursor += 4;
    long kindPass = 1;
    while (kindPass < 4) limit 3 {
      aggregate = 0;
      while (aggregate < aggregateCount) limit MAX_AGGREGATES {
        if (aggregateRows[aggregate] == kindPass) {
          long selectedOwner = aggregateRows[4096 + aggregate];
          long selectedFirstMember = aggregateRows[24576 + aggregate];
          long selectedMemberCount = aggregateRows[28672 + aggregate];
          writeUnsigned(output, cursor, 4, finalDescriptorRows[aggregate]);
          if (kindPass == 1) {
            writeUnsigned(
              output,
              cursor + 4,
              4,
              finalString(
                selectedOwner,
                aggregateRows[12288 + aggregate],
                closureStringCount,
                moduleStringBases,
                finalStringRows
              )
            );
            writeUnsigned(output, cursor + 8, 4, selectedMemberCount);
            cursor += 12;
            long selectedMember = 0;
            while (selectedMember < selectedMemberCount) limit MAX_MEMBERS {
              long selectedMemberRow = selectedFirstMember + selectedMember;
              writeUnsigned(
                output,
                cursor,
                4,
                finalString(
                  selectedOwner,
                  memberRows[32768 + selectedMemberRow],
                  closureStringCount,
                  moduleStringBases,
                  finalStringRows
                )
              );
              writeUnsigned(
                output,
                cursor + 4,
                4,
                linkedTypeCode(
                  memberRows[49152 + selectedMemberRow],
                  selectedOwner,
                  aggregateCount,
                  aggregateRows,
                  finalDescriptorRows
                )
              );
              cursor += 8;
              selectedMember += 1;
            }
          } else {
            writeUnsigned(
              output,
              cursor + 4,
              4,
              linkedTypeCode(
                memberRows[49152 + selectedFirstMember],
                selectedOwner,
                aggregateCount,
                aggregateRows,
                finalDescriptorRows
              )
            );
            if (kindPass == 2) {
              writeUnsigned(output, cursor + 8, 4, aggregateRows[32768 + aggregate]);
              cursor += 12;
            } else {
              cursor += 8;
            }
          }
        }

        aggregate += 1;
      }

      if (kindPass == 1) {
        writeUnsigned(output, cursor, 4, arrayCount);
        cursor += 4;
      } else {
        if (kindPass == 2) {
          writeUnsigned(output, cursor, 4, sliceCount);
          cursor += 4;
        }
      }

      kindPass += 1;
    }

    assert(cursor == outputStart + sectionBytes);
    return sectionBytes;
  }

  /// Emits section type 4: variants, cases, and fields.
  public long emitLinkedVariantSection(
    long aggregateCount,
    long caseCount,
    long closureStringCount,
    borrow mut words moduleStringBases,
    borrow mut words finalStringRows,
    borrow mut words aggregateRows,
    borrow mut words caseRows,
    borrow mut words memberRows,
    borrow mut words finalDescriptorRows,
    borrow mut bytes output,
    long outputStart
  ) {
    assert(-1 < outputStart);
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_AGGREGATES + 1);
    assert(-1 < caseCount);
    assert(caseCount < MAX_CASES + 1);
    assert(-1 < closureStringCount);
    assert(closureStringCount < MAX_STRINGS + 1);
    assert(bufferLength(moduleStringBases) == MAX_MODULES);
    assert(bufferLength(finalStringRows) == MAX_STRINGS);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(bufferLength(caseRows) == CASE_ROWS);
    assert(bufferLength(memberRows) == MEMBER_ROWS);
    assert(bufferLength(finalDescriptorRows) == MAX_AGGREGATES);

    long variantCount = 0;
    long sectionBytes = 4;
    long aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES {
      if (aggregateRows[aggregate] == 4) {
        long owner = aggregateRows[4096 + aggregate];
        long firstCase = aggregateRows[16384 + aggregate];
        long aggregateCaseCount = aggregateRows[20480 + aggregate];
        assert(firstCase < caseCount + 1);
        assert(aggregateCaseCount < caseCount - firstCase + 1);
        assert(-1 < finalDescriptorRows[aggregate]);
        assert(
          -1 < finalString(
            owner,
            aggregateRows[12288 + aggregate],
            closureStringCount,
            moduleStringBases,
            finalStringRows
          )
        );
        sectionBytes += 12;
        long selectedCase = 0;
        while (selectedCase < aggregateCaseCount) limit MAX_CASES {
          long caseRow = firstCase + selectedCase;
          long firstMember = caseRows[16384 + caseRow];
          long memberCount = caseRows[24576 + caseRow];
          assert(caseRows[caseRow] == aggregate);
          assert(firstMember < MAX_MEMBERS + 1);
          assert(memberCount < MAX_MEMBERS - firstMember + 1);
          assert(
            -1 < finalString(
              owner,
              caseRows[8192 + caseRow],
              closureStringCount,
              moduleStringBases,
              finalStringRows
            )
          );
          sectionBytes += 8 + memberCount * 8;
          long member = 0;
          while (member < memberCount) limit MAX_MEMBERS {
            long memberRow = firstMember + member;
            assert(memberRows[memberRow] == aggregate);
            assert(memberRows[16384 + memberRow] == caseRow);
            assert(
              -1 < finalString(
                owner,
                memberRows[32768 + memberRow],
                closureStringCount,
                moduleStringBases,
                finalStringRows
              )
            );
            assert(
              0 < linkedTypeCode(
                memberRows[49152 + memberRow],
                owner,
                aggregateCount,
                aggregateRows,
                finalDescriptorRows
              )
            );
            member += 1;
          }

          selectedCase += 1;
        }

        variantCount += 1;
      }

      aggregate += 1;
    }

    assert(outputStart < bufferLength(output) + 1);
    assert(sectionBytes < bufferLength(output) - outputStart + 1);

    writeUnsigned(output, outputStart, 4, variantCount);
    long cursor = outputStart + 4;
    aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES {
      if (aggregateRows[aggregate] == 4) {
        long outputOwner = aggregateRows[4096 + aggregate];
        long outputFirstCase = aggregateRows[16384 + aggregate];
        long outputCaseCount = aggregateRows[20480 + aggregate];
        writeUnsigned(output, cursor, 4, finalDescriptorRows[aggregate]);
        writeUnsigned(
          output,
          cursor + 4,
          4,
          finalString(
            outputOwner,
            aggregateRows[12288 + aggregate],
            closureStringCount,
            moduleStringBases,
            finalStringRows
          )
        );
        writeUnsigned(output, cursor + 8, 4, outputCaseCount);
        cursor += 12;
        long outputCase = 0;
        while (outputCase < outputCaseCount) limit MAX_CASES {
          long outputCaseRow = outputFirstCase + outputCase;
          long outputFirstMember = caseRows[16384 + outputCaseRow];
          long outputMemberCount = caseRows[24576 + outputCaseRow];
          writeUnsigned(
            output,
            cursor,
            4,
            finalString(
              outputOwner,
              caseRows[8192 + outputCaseRow],
              closureStringCount,
              moduleStringBases,
              finalStringRows
            )
          );
          writeUnsigned(output, cursor + 4, 4, outputMemberCount);
          cursor += 8;
          long outputMember = 0;
          while (outputMember < outputMemberCount) limit MAX_MEMBERS {
            long outputMemberRow = outputFirstMember + outputMember;
            writeUnsigned(
              output,
              cursor,
              4,
              finalString(
                outputOwner,
                memberRows[32768 + outputMemberRow],
                closureStringCount,
                moduleStringBases,
                finalStringRows
              )
            );
            writeUnsigned(
              output,
              cursor + 4,
              4,
              linkedTypeCode(
                memberRows[49152 + outputMemberRow],
                outputOwner,
                aggregateCount,
                aggregateRows,
                finalDescriptorRows
              )
            );
            cursor += 8;
            outputMember += 1;
          }

          outputCase += 1;
        }
      }

      aggregate += 1;
    }

    assert(cursor == outputStart + sectionBytes);
    return sectionBytes;
  }
}
