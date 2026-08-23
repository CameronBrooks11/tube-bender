//
// Structural plate. DO NOT FORMAT THIS FILE, it is manually spaced out for readability.
//
// Everything flat in this machine - the frame and drive links, the die plates, the base -
// is cut from one of these. They are ordered as a cut piece, not as a sheet, which is why
// they are registered here rather than as NopSCADlib sheets: `sheets.scad` tops out at 8 mm
// aluminium and models enclosure panels, and its row carries a weave that plate has no use
// for. See docs/design-basis.md section 11.
//
// The thicknesses are the imperial stock series, which is a fact of the supply chain rather
// than a claim needing a citation. The reference machines sit inside it: the prototype used
// 1/4 in throughout, and Pro-Tools' 105 uses 5/8 in frame arms [PROTOOLS-105].
//
//                                          "name"              "size"      "description"                   t mm      colour
plate_0p125in = ["plate_0p125in", "1/8 in",   "Plate mild steel",             3.175,  "silver"];
plate_0p1875in= ["plate_0p1875in","3/16 in",  "Plate mild steel",             4.7625, "silver"];
plate_0p250in = ["plate_0p250in", "1/4 in",   "Plate mild steel",             6.35,   "silver"];
plate_0p3125in= ["plate_0p3125in","5/16 in",  "Plate mild steel",             7.9375, "silver"];
plate_0p375in = ["plate_0p375in", "3/8 in",   "Plate mild steel",             9.525,  "silver"];
plate_0p500in = ["plate_0p500in", "1/2 in",   "Plate mild steel",            12.7,    "silver"];
plate_0p625in = ["plate_0p625in", "5/8 in",   "Plate mild steel",            15.875,  "silver"];
plate_0p750in = ["plate_0p750in", "3/4 in",   "Plate mild steel",            19.05,   "silver"];
plate_1p000in = ["plate_1p000in", "1 in",     "Plate mild steel",            25.4,    "silver"];
// Above 1 in the series steps in quarters, not eighths. A die is as thick as the tube is
// wide, and tube ODs step in eighths, so from 1 in up the blank is the next quarter and
// the die gets faced down to size. That is the fabrication reality, not a rounding error.
plate_1p250in = ["plate_1p250in", "1-1/4 in", "Plate mild steel",            31.75,   "silver"];
plate_1p500in = ["plate_1p500in", "1-1/2 in", "Plate mild steel",            38.1,    "silver"];
plate_1p750in = ["plate_1p750in", "1-3/4 in", "Plate mild steel",            44.45,   "silver"];
plate_2p000in = ["plate_2p000in", "2 in",     "Plate mild steel",            50.8,    "silver"];
plate_2p250in = ["plate_2p250in", "2-1/4 in", "Plate mild steel",            57.15,   "silver"];
plate_2p500in = ["plate_2p500in", "2-1/2 in", "Plate mild steel",            63.5,    "silver"];

plates = [plate_0p125in, plate_0p1875in, plate_0p250in, plate_0p3125in, plate_0p375in,
          plate_0p500in, plate_0p625in, plate_0p750in, plate_1p000in, plate_1p250in,
          plate_1p500in, plate_1p750in, plate_2p000in, plate_2p250in, plate_2p500in];


//! The thinnest registered plate at least `t` mm thick, or `undef` if nothing reaches it.
//! `undef` propagates, which is the point: a part thicker than any stock in the registry
//! is a part nobody can make, and it should surface as a hole rather than as a silent
//! substitution of the closest thing.
//
// This lives beside the list rather than in plate.scad because a default argument is
// evaluated in the scope of the file that DEFINES the function, and plate.scad cannot see
// `plates`. Written there, it returned undef for every thickness ever asked of it.
function plate_smallest_at_least(t, from = plates) =
    let (above = [for (p = from) if (plate_thickness(p) >= t - 0.01) plate_thickness(p)])
        len(above) == 0 ? undef
                        : [for (p = from) if (plate_thickness(p) == min(above)) p][0];

use <plate.scad>; // plate_2D() declares the blank, render_2D_plate() extrudes the profile
