package main

import (
	"fmt"
	"strconv"
)

// Constants at package level
const MaxRetries = 3

// Package-level variable
var DefaultName = "world"

// MyStruct is a sample struct with methods.
type MyStruct struct {
	Name  string
	Count int
}

func converStrToInt(a string) (int, error) {
	return strconv.Atoi(a)
}

// NewMyStruct creates a new MyStruct.
func NewMyStruct(name string) *MyStruct {
	return &MyStruct{
		Name:  name,
		Count: 0,
	}
}

// HandleRequest processes a request with nested control flow.
func (m *MyStruct) HandleRequest(action string) error {
	if action == "" {
		return fmt.Errorf("empty action")
	}

	for i := 0; i < MaxRetries; i++ {
		if action == "greet" {
			fmt.Printf("Hello, %s (attempt %d)\n", m.Name, i)
			return nil
		}

		if action == "count" {
			m.Count++
			if m.Count > 10 {
				return fmt.Errorf("count overflow")
			}
		}
	}

	return fmt.Errorf("unknown action: %s", action)
}

// ProcessItems takes a slice and applies a function to each item.
func ProcessItems(items []string, fn func(string) string) []string {
	result := make([]string, 0, len(items))

	for _, item := range items {
		transformed := fn(item)
		result = append(result, transformed)
	}

	return result
}

// RunWithCallback demonstrates func literals.
func RunWithCallback() {
	callback := func(msg string) {
		fmt.Println(msg)
	}

	ProcessItems([]string{"a", "b"}, func(s string) string {
		callback(s)
		return s + "!"
	})
}

func main() {
	s := NewMyStruct(DefaultName)
	err := s.HandleRequest("greet")
	if err != nil {
		fmt.Println("Error:", err)
	}

	RunWithCallback()
}
