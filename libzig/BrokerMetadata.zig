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

pub const BrokerMetadataRespError = error{
    Instantiation,
};

pub const BrokerMetadata = struct {
    cHandle: *c.struct_rd_kafka_metadata_broker,

    const Self = @This();

    pub inline fn wrap(rawPtr: *c.struct_rd_kafka_metadata_broker) Self {
        return Self{ .cHandle = rawPtr };
    }

    /// Returns the Broker's cluster ID.
    pub inline fn id(self: Self) i32 {
        return self.cHandle.id;
    }

    /// Returns the hostname of the Broker.
    pub inline fn host(self: Self) []const u8 {
        return std.mem.span(self.cHandle.host);
    }

    /// Returns the port used to connect to the Broker.
    pub inline fn port(self: Self) i32 {
        return @intCast(self.cHandle.port);
    }
};
