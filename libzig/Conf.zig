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

pub const ConfConsumeCallback = ?*const fn (ptr: *anyopaque, zrdk.Message, ?*anyopaque) void;
const ConfConsumeCallbackCABI = ?*const fn ([*c]c.rd_kafka_message_t, ?*anyopaque) callconv(.C) void;

pub const ConfLogCallback = ?*const fn (ptr: *anyopaque, i32, *const u8, *const u8) void;
const ConfLogCallbackCABI = *const fn (?*const c.struct_rd_kafka_s, c_int, [*c]const u8, [*c]const u8) callconv(.C) void;

// TODO: The Zig/RebalanceCallback needs to send a proper error, not this i32 crap!!!
pub const ConfRebalanceCallback = ?*const fn (ptr: *anyopaque, err: i32, zrdk.TopicPartitionList) void;
const ConfRebalanceCallbackCABI = ?*const fn (
    ?*c.rd_kafka_t,
    c.rd_kafka_resp_err_t,
    [*c]c.rd_kafka_topic_partition_list_t,
    ?*anyopaque,
) callconv(.C) void;

/// KafkaDispatcher is any "interface" to anything that knows how to be a Kafka Callback.
/// Further reading: https://www.openmymind.net/Zig-Interfaces/
pub const CallbackHandler = struct {
    ptr: *anyopaque,
    logCallbackFn: ConfLogCallback,
    consumeCallbackFn: ConfConsumeCallback,
    rebalanceCallbackFn: ConfRebalanceCallback,

    fn logCallback(self: CallbackHandler, logLevel: i32, facility: *const u8, msg: *const u8) void {
        return self.logCallbackFn(self.ptr, logLevel, facility, msg);
    }

    fn consumeCallback(self: CallbackHandler, msg: zrdk.Message, @"opaque": ?*anyopaque) void {
        return self.consumeCallback(self.ptr, msg, @"opaque");
    }

    fn rebalanceCallback(self: CallbackHandler, err: c.rd_kafka_resp_err_t, topicPartitionList: zrdk.TopicPartitionList) void {
        return self.rebalanceCallback(self.ptr, err, topicPartitionList);
    }
};

// Kafka uses the syslog(3) log level classification.
pub const LogLevel = enum(u32) {
    Emerg = 0,
    Alert = 1,
    Crit = 2,
    Error = 3,
    Warning = 4,
    Notice = 5,
    Info = 6,
    Debug = 7,
};

pub const ConfResultError = error{
    BufferTooSmall,
    Instantiation,
    Invalid,
    Unknown,
};

pub const EventFlags = packed struct(i32) {
    None: bool = false, // 0x0
    Delivery: bool = false, // 0x1
    Fetch: bool = false, // 0x2
    Log: bool = false, // 0x4
    Error: bool = false, // 0x8
    Rebalance: bool = false, // 0x10
    OffsetCommit: bool = false, // 0x20
    Stats: bool = false, // 0x40
    _padding: u24 = 0,

    pub inline fn C(self: EventFlags) c_int {
        return @bitCast(self);
    }
};

