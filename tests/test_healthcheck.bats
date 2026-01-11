#!/usr/bin/env bats

setup() {
    load 'common_setup'
    _common_setup
}

@test "healthcheck.sh returns 200 when bedrock_server is running" {
    # Mock pgrep to return success
    pgrep() {
        if [[ "$1" == "-x" && "$2" == "bedrock_server" ]]; then
            return 0
        fi
        return 1
    }
    export -f pgrep

    run healthcheck.sh
    assert_success
    assert_output --partial "HTTP/1.1 200 OK"
    assert_output --partial "OK"
}

@test "healthcheck.sh returns 503 when bedrock_server is not running" {
    # Mock pgrep to return failure
    pgrep() {
        return 1
    }
    export -f pgrep

    run healthcheck.sh
    assert_failure
    assert_output --partial "HTTP/1.1 503 Service Unavailable"
    assert_output --partial "BAD"
}
