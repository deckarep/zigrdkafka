const zrk = @This();
const std = @import("std");

const cdef = @import("librdkafka-ext.zig");

// TODO: is this the best way to represent this struct?
// https://devlog.hexops.com/2022/packed-structs-in-zig/
// NOTE: not sure how to model this as it's not an enum, but just a bunch of defines.
// pub const EventFlags = packed struct {
//     None: bool = false,
//     Dr: bool = false,
//     Fetch: bool = false,
//     Log: bool = false,
//     Error: bool = false,
//     Rebalance: bool = false,
//     OffsetCommit: bool = false,
//     Stats: bool = false,

//     _padding: c_int = 0,
//     // TODO: the rest of them.
// };

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

pub const ConfResult = enum(c_int) {
    Unknown = -2, // Unknown configuration name.
    Invalid = -1, // Invalid configuration value.
    OK = 0, // Configuration ok.
};

pub const Conf = extern struct {
    pub fn new() *Conf {
        return cdef.rd_kafka_conf_new();
    }

    pub fn destroy(self: *Conf) void {
        cdef.rd_kafka_conf_destroy(self);
    }

    pub fn dup(self: *const Conf) *Conf {
        return cdef.rd_kafka_conf_dup(self);
    }

    pub fn get(self: *const Conf, name: [*:0]const u8, dest: [*:0]u8, dest_size: *usize) ConfResult {
        return cdef.rd_kafka_conf_get(self, @ptrCast(name), @ptrCast(dest), dest_size);
    }

    pub fn set(self: *Conf, name: [*:0]const u8, value: [*:0]const u8) void {
        // TODO: allow user to get an error string somehow.

        var errStr: [512]u8 = undefined;
        const pErrStr: [*c]u8 = @ptrCast(&errStr);

        const result = cdef.rd_kafka_conf_set(
            self,
            @ptrCast(name),
            @ptrCast(value),
            pErrStr,
            errStr.len,
        );

        // TODO: handle the error appropriately.
        if (result != .OK) {
            std.log.err("result => {?}", .{result});
        }
    }

    // NOTE: rust has a remove method, and the c api doesn't.
    // They do this by actually using a dictionary for everything
    // then there is a create_native_config which returns an actual librdkafka config.
    // pub fn remove(self: *conf, name: []const u8) void

    pub fn setLogLevel(self: *Conf, lvl: LogLevel) void {
        const name = "log_level";
        switch (lvl) {
            .Emerg => self.set(name, "0"),
            .Alert => self.set(name, "1"),
            .Crit => self.set(name, "2"),
            .Error => self.set(name, "3"),
            .Warning => self.set(name, "4"),
            .Notice => self.set(name, "5"),
            .Info => self.set(name, "6"),
            .Debug => self.set(name, "7"),
        }
    }

    // pub fn set_events(self: *Conf, events: EventFlags) void {
    //     cdef.rd_kafka_conf_set_events(self, @intFromEnum(events));
    // }

    pub fn dump(self: *const Conf) void {
        var cnt: usize = undefined;
        const arr = cdef.rd_kafka_conf_dump(self, &cnt);
        defer cdef.rd_kafka_conf_dump_free(arr, cnt);

        std.log.info(">>>> dump <<<<", .{});
        var i: usize = 0;
        while (i < cnt) : (i += 2) {
            std.log.info("{s} = {s}", .{ arr[i], arr[i + 1] });
        }
    }
};
