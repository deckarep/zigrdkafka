const std = @import("std");
const c_rdk = @cImport({
    @cInclude("rdkafka.h");
});

// Configuration: /opt/homebrew/etc/kafka/server.properties

// Starting and stopping through homebrew isn't quite working.
// brew services list
// brew services restart kafka
// brew services start kafka
// brew services stop kafka

// Starting through homebrew cli using kraft (no zookeeper needed) is working.
// ./kafka-server-start ../etc/kafka/kraft/server.properties

// CLI tools of consumer
// ./kafka-console-consumer --bootstrap-server "localhost:9092" --topic "topic.foo" ../etc/kafka/kraft/server.properties

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const brokers = "localhost:9092";
    var errStr: [512]u8 = undefined;
    const pErrStr: [*c]u8 = @ptrCast(&errStr);

    // Kafka configuration
    const conf = c_rdk.rd_kafka_conf_new();

    if (c_rdk.rd_kafka_conf_set(conf, "bootstrap.servers", brokers, pErrStr, errStr.len) != c_rdk.RD_KAFKA_CONF_OK) {
        _ = std.c.printf("Error setting conf: %s\n", pErrStr);
        return;
    }

    // Set logger
    c_rdk.rd_kafka_conf_set_log_cb(conf, logger);
    if (conf) |c| {
        dumpConfig(c);
    }

    // Set delivery report callback.
    c_rdk.rd_kafka_conf_set_dr_msg_cb(conf, deliveryReportCallback);

    const rk = c_rdk.rd_kafka_new(c_rdk.RD_KAFKA_PRODUCER, conf, pErrStr, errStr.len);
    if (rk == null) {
        _ = std.c.printf("Failed to create a new producer: %s\n", pErrStr);
        return;
    }

    // Create topic config.
    const topic_conf = c_rdk.rd_kafka_topic_conf_new();
    var res = c_rdk.RD_KAFKA_CONF_UNKNOWN;
    res = c_rdk.rd_kafka_topic_conf_set(topic_conf, "acks", "-1", pErrStr, errStr.len);
    if (res != c_rdk.RD_KAFKA_CONF_OK) {
        _ = std.c.printf("failed to set the kakfa topic conf with err: %s\n", pErrStr);
        return;
    }

    // Create the topic handle.
    const rkt = c_rdk.rd_kafka_topic_new(rk, "topic.foo", topic_conf);
    defer c_rdk.rd_kafka_topic_destroy(rkt);

    var buf: [512]u8 = undefined;
    var counter: usize = 0;

    while (true) {
        const msg = try std.fmt.bufPrint(buf[0..], "Here is message: {d}", .{counter});

        _ = c_rdk.rd_kafka_produce(
            // Producer handle
            rkt,
            // Topic name
            c_rdk.RD_KAFKA_PARTITION_UA,
            // Make a copy of the payload.
            c_rdk.RD_KAFKA_MSG_F_COPY,
            // Message value and length
            @ptrCast(msg),
            // Per-Message opaque, provided in
            // delivery report callback as
            // msg_opaque.
            msg.len,
            // Key is an optional message key.
            "fart",
            // keylen is the optional message key len.
            4,
            // Optional opaque pointer, that is provided in delivery report callback.
            null,
        );

        counter += 1;

        std.log.info("doing something...", .{});
        std.time.sleep(std.time.ns_per_ms * 10);
    }

    // Topic configuration
    // const topic_conf = c_rdk.rd_kafka_topic_conf_new();
    // defer c_rdk.rd_kafka_topic_conf_destroy(topic_conf);

    // var res = c_rdk.RD_KAFKA_CONF_UNKNOWN;
    // res = c_rdk.rd_kafka_topic_conf_set(topic_conf, "topic.foo", "bar", pErrStr, errStr.len);
}

fn deliveryReportCallback(_: ?*c_rdk.rd_kafka_t, rkmessage: [*c]const c_rdk.rd_kafka_message_t, _: ?*anyopaque) callconv(.C) void {
    if (rkmessage.*.err > 0) {
        _ = std.c.printf("Message delivery failed: %s\n", c_rdk.rd_kafka_err2str(rkmessage.*.err));
    } else {
        std.log.info("Message delivered ({d} bytes, partition: {d})", .{ rkmessage.*.len, rkmessage.*.partition });
    }
}

fn logger(rk: ?*const c_rdk.struct_rd_kafka_s, level: c_int, fac: [*c]const u8, buf: [*c]const u8) callconv(.C) void {
    const name = c_rdk.rd_kafka_name(rk);
    if (name != null) {
        std.log.info("name: {s}, level: {d}, fac: {s}, buf:{s}", .{ name, level, fac, buf });
    }
}

fn dumpConfig(conf: *c_rdk.struct_rd_kafka_conf_s) void {
    var cnt: usize = undefined;
    const arr = c_rdk.rd_kafka_conf_dump(conf, &cnt);
    defer c_rdk.rd_kafka_conf_dump_free(arr, cnt);

    var i: usize = 0;
    while (i < cnt) : (i += 2) {
        std.debug.print("{s} = {s}\n", .{ arr[i], arr[i + 1] });
    }
}
