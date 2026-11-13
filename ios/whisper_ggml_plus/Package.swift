// swift-tools-version: 5.9
import PackageDescription

let definitions: [CSetting] = [
    .define("WHISPER_USE_COREML"),
    .define("WHISPER_COREML_ALLOW_FALLBACK"),
    .define("GGML_USE_METAL", to: "1"),
    .define("GGML_USE_CPU"),
    .define("WHISPER_VERSION", to: "\"1.8.3\""),
    .define("GGML_VERSION", to: "\"0.9.5\""),
    .define("GGML_COMMIT", to: "\"unknown\"")
]
let headers = [
    "Classes/whisper", "Classes/whisper/include", "Classes/whisper/src",
    "Classes/whisper/src/coreml", "Classes/whisper/ggml/include",
    "Classes/whisper/ggml/src", "Classes/whisper/ggml/src/ggml-cpu"
]

let package = Package(
    name: "whisper_ggml_plus",
    platforms: [.iOS("12.0")],
    // Dart looks up request/free_string through DynamicLibrary.process(). A
    // dynamic product keeps these exports available without an ObjC registrar.
    products: [.library(name: "whisper-ggml-plus", type: .dynamic, targets: ["whisper_ggml_plus"])],
    targets: [
        .target(
            name: "WhisperCoreML",
            path: "Classes/whisper/src/coreml",
            publicHeadersPath: "include",
            cSettings: [.unsafeFlags(["-fobjc-arc"])],
            linkerSettings: [.linkedFramework("CoreML"), .linkedFramework("Foundation")]
        ),
        .target(
            name: "whisper_ggml_plus",
            dependencies: ["WhisperCoreML"],
            path: ".",
            exclude: [
                "Classes/whisper/src/coreml",
                "Classes/whisper/ggml/src/ggml-metal/ggml-metal.metal",
                "Resources/default.metallib"
            ],
            sources: [
                "Classes/whisper_flutter_plus.cpp", "Classes/vad_helper.mm",
                "Classes/whisper/src/whisper.cpp",
                "Classes/whisper/ggml/src/ggml.c", "Classes/whisper/ggml/src/ggml.cpp",
                "Classes/whisper/ggml/src/ggml-alloc.c", "Classes/whisper/ggml/src/ggml-backend.cpp",
                "Classes/whisper/ggml/src/ggml-backend-reg.cpp", "Classes/whisper/ggml/src/ggml-opt.cpp",
                "Classes/whisper/ggml/src/ggml-quants.c", "Classes/whisper/ggml/src/ggml-threading.cpp",
                "Classes/whisper/ggml/src/gguf.cpp",
                "Classes/whisper/ggml/src/ggml-cpu/ggml-cpu.c", "Classes/whisper/ggml/src/ggml-cpu/ggml-cpu.cpp",
                "Classes/whisper/ggml/src/ggml-cpu/binary-ops.cpp", "Classes/whisper/ggml/src/ggml-cpu/unary-ops.cpp",
                "Classes/whisper/ggml/src/ggml-cpu/ops.cpp", "Classes/whisper/ggml/src/ggml-cpu/vec.cpp",
                "Classes/whisper/ggml/src/ggml-cpu/quants.c", "Classes/whisper/ggml/src/ggml-cpu/repack.cpp",
                "Classes/whisper/ggml/src/ggml-cpu/traits.cpp", "Classes/whisper/ggml/src/ggml-cpu/hbm.cpp",
                "Classes/whisper/ggml/src/ggml-cpu/arch/arm", "Classes/whisper/ggml/src/ggml-cpu/arch/x86",
                "Classes/whisper/ggml/src/ggml-cpu/amx",
                "Classes/whisper/ggml/src/ggml-metal/ggml-metal.cpp",
                "Classes/whisper/ggml/src/ggml-metal/ggml-metal-common.cpp",
                "Classes/whisper/ggml/src/ggml-metal/ggml-metal-context.m",
                "Classes/whisper/ggml/src/ggml-metal/ggml-metal-device.cpp",
                "Classes/whisper/ggml/src/ggml-metal/ggml-metal-device.m",
                "Classes/whisper/ggml/src/ggml-metal/ggml-metal-ops.cpp"
            ],
            // Compile source at runtime for the actual Metal device. The legacy
            // CocoaPods metallib was built for iphoneos, not the simulator.
            resources: [.copy("Resources/ggml-metal.metal")],
            publicHeadersPath: "include",
            cSettings: definitions + headers.map { .headerSearchPath($0) } + [.unsafeFlags(["-fno-objc-arc"])],
            cxxSettings: headers.map { .headerSearchPath($0) } + [
                .define("WHISPER_USE_COREML"), .define("WHISPER_COREML_ALLOW_FALLBACK"),
                .define("GGML_USE_METAL", to: "1"), .define("GGML_USE_CPU"),
                .define("WHISPER_VERSION", to: "\"1.8.3\""),
                .define("GGML_VERSION", to: "\"0.9.5\""),
                .define("GGML_COMMIT", to: "\"unknown\"")
            ],
            linkerSettings: [
                .linkedFramework("CoreML"), .linkedFramework("Metal"),
                .linkedFramework("Foundation"), .linkedFramework("Accelerate")
            ]
        )
    ],
    cxxLanguageStandard: .cxx17
)
