//
// Clevis pins - the pivots the whole machine turns on.
// DO NOT FORMAT THIS FILE, it is manually spaced out for readability.
//
// A pin here is a real orderable thing. Every row therefore carries the number to ORDER it
// by, because a pin cannot be chosen by measuring the one already fitted: a second builder
// cannot measure this bench at all.
//
// ClevisPin() will build a row for a size that has no number yet, and it leaves `part_no`
// undef when you do not give it one. That is deliberate. An undef part number propagates
// to the BOM and gets noticed; a plausible invented number sitting beside a real one
// inherits its authority. pin_is_orderable() is what notices.
//
// The registered row was measured off the McMaster CAD model embedded in the prototype
// STEP, not retyped from a catalogue page, so the geometry and the number agree by
// construction. See docs/reverse-engineering.md.
//
include <NopSCADlib/core.scad>; // inch()

//! Build a clevis pin row. Lengths in mm; `length` is under the head, as pins are sold.
function ClevisPin(name, size, diameter, length, head_diameter, head_thickness,
                   cotter_hole, cotter_from_end, part_no = undef) =
    [name, size, diameter, length, head_diameter, head_thickness, cotter_hole,
     cotter_from_end, part_no];

//                                                                                                       dia          length       head dia  head t   cotter    from end   part no
pin_0p750x3p750 = ClevisPin("pin_0p750x3p750", "3/4 in dia x 3-3/4 in long",                  inch(3/4),   inch(3.75),  23.9776,  6.604,   inch(5/32), 3.988,   "98306A868");

pins = [pin_0p750x3p750];

use <pin.scad>; // pin() draws the pin these rows describe
