//! Defines canonical scalar type codes for Wheeler-written bytecode tools.
module wheeler.compiler.type_codes;
classical class TypeCodes {
    /// Names the compile-time `TYPE_SIGNED` value owned by this module.
    public const long TYPE_SIGNED = 1;
    /// Names the compile-time `TYPE_BOOLEAN` value owned by this module.
    public const long TYPE_BOOLEAN = 2;
    /// Names the compile-time `TYPE_REGION` value owned by this module.
    public const long TYPE_REGION = 3;
    /// Names the compile-time `TYPE_WORDS` value owned by this module.
    public const long TYPE_WORDS = 4;
    /// Names the compile-time `TYPE_BYTES` value owned by this module.
    public const long TYPE_BYTES = 5;
    /// Names the compile-time `TYPE_LONG_MAP` value owned by this module.
    public const long TYPE_LONG_MAP = 6;
    /// Names the compile-time `TYPE_UTF8` value owned by this module.
    public const long TYPE_UTF8 = 7;
    /// Names the compile-time `TYPE_UTF8_BORROW` value owned by this module.
    public const long TYPE_UTF8_BORROW = 8;
    /// Names the compile-time `TYPE_LONG_MAP_BORROW` value owned by this module.
    public const long TYPE_LONG_MAP_BORROW = 9;
    /// Names the compile-time `TYPE_WORDS_BORROW` value owned by this module.
    public const long TYPE_WORDS_BORROW = 10;
    /// Names the compile-time `TYPE_BYTES_BORROW` value owned by this module.
    public const long TYPE_BYTES_BORROW = 11;
    /// Names the compile-time `TYPE_REGION_BORROW` value owned by this module.
    public const long TYPE_REGION_BORROW = 12;
    /// Names the compile-time `TYPE_BYTE_VIEW` value owned by this module.
    public const long TYPE_BYTE_VIEW = 13;
    /// Names the compile-time `TYPE_DESCRIPTOR_MASK` value owned by this module.
    public const long TYPE_DESCRIPTOR_MASK = 0x0fffffff;
    /// Names the compile-time `TYPE_KIND_MASK` value owned by this module.
    public const long TYPE_KIND_MASK = 0xf0000000;
    /// Names the compile-time `TYPE_RECORD` value owned by this module.
    public const long TYPE_RECORD = 0x10000000;
    /// Names the compile-time `TYPE_VARIANT` value owned by this module.
    public const long TYPE_VARIANT = 0x20000000;
    /// Names the compile-time `TYPE_ARRAY` value owned by this module.
    public const long TYPE_ARRAY = 0x30000000;
    /// Names the compile-time `TYPE_SLICE` value owned by this module.
    public const long TYPE_SLICE = 0x40000000;

    /// Checks whether one canonical value code denotes a record type.
    public boolean isRecordType(long typeCode) {
        return(typeCode & TYPE_KIND_MASK) == TYPE_RECORD;
    }

    /// Decodes the record metadata index from a checked value code.
    public long recordTypeId(long typeCode) {
        return typeCode & TYPE_DESCRIPTOR_MASK;
    }

    /// Checks whether one canonical value code denotes a variant type.
    public boolean isVariantType(long typeCode) {
        return(typeCode & TYPE_KIND_MASK) == TYPE_VARIANT;
    }

    /// Decodes the variant metadata index from a checked value code.
    public long variantTypeId(long typeCode) {
        return typeCode & TYPE_DESCRIPTOR_MASK;
    }

    /// Checks whether one canonical value code denotes a fixed array type.
    public boolean isArrayType(long typeCode) {
        return(typeCode & TYPE_KIND_MASK) == TYPE_ARRAY;
    }

    /// Decodes the array metadata index from a checked value code.
    public long arrayTypeId(long typeCode) {
        return typeCode & TYPE_DESCRIPTOR_MASK;
    }

    /// Checks whether one canonical value code denotes a slice type.
    public boolean isSliceType(long typeCode) {
        return(typeCode & TYPE_KIND_MASK) == TYPE_SLICE;
    }

    /// Decodes the slice metadata index from a checked value code.
    public long sliceTypeId(long typeCode) {
        return typeCode & TYPE_DESCRIPTOR_MASK;
    }
}
