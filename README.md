## zigrdkafka
This is librdkafka under the command and control of Zig. This project
requires Zig 0.13 and is developed on MacOS aarch64.

Note: this lib is under heavy active development and subject to lots of changes.
It is highly unstable at the moment. ⚠️⚠️ You have been warned ⚠️⚠️ !

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
  * Only Zig style strings: `[]const u8`
  * Matching Zig `extern` structs passed around, no C structs insight.
  * Zig-based structs would may have "methods" where it makes sense
  * No `[*c]` tags anywhere
  * C-based #defines, enums converted to Zig enums
  * C-based `_destroy()` => `.deinit()`
  * Use of Zig-flavored callbacks so user doesn't need to declare fn with `callconv(.C)`. Is this doable?