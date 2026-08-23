//
// Clevis pins - the pivots the whole machine turns on.
// DO NOT FORMAT THIS FILE, it is manually spaced out for readability.
//
// This is a DIAMETER SERIES, because that is what pin sizing produces: a required diameter
// from shear and bending, rounded up to something you can buy. Length is not registered -
// it is the stack the pin has to cross, which the assembly knows and the catalogue does
// not, so pin() takes it as an argument.
//
// Only one row carries an order number and head geometry, and it is the one that was
// MEASURED off the McMaster CAD model embedded in the prototype STEP. The rest carry undef
// for both, deliberately: an undef part number reaches the BOM as a hole in it, and a
// plausible invented number sitting beside a real one inherits its authority. Same for the
// head - a pin drawn with a fabricated head looks as specified as a pin drawn with a real
// one. pin_is_orderable() is what notices, and pin() draws a bare shank where it must.
//
// Filling this table in is a shopping trip, not a modelling problem.
//
include <NopSCADlib/core.scad>; // inch()

//! Build a pin row. `diameter` in mm; everything after it is optional and stays undef
//! until somebody looks the part up.
function ClevisPin(name, size, diameter, head_diameter = undef, head_thickness = undef,
                   cotter_hole = undef, cotter_from_end = undef, part_no = undef) =
    [name, size, diameter, head_diameter, head_thickness, cotter_hole, cotter_from_end,
     part_no];

//                                                                   dia         head dia  head t  cotter      from end  part no
pin_0p1875in = ClevisPin("pin_0p1875in", "3/16 in dia", inch(3/16));
pin_0p250in  = ClevisPin("pin_0p250in",  "1/4 in dia",  inch(1/4));
pin_0p3125in = ClevisPin("pin_0p3125in", "5/16 in dia", inch(5/16));
pin_0p375in  = ClevisPin("pin_0p375in",  "3/8 in dia",  inch(3/8));
pin_0p4375in = ClevisPin("pin_0p4375in", "7/16 in dia", inch(7/16));
pin_0p500in  = ClevisPin("pin_0p500in",  "1/2 in dia",  inch(1/2));
pin_0p625in  = ClevisPin("pin_0p625in",  "5/8 in dia",  inch(5/8));
pin_0p750in  = ClevisPin("pin_0p750in",  "3/4 in dia",  inch(3/4),  23.9776,  6.604,  inch(5/32), 3.988, "98306A868");
pin_0p875in  = ClevisPin("pin_0p875in",  "7/8 in dia",  inch(7/8));
pin_1p000in  = ClevisPin("pin_1p000in",  "1 in dia",    inch(1));
pin_1p125in  = ClevisPin("pin_1p125in",  "1-1/8 in dia",inch(1 + 1/8));
pin_1p250in  = ClevisPin("pin_1p250in",  "1-1/4 in dia",inch(1 + 1/4));
pin_1p375in  = ClevisPin("pin_1p375in",  "1-3/8 in dia",inch(1 + 3/8));
pin_1p500in  = ClevisPin("pin_1p500in",  "1-1/2 in dia",inch(1 + 1/2));

pins = [pin_0p1875in, pin_0p250in, pin_0p3125in, pin_0p375in, pin_0p4375in, pin_0p500in,
        pin_0p625in, pin_0p750in, pin_0p875in, pin_1p000in, pin_1p125in, pin_1p250in,
        pin_1p375in, pin_1p500in];

// The last two rows were added when the frame pin's span was corrected to include the die
// plates. At 2 in that asked for 32.0 mm and the series stopped at 31.75 - a shortfall of
// nine tenths of a percent, which is well inside the conservatism of taking AISC's TENSION
// allowable for a solid round in bending. The series was extended rather than the
// allowable relaxed: a bigger pin is cheap and the margin is not the place to find savings.

//
// Pin material. The prototype's pin is McMaster's "1004-1045 carbon steel", which is a
// RANGE of grades rather than a grade - the supplier may ship anything in it. The anchor
// registered here is AISI 1018 cold drawn, 370 MPa yield, from a mill data sheet
// [MW-1018]; 1004 sits below that and is not documented here.
//
// So this number is only as good as the pin you actually buy. Order to a stated grade, or
// re-check the margin against whatever turns up. It is registered as one number rather
// than a band because only one end of the band has a source.
//
pin_material_yield = 370;

//! The smallest registered pin at least `d` mm across, or `undef` if the series does not
//! reach it. Lives beside the list because a default argument is evaluated in the scope of
//! the file that defines the function, and pin.scad cannot see `pins`.
function pin_smallest_at_least(d, from = pins) =
    let (above = [for (p = from) if (pin_diameter(p) >= d - 0.01) pin_diameter(p)])
        len(above) == 0 ? undef
                        : [for (p = from) if (pin_diameter(p) == min(above)) p][0];

use <pin.scad>; // pin() draws the pin these rows describe
