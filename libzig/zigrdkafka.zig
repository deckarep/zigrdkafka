const zrk = @This();
const std = @import("std");

const cfg = @import("Conf.zig");
pub const ConfResult = cfg.ConfResult;
pub const Conf = cfg.Conf;
pub const LogLevel = cfg.LogLevel;

const prd = @import("Producer.zig");
pub const Producer = prd.Producer;

// pub const rd_kafka_type_t = enum(c_int) {
//     Producer,
//     Consumer,
// };

// Opaque types.
// pub const rd_kafka_t = extern struct {};
// pub const rd_kafka_topic_t = extern struct {};
// pub const rd_kafka_topic_conf_t = extern struct {};

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
