const std = @import("std");
const zrdk = @import("zigrdkafka");

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

fn doSomething() void {
    // Use this function to force c bindings to be auto generated to help figure out
    // how the externs should be defined!
    //     const result = c_auto.rd_kafka_topic_conf_new();
    //     defer c_auto.rd_kafka_topic_conf_destroy(result);
}

pub fn main() !void {
    doSomething();

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const serversKey = "bootstrap.servers";
    const brokers = "localhost:9092";

    const conf = try zrdk.Conf.new();
    //defer conf.deinit(); //<-- don't call this, once given to client, as client owns it.

    // Here is how we can duplicate the Conf object.
    const otherConf = conf.dup();
    defer otherConf.deinit();

    try conf.set(serversKey, brokers);
    try conf.setLogLevel(zrdk.LogLevel.Crit);
    conf.dump();

    otherConf.dump();

    var buf: [128]u8 = undefined;
    var bufSize: usize = undefined;
    _ = try conf.get(serversKey, &buf, &bufSize);

    std.log.info("key: {s} => val: {s}", .{ serversKey, buf[0..bufSize] });

    const prodClient = zrdk.Producer.new(conf);
    defer prodClient.deinit();

    var count: usize = 0;
    while (true) {
        // Create the message.
        var msgBuf: [128]u8 = undefined;
        const msg = try std.fmt.bufPrint(&msgBuf, "hello world! {d}", .{count});

        // Produce
        // TODO: figure out why messages aren't producing unless a key is specified.
        try prodClient.produce(msg, .{ .key = "p00p" });

        std.time.sleep(std.time.ns_per_ms * 1000);
        count += 1;
    }

    // // Get a non-existent value.
    // var buf2: [512:0]u8 = undefined;
    // var bufSize2: usize = buf.len;
    // const unknownName = "p00p";
    // if (conf.get(unknownName, buf2[0..], &bufSize2) != zrdk.ConfResult.OK) {
    //     std.debug.print("Oh no, {s} is an .Unknown config!\n", .{unknownName});
    // } else {
    //     const p: [*c]u8 = buf[0..bufSize2].ptr;
    //     _ = std.c.printf("Value found was: %s\n", p);
    // }

    // // Create the producer client.
    // var myProducer = zrdk.Producer.new(conf);
    // defer myProducer.deinit();

    // var count: usize = 0;
    // while (true) {
    //     std.log.info("about to produce...", .{});
    //     myProducer.produce();
    //     std.log.info("finished {d} produce...", .{count});
    //     std.time.sleep(std.time.ns_per_ms * 1000);

    //     count += 1;
    // }

    // const evFlags = zrdk.EventFlags{ .Dr = true, .Log = true };
    // conf.set_events(evFlags);
    //var errStr: [512]u8 = undefined;
    //const pErrStr: [*c]u8 = @ptrCast(&errStr);

    // Kafka configuration
    // Real api.
    //const conf = c_rdk.rd_kafka_conf_new();
    // Wrapper api using extern
    // const conf = conf_new();
    // defer conf.destroy();

    // const confCopy = conf.dup();
    // defer confCopy.destroy();

    // conf.set("bootstrap.servers", brokers);
    // conf.set("batch.num.messages", "500");

    //conf_set(conf, "bootstrap.servers", brokers);
    //std.log.info("printing conf: {?}", .{conf});

    // conf.dump();
    // confCopy.dump();

    // if (c_rdk.rd_kafka_conf_set(conf, "bootstrap.servers", brokers, pErrStr, errStr.len) != c_rdk.RD_KAFKA_CONF_OK) {
    //     _ = std.c.printf("Error setting conf: %s\n", pErrStr);
    //     return;
    // }

    // // Set logger
    // c_rdk.rd_kafka_conf_set_log_cb(conf, logger);
    // if (conf) |c| {
    //     dumpConfig(c);
    // }

    // // Set delivery report callback.
    // c_rdk.rd_kafka_conf_set_dr_msg_cb(conf, deliveryReportCallback);

    // const rk = c_rdk.rd_kafka_new(c_rdk.RD_KAFKA_PRODUCER, conf, pErrStr, errStr.len);
    // if (rk == null) {
    //     _ = std.c.printf("Failed to create a new producer: %s\n", pErrStr);
    //     return;
    // }

    // // Create topic config.
    // const topic_conf = c_rdk.rd_kafka_topic_conf_new();
    // var res = c_rdk.RD_KAFKA_CONF_UNKNOWN;
    // res = c_rdk.rd_kafka_topic_conf_set(topic_conf, "acks", "-1", pErrStr, errStr.len);
    // if (res != c_rdk.RD_KAFKA_CONF_OK) {
    //     _ = std.c.printf("failed to set the kakfa topic conf with err: %s\n", pErrStr);
    //     return;
    // }

    // // Create the topic handle.
    // const rkt = c_rdk.rd_kafka_topic_new(rk, "topic.foo", topic_conf);
    // defer c_rdk.rd_kafka_topic_destroy(rkt);

    // var buf: [512]u8 = undefined;
    // var counter: usize = 0;

    // while (true) {
    //     const msg = try std.fmt.bufPrint(buf[0..], "Here is message: {d}", .{counter});

    //     _ = c_rdk.rd_kafka_produce(
    //         // Producer handle
    //         rkt,
    //         // Topic name
    //         c_rdk.RD_KAFKA_PARTITION_UA,
    //         // Make a copy of the payload.
    //         c_rdk.RD_KAFKA_MSG_F_COPY,
    //         // Message value and length
    //         @ptrCast(msg),
    //         // Per-Message opaque, provided in
    //         // delivery report callback as
    //         // msg_opaque.
    //         msg.len,
    //         // Key is an optional message key.
    //         "fart",
    //         // keylen is the optional message key len.
    //         4,
    //         // Optional opaque pointer, that is provided in delivery report callback.
    //         null,
    //     );

    //     counter += 1;

    //     std.log.info("doing something...", .{});
    //     std.time.sleep(std.time.ns_per_ms * 10);
    // }

    // Topic configuration
    // const topic_conf = c_rdk.rd_kafka_topic_conf_new();
    // defer c_rdk.rd_kafka_topic_conf_destroy(topic_conf);

    // var res = c_rdk.RD_KAFKA_CONF_UNKNOWN;
    // res = c_rdk.rd_kafka_topic_conf_set(topic_conf, "topic.foo", "bar", pErrStr, errStr.len);
}

