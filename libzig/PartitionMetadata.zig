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

pub const PartitionMetadataRespError = error{
    Instantiation,
};

pub const PartitionMetadata = struct {
    cHandle: *c.struct_rd_kafka_metadata_partition,

    const Self = @This();

    pub inline fn wrap(rawPtr: *c.struct_rd_kafka_metadata_partition) Self {
        return Self{ .cHandle = rawPtr };
    }

    /// Returns the Partition's ID.
    pub inline fn id(self: Self) i32 {
        return self.cHandle.id;
    }

    /// Returns the error for the Partition as reported by the Broker.
    pub inline fn err(self: Self) ?c_int {
        if (self.cHandle.err != null) {
            return self.cHandle.err;
        }
    }

    /// ID of the Leader Broker for this Partition.
    pub inline fn leader(self: Self) i32 {
        return self.cHandle.leader;
    }

    // TODO: replicas
    // TODO: in_sync_replicas
};
