const std = @import("std");
const c = @import("cdef.zig").cdef;

pub const TopicPartition = struct {
    // NOTE: I had to mark this as an *allowzero pointer, not sure why.
    cHandle: *allowzero c.rd_kafka_topic_partition_t,

    const Self = @This();

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