pub const Conf = struct {
    cHandle: *c.rd_kafka_conf_t,

    const Self = @This();

    pub fn init() ConfResultError!Self {
        const handle = c.rd_kafka_conf_new();
        if (handle) |h| {
            const cfg = Self{
                .cHandle = h,
            };

            try cfg.set("client.software.name", "zigrdkafka");
            try cfg.set("client.software.version", cfg.softwareVersion());

            return cfg;
        } else {
            return ConfResultError.Instantiation;
        }
    }

    // deinit ensures proper cleanup. Only call this if you did not give this to a Kafka client.
    // Giving it to a Kafka client, the client takes ownership and is responsibile for destory it.
    pub fn deinit(self: Self) void {
        self.destroy();
    }

    pub fn Handle(self: Self) *c.rd_kafka_conf_t {
        return self.cHandle;
    }

    fn destroy(self: Self) void {
        c.rd_kafka_conf_destroy(self.cHandle);
    }

    pub fn get(self: Self, name: [*:0]const u8, dest: []u8, destSize: *usize) ConfResultError!void {
        const res = c.rd_kafka_conf_get(
            self.cHandle,
            @ptrCast(name),
            @ptrCast(dest),
            destSize,
        );

        switch (res) {
            c.RD_KAFKA_CONF_INVALID => return ConfResultError.Invalid,
            c.RD_KAFKA_CONF_UNKNOWN => return ConfResultError.Unknown,
            c.RD_KAFKA_CONF_OK => {
                if (destSize.* > dest.len) {
                    std.log.err("`dest` buffer is not large enough for key: {s}", .{name});
                    return ConfResultError.BufferTooSmall;
                }
            },
            else => unreachable,
        }
    }

    pub fn set(self: Self, name: [*:0]const u8, value: [*:0]const u8) ConfResultError!void {
        var errStr: [512]u8 = undefined;
        const pErrStr: [*c]u8 = @ptrCast(&errStr);

        const res = c.rd_kafka_conf_set(
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
                return ConfResultError.Invalid;
            },
            c.RD_KAFKA_CONF_UNKNOWN => {
                const err = std.mem.span(pErrStr);
                std.log.err("Err setting configuration key: {s}", .{err});
                return ConfResultError.Unknown;
            },
            c.RD_KAFKA_CONF_OK => {
                return;
            },
            else => unreachable,
        }
    }

    /// Enable event sourcing. events is a bitmask of RD_KAFKA_EVENT_* of events to enable
    /// for consumption by rd_kafka_queue_poll().
    pub fn setEvents(self: Self, events: EventFlags) void {
        c.rd_kafka_conf_set_events(self.cHandle, events.C());
    }

    /// Sets the application's opaque pointer that will be passed to callbacks.
    pub fn setOpaque(self: Self, ptr: ?*anyopaque) void {
        c.rd_kafka_conf_set_opaque(self.cHandle, ptr);
    }

    /// Set the logging callback. By default librdkafka will print to stderr (or
    /// syslog if configured).
    ///
    /// NOTE: The application MUST NOT call any librdkafka APIs or do any
    /// prolonged work in a log_cb unless logs have been forwarded to a queue
    /// via set_log_queue.
    pub fn registerForLogging(self: Self) void {
        const abi = struct {
            pub fn C(rk: ?*const c.struct_rd_kafka_s, level: c_int, facility: [*c]const u8, msg: [*c]const u8) callconv(.C) void {
                if (c.rd_kafka_opaque(rk)) |h| {
                    // This callback DOES have the opaque param (unlike the logger cb), so we harvest it directly.
                    const handler: *zrdk.CallbackHandler = @alignCast(@ptrCast(h));

                    // TODO: this callback should be sending Zig friendly types so the callback signature needs to change.
                    if (handler.logCallbackFn) |cb| {
                        cb(handler.ptr, level, facility, msg);
                    }
                } else {
                    @panic(
                        \\The opaque is not set on either the Consumer or Producer. 
                        \\This must be set before you invoke registerForLogging.
                    );
                }
            }
        };

        // NOTE: For this callback, librdkafka doesn't provide an extra opaque pointer, so trying to find a workaround.
        c.rd_kafka_conf_set_log_cb(self.cHandle, abi.C);
    }

    pub fn registerForConsuming(self: Self) void {
        const abi = struct {
            pub fn C(msg: [*c]c.rd_kafka_message_t, @"opaque": ?*anyopaque) callconv(.C) void {
                if (@"opaque") |h| {
                    // This callback DOES have the opaque param (unlike the logger cb), so we harvest it directly.
                    const handler: *zrdk.CallbackHandler = @alignCast(@ptrCast(h));

                    // Wrap msg.
                    const wrappedMsg = zrdk.Message.wrap(msg);

                    // TODO: this callback should be sending Zig friendly types so the callback signature needs to change.
                    if (handler.consumeCallbackFn) |cb| {
                        cb(handler.ptr, wrappedMsg, @"opaque");
                    }
                } else {
                    @panic(
                        \\The opaque is not set on either the Consumer or Producer. 
                        \\This must be set before you invoke registerForConsuming.
                    );
                }
            }
        };

        c.rd_kafka_conf_set_consume_cb(self.cHandle, abi.C);
    }

    pub fn registerForRebalance(self: Self) void {
        const abi = struct {
            pub fn C(
                rk: ?*c.rd_kafka_t,
                err: c.rd_kafka_resp_err_t,
                tpl: [*c]c.rd_kafka_topic_partition_list_t,
                @"opaque": ?*anyopaque,
            ) callconv(.C) void {
                _ = rk;
                if (@"opaque") |h| {
                    // This callback DOES have the opaque param (unlike the logger cb), so we harvest it directly.
                    const handler: *zrdk.CallbackHandler = @alignCast(@ptrCast(h));

                    // TODO: this callback should be sending Zig friendly types so the callback signature needs to change.
                    // TODO: this callback is missing the error (2nd param)
                    // NOTE: If callback is null, don't invoke it.
                    if (handler.rebalanceCallbackFn) |cb| {
                        // Wrap TopicPartitionList.
                        const wrappedTPL = zrdk.TopicPartitionList.wrap(tpl);
                        cb(handler.ptr, err, wrappedTPL);
                    }
                } else {
                    @panic(
                        \\The opaque is not set on either the Consumer or Producer. 
                        \\This must be set before you invoke registerForConsuming.
                    );
                }
            }
        };

        c.rd_kafka_conf_set_rebalance_cb(self.cHandle, abi.C);
    }

    /// Duplicate the current config.
    pub fn dup(self: Self) ConfResultError!Self {
        const res = c.rd_kafka_conf_dup(self.cHandle);
        if (res) |h| {
            return Self{ .cHandle = h };
        }
        return ConfResultError.Instantiation;
    }

    /// Same as `dup` but with a slice of property name prefixes to filter out (ignore) when copying.
    pub fn dupFilter(self: Self, filterPrefixes: []const [:0]const u8) ConfResultError!Self {
        const prefixes = @as(
            [*c][*c]const u8,
            @ptrCast(@constCast(filterPrefixes)),
        );
        const res = c.rd_kafka_conf_dup_filter(
            self.cHandle,
            filterPrefixes.len,
            prefixes,
        );
        if (res) |h| {
            return Self{ .cHandle = h };
        }
        return ConfResultError.Instantiation;
    }

    pub fn dump(self: Self) void {
        var cnt: usize = undefined;
        const arr = c.rd_kafka_conf_dump(self.cHandle, &cnt);
        defer c.rd_kafka_conf_dump_free(arr, cnt);

        std.log.info("\n\n>>>> dump <<<<", .{});
        var i: usize = 0;
        while (i < cnt) : (i += 2) {
            std.log.info("{s} => {s}", .{ arr[i], arr[i + 1] });
        }
    }

    // NOTE: rust has a remove method, and the c api doesn't.
    // They do this by actually using a dictionary for everything
    // then there is a create_native_config which returns an actual librdkafka config.
    // pub fn remove(self: *conf, name: []const u8) void

    pub fn setLogLevel(self: Self, lvl: LogLevel) ConfResultError!void {
        const keyName = "log_level";
        switch (lvl) {
            .Emerg => try self.set(keyName, "0"),
            .Alert => try self.set(keyName, "1"),
            .Crit => try self.set(keyName, "2"),
            .Error => try self.set(keyName, "3"),
            .Warning => try self.set(keyName, "4"),
            .Notice => try self.set(keyName, "5"),
            .Info => try self.set(keyName, "6"),
            .Debug => try self.set(keyName, "7"),
        }
    }

    pub fn softwareVersion(self: Self) [:0]const u8 {
        _ = self;
        // Format must match /^([\.\-a-zA-Z0-9])+$/ per Validation section of
        // KIP-511.
        // v0.5.2-zigrdkafka-v0.0.1-zig-0.13.0
        return "v0.5.2-zigrdkafka-v0.0.1-zig-0.13.0";
    }

    // TODO: read docs and understand this api.
    // pub fn set_events(self: *Conf, events: EventFlags) void {
    //     cdef.rd_kafka_conf_set_events(self, @intFromEnum(events));
    // }
};

// TODO: wire up tests.
test "set a valid value" {
    const cfg = try Conf.new();
    defer cfg.deinit();
}
