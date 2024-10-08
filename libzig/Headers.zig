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
    NotFound, // <-- i made this up on getLast...just to return something useful.
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

    /// headerAt (get) returns a reference to a string slice where the lifetime of the string
    /// is as long as the header is alive in the header list.
    ///
    /// How it works: Iterator index, start at 0 and increment by one for each call as long as
    /// RD_KAFKA_RESP_ERR_NO_ERROR is returned.
    pub fn headerAt(self: Self, idx: usize, name: [:0]const u8) HeadersRespError![]const u8 {
        // size is populated in the rd_kafka_header_get call.
        var size: usize = 0;

        // We need to correctly pass a pointer to a pointer that will simply store
        // the address of where the null-terminated string is located.
        var value: u8 = undefined;
        var valueP: ?*const u8 = &value;
        const valuePP = @as(*?*const anyopaque, @ptrCast(&valueP));

        const res = c.rd_kafka_header_get(
            self.cHandle,
            idx,
            @ptrCast(name),
            valuePP,
            &size,
        );

        // TODO: handle this error.
        std.log.info("getLast err result => {d}", .{res});

        if (res != 0) {
            // Made up error for now.
            return HeadersRespError.NotFound;
        }

        if (valueP) |ptr| {
            // Convert to a multi-pointer which can safely be sliced with our known bounds.
            const multiPtr = @as([*]const u8, @ptrCast(ptr));
            return multiPtr[0..size];
        }

        return "<value-not-found>";
    }

    /// last (getLast) returns a reference to a string slice where the lifetime of the string
    /// is as long as the header is alive in the header list.
    pub fn last(self: Self, name: [:0]const u8) HeadersRespError![]const u8 {
        // size is populated in the rd_kafka_header_get_last call.
        var size: usize = 0;

        // We need to correctly pass a pointer to a pointer that will simply store
        // the address of where the null-terminated string is located.
        var value: u8 = undefined;
        var valueP: ?*const u8 = &value;
        const valuePP = @as(*?*const anyopaque, @ptrCast(&valueP));

        const res = c.rd_kafka_header_get_last(
            self.cHandle,
            @ptrCast(name),
            valuePP,
            &size,
        );

        // TODO: handle this error.
        std.log.info("getLast err result => {d}", .{res});

        if (res != 0) {
            // Made up error for now.
            return HeadersRespError.NotFound;
        }

        if (valueP) |ptr| {
            // Convert to a multi-pointer which can safely be sliced with our known bounds.
            const multiPtr = @as([*]const u8, @ptrCast(ptr));
            return multiPtr[0..size];
        }

        return "<value-not-found>";
    }

    // TODO: get_all
};
