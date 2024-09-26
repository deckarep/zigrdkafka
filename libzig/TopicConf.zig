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
    cHandle: *c.rd_kafka_topic_conf_t,

    const Self = @This();

    pub fn init() TopicConfResultError!Self {
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
