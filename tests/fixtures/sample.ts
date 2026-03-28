// sample.ts — fixture for TypeScript language config tests

const MAX_SIZE = 100;
let defaultName = "unnamed";

// Top-level function declaration
function greet(name: string): string {
  return "Hello, " + name;
}

// Arrow function assigned to a const (variable_declarator + arrow_function)
const add = (a: number, b: number): number => {
  return a + b;
};

// Type alias
type Point = { x: number; y: number };

// Interface with a property signature
interface Shape {
  color: string;
}

// Class with a method
class Animal {
  name: string;

  constructor(name: string) {
    this.name = name;
  }

  speak(): string {
    return this.name + " makes a sound.";
  }
}

// Function with if and for blocks
function check(x: number): boolean {
  if (x > 0) {
    return true;
  }
  for (let i = 0; i < x; i++) {
    console.log(i);
  }
  return false;
}
