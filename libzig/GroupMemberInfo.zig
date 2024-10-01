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

pub const GroupMemberInfo = struct {
    cHandle: *c.struct_rd_kafka_group_member_info,

    const Self = @This();

    // A convenience function to wrap a raw pointer.
    pub inline fn wrap(rawPtr: *c.struct_rd_kafka_group_member_info) Self {
        return Self{ .cHandle = rawPtr };
    }

    /// Returns the broker generated member id for the consumer.
    pub inline fn memberId(self: Self) []const u8 {
        return std.mem.span(self.cHandle.member_id);
    }

    /// Returns the Consumer's client.id config setting.
    pub inline fn clientId(self: Self) []const u8 {
        return std.mem.span(self.cHandle.client_id);
    }

    /// Returns the hostname of the consumer.
    pub inline fn clientHost(self: Self) []const u8 {
        return std.mem.span(self.cHandle.client_host);
    }

    /// Returns the binary metadata for the consumer.
    pub fn memberMetadata(self: Self) ?[]const u8 {
        if (self.cHandle.member_metadata) |mmd| {
            const rawBytes = @as([*]const u8, @ptrCast(mmd));
            return rawBytes[0..self.cHandle.member_metadata_size];
        }
        return null;
    }

    /// Returns the binary assignment data for the consumer.
    pub fn memberAssignment(self: Self) ?[]const u8 {
        if (self.cHandle.member_assignment) |mmd| {
            const rawBytes = @as([*]const u8, @ptrCast(mmd));
            return rawBytes[0..self.cHandle.member_assignment_size];
        }
        return null;
    }
};
