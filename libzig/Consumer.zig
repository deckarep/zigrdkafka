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
const c = @import("cdef.zig").cdef;
const zrdk = @import("zigrdkafka.zig");

pub const ConsumerResultError = error{
    Instantiation,
};

pub const Consumer = struct {
    cHandle: *c.rd_kafka_t,
    conf: zrdk.Conf,

    const Self = @This();

    pub fn init(conf: zrdk.Conf) ConsumerResultError!Self {
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

        return Self{
            .cHandle = rk.?,
            .conf = conf,
        };
    }

    pub fn deinit(self: Self) void {
        // Internally, rd_kafka_consumer_close will be called if this is called.
        c.rd_kafka_destroy(self.cHandle);
    }

    pub fn Handle(self: Self) zrdk.Handle {
        return zrdk.Handle{
            .cHandle = self.cHandle,
        };
    }

    /// Retrieve the Consumer's broker assigned group Member ID.
    pub fn memberId(self: Self) []const u8 {
        const res = c.rd_kafka_memberid(self.cHandle);
        if (res == null) {
            return "<null>";
        }
        return std.mem.span(res);
    }

    /// Close down the consumer. This will block until the consumer has revoked
    /// its assignment(s), committed offsets, and left the consumer group. The
    /// maximum blocking time is roughly limited to the `session.timeout.ms`
    /// config option.
    ///
    /// Ensure that `deinit` is called after the Consumer is closed to free up
    /// resources.
    pub fn close(self: Self) void {
        // TODO: handle return error.
        _ = c.rd_kafka_consumer_close(self.cHandle);
    }

    /// Check if the Consumer has been closed.
    pub fn closed(self: Self) bool {
        return c.rd_kafka_consumer_closed(self.cHandle) == 1;
    }

    pub fn subscribe(self: Self, topics: []const [:0]const u8) void {
        // Convert list of topics to a format suitable for librdkafka.
        const topicSubs = zrdk.TopicPartitionList.initWithCapacity(topics.len);
        defer topicSubs.deinit();

        for (topics) |t| {
            // TODO: .add might return an error in the future.
            topicSubs.add(t, c.RD_KAFKA_PARTITION_UA);
        }

        // Subscribe to the list of topics.
        // TODO: handle error.
        _ = c.rd_kafka_subscribe(self.cHandle, topicSubs.Handle());

        std.log.info(
            "Subscribed to {d} topic(s), waiting for rebalance and messages...",
            .{topicSubs.count()},
        );
    }

    pub fn unsubscribe(self: Self) void {
        // TODO: handle and return error.
        _ = c.rd_kafka_unsubscribe(self.cHandle);
    }

    /// Commit the set of offsets from the given TopicPartitionList.
    /// offsets is the set of topic+partition with offset (and maybe metadata) to
    /// be commited. If offsets is nil the current partition assignment set will
    /// be used instead.
    /// If async is false this operation will block until the broker
    /// offset commit is done.
    pub fn commit(self: Self, offsets: ?zrdk.TopicPartitionList, @"async": bool) void {
        // TODO: handle and return error.
        _ = c.rd_kafka_commit(
            self.cHandle,
            if (offsets != null) offsets.?.Handle() else null,
            @"async" == 1,
        );
    }

    /// Commit the message's offset on the broker for the message's partition.
    pub fn commitMessage(self: Self, msg: zrdk.Message, @"async": bool) void {
        // TODO: handle and return error.
        _ = c.rd_kafka_commit_message(
            self.cHandle,
            msg.Handle(),
            @"async" == 1,
        );
    }

    /// poll returns a wrapped message which the caller owns.
    /// Always .deinit() the message no matter what.
    /// Always ensure message !isEmpty() before inspecting it.
    pub fn poll(self: Self, milliseconds: u64) zrdk.Message {
        const rawMsg = c.rd_kafka_consumer_poll(
            self.cHandle,
            @intCast(milliseconds),
        );
        return zrdk.Message.wrap(rawMsg);
    }
};
