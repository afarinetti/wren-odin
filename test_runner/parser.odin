package main

import "core:strings"

TestExpectations :: struct {
	expected_outputs:   [dynamic]string,
	has_runtime_error:  bool,
	runtime_error_msg:  string,
	has_compile_error:  bool,
	compile_error_line: int,
	is_nontest:         bool, // File marked with "// nontest" - skip it
}
parse_expectations :: proc(content: string) -> TestExpectations {
	expectations: TestExpectations

	lines := strings.split(content, "\n")
	defer delete(lines)

	for line in lines {
		// Check for nontest marker
		if strings.has_prefix(strings.trim_space(line), "// nontest") {
			expectations.is_nontest = true
			continue
		}

		// Check for runtime error expectation
		if idx := strings.index(line, "// expect runtime error:"); idx >= 0 {
			msg := strings.trim_space(line[idx + len("// expect runtime error:"):])
			expectations.has_runtime_error = true
			expectations.runtime_error_msg = msg
			continue
		}

		// Check for compile error expectation (e.g., "// expect error line 2")
		if idx := strings.index(line, "// expect error"); idx >= 0 {
			expectations.has_compile_error = true
			// Try to extract line number if present
			rest := line[idx + len("// expect error"):]
			if line_idx := strings.index(rest, "line "); line_idx >= 0 {
				line_num_str := strings.trim_space(rest[line_idx + len("line "):])
				// Parse the line number (simple single-digit for now)
				if len(line_num_str) > 0 {
					expectations.compile_error_line = int(line_num_str[0] - '0')
				}
			}
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
		strings.write_string(&builder, expectations.expected_outputs[i])
		strings.write_string(&builder, "\n")
	}

	// Copy the string before destroying the builder
	temp := strings.to_string(builder)
	result := make([]byte, len(temp))
	for i in 0 ..< len(temp) {
		result[i] = temp[i]
	}
	strings.builder_destroy(&builder)

	return string(result)
}
