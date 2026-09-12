//! Defines counted scalar products independently of their source or name storage.

module wheeler.compiler.constant_product_schema;

classical class ConstantProductSchema {
  /// Bounds one counted scalar product window.
  public const long MAX_CONSTANT_PRODUCTS = 16384;
  /// Counts name, type, value, resolution, and qualifier coordinates per product.
  public const long CONSTANT_PRODUCT_COLUMNS = 7;
  /// Reserves the leading product count.
  public const long CONSTANT_PRODUCT_HEADER_ROWS = 1;
  /// Sizes the complete counted product table.
  public const long CONSTANT_PRODUCT_ROWS = CONSTANT_PRODUCT_HEADER_ROWS + MAX_CONSTANT_PRODUCTS
    * CONSTANT_PRODUCT_COLUMNS;
  /// Bounds the detached name view, including any caller-owned prefix.
  public const long CONSTANT_PRODUCT_NAME_BYTES = 1048576;
  /// Bounds one copied identifier or qualified module name.
  public const long MAX_CONSTANT_NAME_BYTES = 256;
  /// Locates the identifier start within one product row.
  public const long CONSTANT_NAME_START = 0;
  /// Locates its byte length.
  public const long CONSTANT_NAME_LENGTH = CONSTANT_NAME_START + 1;
  /// Locates the scalar type code.
  public const long CONSTANT_TYPE = CONSTANT_NAME_LENGTH + 1;
  /// Locates the full signed scalar value.
  public const long CONSTANT_VALUE = CONSTANT_TYPE + 1;
  /// Locates the zero-or-one resolution flag.
  public const long CONSTANT_RESOLVED = CONSTANT_VALUE + 1;
  /// Locates the optional module qualifier start.
  public const long CONSTANT_MODULE_START = CONSTANT_RESOLVED + 1;
  /// Locates its byte length. Zero means no qualifier.
  public const long CONSTANT_MODULE_LENGTH = CONSTANT_MODULE_START + 1;
  /// Names a signed scalar product.
  public const long CONSTANT_SIGNED = 1;
  /// Names a Boolean scalar product.
  public const long CONSTANT_BOOLEAN = 2;
}
