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

const AppHandler = struct {
    logCalls: usize = 0,
    consumeCalls: usize = 0,
    rebalanceCalls: usize = 0,
    offsetCommitCalls: usize = 0,
    statsCalls: usize = 0,
    deliveryReportMessageCalls: usize = 0,
    backgroundEventCalls: usize = 0,
    throttleCalls: usize = 0,
    socketCalls: usize = 0,
    connectCalls: usize = 0,
    closeCalls: usize = 0,
    openCalls: usize = 0,

    inline fn from(ptr: *anyopaque) *AppHandler {
        return @alignCast(@ptrCast(ptr));
    }

    fn log(ptr: *anyopaque, level: i32, fac: *const u8, buf: *const u8) void {
        const self = AppHandler.from(ptr);
        self.logCalls += 1;
        std.log.info("log calls: {d}, level: {d}, fac: {s}, buf:{s}", .{ self.logCalls, level, fac, buf });
    }

    fn consume(ptr: *anyopaque, msg: zrdk.Message, @"opaque": ?*anyopaque) void {
        const self = AppHandler.from(ptr);
        _ = @"opaque"; // I don't think this callback api needs to provide opaque behavior, for any of the callbacks.
        self.consumeCalls += 1;
        std.log.info("consume calls: {d}, topic: {s}", .{ self.consumeCalls, msg.topic().name() });
    }

    fn rebalance(ptr: *anyopaque, err: i32, topicPartitionList: zrdk.TopicPartitionList) void {
        const self = AppHandler.from(ptr);
        self.rebalanceCalls += 1;
        std.log.info("rebalance calls: {d}, err:{d}, topicPartitionList: {?}", .{
            self.rebalanceCalls,
            err,
            topicPartitionList,
        });
    }

    fn offsetCommits(ptr: *anyopaque, err: i32, topicPartitionList: zrdk.TopicPartitionList) void {
        const self = AppHandler.from(ptr);
        self.offsetCommitCalls += 1;
        std.log.info("offset commit calls: {d}, err:{d}, topicPartitionList: {?}", .{
            self.offsetCommitCalls,
            err,
            topicPartitionList,
        });
    }

    fn stats(ptr: *anyopaque, json: []const u8) void {
        const self = AppHandler.from(ptr);
        self.statsCalls += 1;

        std.log.info("stats calls: {d}, json: {s}", .{
            self.statsCalls,
            json,
        });
    }

    fn deliveryReportMessage(ptr: *anyopaque, msg: zrdk.Message) void {
        const self = AppHandler.from(ptr);
        self.deliveryReportMessageCalls += 1;

        std.log.info("deliveryReportMessage calls: {d}, msg: {s}", .{
            self.deliveryReportMessageCalls,
            msg.payloadAsString(),
        });
    }

    fn backgroundEvent(ptr: *anyopaque, evt: zrdk.Event) void {
        const self = AppHandler.from(ptr);
        self.backgroundEventCalls += 1;

        std.log.info("backgroundEvent calls: {d}, msg: {s}", .{
            self.backgroundEventCalls,
            evt.name(),
        });
    }

    fn throttle(ptr: *anyopaque, brokerName: []const u8, brokerID: i32, throttleMS: i32) void {
        const self = AppHandler.from(ptr);
        self.throttleCalls += 1;

        std.log.info("throttle calls: {d}, brokerName: {s}, brokerID: {d}, throttleMS: {d}", .{
            self.throttleCalls,
            brokerName,
            brokerID,
            throttleMS,
        });
    }

    fn socket(ptr: *anyopaque, domain: i32, @"type": i32, protocol: i32) i32 {
        const self = AppHandler.from(ptr);
        self.socketCalls += 1;

        std.log.info("socket calls: {d}, domain: {d}, type: {d}, protocol: {d}", .{
            self.socketCalls,
            domain,
            @"type",
            protocol,
        });

        return 0;
    }

    fn connect(ptr: *anyopaque, sockfd: i32, sockaddr: *const anyopaque, addrLen: i32, brokerID: []const u8) i32 {
        const self = AppHandler.from(ptr);
        self.connectCalls += 1;

        std.log.info("connect calls: {d}, sockfd: {d}, sockaddr: {*}, addrLen: {d}, brokerID: {s}", .{
            self.connectCalls,
            sockfd,
            sockaddr,
            addrLen,
            brokerID,
        });

        return 0;
    }

    fn open(ptr: *anyopaque, pathName: []const u8, flags: i32, mode: u16) i32 {
        const self = AppHandler.from(ptr);
        self.openCalls += 1;

        std.log.info("open calls: {d}, pathName: {s}, flags: {d}, mode: {d}", .{
            self.openCalls,
            pathName,
            flags,
            mode,
        });

        return 0;
    }

    fn close(ptr: *anyopaque, sockfd: i32) i32 {
        const self = AppHandler.from(ptr);
        self.closeCalls += 1;

        std.log.info("close calls: {d}, sockfd: {d}", .{
            self.closeCalls,
            sockfd,
        });

        return 0;
    }

    pub fn handler(self: *AppHandler) zrdk.CallbackHandler {
        return .{
            .ptr = self,
            .logCallbackFn = log,
            .consumeCallbackFn = consume,
            .rebalanceCallbackFn = rebalance,
            .offsetCommitsCallbackFn = offsetCommits,
            .statsCallbackFn = stats,
            .deliveryReportMessageCallbackFn = deliveryReportMessage,
            .backgroundEventCallbackFn = backgroundEvent,
            .throttleCallbackFn = throttle,
            .socketCallbackFn = socket,
            .connectCallbackFn = connect,
            .closeCallbackFn = close,
            .openCallbackFn = open,
        };
    }
};

