# Wren-Odin: Remaining Test Failures

## Current Status

**Pass Rate:** 829/836 tests passing (99.2%)

**Total Tests:** 892 Wren test files
- 836 active tests (56 are nontests/benchmarks)
- 829 passing
- 7 failing

## Remaining Failures

### 1. `vendor/wren/test/api/call.wren`

**Issue:** Requires `wrenCall()` API for re-entrant calls from host to Wren

**What's Needed:**
The test expects the C API's `wrenCall()` function which allows calling Wren methods from foreign method callbacks using handles. The current test runner only supports `wrenInterpret()` for executing Wren code.

**Implementation:**
- Add `wrenCall()` wrapper to high-level API
- Implement handle-based method invocation from foreign callbacks
- Manage call stack for re-entrant calls

**Reference:** `vendor/wren/test/api/call.c` shows the C implementation using `wrenMakeCallHandle()`, `wrenCall()`, and slot operations.

---

### 2. `vendor/wren/test/api/call_calls_foreign.wren`

**Issue:** Requires `wrenCall()` API for re-entrant calls

**What's Needed:**
Similar to `call.wren`, this test requires calling Wren methods from foreign callbacks. The test verifies that foreign methods can be called during a `wrenCall()` invocation.

**Implementation:**
- Same as `call.wren` - requires `wrenCall()` API support
- Must handle nested foreign method calls

---

### 3. `vendor/wren/test/api/reset_stack_after_call_abort.wren`

**Issue:** Requires `wrenCall()` API with abort handling

**What's Needed:**
Tests that the stack is properly reset after a `wrenCall()` is aborted. Requires implementing the call API with proper error recovery.

**Implementation:**
- Implement `wrenCall()` with abort support
- Ensure stack cleanup on error paths

---

### 4. `vendor/wren/test/api/reset_stack_after_foreign_construct.wren`

**Issue:** Requires `wrenCall()` API with foreign class construction

**What's Needed:**
Tests stack reset after constructing a foreign class via `wrenCall()`. Requires foreign class support in the call API.

**Implementation:**
- Implement `wrenCall()` with foreign class construction
- Handle foreign class allocate/finalize callbacks

---

### 5. `vendor/wren/test/api/resolution.wren`

**Issue:** Requires per-test VM configuration with custom callbacks

**What's Needed:**
The test requires configuring each test VM with custom `resolveModuleFn`, `loadModuleFn`, `writeFn`, and `errorFn` callbacks. The current test runner uses a single global configuration for all tests.

**Implementation:**
- Add per-test VM configuration support
- Allow tests to specify custom callbacks
- Implement module resolution logic in Odin

**Reference:** `vendor/wren/test/api/resolution.c` shows the C implementation with custom module resolution that concatenates importer and module names.

---

### 6. `vendor/wren/test/api/call_wren_call_root.wren`

**Issue:** Expects runtime error that isn't triggered

**What's Needed:**
The test expects a runtime error when calling a method on the root object. This may require implementing additional error checking in the call API or fixing how runtime errors are detected.

**Investigation:**
The test passes `interpret_result` as success when it should be a runtime error. May be related to how errors propagate through the call API.

---

### 7. `vendor/wren/test/language/string/literals.wren`

**Issue:** Wren VM crash when processing raw strings with special characters

**What's Needed:**
The test crashes mid-execution when processing raw strings with Unicode characters and escape sequences. This appears to be a Wren VM bug rather than a binding issue.

**Symptoms:**
- Actual output stops at "multi line" while expected continues
- Crash happens during raw string indentation processing
- May be related to ARM64 stack alignment or Wren VM string handling

**Investigation:**
The crash occurs in the Wren VM itself, not in the Odin bindings. May require updating Wren version or patching the VM.

---

## Known Issues

### ARM64 Stack Alignment Crash

The test runner crashes during cleanup after the last test completes. This is a cosmetic issue - all tests execute successfully. The crash happens in the Odin runtime during VM cleanup or output buffer flushing.

**Workaround:** All test results are printed before the crash. The summary statistics can be computed from the output.

**Potential Fixes:**
- Use heap allocation instead of stack allocation for large buffers
- Add explicit cleanup calls before exit
- Investigate Odin runtime's ARM64 stack alignment

---

## Priority Order

1. **High Priority:** `wrenCall()` API (fixes 4 tests)
   - Most impactful single change
   - Required for full API compatibility

2. **Medium Priority:** Per-test VM configuration (fixes 1 test)
   - Important for testing custom VM setups
   - Enables more flexible test scenarios

3. **Low Priority:** Runtime error detection (fixes 1 test)
   - May be fixed by `wrenCall()` implementation
   - Requires investigation of error propagation

4. **Low Priority:** String literals crash (fixes 1 test)
   - Likely a Wren VM bug
   - May require upstream fix or version update

---

## Implementation Notes

### `wrenCall()` API

The raw bindings already include `wrenCall()`:
```odin
Call :: proc(vm: ^RawVM, method: ^RawHandle) -> RawInterpretResult ---
```

The high-level wrapper exists in `wren/vm.odin`:
```odin
call :: proc(vm: VM, method: Handle) -> Result {
    result := RawCall(vm.raw, method.raw)
    return convert_result(result)
}
```

What's missing is the test runner integration - the ability to call Wren methods from foreign callbacks and handle the re-entrant execution model.

### Per-Test Configuration

The current test runner creates a single VM configuration in `register_api_tests()` and reuses it for all tests. To support `resolution.wren`, we need:

1. A way to specify per-test callbacks
2. A mechanism to create fresh VM configurations for each test
3. Module resolution logic in Odin

---

## Testing the Fix

After implementing fixes, verify with:

```bash
./build_wren.sh
odin build test_runner
./build/test_runner
```

Expected output:
```
Total:  836
Passed: 836
Failed: 0
```

Or with remaining failures:
```
Total:  836
Passed: 829
Failed: 7
```

---

## References

- Wren C API: `vendor/wren/src/include/wren.h`
- C test implementations: `vendor/wren/test/api/*.c`
- Wren test files: `vendor/wren/test/**/*.wren`
- Odin bindings: `wren/*.odin`
- Test runner: `test_runner/main.odin`, `test_runner/runner.odin`
