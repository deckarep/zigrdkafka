const std = @import("std");

const c_rdk = @cImport({
    @cInclude("rdkafka.h");
});

const KafkaError = error{
    Config,
    Instantiation,
};

// Somewhat based on the original raw C example: https://github.com/confluentinc/librdkafka/blob/master/examples/consumer.c

pub fn main() !void {
    std.log.info("all your bases..blah, blah...", .{});

    var errStr: [512]u8 = undefined;

    const brokers = "localhost:9092";
    const groupid = "zig-cli-consumer";
    const topics = [_][]const u8{"topic.foo"};

    var conf = c_rdk.rd_kafka_conf_new();
    if (conf) |c| {
        try conf_set(c, "bootstrap.servers", brokers, &errStr);
        try conf_set(c, "group.id", groupid, &errStr);
        try conf_set(c, "auto.offset.reset", "earliest", &errStr);
    }

    // Create handle to client.
    const client = try new_consumer(conf.?, &errStr);
    defer destroy_client(client);
    defer close_consumer(client);
    conf = null;

    // Redirect all messages from per-partition queues to the main queue.
    _ = c_rdk.rd_kafka_poll_set_consumer(client);

    // Convert list of topics to a format suitable for librdkafka.
    const topicSubscriptions = c_rdk.rd_kafka_topic_partition_list_new(topics.len);
    defer c_rdk.rd_kafka_topic_partition_list_destroy(topicSubscriptions);

    for (topics) |t| {
        _ = c_rdk.rd_kafka_topic_partition_list_add(
            topicSubscriptions,
            @ptrCast(t),
            c_rdk.RD_KAFKA_PARTITION_UA,
        );
    }

    // Subscribe to the list of topics.
    _ = c_rdk.rd_kafka_subscribe(client, topicSubscriptions);

    std.log.info("Subscribed to {d} topic(s), waiting for rebalance and messages...", .{topicSubscriptions.*.cnt});

    while (true) {
        const msg = c_rdk.rd_kafka_consumer_poll(client, 100);
        if (msg == null) {
            std.log.warn("consumer timeout occurred, continuing...", .{});
            continue; // Timeout: no message within 100ms.
        }

        defer c_rdk.rd_kafka_message_destroy(msg);

        if (msg.*.err != 0) {
            std.log.warn("error occurred, continuing...", .{});
            continue; // TODO: log out error.
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
        std.time.sleep(std.time.ns_per_ms * 10);
    }
}

fn conf_set(conf: *c_rdk.struct_rd_kafka_conf_s, name: []const u8, value: []const u8, err: []u8) !void {
    const res = c_rdk.rd_kafka_conf_set(
        conf,
        @ptrCast(name),
        @ptrCast(value),
        @ptrCast(err),
        err.len,
    );
    if (res != c_rdk.RD_KAFKA_CONF_OK) {
        std.log.err("Error setting config: {s}", .{err});
        return KafkaError.Config;
    }
}

fn new_consumer(conf: *c_rdk.struct_rd_kafka_conf_s, err: []u8) !*c_rdk.struct_rd_kafka_s {
    const rk = c_rdk.rd_kafka_new(
        c_rdk.RD_KAFKA_CONSUMER,
        conf,
        @ptrCast(err),
        err.len,
    );
    if (rk == null) {
        std.log.err("Failed to create a new consumer: {s}\n", .{err});
        return KafkaError.Instantiation;
    }
    return rk.?;
}

fn close_consumer(c: *c_rdk.rd_kafka_t) void {
    std.log.debug("closing the consumer...");
    c_rdk.rd_kafka_consumer_close(c);
}

fn destroy_client(c: *c_rdk.rd_kafka_t) void {
    std.log.debug("destroy the client...");
    c_rdk.rd_kafka_destroy(c);
}
