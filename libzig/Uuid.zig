const std = @import("std");
const zrdk = @import("zigrdkafka.zig");
const c = @import("cdef.zig").cdef;

pub const Uuid = struct {
    cHandle: ?*c.rd_kafka_Uuid_t,

    pub fn new(mostSigBits: i64, leastSigBits: i64) Uuid {
        const h = c.rd_kafka_Uuid_new(mostSigBits, leastSigBits);
        return Uuid{ .cHandle = h };
    }

    pub fn deinit(self: Uuid) void {
        if (self.cHandle) |h| {
            c.rd_kafka_Uuid_destroy(h);
        }
    }

    pub fn copy(self: Uuid) Uuid {
        if (self.cHandle) |h| {
            const copied = c.rd_kafka_Uuid_copy(h);
            return Uuid{ .cHandle = copied };
        }

        return Uuid{ .cHandle = null };
    }

    pub fn base64Str(self: Uuid) ?[]const u8 {
        // Looking at code, this gets tacked onto the internal cHandle Uuid raw C pointer
        // so will get cleaned up upon the UUID being destroyed.
        if (self.cHandle) |h| {
            const res = c.rd_kafka_Uuid_base64str(h);
            return std.mem.span(res);
        }
        return null;
    }

    pub fn leastSignificantBits(self: Uuid) i64 {
        if (self.cHandle) |h| {
            return c.rd_kafka_Uuid_least_significant_bits(h);
        }

        // TODO: this isn't right, cHandle should never be null, but in our current design
        // what should we return? An error or what?
        return 0;
    }

    pub fn mostSignificantBits(self: Uuid) i64 {
        if (self.cHandle) |h| {
            return c.rd_kafka_Uuid_most_significant_bits(h);
        }

        // TODO: this isn't right, cHandle should never be null, but in our current design
        // what should we return? An error or what?
        return 0;
    }
};
