package main

import "core:fmt"

// Test result tracking
TestResult :: struct {
	file:     string,
	passed:   bool,
	expected: string,
	actual:   string,
	error:    string,
}

main :: proc() {
	fmt.println("=== Wren Test Runner ===")

	// Find all test files
	test_dir := "vendor/wren/test"
	test_files := find_test_files(test_dir)

	fmt.printf("Found %d test files\n", len(test_files))

	// Run tests
	results: [dynamic]TestResult
	for file in test_files {
		result := run_test(file)
		append(&results, result)
	}

	// Report results
	passed := 0
	failed := 0
	for result in results {
		if result.passed {
			passed += 1
			fmt.printf("✓ %s\n", result.file)
		} else {
			failed += 1
			fmt.printf("✗ %s\n", result.file)
			if result.error != "" {
				fmt.printf("  Error: %s\n", result.error)
			}
			if result.expected != result.actual {
				fmt.printf("  Expected: %s\n", result.expected)
				fmt.printf("  Actual:   %s\n", result.actual)
			}
		}
	}

	fmt.println()
	fmt.printf("Total:  %d\n", len(results))
	fmt.printf("Passed: %d\n", passed)
	fmt.printf("Failed: %d\n", failed)
}
