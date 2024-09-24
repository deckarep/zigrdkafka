const std = @import("std");
const c = @import("cdef.zig").cdef;

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

pub const Conf = struct {
    cHandle: *c.rd_kafka_conf_t = undefined,

    const Self = @This();

    pub fn new() ConfResultError!Self {
        const handle = c.rd_kafka_conf_new();
        if (handle) |h| {
            return Self{
                .cHandle = h,
            };
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

    pub fn dup(self: Self) ConfResultError!Self {
        const res = c.rd_kafka_conf_dup(self.cHandle);
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
