const std = @import("std");
const Conf = @import("Conf.zig").Conf;
const zrdk = @import("zigrdkafka.zig");
const c = @import("cdef.zig").cdef;

pub const ProduceOptions = struct {
    partition: i32 = zrdk.RD_KAFKA_PARTITION_UA,
    flags: c_int = c.RD_KAFKA_MSG_F_COPY,
    key: ?[]const u8,
    //key: ?*const anyopaque = null,
    //keyLen: usize = 0,
};

pub const Producer = struct {
    cClient: ?*c.rd_kafka_t = undefined,
    conf: Conf,

    pub fn new(conf: Conf) Producer {
        // TODO: an error needs to get returned possibly.
        var errStr: [512]u8 = undefined;
        const pErrStr: [*c]u8 = @ptrCast(&errStr);

        const rk = c.rd_kafka_new(
            c.RD_KAFKA_PRODUCER,
            conf.Handle(),
            pErrStr,
            errStr.len,
        );

        if (rk == null) {
            std.log.err("Uh no the kafka handle *rk is null for some reason!\n", .{});
        } else {
            std.log.info("rk was nicely created...\n", .{});
        }

        return Producer{
            .cClient = rk,
            .conf = conf,
        };
    }

    pub fn deinit(_: Producer) void {}

    // pub fn new(conf: *Conf) Producer {
    //     // var errStr: [512]u8 = undefined;
    //     // const pErrStr: [*c]u8 = @ptrCast(&errStr);

    //     // // TODO: an error needs to get returned possibly.

    //     // const rk = cdef.rd_kafka_new(
    //     //     .Producer,
    //     //     conf,
    //     //     pErrStr,
    //     //     errStr.len,
    //     // );

    //     // if (rk == null) {
    //     //     std.log.err("Uh no the kafka handle *rk is null for some reason!\n", .{});
    //     // } else {
    //     //     std.log.info("rk was nicely created...\n", .{});
    //     // }

    //     // return Producer{ .rk = rk, .cfg = conf };
    // }

    // pub fn deinit(self: *Producer) void {
    //     // if (self.rk) |h| {
    //     //     cdef.rd_kafka_destroy(h);
    //     //     self.rk = null;
    //     // }
    // }

    pub fn produce(self: Producer, message: []const u8, options: ProduceOptions) !void {
        if (self.cClient) |client| {
            // TODO: creating topic config here but shouldn't be done here.
            // Should be passed in.
            const tc = c.rd_kafka_topic_conf_new();
            const topic = c.rd_kafka_topic_new(
                client,
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
    }
};
