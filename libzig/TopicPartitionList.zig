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

pub const TopicPartitionList = struct {
    cHandle: *c.rd_kafka_topic_partition_list_t,

    const Self = @This();

    pub fn init() Self {
        return Self.initWithCapacity(0);
    }

    pub fn initWithCapacity(capacity: usize) Self {
        const size: c_int = @intCast(capacity);
        const res = c.rd_kafka_topic_partition_list_new(size);
        return Self{ .cHandle = res };
    }

    /// deinit cleans up internal handles by ensuring the Kafka runtime destroys them.
    /// Returns: void
    pub fn deinit(self: Self) void {
        self.destroy();
    }

    fn destroy(self: Self) void {
        c.rd_kafka_topic_partition_list_destroy(self.cHandle);
    }

    pub fn elemAt(self: Self, index: usize) ?zrdk.TopicPartition {
        if (index <= self.cHandle.cnt - 1) {
            return zrdk.TopicPartition{ .cHandle = &self.cHandle.elems[index] };
        }
        return null;
    }

    pub fn count(self: Self) usize {
        return @intCast(self.cHandle.cnt);
    }

    pub fn cap(self: Self) usize {
        return @intCast(self.cHandle.size);
    }

    /// add will add a topic+partition to list.
    pub fn add(self: Self, topic: [:0]const u8, partition: i32) void {
        // TODO: this is supposed to return a *rd_kafka_topic_partition...how to handle.
        _ = c.rd_kafka_topic_partition_list_add(
            self.cHandle,
            @ptrCast(topic),
            partition,
        );
    }

    /// addRange adds a range of partitions from start to stop inclusive.
    pub fn addRange(self: Self, topic: [:0]const u8, start: i32, stop: i32) void {
        // TODO: this is supposed to return a *rd_kafka_topic_partition...how to handle.
        c.rd_kafka_topic_partition_list_add_range(
            self.cHandle,
            @ptrCast(topic),
            start,
            stop,
        );
    }

    /// Delete partition from list.
    /// Returns: true if partition was found (and removed), otherwise false.
    pub fn del(self: Self, topic: [:0]const u8, partition: i32) bool {
        return c.rd_kafka_topic_partition_list_del(
            self.cHandle,
            @ptrCast(topic),
            partition,
        ) == 1;
    }

    /// Delete partition from list at provided index.
    /// Returns: true if partition was found (and removed), otherwise false.
    pub fn delAt(self: Self, index: i32) bool {
        return c.rd_kafka_topic_partition_list_del_by_idx(
            self.cHandle,
            @intCast(index),
        ) == 1;
    }

    /// Make a copy of an existing list.
    /// Returns: a new list fully populated to be identical to source.
    pub fn copy(self: Self) Self {
        const res = c.rd_kafka_topic_partition_list_copy(self.cHandle);
        return Self{
            .cHandle = res,
        };
    }

    /// Set offset to offset for topic and partition.
    /// Returns: No error on success or UnknownPartition error if partition was not found in the list.
    pub fn setOffset(self: Self, topic: [:0]const u8, partition: i32, offset: i64) void {
        // TODO: handle the returned error!
        _ = c.rd_kafka_topic_partition_list_set_offset(
            self.cHandle,
            @ptrCast(topic),
            partition,
            offset,
        );
    }

    /// Find element by topic and partition.
    /// Returns: a pointer to the first matching element, or null if not found.
    pub fn find(self: Self, topic: [:0]const u8, partition: i32) ?zrdk.TopicPartition {
        const res = c.rd_kafka_topic_partition_list_find(
            self.cHandle,
            @ptrCast(topic),
            partition,
        );

        if (res != null) {
            return zrdk.TopicPartition{ .cHandle = res };
        }

        return null;
    }

    // NOTE: this requires a a comparator function arg.
    // TODO: partition_list_sort();
};