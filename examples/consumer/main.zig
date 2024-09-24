const std = @import("std");
const zrdk = @import("zigrdkafka");

// Somewhat based on the original raw C example: https://github.com/confluentinc/librdkafka/blob/master/examples/consumer.c

pub fn main() !void {
    std.log.info("all your bases..blah, blah...", .{});

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

    while (true) {
        consumer.do();
    }
}
