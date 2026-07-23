package main

import "core:strings"

TestExpectations :: struct {
	expected_outputs:  [dynamic]string,
	has_runtime_error: bool,
	runtime_error_msg: string,
}

parse_expectations :: proc(content: string) -> TestExpectations {
	expectations: TestExpectations

	lines := strings.split(content, "\n")
	defer delete(lines)

	for line in lines {
		// Check for runtime error expectation
		if idx := strings.index(line, "// expect runtime error:"); idx >= 0 {
			msg := strings.trim_space(line[idx + len("// expect runtime error:"):])
			expectations.has_runtime_error = true
			expectations.runtime_error_msg = msg
			continue
		}

		// Check for output expectation
		if idx := strings.index(line, "// expect:"); idx >= 0 {
			expected := strings.trim_space(line[idx + len("// expect:"):])
			append(&expectations.expected_outputs, expected)
		}
	}

	return expectations
}

build_expected_output :: proc(expectations: TestExpectations) -> string {
	if len(expectations.expected_outputs) == 0 {
		return ""
	}

	builder: strings.Builder
	strings.builder_init(&builder)

	for i in 0 ..< len(expectations.expected_outputs) {
		if i > 0 {
			strings.write_string(&builder, "\n")
		}
		strings.write_string(&builder, expectations.expected_outputs[i])
	}

	result := strings.to_string(builder)
	strings.builder_destroy(&builder)

	return result
}