// NOTE: in order to do this like Raylib, I need to control the externs
// When I define the externs I need to swap out librdkafka types for the shimmed types I define.
// See this file: https://github.com/Not-Nik/raylib-zig/blob/devel/lib/raylib-ext.zig
// Importing automatigically with Zig only gets you so far.

// pub const Conf = extern struct {
//     pub fn destroy(self: *Conf) void {
//         rd_kafka_conf_destroy(self);
//     }

//     pub fn dup(self: *const Conf) *Conf {
//         return rd_kafka_conf_dup(self);
//     }

//     pub fn set(self: *Conf, name: []const u8, value: []const u8) void {
//         var errStr: [512]u8 = undefined;
//         const pErrStr: [*c]u8 = @ptrCast(&errStr);
//         const result = rd_kafka_conf_set(self, @ptrCast(name), @ptrCast(value), pErrStr, errStr.len);

//         std.log.info("result => {d}", .{result});
//     }

//     pub fn dump(self: *const Conf) void {
//         var cnt: usize = undefined;
//         const arr = rd_kafka_conf_dump(self, &cnt);
//         defer c_rdk.rd_kafka_conf_dump_free(arr, cnt);

//         std.log.info(">>>> dump <<<<", .{});
//         var i: usize = 0;
//         while (i < cnt) : (i += 2) {
//             std.log.info("{s} = {s}", .{ arr[i], arr[i + 1] });
//         }
//     }
// };

// // librdkafka "conf" externs.
// pub extern "c" fn rd_kafka_conf_new() *Conf;
// pub extern "c" fn rd_kafka_conf_set(conf: *Conf, name: [*c]const u8, value: [*c]const u8, errStr: [*c]u8, s: usize) c_rdk.rd_kafka_conf_res_t;
// pub extern "c" fn rd_kafka_conf_destroy(conf: *const Conf) void;
// pub extern "c" fn rd_kafka_conf_dup(conf: *const Conf) *Conf;
// pub extern "c" fn rd_kafka_conf_dump(conf: *const Conf, count: [*c]usize) [*c][*c]const u8;

// fn conf_new() *Conf {
//     return rd_kafka_conf_new();
// }

// fn conf_set(conf: *Conf, name: []const u8, value: []const u8) void {
//     var errStr: [512]u8 = undefined;
//     const pErrStr: [*c]u8 = @ptrCast(&errStr);
//     const result = rd_kafka_conf_set(conf, @ptrCast(name), @ptrCast(value), pErrStr, errStr.len);
//     std.log.info("result => {d}", .{result});
// }

// fn deliveryReportCallback(_: ?*c_rdk.rd_kafka_t, rkmessage: [*c]const c_rdk.rd_kafka_message_t, _: ?*anyopaque) callconv(.C) void {
//     if (rkmessage.*.err > 0) {
//         _ = std.c.printf("Message delivery failed: %s\n", c_rdk.rd_kafka_err2str(rkmessage.*.err));
//     } else {
//         std.log.info("Message delivered ({d} bytes, partition: {d})", .{ rkmessage.*.len, rkmessage.*.partition });
//     }
// }

// fn logger(rk: ?*const c_rdk.struct_rd_kafka_s, level: c_int, fac: [*c]const u8, buf: [*c]const u8) callconv(.C) void {
//     const name = c_rdk.rd_kafka_name(rk);
//     if (name != null) {
//         std.log.info("name: {s}, level: {d}, fac: {s}, buf:{s}", .{ name, level, fac, buf });
//     }
// }

// //fn dumpConfig(conf: *c_rdk.struct_rd_kafka_conf_s) void {
// fn dumpConfig(conf: *Conf) void {
//     var cnt: usize = undefined;
//     //const arr = c_rdk.rd_kafka_conf_dump(conf, &cnt);
//     const arr = rd_kafka_conf_dump(conf, &cnt);
//     defer c_rdk.rd_kafka_conf_dump_free(arr, cnt);

//     var i: usize = 0;
//     while (i < cnt) : (i += 2) {
//         std.debug.print("{s} = {s}\n", .{ arr[i], arr[i + 1] });
//     }
// }
