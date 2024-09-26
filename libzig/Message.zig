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
const c = @import("cdef.zig").cdef;

pub const Message = struct {
    cHandle: ?*c.struct_rd_kafka_message_s,

    const Self = @This();

    pub fn wrap(rawPtr: ?*c.struct_rd_kafka_message_s) Self {
        return Self{ .cHandle = rawPtr };
    }

    pub fn deinit(self: Self) void {
        if (self.cHandle) |h| {
            c.rd_kafka_message_destroy(h);
        }
    }

    pub fn isEmpty(self: Self) bool {
        return self.cHandle == null;
    }

    // TODO: a message also hold a raw pointer to *rkt which needs to get extracted too.

    // TODO: don't return raw c_int, it should be a Zig error type.
    pub fn err(self: Self) c_int {
        // Note: When checking err() you must have already ruled out
        // the message is not empty.
        return self.cHandle.?.err;
    }

    pub fn partition(self: Self) i32 {
        // Note: When checking partition() you must have already ruled out
        // the message is not empty.
        return self.cHandle.?.partition;
    }

    pub fn offset(self: Self) i64 {
        // Note: When checking offset() you must have already ruled out
        // the message is not empty.
        return self.cHandle.?.offset;
    }

    pub fn payloadLen(self: Self) usize {
        // Note: When checking offset() you must have already ruled out
        // the message is not empty.
        return self.cHandle.?.len;
    }

    pub fn payloadStr(self: Self) void {
        if (self.cHandle.?.payload) |p| {
            const len = self.payloadLen();
            const bytePtr: [*c]u8 = @ptrCast(p);
            const txt = bytePtr[0..len];

            std.log.info("Message is: \"{s}\", payload is {d} bytes long", .{ txt, len });
        }
    }
};
