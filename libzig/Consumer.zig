const std = @import("std");
const Conf = @import("Conf.zig").Conf;
const zrdk = @import("zigrdkafka.zig");
const c = @import("cdef.zig").cdef;

pub const ConsumerResultError = error{
    Instantiation,
};

pub const Consumer = struct {
    cClient: ?*c.rd_kafka_t = undefined,
    conf: Conf,

    pub fn new(conf: Conf) ConsumerResultError!Consumer {
        var errStr: [512]u8 = undefined;
        const pErrStr: [*c]u8 = @ptrCast(&errStr);

        const rk = c.rd_kafka_new(
            c.RD_KAFKA_CONSUMER,
            conf.Handle(),
            pErrStr,
            errStr.len,
        );

        if (rk == null) {
            const err = std.mem.span(pErrStr);
            std.log.err("Err setting instantiating producer: {s}", .{err});
            return ConsumerResultError.Instantiation;
        }

        // Redirect all messages from per-partition queues to the main queue.
        // Perhaps make this a default setting.
        _ = c.rd_kafka_poll_set_consumer(rk);

        return Consumer{
            .cClient = rk,
            .conf = conf,
        };
    }

    pub fn deinit(self: Consumer) void {
        if (self.cClient) |h| {
            c.rd_kafka_destroy(h);
        }
    }

    pub fn close(self: Consumer) void {
        if (self.cClient) |h| {
            // TODO: handle return error.
            _ = c.rd_kafka_consumer_close(h);
        }
    }

    pub fn subscribe(self: Consumer, topics: []const []const u8) void {
        // Convert list of topics to a format suitable for librdkafka.
        const len: c_int = @intCast(topics.len);
        const topicSubscriptions = c.rd_kafka_topic_partition_list_new(len);
        defer c.rd_kafka_topic_partition_list_destroy(topicSubscriptions);

        for (topics) |t| {
            _ = c.rd_kafka_topic_partition_list_add(
                topicSubscriptions,
                @ptrCast(t),
                c.RD_KAFKA_PARTITION_UA,
            );
        }

        // Subscribe to the list of topics.
        // TODO: handle error.
        _ = c.rd_kafka_subscribe(self.cClient, topicSubscriptions);

        std.log.info("Subscribed to {d} topic(s), waiting for rebalance and messages...", .{topicSubscriptions.*.cnt});
    }

    pub fn do(self: Consumer) void {
        const msg = c.rd_kafka_consumer_poll(self.cClient, 100);
        if (msg == null) {
            std.log.warn("consumer timeout occurred, continuing...", .{});
            return; // Timeout: no message within 100ms.
        }

        defer c.rd_kafka_message_destroy(msg);

        if (msg.*.err != 0) {
            std.log.warn("error occurred, continuing...", .{});
            return; // TODO: log out error.
        }

        // Proper message below.
        std.log.info("Message on <topic-name>, partition: {d}, offset: {d}", .{ msg.*.partition, msg.*.offset });

        // TODO: Print the key if one.

        // Print the message value/payload
        if (msg.*.payload) |p| {
            const bytePtr: [*c]u8 = @ptrCast(p);
            const txt = bytePtr[0..msg.*.len];
            std.log.info("Message is: \"{s}\", payload is {d} bytes long", .{ txt, msg.*.len });
        }

        std.log.info("just consuming along...", .{});
    }
};
