package com.typeobject.wheeler.compiler.ast.hybrid;

import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.classical.Block;

public final class HybridBlock extends Block {
  @Override
  public <T> T accept(NodeVisitor<T> visitor) {
    return visitor.visitHybridBlock(this);
  }
}
