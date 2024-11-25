// TensorProduct.java
package com.typeobject.wheeler.compiler.ast.quantum.expressions;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;

import java.util.List;

public final class TensorProduct extends QubitExpression {
    private final List<QubitExpression> factors;

    public TensorProduct(Position position, List<Annotation> annotations,
                         List<QubitExpression> factors) {
        super(position, annotations);
        this.factors = factors;
    }

    public List<QubitExpression> getFactors() {
        return factors;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitTensorProduct(this);
    }
}