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

pub const HeadersRespError = error{
    Instantiation,
    // TODO: other types of errors that this can return ultimately.
};

pub const Headers = struct {
    cHandle: *c.rd_kafka_headers_t,

    const Self = @This();

    pub fn init() HeadersRespError!Headers {
        return initWithCapacity(0);
    }

    pub fn initWithCapacity(initialCount: usize) HeadersRespError!Headers {
        if (c.rd_kafka_headers_new(initialCount)) |h| {
            return Self{ .cHandle = h };
        }
        return HeadersRespError.Instantiation;
    }

    pub fn deinit(self: Self) void {
        self.destroy();
    }

    fn destroy(self: Self) void {
        c.rd_kafka_headers_destroy(self.cHandle);
    }

    pub fn count(self: Self) usize {
        return c.rd_kafka_header_cnt(self.cHandle);
    }

    pub fn Handle(self: Self) *c.rd_kafka_headers_t {
        return self.cHandle;
    }

    pub fn copy(self: Self) HeadersRespError!Headers {
        const hdrs = c.rd_kafka_headers_copy(self.cHandle);
        if (hdrs) |h| {
            return Self{ .cHandle = h };
        }
        return HeadersRespError.Instantiation;
    }

    // Simplified api for zero-terminated name and value.
    pub fn addZ(self: Self, name: [:0]const u8, value: [:0]const u8) HeadersRespError!void {
        // TODO: handle this error.
        _ = c.rd_kafka_header_add(
            self.cHandle,
            @ptrCast(name),
            -1,
            @ptrCast(value),
            -1,
        );
    }

    pub fn add(self: Self, name: []const u8, value: []const u8) HeadersRespError!void {
        // TODO: handle this error.
        _ = c.rd_kafka_header_add(
            self.cHandle,
            @ptrCast(name),
            @intCast(name.len),
            @ptrCast(value),
            @intCast(value.len),
        );
    }

    pub fn remove(self: Self, name: []const u8) HeadersRespError!void {
        // TODO: handle this error.
        _ = c.rd_kafka_header_remove(self.cHandle, @ptrCast(name));
    }

    pub fn getLast(self: Self, name: [:0]const u8, valueP: [*c]?*const anyopaque, sizeP: *usize) HeadersRespError!void {
        // TODO: handle this error.

        std.log.info("about to do call!!!", .{});
        const res = c.rd_kafka_header_get_last(
            self.cHandle,
            @ptrCast(name),
            valueP,
            sizeP,
        );

        std.log.info("getLast err result => {d}", .{res});
    }

    // TODO: get_last
    // TODO: get
    // TODO: get_all
};
