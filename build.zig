const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "kafkazig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkSystemLibrary("c");

    // OpenSSL => brew install openssl
    exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/opt/openssl@3/include" });
    exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/opt/openssl@3/lib" });
    exe.linkSystemLibrary("crypto");
    exe.linkSystemLibrary("ssl");

    // Curl => brew install curl
    exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/opt/curl/include" });
    exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/opt/curl/lib" });
    exe.linkSystemLibrary("curl");

    // Zlib => brew install zlib
    exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/opt/zlib/include" });
    exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/opt/zlib/lib" });
    exe.linkSystemLibrary("zlib");

    // Zstd => brew install zstd
    exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/opt/zstd/include" });
    exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/opt/zstd/lib" });
    exe.linkSystemLibrary("zstd");

    // cyrus-sasl/libsasl2 => brew install cyrus-sasl
    exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/opt/cyrus-sasl/include" });
    exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/opt/cyrus-sasl/lib" });
    exe.linkSystemLibrary("sasl2");

    exe.linkLibC();

    // cflags are defined here: https://github.com/confluentinc/librdkafka/blob/master/dev-conf.sh
    const cflags = &[_][]const u8{
        "-std=c99",
    };

    exe.addIncludePath(b.path("lib/librdkafka/"));
    exe.addIncludePath(b.path("lib/librdkafka/src"));
    exe.addIncludePath(b.path("lib/librdkafka/src/nanopb"));
    exe.addIncludePath(b.path("lib/librdkafka/src/opentelemetry"));
    exe.addCSourceFiles(.{
        .files = &.{
            "lib/librdkafka/src/nanopb/pb_common.c",
            "lib/librdkafka/src/nanopb/pb_decode.c",
            "lib/librdkafka/src/nanopb/pb_encode.c",
            "lib/librdkafka/src/opentelemetry/common.pb.c",
            "lib/librdkafka/src/opentelemetry/metrics.pb.c",
            "lib/librdkafka/src/opentelemetry/resource.pb.c",
            "lib/librdkafka/src/lz4frame.c",
            "lib/librdkafka/src/lz4.c",
            "lib/librdkafka/src/lz4hc.c",
            "lib/librdkafka/src/snappy.c",
            "lib/librdkafka/src/cJSON.c",
            "lib/librdkafka/src/rdmurmur2.c",
            "lib/librdkafka/src/crc32c.c",
            "lib/librdkafka/src/rdstring.c",
            "lib/librdkafka/src/rdregex.c",
            "lib/librdkafka/src/rdrand.c",
            "lib/librdkafka/src/rdxxhash.c",
            "lib/librdkafka/src/rdavl.c",
            "lib/librdkafka/src/rdvarint.c",
            "lib/librdkafka/src/rddl.c",
            "lib/librdkafka/src/rdbase64.c",
            "lib/librdkafka/src/rdaddr.c",
            "lib/librdkafka/src/rdfnv1a.c",
            "lib/librdkafka/src/rdhttp.c",
            "lib/librdkafka/src/rdunittest.c",
            "lib/librdkafka/src/rdgz.c",
            "lib/librdkafka/src/rdcrc32.c",
            "lib/librdkafka/src/rdbuf.c",
            "lib/librdkafka/src/rdlog.c",
            "lib/librdkafka/src/rdports.c",
            "lib/librdkafka/src/rdmap.c",
            "lib/librdkafka/src/rdlist.c",
            "lib/librdkafka/src/rdhdrhistogram.c",
            "lib/librdkafka/src/rdkafka.c",
            "lib/librdkafka/src/rdkafka_admin.c",
            "lib/librdkafka/src/rdkafka_assignment.c",
            "lib/librdkafka/src/rdkafka_assignor.c",
            "lib/librdkafka/src/rdkafka_aux.c",
            "lib/librdkafka/src/rdkafka_background.c",
            "lib/librdkafka/src/rdkafka_broker.c",
            "lib/librdkafka/src/rdkafka_buf.c",
            "lib/librdkafka/src/rdkafka_cert.c",
            "lib/librdkafka/src/rdkafka_cgrp.c",
            "lib/librdkafka/src/rdkafka_conf.c",
            "lib/librdkafka/src/rdkafka_coord.c",
            "lib/librdkafka/src/rdkafka_error.c",
            "lib/librdkafka/src/rdkafka_event.c",
            "lib/librdkafka/src/rdkafka_feature.c",
            "lib/librdkafka/src/rdkafka_fetcher.c",
            "lib/librdkafka/src/rdkafka_header.c",
            "lib/librdkafka/src/rdkafka_idempotence.c",
            "lib/librdkafka/src/rdkafka_interceptor.c",
            "lib/librdkafka/src/rdkafka_lz4.c",
            "lib/librdkafka/src/rdkafka_metadata.c",
            "lib/librdkafka/src/rdkafka_metadata_cache.c",
            "lib/librdkafka/src/rdkafka_mock.c",
            "lib/librdkafka/src/rdkafka_mock_cgrp.c",
            "lib/librdkafka/src/rdkafka_mock_handlers.c",
            "lib/librdkafka/src/rdkafka_msg.c",
            "lib/librdkafka/src/rdkafka_msgset_reader.c",
            "lib/librdkafka/src/rdkafka_msgset_writer.c",
            "lib/librdkafka/src/rdkafka_offset.c",
            "lib/librdkafka/src/rdkafka_op.c",
            "lib/librdkafka/src/rdkafka_partition.c",
            "lib/librdkafka/src/rdkafka_pattern.c",
            "lib/librdkafka/src/rdkafka_plugin.c",
            "lib/librdkafka/src/rdkafka_queue.c",
            "lib/librdkafka/src/rdkafka_range_assignor.c",
            "lib/librdkafka/src/rdkafka_request.c",
            "lib/librdkafka/src/rdkafka_roundrobin_assignor.c",
            "lib/librdkafka/src/rdkafka_sasl.c",
            "lib/librdkafka/src/rdkafka_sasl_cyrus.c",
            "lib/librdkafka/src/rdkafka_sasl_oauthbearer.c",
            "lib/librdkafka/src/rdkafka_sasl_oauthbearer_oidc.c",
            "lib/librdkafka/src/rdkafka_sasl_plain.c",
            "lib/librdkafka/src/rdkafka_sasl_scram.c",
            // Windows only obvi. - include this when building on Windows.
            //"lib/librdkafka/src/rdkafka_sasl_win32.c",
            "lib/librdkafka/src/rdkafka_ssl.c",
            "lib/librdkafka/src/rdkafka_sticky_assignor.c",
            "lib/librdkafka/src/rdkafka_subscription.c",
            "lib/librdkafka/src/rdkafka_telemetry.c",
            "lib/librdkafka/src/rdkafka_telemetry_decode.c",
            "lib/librdkafka/src/rdkafka_telemetry_encode.c",
            "lib/librdkafka/src/rdkafka_timer.c",
            "lib/librdkafka/src/rdkafka_topic.c",
            "lib/librdkafka/src/rdkafka_transport.c",
            "lib/librdkafka/src/rdkafka_txnmgr.c",
            "lib/librdkafka/src/rdkafka_zstd.c",
            "lib/librdkafka/src/tinycthread.c",
            "lib/librdkafka/src/tinycthread_extra.c",
        },
        .flags = cflags,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
