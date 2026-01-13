setup() {
    load 'common_setup'
    _common_setup

    # Mock socat to do nothing
    socat() {
        echo "Mock socat started with args: $*"
    }
    export -f socat

    # Mock healthcheck.sh path if needed, but since we are not running real socat it might be fine
}

@test "run.sh sets LD_LIBRARY_PATH and executes binary" {
    # Create a dummy binary and properties file
    TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/bin"
    mkdir -p "$TEST_DIR/data"
    mkdir -p "$TEST_DIR/runtime"
    BINARY_PATH="$TEST_DIR/bin/bedrock_server"
    PROPERTIES_PATH="$TEST_DIR/runtime/server.properties"

    cat <<EOF > "$BINARY_PATH"
#!/bin/sh
echo "Binary executed"
echo "LD_LIBRARY_PATH: \$LD_LIBRARY_PATH"
echo "PWD: \$(pwd)"
EOF
    chmod +x "$BINARY_PATH"
    touch "$PROPERTIES_PATH"

    # Run the script from a different directory
    cd "$TEST_DIR"
    RUNTIME_DIR="$TEST_DIR/runtime" run run.sh --binary "$BINARY_PATH" --data "$TEST_DIR/data"

    assert_success
    assert_output --partial "Binary executed"
    assert_output --partial "LD_LIBRARY_PATH: $TEST_DIR/runtime"
    assert_output --partial "PWD: $TEST_DIR/runtime"
    
    rm -rf "$TEST_DIR"
}

@test "run.sh applies environment overrides to properties" {
    TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/bin"
    mkdir -p "$TEST_DIR/data"
    mkdir -p "$TEST_DIR/runtime"
    BINARY_PATH="$TEST_DIR/bin/bedrock_server"
    PROPERTIES_PATH="$TEST_DIR/runtime/server.properties"

    cat <<EOF > "$BINARY_PATH"
#!/bin/sh
cat "$PROPERTIES_PATH"
EOF
    chmod +x "$BINARY_PATH"
    echo "server-name=DefaultName" > "$PROPERTIES_PATH"

    SERVER_NAME="NewServerName" RUNTIME_DIR="$TEST_DIR/runtime" run run.sh --binary "$BINARY_PATH" --data "$TEST_DIR/data"

    assert_success
    assert_output --partial "server-name=NewServerName"
    
    rm -rf "$TEST_DIR"
}

@test "run.sh fails without required flags" {
    run run.sh
    assert_failure
    assert_output --partial "Usage:"
}

@test "run.sh uses server.properties in data directory" {
    TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/bin"
    mkdir -p "$TEST_DIR/data"
    mkdir -p "$TEST_DIR/runtime"
    BINARY_PATH="$TEST_DIR/bin/bedrock_server"
    PROPERTIES_PATH="$TEST_DIR/runtime/server.properties"

    cat <<EOF > "$BINARY_PATH"
#!/bin/sh
if [ -f server.properties ]; then
    echo "Found server.properties in PWD"
    cat server.properties
else
    echo "server.properties NOT found in PWD"
fi
EOF
    chmod +x "$BINARY_PATH"
    echo "server-name=DataDirProp" > "$PROPERTIES_PATH"

    RUNTIME_DIR="$TEST_DIR/runtime" run run.sh --binary "$BINARY_PATH" --data "$TEST_DIR/data"

    assert_success
    assert_output --partial "Found server.properties in PWD"
    assert_output --partial "server-name=DataDirProp"
    
    rm -rf "$TEST_DIR"
}

@test "run.sh starts healthcheck listener" {
    TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/bin"
    mkdir -p "$TEST_DIR/data"
    mkdir -p "$TEST_DIR/runtime"
    BINARY_PATH="$TEST_DIR/bin/bedrock_server"
    PROPERTIES_PATH="$TEST_DIR/runtime/server.properties"

    cat <<EOF > "$BINARY_PATH"
#!/bin/sh
echo "Binary executed"
EOF
    chmod +x "$BINARY_PATH"
    touch "$PROPERTIES_PATH"

    RUNTIME_DIR="$TEST_DIR/runtime" run run.sh --binary "$BINARY_PATH" --data "$TEST_DIR/data"
    
    # Calculate expected script path (absolute path to src/healthcheck.sh)
    SRC_DIR="$(cd "$BATS_TEST_DIRNAME/../src" && pwd)"
    EXPECTED_PATH="$SRC_DIR/healthcheck.sh"

    assert_success
    assert_output --partial "Mock socat started with args: -T 5 TCP-LISTEN:19134,reuseaddr,fork EXEC:$EXPECTED_PATH"
    
    rm -rf "$TEST_DIR"
}

@test "run.sh bootstraps /data when it is empty" {
    TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/bin"
    mkdir -p "$TEST_DIR/data"
    mkdir -p "$TEST_DIR/runtime"
    
    BINARY_PATH="$TEST_DIR/bin/bedrock_server"
    cat <<EOF > "$BINARY_PATH"
#!/bin/sh
echo "Binary executed"
EOF
    chmod +x "$BINARY_PATH"
    
    # Put some initial data in --data dir
    echo "test-file-content" > "$TEST_DIR/data/initial-file.txt"
    touch "$TEST_DIR/data/server.properties"

    RUNTIME_DIR="$TEST_DIR/runtime" run run.sh --binary "$BINARY_PATH" --data "$TEST_DIR/data"

    assert_success
    assert_output --partial "/data is empty; copying initial data from"
    assert [ -f "$TEST_DIR/runtime/initial-file.txt" ]
    assert [ -f "$TEST_DIR/runtime/server.properties" ]
    
    rm -rf "$TEST_DIR"
}

@test "run.sh does NOT bootstrap /data when it is not empty" {
    TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/bin"
    mkdir -p "$TEST_DIR/data"
    mkdir -p "$TEST_DIR/runtime"
    
    BINARY_PATH="$TEST_DIR/bin/bedrock_server"
    cat <<EOF > "$BINARY_PATH"
#!/bin/sh
echo "Binary executed"
EOF
    chmod +x "$BINARY_PATH"
    
    # Put something in /data (runtime dir)
    touch "$TEST_DIR/runtime/existing-file.txt"
    touch "$TEST_DIR/runtime/server.properties"
    
    # Put different data in --data dir
    touch "$TEST_DIR/data/should-not-be-copied.txt"

    RUNTIME_DIR="$TEST_DIR/runtime" run run.sh --binary "$BINARY_PATH" --data "$TEST_DIR/data"

    assert_success
    assert_output --partial "/data is not empty; skipping data copy"
    assert [ ! -f "$TEST_DIR/runtime/should-not-be-copied.txt" ]
    
    rm -rf "$TEST_DIR"
}
