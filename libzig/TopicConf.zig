const std = @import("std");
const c = @import("cdef.zig").cdef;

// NOTE: this api largely seems to match the regular Conf api.
// Most of below was copied from Conf.zig, perhaps I need to refactor
// and mimic some type of "super" Conf that both can use.
// NOTE: C++ librdkafka does this by having the create take a "global" or "topic" enum value.

pub const TopicConfResultError = error{
    BufferTooSmall,
    Instantiation,
    Invalid,
    Unknown,
};

pub const TopicConf = struct {
    cHandle: *c.rd_kafka_topic_conf_t = undefined,

    const Self = @This();

    pub fn new() TopicConfResultError!Self {
        const handle = c.rd_kafka_topic_conf_new();
        if (handle) |h| {
            return Self{
                .cHandle = h,
            };
        } else {
            return TopicConfResultError.Instantiation;
        }
    }

    // deinit ensures proper cleanup. Only call this if you did not give this to a Kafka client.
    // Giving it to a Kafka client, the client takes ownership and is responsibile for destory it.
    pub fn deinit(self: Self) void {
        self.destroy();
    }

    fn destroy(self: Self) void {
        c.rd_kafka_topic_conf_destroy(self.cHandle);
    }

    pub fn Handle(self: Self) *c.rd_kafka_topic_conf_t {
        return self.cHandle;
    }

    pub fn get(self: Self, name: [*:0]const u8, dest: []u8, destSize: *usize) TopicConfResultError!void {
        const res = c.rd_kafka_topic_conf_get(
            self.cHandle,
            @ptrCast(name),
            @ptrCast(dest),
            destSize,
        );

        switch (res) {
            c.RD_KAFKA_CONF_INVALID => return TopicConfResultError.Invalid,
            c.RD_KAFKA_CONF_UNKNOWN => return TopicConfResultError.Unknown,
            c.RD_KAFKA_CONF_OK => {
                if (destSize.* > dest.len) {
                    std.log.err("`dest` buffer is not large enough for key: {s}", .{name});
                    return TopicConfResultError.BufferTooSmall;
                }
            },
            else => unreachable,
        }
    }

    pub fn set(self: Self, name: [*:0]const u8, value: [*:0]const u8) TopicConfResultError!void {
        var errStr: [512]u8 = undefined;
        const pErrStr: [*c]u8 = @ptrCast(&errStr);

        const res = c.rd_kafka_topic_conf_set(
            self.cHandle,
            @ptrCast(name),
            @ptrCast(value),
            pErrStr,
            errStr.len,
        );

        switch (res) {
            c.RD_KAFKA_CONF_INVALID => {
                const err = std.mem.span(pErrStr);
                std.log.err("Err setting configuration key: {s}", .{err});
                return TopicConfResultError.Invalid;
            },
            c.RD_KAFKA_CONF_UNKNOWN => {
                const err = std.mem.span(pErrStr);
                std.log.err("Err setting configuration key: {s}", .{err});
                return TopicConfResultError.Unknown;
            },
            c.RD_KAFKA_CONF_OK => {
                return;
            },
            else => unreachable,
        }
    }

    pub fn dup(self: Self) TopicConfResultError!Self {
        const res = c.rd_kafka_topic_conf_dup(self.cHandle);
        if (res) |h| {
            return Self{ .cHandle = h };
        }
        return TopicConfResultError.Instantiation;
    }

    pub fn dump(self: Self) void {
        var cnt: usize = undefined;
        const arr = c.rd_kafka_topic_conf_dump(self.cHandle, &cnt);
        // Note: even though this is a topic_conf, it's freed with conf_dump_free (per the docs)
        // no topic_conf_dump_free exists.
        defer c.rd_kafka_conf_dump_free(arr, cnt);

        std.log.info("\n\n*** TopicConf Dump ***", .{});
        var i: usize = 0;
        while (i < cnt) : (i += 2) {
            std.log.info("{s} => {s}", .{ arr[i], arr[i + 1] });
        }
    }
};
