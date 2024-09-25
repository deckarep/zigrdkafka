const std = @import("std");
const c = @import("cdef.zig").cdef;

pub const TopicPartitions = struct {
    cHandle: *const c.rd_kafka_topic_partition_list_t,

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
        const res = c.rd_kafka_topic_parition_list_copy(self.cHandle);
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
    pub fn find(self: Self, topic: [:0]const u8, partition: i32) void {
        _ = c.rd_kafka_topic_partition_list_find(
            self.cHandle,
            @ptrCast(topic),
            partition,
        );
    }

    // NOTE: this requires a a comparator function arg.
    // TODO: partition_list_sort();
};
