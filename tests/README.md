# Test Suite for File-Merge-and-Rename

This directory contains the test suite for the File Merge and Rename utility.

## Structure

```
tests/
├── README.md                           # This file
├── fixtures/                           # Test fixture files
│   ├── Create-TestFixtures.ps1        # Script to generate test files
│   ├── valid_video.mp4                # Generated test files
│   ├── valid_audio.m4a
│   └── ... (other test files)
└── (test files are in parent directory)
```

## Prerequisites

### Required Software

1. **PowerShell**: Version 5.1 or PowerShell Core 7+ (cross-platform)
   - Windows: Built-in (PowerShell 5.1)
   - Linux/macOS: Install PowerShell Core from https://github.com/PowerShell/PowerShell

2. **Pester**: Testing framework for PowerShell
   ```powershell
   # Install Pester v5.x
   Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
   ```

3. **FFmpeg** (for integration tests only):
   - Download from: https://ffmpeg.org/download.html
   - Ensure `ffmpeg` is in your PATH

### Optional
- **FFmpeg** for creating real media test fixtures (see fixtures/Create-TestFixtures.ps1)

## Running Tests

### Quick Start

```powershell
# Navigate to the repository root
cd /path/to/File-Merge-and-Rename

# Run all tests
Invoke-Pester -Path ./File_Renamer.Tests.ps1
```

### Detailed Test Runs

```powershell
# Run with detailed output
Invoke-Pester -Path ./File_Renamer.Tests.ps1 -Output Detailed

# Run specific test suite
Invoke-Pester -Path ./File_Renamer.Tests.ps1 -FullNameFilter "*Parameter Validation*"

# Run with code coverage
Invoke-Pester -Path ./File_Renamer.Tests.ps1 -CodeCoverage ./File_Renamer.ps1

# Generate test results for CI/CD
Invoke-Pester -Path ./File_Renamer.Tests.ps1 -OutputFormat NUnitXml -OutputFile TestResults.xml
```

### Generate Test Fixtures

Before running integration tests, create test fixture files:

```powershell
cd tests/fixtures
./Create-TestFixtures.ps1
```

## Test Categories

The test suite is organized into the following categories:

### 1. Parameter Validation Tests
- Missing required parameters
- Empty string parameters
- Special characters in filenames
- Located in: `Describe "File_Renamer.ps1 - Parameter Validation"`

### 2. FFmpeg Availability Tests
- FFmpeg presence in PATH
- FFmpeg version compatibility
- Located in: `Describe "File_Renamer.ps1 - FFmpeg Availability"`

### 3. Input File Validation Tests
- Non-existent files
- Empty files (0 bytes)
- Locked/inaccessible files
- Located in: `Describe "File_Renamer.ps1 - Input File Validation"`

### 4. Output Directory Tests
- Non-existent directories (auto-creation)
- Permissions issues
- Located in: `Describe "File_Renamer.ps1 - Output Directory Validation"`

### 5. Temporary File Handling Tests
- Naming conflict avoidance
- Cleanup on success
- Cleanup on failure
- KeepTemporaryFiles flag behavior
- Located in: `Describe "File_Renamer.ps1 - Temporary File Handling"`

### 6. FFmpeg Integration Tests
- FFmpeg process execution
- Error handling for merge failures
- Empty output detection
- Located in: `Describe "File_Renamer.ps1 - FFmpeg Integration"`

### 7. Edge Case Tests
- Large files (>4GB)
- UNC paths
- Existing output files
- Special characters in paths
- Located in: `Describe "File_Renamer.ps1 - Edge Cases"`

### 8. Success Scenario Tests
- Happy path with mocked FFmpeg
- End-to-end integration (requires real FFmpeg)
- Located in: `Describe "File_Renamer.ps1 - Success Scenarios"`

## Test Coverage Goals

| Category | Current Coverage | Target |
|----------|-----------------|--------|
| Parameter Validation | ~90% | 100% |
| File Operations | ~75% | 95% |
| FFmpeg Integration | ~60% | 90% |
| Error Handling | ~80% | 95% |
| Edge Cases | ~50% | 80% |
| Overall | ~70% | 90% |

## Writing New Tests

### Test Template

```powershell
Describe "Feature Name" {
    Context "When condition occurs" {
        BeforeAll {
            # Setup test environment
            $testDir = New-TestOutputDirectory
        }

        AfterAll {
            # Cleanup
            Remove-Item -Path $testDir -Recurse -Force
        }

        It "Should behave in expected way" {
            # Arrange
            $input = "test value"

            # Act
            $result = & $scriptPath -Parameter $input

            # Assert
            $result | Should -Be "expected value"
        }
    }
}
```

### Best Practices

1. **Isolation**: Each test should be independent and not rely on other tests
2. **Cleanup**: Always clean up created files/directories in AfterAll/AfterEach
3. **Mocking**: Use mocks for external dependencies (FFmpeg) when possible
4. **Assertions**: Use descriptive Should assertions with clear messages
5. **Naming**: Use descriptive test names: "Should [expected behavior] when [condition]"

## Continuous Integration

### GitHub Actions Example

```yaml
name: PowerShell Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [windows-latest, ubuntu-latest, macos-latest]
    steps:
      - uses: actions/checkout@v3
      - name: Install Pester
        shell: pwsh
        run: Install-Module -Name Pester -Force -SkipPublisherCheck
      - name: Run Tests
        shell: pwsh
        run: Invoke-Pester -Path ./File_Renamer.Tests.ps1 -Output Detailed
```

## Troubleshooting

### Common Issues

**Issue**: `Invoke-Pester: The term 'Invoke-Pester' is not recognized`
**Solution**: Install Pester: `Install-Module -Name Pester -Force`

**Issue**: Tests fail with "Access Denied" errors
**Solution**: Run PowerShell as Administrator or use -Scope CurrentUser when installing modules

**Issue**: FFmpeg tests always fail
**Solution**: These tests may be placeholders. Install FFmpeg and update tests with real integration code.

**Issue**: "Cannot find path" errors on Linux/macOS
**Solution**: Ensure you're using PowerShell Core (pwsh) not Windows PowerShell

## Contributing

When adding new features to File_Renamer.ps1:

1. Write tests first (TDD approach recommended)
2. Ensure all existing tests pass
3. Add new test cases for new functionality
4. Maintain minimum 80% code coverage
5. Update this README if adding new test categories

## Resources

- **Pester Documentation**: https://pester.dev/
- **PowerShell Testing Best Practices**: https://pester.dev/docs/usage/test-syntax
- **FFmpeg Documentation**: https://ffmpeg.org/documentation.html

## License

Tests are part of the File-Merge-and-Rename project and are licensed under GNU GPL v3.0.