pub fn main() !void {
    std.log.info("all your bases..blah, blah...", .{});
    std.log.info("kafka version => {s}", .{zrdk.kafkaVersionStr()});

    var myApp = AppHandler{};
    const handler = myApp.handler();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // try testTopicConf();
    try testTopicPartitionList();
    try testHeaders();

    for (0..10) |i| {
        const a: i64 = @intCast(i);
        const b: i64 = @intCast(i + 1);
        try testUUID(a, b);
    }

    const conf = try zrdk.Conf.init();
    conf.setEvents(.{ .Delivery = true });

    // These lines below register for the respective callbacks to fire.
    conf.setOpaque(@constCast(&handler));

    // TODO: these is verbose, just use a single function with flags probably.
    conf.registerForLogging();
    conf.registerForConsuming();
    conf.registerForRebalance();
    conf.registerForOffsetCommits();
    conf.registerForStats();
    conf.registerForDeliveryReportMessage();
    conf.registerForBackgroundEvent();
    conf.registerForThrottle();
    conf.registerForSocket();
    conf.registerForConnect();
    conf.registerForClose();
    conf.registerForOpen();

    try conf.set("bootstrap.servers", "localhost:9092");
    try conf.set("group.id", "zig-cli-consumer");
    try conf.set("auto.offset.reset", "earliest");

    const consumer = try zrdk.Consumer.init(conf);
    defer consumer.deinit();
    defer consumer.close();

    consumer.subscribe(&.{"topic.foo"});

    var count: usize = 0;
    while (count < 5) {
        const msg = consumer.poll(100);
        defer msg.deinit();

        defer count += 1;

        const memberStr = try consumer.memberId(allocator);
        if (memberStr) |str| {
            defer allocator.free(str);
            std.log.info("member_id => {s}", .{str});
        }

        if (!msg.isOK()) {
            std.log.warn("either message was empty or it had an error...", .{});
            // Deal with it here.
            continue;
        }

        // Log the message.
        std.log.info("message => {s}\ntopic => {s}\npartition => {d}\noffset => {d}\n", .{
            msg.payloadAsString(),
            msg.topic().name(),
            msg.partition(),
            msg.offset(),
        });
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

    // userSort
    const cmp = struct {
        fn inner(a: zrdk.TopicPartition, b: zrdk.TopicPartition) i32 {
            if (a.partition() < b.partition()) {
                return 1;
            } else if (a.partition() > b.partition()) {
                return -1;
            } else {
                return 0;
            }
        }
    };

    tpl.sort(cmp.inner);
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

    try hdrs.addZ("Hello", "aaa");
    try hdrs.addZ("How", "bbbb");
    try hdrs.addZ("How", "eeeeeee");
    try hdrs.addZ("How", "dddddddddddd");
    try hdrs.addZ("How", "ggggggggggggggggg");
    try hdrs.addZ("What", "ccccc");

    std.log.info("headers count => {d}", .{hdrs.count()});

    const strResult = try hdrs.last("How");
    std.log.info("strResult => {s}", .{strResult});

    var i: usize = 0;
    while (true) : (i += 1) {
        if (hdrs.headerAt(i, "How")) |res| {
            std.log.info("idx => {d} at str: {s}", .{ i, res });
        } else |err| switch (err) {
            zrdk.HeadersRespError.NotFound => {
                std.log.info("reached the end of the list!", .{});
                break;
            },
            else => |otherErr| return otherErr,
        }
    }
}
