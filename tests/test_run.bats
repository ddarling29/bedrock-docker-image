setup() {
    load 'common_setup'
    _common_setup
}

@test "run.sh sets LD_LIBRARY_PATH and executes binary" {
    # Create a dummy binary and properties file
    TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/bin"
    mkdir -p "$TEST_DIR/data"
    BINARY_PATH="$TEST_DIR/bin/bedrock_server"
    PROPERTIES_PATH="$TEST_DIR/data/server.properties"

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
    run run.sh --binary "$BINARY_PATH" --data "$TEST_DIR/data"

    assert_success
    assert_output --partial "Binary executed"
    assert_output --partial "LD_LIBRARY_PATH: $TEST_DIR/data"
    # Updated expectation: PWD should be $TEST_DIR/data
    assert_output --partial "PWD: $TEST_DIR/data"
    
    rm -rf "$TEST_DIR"
}

@test "run.sh applies environment overrides to properties" {
    TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/bin"
    mkdir -p "$TEST_DIR/data"
    BINARY_PATH="$TEST_DIR/bin/bedrock_server"
    PROPERTIES_PATH="$TEST_DIR/data/server.properties"

    cat <<EOF > "$BINARY_PATH"
#!/bin/sh
cat "$PROPERTIES_PATH"
EOF
    chmod +x "$BINARY_PATH"
    echo "server-name=DefaultName" > "$PROPERTIES_PATH"

    SERVER_NAME="NewServerName" run run.sh --binary "$BINARY_PATH" --data "$TEST_DIR/data"

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
    BINARY_PATH="$TEST_DIR/bin/bedrock_server"
    PROPERTIES_PATH="$TEST_DIR/data/server.properties"

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

    run run.sh --binary "$BINARY_PATH" --data "$TEST_DIR/data"

    assert_success
    assert_output --partial "Found server.properties in PWD"
    assert_output --partial "server-name=DataDirProp"
    
    # Also verify it's NOT in the binary directory
    if [ -f "$TEST_DIR/bin/server.properties" ]; then
        echo "Error: server.properties found in binary directory"
        false
    fi
    
    rm -rf "$TEST_DIR"
}
