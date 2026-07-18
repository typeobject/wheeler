/// Defines canonical scalar type codes for Wheeler-written bytecode tools.
module examples.compiler.type_codes;
classical class TypeCodes {
    public const long TYPE_SIGNED = 1;
    public const long TYPE_BOOLEAN = 2;
    public const long TYPE_REGION = 3;
    public const long TYPE_WORDS = 4;
    public const long TYPE_BYTES = 5;
    public const long TYPE_LONG_MAP = 6;
    public const long TYPE_DESCRIPTOR_MASK = 0x0fffffff;
    public const long TYPE_KIND_MASK = 0xf0000000;
    public const long TYPE_RECORD = 0x10000000;
    public const long TYPE_VARIANT = 0x20000000;
    public const long TYPE_ARRAY = 0x30000000;
    public const long TYPE_SLICE = 0x40000000;

    public boolean isRecordType(long typeCode) {
        return (typeCode & TYPE_KIND_MASK) == TYPE_RECORD;
    }

    public long recordTypeId(long typeCode) {
        return typeCode & TYPE_DESCRIPTOR_MASK;
    }

    public boolean isVariantType(long typeCode) {
        return (typeCode & TYPE_KIND_MASK) == TYPE_VARIANT;
    }

    public long variantTypeId(long typeCode) {
        return typeCode & TYPE_DESCRIPTOR_MASK;
    }

    public boolean isArrayType(long typeCode) {
        return (typeCode & TYPE_KIND_MASK) == TYPE_ARRAY;
    }

    public long arrayTypeId(long typeCode) {
        return typeCode & TYPE_DESCRIPTOR_MASK;
    }

    public boolean isSliceType(long typeCode) {
        return (typeCode & TYPE_KIND_MASK) == TYPE_SLICE;
    }

    public long sliceTypeId(long typeCode) {
        return typeCode & TYPE_DESCRIPTOR_MASK;
    }
}
