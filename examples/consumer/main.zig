// Open Source Initiative OSI - The MIT License (MIT):Licensing

// The MIT License (MIT)
// Copyright (c) 2024 Ralph Caraveo (deckarep@gmail.com)

// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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

    const conf = try zrdk.Conf.init();
    try conf.set("bootstrap.servers", brokers);
    try conf.set("group.id", groupid);
    try conf.set("auto.offset.reset", "earliest");

    const consumer = try zrdk.Consumer.init(conf);
    defer consumer.deinit();
    defer consumer.close();

    consumer.subscribe(&topics);

    var count: usize = 0;
    while (count < 5) {
        const msg = consumer.poll(100);
        defer msg.deinit();

        // Message could be empty because the consumer timed out.
        if (msg.isEmpty()) {
            std.log.warn("consumer timeout occurred so nothing to do, continuing...", .{});
            continue;
        }

        // The message could also have an associated error.
        if (msg.err() != 0) {
            std.log.warn("error occurred, do something with it...", .{});
            continue;
        }

        // Proper message below.
        std.log.info("message on {s}, partition: {d}, offset: {d}", .{
            msg.topic().name(),
            msg.partition(),
            msg.offset(),
        });

        // TODO: If message has a "key" print it.

        // Print the message value/payload
        std.log.info("Payload as a string {s}", .{msg.payloadAsString()});

        count += 1;
    }

    std.log.info("consumer loop ended.", .{});
}

pub fn testTopicPartitionList() !void {
    const tpl = zrdk.TopicPartitionList.init();
    defer tpl.deinit();

    std.debug.assert(tpl.count() == 0);

    // some adds
    tpl.add("Foo", 0);

    // elemAt
    if (tpl.elemAt(0)) |el| {
        std.debug.assert(el.partition() == 0);
        std.debug.assert(el.offset() == -1001); // Not sure why the default offset is this val.
        std.debug.assert(std.mem.eql(u8, el.topic(), "Foo"));
    }

    tpl.add("Bar", 1);
    tpl.add("Baz", 2);

    std.debug.assert(tpl.count() == 3);

    // addRange
    tpl.addRange("Biz", 3, 7);

    std.debug.assert(tpl.count() == 8);

    // find
    if (tpl.find("Bar", 1)) |tp| {
        std.debug.assert(std.mem.eql(u8, tp.topic(), "Bar"));
        std.debug.assert(tp.partition() == 1);
        std.debug.assert(tp.offset() == -1001);
    }

    // setOffset
    tpl.setOffset("Bar", 1, 0);

    // find again.
    if (tpl.find("Bar", 1)) |tp| {
        std.debug.assert(std.mem.eql(u8, tp.topic(), "Bar"));
        std.debug.assert(tp.partition() == 1);
        std.debug.assert(tp.offset() == 0);
    }

    // copy
    const tplCopy = tpl.copy();
    defer tplCopy.deinit();

    // del
    std.debug.assert(tpl.del("Foo", 0));

    std.debug.assert(tpl.count() == 7);

    // delAt
    std.debug.assert(tpl.delAt(0));

    std.debug.assert(tpl.count() == 6);
}

pub fn testUUID(first: i64, second: i64) !void {
    const u = try zrdk.Uuid.init(first, second);
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
    const conf = try zrdk.Conf.init();

    const consumer = try zrdk.Consumer.init(conf);
    defer consumer.deinit();

    const tc = try zrdk.TopicConf.init();
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
    const topic = try zrdk.Topic.init(consumer.Handle(), "foo.bar", tc);
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
