// Open Source Initiative OSI - The MIT License (MIT):Licensing

// The MIT License (MIT)
// Copyright (c) 2024 Ralph Caraveo (deckarep@gmail.com)

// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

const std = @import("std");
const zrdk = @import("zigrdkafka.zig");
const c = @import("cdef.zig").cdef;

pub const UuidResultError = error{
    Instantiation,
};

pub const Uuid = struct {
    cHandle: *c.rd_kafka_Uuid_t,

    const Self = @This();

    pub fn init(mostSigBits: i64, leastSigBits: i64) UuidResultError!Self {
        const h = c.rd_kafka_Uuid_new(mostSigBits, leastSigBits);
        if (h == null) {
            return UuidResultError.Instantiation;
        } else {
            return Self{ .cHandle = h.? };
        }
    }

    pub fn deinit(self: Self) void {
        c.rd_kafka_Uuid_destroy(self.cHandle);
    }

    pub fn copy(self: Self) Uuid {
        const copied = c.rd_kafka_Uuid_copy(self.cHandle);
        return Uuid{ .cHandle = copied };
    }

    pub fn Handle(self: Self) *c.rd_kafka_Uuid_t {
        return self.cHandle;
    }

    pub fn base64Str(self: Self) ?[]const u8 {
        // Looking at code, this gets tacked onto the internal cHandle Uuid raw C pointer
        // so will get cleaned up upon the UUID being destroyed.
        const res = c.rd_kafka_Uuid_base64str(self.cHandle);
        return std.mem.span(res);
    }

    pub fn leastSignificantBits(self: Self) i64 {
        return c.rd_kafka_Uuid_least_significant_bits(self.cHandle);
    }

    pub fn mostSignificantBits(self: Self) i64 {
        return c.rd_kafka_Uuid_most_significant_bits(self.cHandle);
    }
};
