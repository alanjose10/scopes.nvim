"""Module for processing animals."""

import os
from pathlib import Path
import sys as system

MAX_SIZE = 100
DEFAULT_NAME = "unnamed"


class Animal:
    """Base animal class."""

    def __init__(self, name, species):
        self.name = name
        self.species = species

    def speak(self):
        pass

    def describe(self):
        if self.name:
            return f"{self.name} is a {self.species}"
        return "unknown"


class Dog(Animal):
    """Dog subclass."""

    def speak(self):
        return "woof"

    def fetch(self, item):
        for i in range(3):
            print(f"fetching {item}")
        return item


def process_animals(animals):
    """Process a list of animals."""
    results = []
    for animal in animals:
        with open("log.txt", "w") as f:
            f.write(animal.describe())
        results.append(animal)
    return results


def main():
    dog = Dog("Rex", "dog")
    cat = Animal("Whiskers", "cat")
    process_animals([dog, cat])


if __name__ == "__main__":
    main()
