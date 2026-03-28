# BUILD file for a Go auth service

SERVICE_NAME = "auth-service"
VERSION = "1.0.0"

go_binary(
    name = "server",
    srcs = ["main.go"],
    deps = [
        "//lib/config",
        "//lib/auth",
    ],
)

go_library(
    name = "auth_lib",
    srcs = glob(["*.go"], exclude = ["main.go"]),
    deps = [
        "//third_party/go:jwt",
    ],
)

go_test(
    name = "auth_test",
    srcs = ["auth_test.go"],
    deps = [":auth_lib"],
)

def make_targets(name, srcs):
    go_binary(
        name = name,
        srcs = srcs,
    )
    go_test(
        name = name + "_test",
        srcs = srcs,
    )
