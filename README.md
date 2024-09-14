## zigrdkafka
This is librdkafka under the command and control of Zig. This project
requires Zig 0.13 and is developed on MacOS aarch64.

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
# Example: runs the producer.
cd zig-out/bin
./producer
```