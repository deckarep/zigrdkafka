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

        const s = Self{
            .cHandle = rk.?,
            .conf = conf,
        };

        // Redirect all messages from per-partition queues to the main queue.
        // Perhaps make this a default setting.
        s.pollSetConsumer();

        return s;
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

    pub fn getOpaque(self: Self) ?*anyopaque {
        return c.rd_kafka_opaque(self.cHandle);
    }

    /// Atomically assign the set of partitions to consume. This will replace the
    /// existing assignment.
    ///
    /// @see rdkafka.h rd_kafka_assign for semantics on use from callbacks and
    /// how empty vs NULL lists affect internal state.
    pub fn assign(self: Self, topicPartitionList: zrdk.TopicPartitionList) void {
        // TODO: handle error and return if present.
        _ = c.rd_kafka_assign(self.cHandle, topicPartitionList.Handle());
    }

    /// Returns this client's broker-assigned group member id.
    ///
    /// Remarks: This currently requires the high-level KafkaConsumer.
    ///
    /// Returns: An allocated string containing the current broker-assigned group member id
    /// or NULL if not available. You must remember to free the string.
    pub fn memberId(self: Self, allocator: std.mem.Allocator) !?[]const u8 {
        const res = c.rd_kafka_memberid(self.cHandle);
        defer c.rd_kafka_mem_free(self.cHandle, res);

        if (res != null) {
            // To mitigate Zig end-users having to use the raw C api to free:
            //      We'll just use the passed allocator, make a copy and return that.
            //      This way, we immediately free the librdkafka returned string
            //      but the Zig user will receive a string managed with their choice of allocator.
            //      Furthermore since this function takes an allocator parameter, Zig user's
            //      should know that this function allocates and therefore needs to be balanced
            //      with a call to free.
            const zigStr = std.mem.span(res);
            const buf = try allocator.alloc(u8, zigStr.len);
            @memcpy(buf, zigStr);
            return buf;
        }

        return null;
    }

    /// Get last known low (oldest/beginning) and high (newest/end) offsets for partition.
    /// The low offset is updated periodically (if statitiscs.interval.ms is set) while the
    /// high offset is updated on each fetched message set from the broker.
    ///
    /// If there is no cached offset (either low or high, or both) then RD_KAFKA_OFFSET_INVALID
    /// will be returned for the respective offset.
    ///
    /// NOTE: Offsets are returned as fields in an anonymous struct instead of using pointer
    /// out params as the original librdkafka c code does.
    ///
    /// Remarks: Shall only be used with an active consumer instance.
    pub fn getWatermarkOffsets(self: Self, topic: [:0]const u8, partition: i32) struct {
        low: i64,
        high: i64,
    } {
        // TODO: handle and return error.
        var low: i64 = undefined;
        var high: i64 = undefined;

        const res = c.rd_kafka_get_watermark_offsets(
            self.cHandle,
            @ptrCast(topic),
            partition,
            &low,
            &high,
        );

        std.log.info("res of getWatermarkOffsets => {d}", .{res});

        return .{
            .low = low,
            .high = high,
        };
    }

    /// Redirect the main event queue to the Consumer's queue so the consumer
    /// doesn't need to poll from it separately for event callbacks to fire.
    ///
    /// NOTE: It is not permitted to call poll after redirecting the main queue
    /// with pollSetConsumer.
    pub inline fn pollSetConsumer(self: Self) void {
        // TODO: handle and return an error if it has one.
        _ = c.rd_kafka_poll_set_consumer(self.cHandle);
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

    /// subscribe conveniently subscribes to the provided string topics
    /// by creating taking care of creating the TopicPartitionList
    /// and using an unassigned partition (-1) to let Kafka handle the
    /// partition assignment internally.
    pub fn subscribe(self: Self, topics: []const [:0]const u8) void {
        // Convert list of topics to a format suitable for librdkafka.
        const topicSubs = zrdk.TopicPartitionList.initWithCapacity(topics.len);
        defer topicSubs.deinit();

        for (topics) |t| {
            // TODO: .add might return an error in the future.
            topicSubs.add(t, c.RD_KAFKA_PARTITION_UA);
        }

        self.subscribeWithList(topicSubs);
    }

    /// subscribe subscribes to the provided TopicPartitionList of topics
    /// and allows the caller to precisely define the mapping of topic
    /// + subscriptions + partitions.
    pub fn subscribeWithList(self: Self, topicSubs: zrdk.TopicPartitionList) void {
        // Subscribe to the list of topics.
        // TODO: handle error.
        _ = c.rd_kafka_subscribe(self.cHandle, topicSubs.Handle());

        std.log.info(
            "Subscribed to {d} topic(s), waiting for rebalance and messages...",
            .{topicSubs.count()},
        );
    }

    /// Unsubscribe from the current subscription set (e.g. all current
    /// subscriptions).
    pub fn unsubscribe(self: Self) void {
        // TODO: handle and return error.
        _ = c.rd_kafka_unsubscribe(self.cHandle);
    }

    /// Retrieve committed offsets for topics + partitions. The offset field for
    /// each TopicPartition in list will be set to the stored offset or
    /// RD_KAFKA_OFFSET_INVALID in case there was no stored offset for that
    /// partition. The error field is set if there was an error with the
    /// TopicPartition.
    pub fn committed(self: Self, args: struct {
        topicPartitionList: zrdk.TopicPartitionList,
        timeoutMS: i32 = 1000,
    }) void {
        // TODO: handle and return error.
        _ = c.rd_kafka_committed(
            self.cHandle,
            args.topicPartitionList.Handle(),
            args.timeoutMS,
        );
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
