## zigrdkafka
*All your codebase are belong to us.*

#

This is `librdkafka`, hijacked and under the command and control of Zig. 
This project requires `Zig 0.13` and is developed currently on `macos-aarch64`.

## Sample Consumer
```zig
const std = @import("std");
const zrdk = @import("zigrdkafka");

pub fn main() !void {
  // Create a fresh consumer configuration.
  const conf = try zrdk.Conf.init();
  
  try conf.set("bootstrap.servers", "localhost:9092");
  try conf.set("group.id", "zig-cli-consumer");

  // Create a new consumer.
  const consumer = try zrdk.Consumer.init(conf);
  defer consumer.deinit();
  defer consumer.close();

  // Define topics of interest to consume.
  const topics = [_][]const u8{"topic.foo", "topic.bar"};
  try consumer.subscribe(&topics);

  while (true) {
    const msg = consumer.poll(100);
    defer msg.deinit();

    if (!msg.isOK()) {
        std.log.warn("either message was empty or it had an error...", .{});
        // Deal with it here.
        continue;
    }

    // Log the message.
    std.log.info("message => {s}\ntopic => {s}\npartition => {d}\noffset => {d}\n", .{
        msg.payloadAsString(),
        msg.topic().name(),
        msg.partition(),
        msg.offset(),
    });

    count += 1;
  }

  std.log.info("Consumer loop ended!", .{});
  std.log.info("Yep, it's really that easy!", .{});
}
```

## Currently Implemented
  - [x] Conf + TopicConf ✅
  - [x] Uuid ✅
  - [x] Topic (in-progress)
  - [x] TopicPartition ✅
  - [x] TopicPartitionList (in-progress)
  - [x] Headers collection (in-progress)
  - [x] Message (in-progress)
  - [x] Consumer (in-progress, but works!)
  - [x] Producer (in-progress, but works!)
  - [ ] Support for librdkafka callbacks (not-started)
  - [ ] Admin client (not-started)
  - [ ] Proper error-handling (in-progress)
  - [ ] etc. as there's a lot more to librdkafka than meets the eye.

## Warning
  * While both the Consumer and Producer work, some things are still hard-coded as this lib is
    currently in discovery phase.
  * ⚠️⚠️ Unstable API ⚠️⚠️: This lib is under heavy active development and subject to heavy changes.
  * The api is far, from complete!
  * Use at your own risk, no warranty expressed or implied.
  * Until the API becomes more stable, I will not be worrying about unit-tests.

## Contributions
  * This API is not intended to have 100% feature parity with the librdkafka C lib.
    * One reason: Zig can provide a nicer experience over C so it should not be a 1 for 1 port.
    * If I don't use a feature, it may not get built out in this API so submit a PR!

## Getting up and running

```sh
# 1. Clone this repo and pull down any submodules.
git clone <this repo>
git submodule update --init --recursive

# 2. Install deps for your operating system.
# For MacOS
brew install openssl curl zlib zstd cyrus-sasl

# 3. Run cmake configuration for librdkafka
# This generates a config.h header file.
cd lib/librdkafka
./configure
cd ../../

# 4. Build all examples projects.
zig build

# 5. Each of the binaries are now located in: zig-out/bin
# Example:
  # a. Prestep: Ensure your Kafka cluster is running. 
  
  # b. Navigate to the freshly built binaries.
  cd zig-out/bin
  # c. Run the producer in one window.
  ./producer
  # d. Run the consumer in another window.
  ./consumer
```

## Design Goals/Considerations

* Provide a 1st class Zig-flavored wrapper around librdkafka
* Consider auto-generation down the road, at least for some things.
* Design choice: As it stands, all Zig structs are value-type and immutable, this may change for all or some structs.
  * The idea is that it makes the API even more user-friendly and all mutable state occurs in the librdkafka layer anyway.
  * Additionally, Zig/llvm often account for this and can often pass const value-types by reference anyway as an optimization.
* All C ugliness should be hidden away
  * Zig namespacing more lightweight and less redundant. Example: `c.rd_kafka_conf_set` => `z.Conf.set` (something like this)
  * Only Zig style strings: `[]const u8` or null-terminated when required: `[:0]const u8`
  * Utilize Zig-based struct methods where it makes sense.
  * No `[*c]` tags anywhere (in-progress), internal is ok.
  * C-based #defines, enums converted to Zig enums (not started)
  * C-based `new` or `create` => `init` for Zig.
  * C-based `_destroy()` => `.deinit()` for Zig.
  * Use of Zig-flavored callbacks so user doesn't need to declare fn with `callconv(.C)`.
  * librdkafka doesn't expose allocators the way Zig prefers, not sure if there is a way around this.

  ### Other implementations
    * [Ruby](https://github.com/deadmanssnitch/kafka/tree/4e61b272e91d9a98f9eb97cf044ab3064e57712a/lib/kafka/ffi) 