## zigrdkafka
*All your codebase are belong to us.*
This is `librdkafka`, hijacked and under the command and control of Zig. 
This project requires `Zig 0.13` and is developed currently on `macos-aarch64`.

## Currently Implemented
  - [x] Conf ✅
  - [x] TopicConf ✅
  - [x] Uuid ✅
  - [x] Topic (in-progress)
  - [x] Headers collection (in-progress)
  - [x] Consumer (in-progress)

## Warning
  * ⚠️⚠️ Unstable API ⚠️⚠️: This lib is under heavy active development and subject to heavy changes.
  * The api is far, far, from complete!
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

## Dev notes

1. Ideally I will build a 1st class Zig-flavored wrapper
2. Big question: attempt auto-generation???
3. All C ugliness would be hidden away
  * Zig namespacing more lightweight. Example: `c.rd_kafka_conf_set` => `z.Conf.set` (something like this)
  * Only Zig style strings: `[]const u8` or null-terminated when required: `[:0]const u8`
  * Zig-based structs would may have "methods" where it makes sense
  * No `[*c]` tags anywhere (in-progress)
  * C-based #defines, enums converted to Zig enums
  * C-based `_destroy()` => `.deinit()`
  * Use of Zig-flavored callbacks so user doesn't need to declare fn with `callconv(.C)`.
  * librdkafka doesn't expose allocators the way Zig prefers, not sure if there is a way around this.