package com.typeobject.wheeler.runtime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import javax.xml.parsers.DocumentBuilderFactory;
import org.junit.jupiter.api.Test;

/** Exercises coverage adapters and their unsupported-dimension disclosures. */
final class SemanticCoverageRendererTest {
  @Test
  void everyAdapterDisclosesUnavailableSemanticDimensions() throws Exception {
    SemanticCoverage coverage = coverage();
    String identity = coverage.identity();
    for (SemanticCoverageRenderer.Format format : SemanticCoverageRenderer.Format.values()) {
      String first = SemanticCoverageRenderer.render(coverage, "example<&>", format);
      String second = SemanticCoverageRenderer.render(coverage, "example<&>", format);
      assertEquals(first, second);
      assertTrue(first.contains(identity));
      assertTrue(first.toLowerCase(java.util.Locale.ROOT).contains("unsupported"));
      assertTrue(first.contains("source-lines"));
      assertTrue(first.contains("proof-obligations"));
      assertTrue(first.contains("quantum-state"));
    }
  }

  @Test
  void structuredAdaptersRemainMachineReadableWithoutInventingSourceMappings()
      throws Exception {
    SemanticCoverage coverage = coverage();
    String json = SemanticCoverageRenderer.render(
        coverage, "fixture", SemanticCoverageRenderer.Format.JSON);
    assertTrue(json.startsWith("{\"schema\":\"wheeler-coverage-adapter/1\""));
    assertTrue(json.contains("\"function\":0"));
    assertTrue(json.contains("\"instruction\":0"));

    String lcov = SemanticCoverageRenderer.render(
        coverage, "fixture", SemanticCoverageRenderer.Format.LCOV);
    assertTrue(lcov.contains("SF:wheeler-bytecode/function-0\n"));
    assertTrue(lcov.contains("# wheeler-unsupported:"));

    String cobertura = SemanticCoverageRenderer.render(
        coverage, "fixture", SemanticCoverageRenderer.Format.COBERTURA);
    parseXml(cobertura);
    assertTrue(cobertura.contains("wheeler-unsupported="));
    assertTrue(cobertura.contains("filename=\"wheeler-bytecode/function-0\""));

    String website = SemanticCoverageRenderer.render(
        coverage, "fixture", SemanticCoverageRenderer.Format.WEBSITE);
    parseXml(website.substring("<!doctype html>".length()));
    assertTrue(website.contains("data-unsupported="));
    assertTrue(website.contains("<h1>fixture</h1>"));
  }

  @Test
  void adaptersDoNotChangeCanonicalCoverageOrAdmitForgedCoordinates() {
    SemanticCoverage coverage = coverage();
    String report = coverage.canonicalReport();
    String identity = coverage.identity();
    for (SemanticCoverageRenderer.Format format : SemanticCoverageRenderer.Format.values()) {
      SemanticCoverageRenderer.render(coverage, "fixture", format);
    }
    assertEquals(report, coverage.canonicalReport());
    assertEquals(identity, coverage.identity());
    assertThrows(
        IllegalArgumentException.class,
        () -> new SemanticCoverage.Point("forward", -1, 0, "HALT", "none"));
  }

  private static SemanticCoverage coverage() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.ADD_CONST, 0, 1), Instruction.of(Opcode.HALT)),
        List.of());
    Program program = new Program(
        "CoverageAdapter", 0, List.of(new Global("value", 0)), List.of(main));
    SemanticCoverage coverage = new SemanticCoverage();
    new VirtualMachine(program, coverage).run();
    return coverage;
  }

  private static void parseXml(String xml) throws Exception {
    DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
    factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
    factory.newDocumentBuilder().parse(
        new ByteArrayInputStream(xml.getBytes(StandardCharsets.UTF_8)));
  }
}
