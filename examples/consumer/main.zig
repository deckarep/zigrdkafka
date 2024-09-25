const std = @import("std");
const zrdk = @import("zigrdkafka");

// Somewhat based on the original raw C example: https://github.com/confluentinc/librdkafka/blob/master/examples/consumer.c

pub fn main() !void {
    std.log.info("all your bases..blah, blah...", .{});
    std.log.info("kafka version => {s}", .{zrdk.kafkaVersionStr()});

    // try testTopicConf();
    try testTopicPartitionList();
    try testHeaders();

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

    std.log.info("consumer loop ended.", .{});
}

pub fn testTopicPartitionList() !void {
    const tpl = zrdk.TopicPartitions.init();
    defer tpl.deinit();

    std.debug.assert(tpl.count() == 0);

    // some adds
    tpl.add("Foo", 0);
    tpl.add("Bar", 1);
    tpl.add("Baz", 2);

    std.debug.assert(tpl.count() == 3);

    // addRange
    tpl.addRange("Biz", 3, 7);

    std.debug.assert(tpl.count() == 8);

    // find
    tpl.find("Bar", 1);

    // setOffset
    tpl.setOffset("Bar", 1, 0);

    // find again.
    tpl.find("Bar", 1);

    // copy
    const tplCopy = tpl.copy();
    defer tplCopy.deinit();

    // del
    std.debug.assert(tpl.del("Foo", 0));

    // delAt
    std.debug.assert(tpl.delAt(0));
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

// WARNING: Bug, this function is show malloc-double-free errors...not sure why yet.
pub fn testTopicConf() !void {
    const conf = try zrdk.Conf.new();

    const consumer = try zrdk.Consumer.new(conf);
    defer consumer.deinit();

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

    // Test topic itself. (not the config)
    const topic = try zrdk.Topic.new(consumer.Handle(), "foo.bar", tc);
    defer topic.deinit();
}

pub fn testHeaders() !void {
    const hdrs = try zrdk.Headers.init();
    defer hdrs.deinit();

    try hdrs.add("Hello", "World!");
    try hdrs.add("How", "Are You?");
    try hdrs.add("What", "me worry?");

    std.log.info("headers count => {d}", .{hdrs.count()});
}
