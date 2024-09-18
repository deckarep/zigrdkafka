const zrdk = @import("zigrdkafka.zig");

// "conf" externs.
pub extern "c" fn rd_kafka_conf_new() *zrdk.Conf;
pub extern "c" fn rd_kafka_conf_get(conf: *const zrdk.Conf, name: [*c]const u8, dest: [*c]u8, dest_size: [*c]usize) zrdk.ConfResult;
pub extern "c" fn rd_kafka_conf_set(conf: *zrdk.Conf, name: [*c]const u8, value: [*c]const u8, errStr: [*c]u8, s: usize) zrdk.ConfResult;
pub extern "c" fn rd_kafka_conf_destroy(conf: *const zrdk.Conf) void;
pub extern "c" fn rd_kafka_conf_dup(conf: *const zrdk.Conf) *zrdk.Conf;
pub extern "c" fn rd_kafka_conf_dump(conf: *const zrdk.Conf, count: [*c]usize) [*c][*c]const u8;
pub extern "c" fn rd_kafka_conf_dump_free(arr: [*c][*c]const u8, cnt: usize) void;
pub extern "c" fn rd_kafka_conf_set_events(conf: *zrdk.Conf, events: c_int) void;
