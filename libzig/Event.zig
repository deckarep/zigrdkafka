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

pub const TopicResultError = error{
    Instantiation,
    // TODO: other possible errors.
};

/// Somewhat based on this: https://github.com/deadmanssnitch/kafka/blob/4e61b272e91d9a98f9eb97cf044ab3064e57712a/lib/kafka/ffi/event.rb
pub const Event = struct {
    cHandle: *c.rd_kafka_event_t,

    const Self = @This();

    pub fn wrap(cPtr: *c.rd_kafka_event_t) Self {
        return .{ .cHandle = cPtr };
    }

    pub fn deinit(self: Self) void {
        self.destroy();
    }

    /// Destroy the event, releasing it's resources back to the system.
    fn destroy(self: Self) void {
        c.rd_kafka_event_destroy(self.cHandle);
    }

    /// Returns the name of the event's type.
    pub fn name(self: Self) []const u8 {
        return std.mem.span(c.rd_kafka_event_name(self.cHandle));
    }

    /// Returns the event's type
    ///
    /// @see RD_KAFKA_EVENT_*
    pub fn @"type"(self: Self) void {
        // TODO: this should RETURN some type classification, but not raw C Kafka type bullshit.
        // TODO: Figure out this mapping, and return a higher-level zigrdkafka construct.
        const res = c.rd_kafka_event_type(self.cHandle);
        std.log.info("type of event => {}", .{res});
    }

    /// Returns true when the event does not have an attached error.
    pub fn successful(self: Self) bool {
        return !self.hasError();
    }

    /// Returns true when an error occurred at the event level. This only checks
    /// if there was an error attached to the event, some events have more
    /// granular errors embeded in their results. For example the
    /// Kafka::FFI::Admin::DeleteTopicsResult event has potential errors on each
    /// of the results included in #topics.
    pub fn hasError(self: Self) bool {
        return c.rd_kafka_event_error(self.cHandle) != 0;
    }

    // Returns a description of the error or null when there is no error.
    pub fn errorAsString(self: Self) ?[]const u8 {
        if (c.rd_kafka_event_error_string(self.cHandle)) |errStr| {
            return std.mem.span(errStr);
        } else {
            return null;
        }
    }
};
