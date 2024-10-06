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

const zrk = @This();
const std = @import("std");
const c = @import("cdef.zig").cdef;

const bm = @import("BrokerMetadata.zig");
const cfg = @import("Conf.zig");
const gi = @import("GroupInfo.zig");
const gl = @import("GroupList.zig");
const gmi = @import("GroupMemberInfo.zig");
const topCfg = @import("TopicConf.zig");
const top = @import("Topic.zig");
const tp = @import("TopicPartition.zig");
const tpl = @import("TopicPartitionList.zig");
const hdrs = @import("Headers.zig");
const prd = @import("Producer.zig");
const msg = @import("Message.zig");
const csmr = @import("Consumer.zig");
const uuid = @import("Uuid.zig");
const hndl = @import("Handle.zig");
const pm = @import("PartitionMetadata.zig");

pub const Handle = hndl.Handle;
pub const BrokerMetadata = bm.BrokerMetadata;
pub const BrokerMetadataRespError = bm.BrokerMetadataRespError;
pub const ConfResult = cfg.ConfResult;
pub const Conf = cfg.Conf;
pub const CallbackHandler = cfg.CallbackHandler;
pub const ConfLogCallback = cfg.ConfLogCallback;
pub const ConfRebalanceCallback = cfg.ConfRebalanceCallback;
pub const ConfDeliveryReportMessageCallback = cfg.ConfDeliveryReportMessageCallback;
pub const ConfEventFlags = cfg.EventFlags;
pub const GroupInfo = gi.GroupInfo;
pub const GroupList = gl.GroupList;
pub const GroupMemberInfo = gmi.GroupMemberInfo;
pub const Message = msg.Message;
pub const TopicConf = topCfg.TopicConf;
pub const Topic = top.Topic;
pub const TopicPartitionList = tpl.TopicPartitionList;
pub const TopicPartitionListSortCmp = tpl.SortComparator;
pub const TopicPartition = tp.TopicPartition;
pub const Headers = hdrs.Headers;
pub const HeadersRespError = hdrs.HeadersRespError;
pub const LogLevel = cfg.LogLevel;
pub const Producer = prd.Producer;
pub const Consumer = csmr.Consumer;
pub const Uuid = uuid.Uuid;
pub const PartitionMetadata = pm.PartitionMetadata;
pub const PartitionMetadataRespError = pm.PartitionMetadataRespError;
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
