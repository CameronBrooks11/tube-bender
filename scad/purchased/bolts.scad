//
// Hex head bolts, for joints that have to CLAMP rather than just locate.
// DO NOT FORMAT THIS FILE, it is manually spaced out for readability.
//
// A diameter series, like the pins, and for the same reason: bolt sizing produces a
// required diameter and length is whatever the stack turns out to be. NopSCADlib's screw
// registry stops at M8, which is a long way below anything here.
//
// One row was MEASURED off the McMaster CAD model in the prototype STEP, and it is what
// lets the rest be drawn honestly rather than guessed. Its width across flats is 28.575 mm
// on a 19.05 mm bolt - exactly 1.5 x the nominal diameter, which is the ANSI relation for
// hex head cap screws across most of the range. So the flats are DERIVED from that ratio
// and the one measured row is the check on it, rather than a proportion invented to make
// the picture look right. Head height is the same story: 12.7 on 19.05 is 2/3 d.
//
// Order numbers are another matter. Only the measured row has one, and the others say so
// on the BOM.
//
include <NopSCADlib/core.scad>; // inch()

//! Build a bolt row.
function HexBolt(name, size, diameter, part_no = undef) = [name, size, diameter, part_no];

//                                                          dia            part no
bolt_0p250in = HexBolt("bolt_0p250in", "1/4 in",  inch(1/4));
bolt_0p3125in= HexBolt("bolt_0p3125in","5/16 in", inch(5/16));
bolt_0p375in = HexBolt("bolt_0p375in", "3/8 in",  inch(3/8));
bolt_0p500in = HexBolt("bolt_0p500in", "1/2 in",  inch(1/2));
bolt_0p625in = HexBolt("bolt_0p625in", "5/8 in",  inch(5/8));
bolt_0p750in = HexBolt("bolt_0p750in", "3/4 in",  inch(3/4),  "91236A849");
bolt_0p875in = HexBolt("bolt_0p875in", "7/8 in",  inch(7/8));
bolt_1p000in = HexBolt("bolt_1p000in", "1 in",    inch(1));
bolt_1p250in = HexBolt("bolt_1p250in", "1-1/4 in",inch(1 + 1/4));

bolts = [bolt_0p250in, bolt_0p3125in, bolt_0p375in, bolt_0p500in, bolt_0p625in,
         bolt_0p750in, bolt_0p875in, bolt_1p000in, bolt_1p250in];

//
// Bolt material. REGISTERED CONSERVATIVELY at A36's 250 MPa rather than at a fastener
// grade. The one bolt with a number is McMaster's "low-strength" line, and a bolt whose
// grade nobody has recorded must not be assumed stronger than mild steel. Order a graded
// fastener and the margin is better than the model says; the report prints the stress so
// that can be judged rather than taken on trust.
//
bolt_material_yield = 250;

//! The smallest registered bolt at least `d` mm across, or `undef` past the top of series.
function bolt_smallest_at_least(d, from = bolts) =
    let (above = [for (b = from) if (bolt_diameter(b) >= d - 0.01) bolt_diameter(b)])
        len(above) == 0 ? undef
                        : [for (b = from) if (bolt_diameter(b) == min(above)) b][0];

use <bolt.scad>; // bolt() draws the fastener these rows describe

//! The row called `name`, for a caller that has a string rather than a row.
//!
//! This is how the OpenSCAD Customizer reaches the registry. Customizer parameters may only
//! be LITERALS - a string, a number, a boolean - so a configuration cannot hold a row; it
//! holds the row's name and looks it up here. Lives beside the list for the usual reason: a
//! default argument is evaluated in the scope of the file that defines the function.
//!
//! Asserts rather than returning undef. A name that is not in the registry is a typo or a
//! stale dropdown, and undef would travel a long way from here before it surfaced.
function bolt_by_name(name, from = bolts) =
    let (hit = [for (r = from) if (bolt_name(r) == name) r])
        assert(len(hit) == 1, str("no such bolt in the registry: ", name))
        hit[0];

//! Every registered name, in registry order - what a Customizer dropdown has to offer.
function bolt_names(from = bolts) = [for (r = from) bolt_name(r)];
