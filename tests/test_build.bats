setup() {
    load 'common_setup'
    _common_setup
    
    # Create a temporary directory for tests
    TEST_TEMP_DIR="$(mktemp -d)"

    # Mock directory
    MOCK_DIR="$TEST_TEMP_DIR/mocks"
    mkdir -p "$MOCK_DIR"
    PATH="$MOCK_DIR:$PATH"

    # Ensure mocks are executable
    touch "$MOCK_DIR/aws" "$MOCK_DIR/unzip"
    chmod +x "$MOCK_DIR/aws" "$MOCK_DIR/unzip"

    # Export MOCK_DIR so mocks can use it if needed
    export MOCK_DIR
    export TEST_TEMP_DIR
}

teardown() {
    # Remove temporary directory and mocks
    rm -rf "$TEST_TEMP_DIR"
}

@test "main: fails with insufficient arguments" {
    run build.sh
    assert_failure
    assert_output --partial "Usage:"
    assert_output --partial "<zip_path> <binary_out_dir> <data_out_dir>"
}

@test "extract_file: success" {
    source build.sh
    
    # Setup mock unzip to succeed
    echo '#!/bin/bash' > "$MOCK_DIR/unzip"
    echo 'exit 0' >> "$MOCK_DIR/unzip"
    
    touch "$TEST_TEMP_DIR/dummy.zip"
    
    run extract_file "$TEST_TEMP_DIR/dummy.zip" "$TEST_TEMP_DIR/dest"
    assert_success
    assert_output --partial "Extraction successful."
    [ ! -f "$TEST_TEMP_DIR/dummy.zip" ]
}

@test "extract_file: failure" {
    source build.sh
    
    # Setup mock unzip to fail
    echo '#!/bin/bash' > "$MOCK_DIR/unzip"
    echo 'exit 1' >> "$MOCK_DIR/unzip"
    
    touch "$TEST_TEMP_DIR/dummy.zip"
    
    run extract_file "$TEST_TEMP_DIR/dummy.zip" "$TEST_TEMP_DIR/dest"
    assert_failure
    assert_output --partial "Extraction failed."
    # Zip should NOT be removed on failure
    [ -f "$TEST_TEMP_DIR/dummy.zip" ]
}

@test "main: end-to-end success" {
    # Mock unzip: unzip -q <zip_path> -d <dest_dir>
    # So $1=-q, $2=<zip_path>, $3=-d, $4=<dest_dir>
    echo '#!/bin/bash' > "$MOCK_DIR/unzip"
    echo 'mkdir -p "$4"' >> "$MOCK_DIR/unzip"
    echo 'touch "$4/bedrock_server"' >> "$MOCK_DIR/unzip"
    echo 'exit 0' >> "$MOCK_DIR/unzip"

    touch "$TEST_TEMP_DIR/test.zip"

    run build.sh "$TEST_TEMP_DIR/test.zip" "$TEST_TEMP_DIR/bin" "$TEST_TEMP_DIR/data"
    assert_success
    assert_output --partial "Extraction successful."
    [ -f "$TEST_TEMP_DIR/bin/bedrock_server" ]
    [ -x "$TEST_TEMP_DIR/bin/bedrock_server" ]
}