package main

import "fmt"

// ValidFunc is a valid function before the error.
func ValidFunc() {
	fmt.Println("valid")
}

// BrokenFunc has a syntax error (missing closing brace in if).
func BrokenFunc(x int) {
	if x > 0 {
		fmt.Println("positive")
	// missing closing brace for if

	return x
}

// AnotherFunc comes after the broken code.
func AnotherFunc() string {
	return "hello"
}
