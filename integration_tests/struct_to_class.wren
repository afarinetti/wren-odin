// Integration Test: Odin Struct ↔ Wren Foreign Class
// Demonstrates bidirectional data flow between Odin and Wren

class Point {
    foreign construct new()
    foreign construct new(x, y)
    foreign x
    foreign y
    foreign x=(value)
    foreign y=(value)
    foreign magnitude
    foreign distanceTo(other)
    
    toString { "Point(%(x), %(y))" }
}

// Test 1: Create default point
var p1 = Point.new()
System.print("Default: %(p1)")

// Test 2: Create point with values
var p2 = Point.new(3, 4)
System.print("Created: %(p2)")
System.print("Magnitude: %(p2.magnitude)")

// Test 3: Modify from Wren
p2.x = 5
p2.y = 12
System.print("Modified: %(p2)")
System.print("New magnitude: %(p2.magnitude)")

// Test 4: Distance between two points
var origin = Point.new(0, 0)
System.print("Distance to origin: %(p2.distanceTo(origin))")

// expect: Default: Point(0, 0)
// expect: Created: Point(3, 4)
// expect: Magnitude: 5
// expect: Modified: Point(5, 12)
// expect: New magnitude: 13
// expect: Distance to origin: 13
