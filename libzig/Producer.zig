const std = @import("std");
const Conf = @import("Conf.zig").Conf;
const zrdk = @import("zigrdkafka.zig");
const c = @import("cdef.zig").cdef;

pub const ProducerResultError = error{
    Instantiation,
};

pub const ProduceOptions = struct {
    /// Which partition to send on, the default is `unassigned`.
    partition: i32 = zrdk.RD_KAFKA_PARTITION_UA,
    /// Flags to utilize on how the message is handled, the default is `copy`.
    flags: c_int = c.RD_KAFKA_MSG_F_COPY,
    /// An optional key to send.
    key: ?[]const u8,
};

pub const Producer = struct {
    cClient: *c.rd_kafka_t,
    conf: Conf,

    const Self = @This();

    pub fn new(conf: Conf) ProducerResultError!Self {
        var errStr: [512]u8 = undefined;
        const pErrStr: [*c]u8 = @ptrCast(&errStr);

        const rk = c.rd_kafka_new(
            c.RD_KAFKA_PRODUCER,
            conf.Handle(),
            pErrStr,
            errStr.len,
        );

        if (rk == null) {
            const err = std.mem.span(pErrStr);
            std.log.err("Err setting instantiating producer: {s}", .{err});
            return ProducerResultError.Instantiation;
        }

        return Self{
            .cClient = rk.?,
            .conf = conf,
        };
    }

    pub fn deinit(self: Self) void {
        c.rd_kafka_destroy(self.cClient);
    }

    pub fn Handle(self: Self) zrdk.Handle {
        return zrdk.Handle{ .cHandle = self.cClient };
    }

    pub fn flush(self: Self, milliseconds: u64) !void {
        _ = c.rd_kafka_flush(self.cClient, @intCast(milliseconds));
    }

    // TODO: produceBatch

    pub fn produce(self: Self, message: []const u8, options: ProduceOptions) !void {

        // TODO: creating topic config here but shouldn't be done here.
        // Should be passed in.
        const tc = c.rd_kafka_topic_conf_new();
        const topic = c.rd_kafka_topic_new(
            self.cClient,
            "topic.foo",
            tc,
        );

        var key: ?*const anyopaque = null;
        var keyLen: usize = 0;

        if (options.key) |k| {
            key = @ptrCast(options.key);
            keyLen = k.len;
        }

        const res = c.rd_kafka_produce(
            // Producer handle
            topic,
            // Topic name
            options.partition,
            // Make a copy of the payload.
            options.flags,
            // Message value and length (Zig NOTE: the C api uses void*, so we have to remove constness.)
            @constCast(@ptrCast(message)),
            // Per-Message opaque, provided in
            // delivery report callback as
            // msg_opaque.
            message.len,
            // Key is an optional message key.
            key,
            // keylen is the optional message key len.
            keyLen,
            // Optional opaque pointer, that is provided in delivery report callback.
            // TODO: allow for sending this in as well.
            null,
        );

        if (res != c.RD_KAFKA_RESP_ERR_NO_ERROR) {
            std.log.info("result of produce was => {d}", .{res});
        }
    }
};
