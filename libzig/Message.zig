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
const zrdk = @import("zigrdkafka.zig");

pub const Message = struct {
    cHandle: ?*c.struct_rd_kafka_message_s,

    const Self = @This();

    pub inline fn wrap(rawPtr: ?*c.struct_rd_kafka_message_s) Self {
        return Self{ .cHandle = rawPtr };
    }

    pub fn deinit(self: Self) void {
        if (self.cHandle) |h| {
            c.rd_kafka_message_destroy(h);
        }
    }

    pub inline fn isEmpty(self: Self) bool {
        return self.cHandle == null;
    }

    /// topic returns the Topic struct.
    pub fn topic(self: Self) zrdk.Topic {
        return zrdk.Topic.wrap(self.cHandle.?.rkt.?);
    }

    // TODO: don't return raw c_int, it should be a Zig error type.
    pub inline fn err(self: Self) c_int {
        // Note: When checking err() you must have already ruled out
        // the message is not empty.
        return self.cHandle.?.err;
    }

    /// errorAsString is a convenience method that returns the error as a string.
    pub fn errorAsString(self: Self) []const u8 {
        if (self.err() != 0) {
            return self.payloadAsString();
        }
        return "<no-error>";
    }

    /// Partition is the partition this message lives on.
    pub inline fn partition(self: Self) i32 {
        // Note: When checking partition() you must have already ruled out
        // the message is not empty.
        return self.cHandle.?.partition;
    }

    /// Message offset (or offset for error if err!=0 if applicable).
    /// Producer, dr_msg_cb: Message offset assigned by broker.
    /// May be RD_KAFKA_OFFSET_INVALID for retried messages when idempotence is enabled.
    pub inline fn offset(self: Self) i64 {
        // Note: When checking offset() you must have already ruled out
        // the message is not empty.
        return self.cHandle.?.offset;
    }

    /// Depends on the value of err.
    /// err == 0: Message payload length
    /// err != 0: Error string length
    pub inline fn len(self: Self) usize {
        // Note: When checking offset() you must have already ruled out
        // the message is not empty.
        return self.cHandle.?.len;
    }

    /// Producer: original message payload.
    /// Consumer: Depends on the value of err:
    ///     err == 0: Message payload.
    ///     err != 0: Error string.
    pub fn payload(self: Self) ?*anyopaque {
        return self.cHandle.?.payload;
    }

    /// payloadAsString just interprets the payload as a string which will work for
    /// either a valid message or an error.
    ///
    /// Producer: original message payload.
    /// Consumer: Depends on the value of err:
    ///     err == 0: Message payload.
    ///     err != 0: Error string.
    pub fn payloadAsString(self: Self) []const u8 {
        if (self.cHandle.?.payload) |p| {
            const pLen = self.len();
            const bytePtr: [*c]const u8 = @ptrCast(p);
            const result = bytePtr[0..pLen];
            return result;
        }

        return "<empty>";
    }

    /// Depends on the value of err:
    ///     err == 0: Optional message key.
    pub fn key(self: Self) ?*anyopaque {
        return self.cHandle.?.key;
    }

    /// Key as a string is a convenience message to interpret the key as a string.
    /// Depends on the value of err:
    ///     err == 0: Optional message key as a string.
    pub fn keyAsString(self: Self) []const u8 {
        if (self.cHandle.?.key) |p| {
            const kLen = self.keyLen();
            const bytePtr: [*c]const u8 = @ptrCast(p);
            const result = bytePtr[0..kLen];
            return result;
        }
        return null;
    }

    /// Depends on the value of err:
    ///     err == 0: Optional message key length
    pub fn keyLen(self: Self) usize {
        return self.cHandle.?.key_len;
    }
};
