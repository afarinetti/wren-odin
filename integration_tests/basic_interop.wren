// Integration Test: Basic Data Interop
// Demonstrates passing data between Odin and Wren using static foreign methods

class DataInterop {
    foreign static addNumbers(a, b)
    foreign static concatenateStrings(a, b)
    foreign static createList()
    foreign static createMap()
}

// Test 1: Number interop
var sum = DataInterop.addNumbers(10, 20)
System.print("Sum: %(sum)") // expect: Sum: 30

// Test 2: String interop
var greeting = DataInterop.concatenateStrings("Hello", " World")
System.print("Greeting: %(greeting)") // expect: Greeting: Hello World

// Test 3: List interop
var list = DataInterop.createList()
System.print("List: %(list)") // expect: List: [1, 2, 3, 4, 5]

// Test 4: Map interop
var map = DataInterop.createMap()
System.print("Map: %(map)") // expect: Map: {one: 1, two: 2, three: 3}
