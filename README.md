## Installing

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

# 4. Build and run the zig project.
zig build run
```