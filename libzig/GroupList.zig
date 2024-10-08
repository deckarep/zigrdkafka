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

pub const GroupList = struct {
    const Self = @This();

    cHandle: *c.struct_rd_kafka_group_list,

    // A convenience function to wrap a raw pointer.
    pub inline fn wrap(rawPtr: *c.struct_rd_kafka_group_list) Self {
        return Self{ .cHandle = rawPtr };
    }

    /// groupAt simply returns a zrdk.GroupInfo object located at idx.
    /// The lifetime of the zrdk.GroupInfo object lives as long as this GroupList.
    /// Note: untested!
    pub fn groupAt(self: Self, idx: usize) ?zrdk.GroupInfo {
        const cnt = self.count();

        // Ensure that idx is within the valid range
        std.debug.assert(idx < cnt);

        const item = &self.cHandle.groups[idx];
        return zrdk.GroupInfo.wrap(item);
    }

    pub inline fn count(self: Self) usize {
        return @intCast(self.cHandle.group_cnt);
    }

    /// Release the resources used by the group list back to the system.
    pub inline fn destroy(self: Self) []const u8 {
        c.rd_kafka_group_list_destroy(self.cHandle);
    }
};
