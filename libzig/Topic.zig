const std = @import("std");
const c = @import("cdef.zig").cdef;
const zrdk = @import("zigrdkafka.zig");

pub const TopicResultError = error{
    Instantiation,
    // TODO: other possible errors.
};

pub const Topic = struct {
    cHandle: *c.rd_kafka_topic_t = undefined,

    const Self = @This();

    // TODO: new should take a generic Handle type me thinks.
    pub fn new(client: zrdk.Handle, topicName: [:0]const u8, conf: zrdk.TopicConf) TopicResultError!Self {
        const handle = c.rd_kafka_topic_new(
            client.Handle(),
            topicName,
            conf.Handle(),
        );
        if (handle) |h| {
            return Self{ .cHandle = h };
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

    fn name(self: Self) []const u8 {
        const res = c.rd_kafka_topic_name(self.cHandle);
        return std.mem.spand(res);
    }

    // TODO: partition_available(); // WARNING: MUST ONLY be called from within a RdKafka PartitionerCb callback.
    // TODO: offset_store(); // Deprecated.
};
