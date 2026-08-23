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

plates = [plate_0p125in, plate_0p1875in, plate_0p250in, plate_0p3125in, plate_0p375in,
          plate_0p500in, plate_0p625in, plate_0p750in, plate_1p000in];

use <plate.scad>; // plate_2D() declares the blank, render_2D_plate() extrudes the profile
