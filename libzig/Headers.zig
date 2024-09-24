const std = @import("std");
const c = @import("cdef.zig").cdef;

pub const HeadersRespError = error{
    Instantiation,
    // TODO: other types of errors that this can return ultimately.
};

pub const Headers = struct {
    cHandle: *c.rd_kafka_headers_t = undefined,

    const Self = @This();

    pub fn new() HeadersRespError!Headers {
        return newWithCapacity(0);
    }

    pub fn newWithCapacity(initialCount: usize) HeadersRespError!Headers {
        const hdrs = c.rd_kafka_headers_new(initialCount);
        if (hdrs) |h| {
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

    // TODO: get_last
    // TODO: get
    // TODO: get_all
};
