Highly in-development

## Test Framework

- **Qt Test (QTest)**: Native Qt testing framework
- **CMake/CTest**: Build system integration for running tests

## Running Tests

```bash
just test

# Run tests directly for more verbose output
./build/bin/test_system_update

# Run specific tests
./build/bin/test_system_update testPropertyGettersSetters
```

### What is tested
- displaying text in the integrated terminal
- Utils
- AppState 
- SystemUpdate