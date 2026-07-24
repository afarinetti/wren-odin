// Integration Test: Foreign Class (Odin Struct ↔ Wren Class)
// Demonstrates bidirectional data flow between Odin structs and Wren classes

class Point {
    foreign construct new()
    foreign construct new(x, y)
    foreign x
    foreign y
    foreign x=(value)
    foreign y=(value)
    foreign magnitude
    foreign distanceTo(other)
    foreign toString
    
    // Wren methods that use foreign data
    scale(factor) {
        this.x = this.x * factor
        this.y = this.y * factor
    }
}

// Test 1: Create default point
var p1 = Point.new()
System.print("Default: %(p1)") // expect: Default: (0, 0)

// Test 2: Create point with values
var p2 = Point.new(3, 4)
System.print("Created: %(p2)") // expect: Created: (3, 4)
System.print("Magnitude: %(p2.magnitude)") // expect: Magnitude: 5

// Test 3: Modify from Wren
p2.x = 5
p2.y = 12
System.print("Modified: %(p2)") // expect: Modified: (5, 12)
System.print("New magnitude: %(p2.magnitude)") // expect: New magnitude: 13

// Test 4: Distance between two points
var origin = Point.new(0, 0)
System.print("Distance to origin: %(p2.distanceTo(origin))") // expect: Distance to origin: 13

// Test 5: Scale from Wren
p2.scale(2)
System.print("Scaled: %(p2)") // expect: Scaled: (10, 24)
System.print("Scaled magnitude: %(p2.magnitude)") // expect: Scaled magnitude: 26
