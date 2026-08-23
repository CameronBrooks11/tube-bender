//
// Round tube stock. DO NOT FORMAT THIS FILE, it is manually spaced out for readability.
//
// Tube is specified by OUTSIDE DIAMETER and WALL THICKNESS. Pipe is not - a pipe's nominal
// size is neither its OD nor its ID, and its wall comes from a schedule. There are no pipe
// rows here on purpose: pipe is bent by looking its real OD up in a pipe table and treating
// it as a tube of that OD, which is what the trade does. See docs/design-basis.md section 2.
//
// A row's IDENTITY IS ITS INCH SIZE, because that is what you order and what is stamped on
// the die. The millimetres beside it are the conversion, not the name. Arithmetic downstream
// is all millimetres - see docs/design-basis.md section 8.
//
// The OD series is the one the die catalogues actually cover: 1/8 in at the bottom, where
// the Swagelok hand bender starts, to 2 in at the top, where manual bending stops being
// feasible (docs/design-basis.md section 3). Walls are the common gauges at each size, one
// row per OD; anything else is built with Tube() rather than added here, so this list stays
// a list of sizes rather than a matrix.
//
include <NopSCADlib/core.scad>; // inch()
include <tube_materials.scad>

//! Build a tube of any OD and wall. `size` is the human name, and it is imperial for
//! imperial stock because that is the identity; `od` and `wall` are millimetres.
function Tube(name, size, od, wall, material = A513_T1) = [name, size, od, wall, material];

//                                                                       "name"              "size"                          od           wall
tube_0p125x0p028 = Tube("tube_0p125x0p028", "1/8 in OD x 0.028 in wall",     inch(1/8),     inch(0.028));
tube_0p250x0p035 = Tube("tube_0p250x0p035", "1/4 in OD x 0.035 in wall",     inch(1/4),     inch(0.035));
tube_0p375x0p049 = Tube("tube_0p375x0p049", "3/8 in OD x 0.049 in wall",     inch(3/8),     inch(0.049));
tube_0p500x0p049 = Tube("tube_0p500x0p049", "1/2 in OD x 0.049 in wall",     inch(1/2),     inch(0.049));
tube_0p625x0p049 = Tube("tube_0p625x0p049", "5/8 in OD x 0.049 in wall",     inch(5/8),     inch(0.049));
tube_0p750x0p065 = Tube("tube_0p750x0p065", "3/4 in OD x 0.065 in wall",     inch(3/4),     inch(0.065));
tube_0p875x0p065 = Tube("tube_0p875x0p065", "7/8 in OD x 0.065 in wall",     inch(7/8),     inch(0.065));
tube_1p000x0p065 = Tube("tube_1p000x0p065", "1 in OD x 0.065 in wall",       inch(1),       inch(0.065));
tube_1p125x0p065 = Tube("tube_1p125x0p065", "1-1/8 in OD x 0.065 in wall",   inch(1 + 1/8), inch(0.065));
tube_1p250x0p065 = Tube("tube_1p250x0p065", "1-1/4 in OD x 0.065 in wall",   inch(1 + 1/4), inch(0.065));
tube_1p375x0p083 = Tube("tube_1p375x0p083", "1-3/8 in OD x 0.083 in wall",   inch(1 + 3/8), inch(0.083));
tube_1p500x0p095 = Tube("tube_1p500x0p095", "1-1/2 in OD x 0.095 in wall",   inch(1 + 1/2), inch(0.095));
tube_1p625x0p095 = Tube("tube_1p625x0p095", "1-5/8 in OD x 0.095 in wall",   inch(1 + 5/8), inch(0.095));
tube_1p750x0p095 = Tube("tube_1p750x0p095", "1-3/4 in OD x 0.095 in wall",   inch(1 + 3/4), inch(0.095));
tube_2p000x0p120 = Tube("tube_2p000x0p120", "2 in OD x 0.120 in wall",       inch(2),       inch(0.120));

tubes = [tube_0p125x0p028, tube_0p250x0p035, tube_0p375x0p049, tube_0p500x0p049,
         tube_0p625x0p049, tube_0p750x0p065, tube_0p875x0p065, tube_1p000x0p065,
         tube_1p125x0p065, tube_1p250x0p065, tube_1p375x0p083, tube_1p500x0p095,
         tube_1p625x0p095, tube_1p750x0p095, tube_2p000x0p120];

use <tube.scad>; // tube() draws the stock these rows describe
