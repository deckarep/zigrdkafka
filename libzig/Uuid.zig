const std = @import("std");
const zrdk = @import("zigrdkafka.zig");
const c = @import("cdef.zig").cdef;

pub const UuidResultError = error{
    Instantiation,
};

pub const Uuid = struct {
    cHandle: *c.rd_kafka_Uuid_t,

    pub fn new(mostSigBits: i64, leastSigBits: i64) UuidResultError!Uuid {
        const h = c.rd_kafka_Uuid_new(mostSigBits, leastSigBits);
        if (h == null) {
            return UuidResultError.Instantiation;
        } else {
            return Uuid{ .cHandle = h.? };
        }
    }

    pub fn deinit(self: Uuid) void {
        c.rd_kafka_Uuid_destroy(self.cHandle);
    }

    pub fn copy(self: Uuid) Uuid {
        const copied = c.rd_kafka_Uuid_copy(self.cHandle);
        return Uuid{ .cHandle = copied };
    }

    pub fn Handle(self: Uuid) *c.rd_kafka_Uuid_t {
        return self.cHandle;
    }

    pub fn base64Str(self: Uuid) ?[]const u8 {
        // Looking at code, this gets tacked onto the internal cHandle Uuid raw C pointer
        // so will get cleaned up upon the UUID being destroyed.
        const res = c.rd_kafka_Uuid_base64str(self.cHandle);
        return std.mem.span(res);
    }

    pub fn leastSignificantBits(self: Uuid) i64 {
        return c.rd_kafka_Uuid_least_significant_bits(self.cHandle);
    }

    pub fn mostSignificantBits(self: Uuid) i64 {
        return c.rd_kafka_Uuid_most_significant_bits(self.cHandle);
    }
};
