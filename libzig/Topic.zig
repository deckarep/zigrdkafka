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

pub const TopicResultError = error{
    Instantiation,
    // TODO: other possible errors.
};

pub const Topic = struct {
    cHandle: *c.rd_kafka_topic_t,

    const Self = @This();

    pub fn wrap(cPtr: *c.rd_kafka_topic_t) Self {
        return Self{ .cHandle = cPtr };
    }

    // TODO: new should take a generic Handle type me thinks.
    pub fn init(client: zrdk.Handle, topicName: [:0]const u8, conf: zrdk.TopicConf) TopicResultError!Self {
        const handle = c.rd_kafka_topic_new(
            client.Handle(),
            topicName,
            conf.Handle(),
        );
        if (handle) |h| {
            return Topic.wrap(h);
        }

        return TopicResultError.Instantiation;
    }

    pub fn Handle(self: Self) *c.rd_kafka_topic_t {
        return self.cHandle;
    }

    pub fn deinit(self: Self) void {
        self.destroy();
    }

    fn destroy(self: Self) void {
        c.rd_kafka_topic_destroy(self.cHandle);
    }

    /// Returns the name of the topic.
    pub fn name(self: Self) []const u8 {
        const res = c.rd_kafka_topic_name(self.cHandle);
        return std.mem.span(res);
    }

    /// WARNING: MUST ONLY be called from within a RdKafka PartitionerCb callback.
    pub fn partitionAvailable(self: Self, partition: i32) bool {
        return c.rd_kafka_topic_partition_available(self.cHandle, partition) == 1;
    }

    /// offsetStore ...TODO docs and don't use c_int, use a real Error type.
    pub fn offsetStore(self: Self, partition: i32, offset: i64) c_int {
        _ = self;
        _ = partition;
        _ = offset;
        @panic("offsetStore is deprecated and therefore unreachable!");
    }
};
