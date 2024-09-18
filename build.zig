const std = @import("std");
const this = @This();

const Program = struct {
    name: []const u8,
    path: []const u8,
    desc: []const u8,
};

// var _zigrdkafka_lib_cache: ?*std.Build.Step.Compile = null;
// fn getZigrdkafka(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.Mode) *std.Build.Step.Compile {
//     if (_zigrdkafka_lib_cache) |lib| return lib else {
//         const zigrdkafka = b.dependency("zigrdkafka", .{
//             .target = target,
//             .optimize = optimize,
//         });

//         const lib = zigrdkafka.artifact("zigrdkafka");

//         // const raygui_dep = b.dependency("raygui", .{
//         //     .target = target,
//         //     .optimize = optimize,
//         // });

//         var gen_step = b.addWriteFiles();
//         lib.step.dependOn(&gen_step.step);

//         // const raygui_c_path = gen_step.add("raygui.c", "#define RAYGUI_IMPLEMENTATION\n#include \"raygui.h\"\n");
//         // lib.addCSourceFile(.{
//         //     .file = raygui_c_path,
//         //     .flags = &[_][]const u8{
//         //         "-std=gnu99",
//         //         "-D_GNU_SOURCE",
//         //         "-DGL_SILENCE_DEPRECATION=199309L",
//         //         "-fno-sanitize=undefined", // https://github.com/raysan5/raylib/issues/3674
//         //     },
//         // });
//         //lib.addIncludePath(raylib.path("src"));
//         //lib.addIncludePath(raygui_dep.path("src"));

//         //lib.installHeader(raygui_dep.path("src/raygui.h"), "raygui.h");

//         b.installArtifact(lib);
//         _zigrdkafka_lib_cache = lib;
//         return lib;
//     }
// }

fn getModule(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.Mode) *std.Build.Module {
    if (b.modules.contains("zigrdkafka")) {
        return b.modules.get("zigrdkafka").?;
    }
    return b.addModule("zigrdkafka", .{
        .root_source_file = b.path("libzig/zigrdkafka.zig"),
        .target = target,
        .optimize = optimize,
    });
}

fn link(
    _: *std.Build,
    exe: *std.Build.Step.Compile,
    _: std.Build.ResolvedTarget,
    _: std.builtin.Mode,
) void {
    const target_os = exe.rootModuleTarget().os.tag;
    switch (target_os) {
        .macos => {
            exe.linkSystemLibrary("c");

            // openssl              => brew install openssl
            // zlib                 => brew install zlib
            // curl                 => brew install curl
            // libsasl2/cyrus-sasl  => brew install cyrus-sasl
            // zstd                 => brew install zstd

            const macos_arm64_homebrew_path = "/opt/homebrew/opt/";

            exe.addIncludePath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "openssl@3/include" });
            exe.addLibraryPath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "openssl@3/lib" });
            exe.linkSystemLibrary("crypto");
            exe.linkSystemLibrary("ssl");

            exe.addIncludePath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "curl/include" });
            exe.addLibraryPath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "curl/lib" });
            exe.linkSystemLibrary("curl");

            exe.addIncludePath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "zlib/include" });
            exe.addLibraryPath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "zlib/lib" });
            exe.linkSystemLibrary("zlib");

            exe.addIncludePath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "zstd/include" });
            exe.addLibraryPath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "zstd/lib" });
            exe.linkSystemLibrary("zstd");

            exe.addIncludePath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "cyrus-sasl/include" });
            exe.addLibraryPath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "cyrus-sasl/lib" });
            exe.linkSystemLibrary("sasl2");

            exe.linkLibC();
        },
        else => {
            // Other builds currently unsupported. Please submit a patch!
            unreachable;
        },
    }

    //exe.linkLibrary(lib);
}

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

    const examples = [_]Program{
        .{
            .name = "producer",
            .path = "examples/producer/main.zig",
            .desc = "Produces a stream of messages into kafka",
        },
        .{
            .name = "consumer",
            .path = "examples/consumer/main.zig",
            .desc = "Consumes a stream of messages from kafka",
        },
    };

    const zigrdkafka = this.getModule(b, target, optimize);

    for (examples) |ex| {
        const exe = b.addExecutable(.{
            .name = ex.name,
            .root_source_file = b.path(ex.path),
            .optimize = optimize,
            .target = target,
        });

        link(b, exe, target, optimize);
        exe.root_module.addImport("zigrdkafka", zigrdkafka);

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
    }
}
