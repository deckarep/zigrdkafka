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

pub const TopicPartition = struct {
    // NOTE: I had to mark this as an *allowzero pointer, not sure why.
    cHandle: *allowzero c.rd_kafka_topic_partition_t,

    const Self = @This();

    pub fn wrap(cPtr: *allowzero c.rd_kafka_topic_partition_t) Self {
        return Self{ .cHandle = cPtr };
    }

    pub fn topic(self: Self) [:0]const u8 {
        return std.mem.span(self.cHandle.topic);
    }

    pub fn partition(self: Self) i32 {
        return self.cHandle.partition;
    }

    pub fn offset(self: Self) i64 {
        return self.cHandle.offset;
    }

    // TODO: also getters for these fields also on this struct.
    // metadata, metadata_size
    // opaque
    // err
};
