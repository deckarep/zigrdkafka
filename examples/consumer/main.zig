const std = @import("std");
const zrdk = @import("zigrdkafka");

// Somewhat based on the original raw C example: https://github.com/confluentinc/librdkafka/blob/master/examples/consumer.c

pub fn main() !void {
    std.log.info("all your bases..blah, blah...", .{});
    std.log.info("kafka version => {s}", .{zrdk.kafkaVersionStr()});

    try testTopicConf();

    for (0..10) |i| {
        const a: i64 = @intCast(i);
        const b: i64 = @intCast(i + 1);
        try testUUID(a, b);
    }

    const brokers = "localhost:9092";
    const groupid = "zig-cli-consumer";
    const topics = [_][]const u8{"topic.foo"};

    const conf = try zrdk.Conf.new();
    try conf.set("bootstrap.servers", brokers);
    try conf.set("group.id", groupid);
    try conf.set("auto.offset.reset", "earliest");

    const consumer = try zrdk.Consumer.new(conf);
    defer consumer.deinit();
    defer consumer.close();

    consumer.subscribe(&topics);

    var count: usize = 0;
    while (count < 5) {
        try consumer.do();

        count += 1;
    }
}

pub fn testUUID(first: i64, second: i64) !void {
    const u = try zrdk.Uuid.new(first, second);
    defer u.deinit();

    const str = u.base64Str();
    if (str) |s| {
        std.log.info("Uuid b64 => {s}", .{s});
    }

    std.log.info("msb => {d}", .{u.mostSignificantBits()});
    std.log.info("lsb => {d}", .{u.leastSignificantBits()});
}

pub fn testTopicConf() !void {
    const tc = try zrdk.TopicConf.new();
    defer tc.deinit();

    tc.dump();

    try tc.set("request.required.acks", "3");
    try tc.set("acks", "2");

    var buf: [128]u8 = undefined;
    var bufSize: usize = 0;
    try tc.get("acks", &buf, &bufSize);

    std.log.info("key acks => {s}", .{buf[0..bufSize]});

    tc.dump();
}
