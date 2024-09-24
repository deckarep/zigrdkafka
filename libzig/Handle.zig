const c = @import("cdef.zig").cdef;

// Handle is used to pass the root c *rd_kafka_t pointer.
// Never allow users to pass the root pointer directly.
pub const Handle = struct {
    cHandle: *c.rd_kafka_t,

    const Self = @This();

    pub fn Handle(self: Self) *c.rd_kafka_t {
        return self.cHandle;
    }
};
