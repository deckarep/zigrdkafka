const zrk = @This();
const std = @import("std");
const c = @import("cdef.zig").cdef;

const cfg = @import("Conf.zig");
pub const ConfResult = cfg.ConfResult;
pub const Conf = cfg.Conf;
pub const LogLevel = cfg.LogLevel;

const prd = @import("Producer.zig");
pub const Producer = prd.Producer;

const csmr = @import("Consumer.zig");
pub const Consumer = csmr.Consumer;

const uuid = @import("Uuid.zig");
pub const Uuid = uuid.Uuid;

pub const RD_KAFKA_PARTITION_UA = c.RD_KAFKA_PARTITION_UA;

pub fn kafkaVersionStr() []const u8 {
    return std.mem.span(c.rd_kafka_version_str());
}

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
