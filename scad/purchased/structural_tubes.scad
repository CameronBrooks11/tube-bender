//
// Round tube used as a STRUCTURAL MEMBER - the handle, and the pedestal post.
// DO NOT FORMAT THIS FILE, it is manually spaced out for readability.
//
// Kept apart from tubes.scad on purpose. That registry is stock to be BENT, and its rows
// are thin-wall sizes a bender can form; these are members that have to carry a moment,
// and the two are selected on opposite criteria. A row appearing in both would be one
// physical fact stated twice.
//
// Mild steel, A36's specified minimum yield [ASTM-A36]. Walls thicken with diameter the
// way stock actually does rather than staying constant.
//
include <NopSCADlib/core.scad>; // inch()

//                                                  "name"                 "size"                      od          wall        yield  colour
structural_0p500x0p065 = ["structural_0p500x0p065", "1/2 in OD x 0.065",   inch(1/2),      inch(0.065),   250, "silver"];
structural_0p750x0p083 = ["structural_0p750x0p083", "3/4 in OD x 0.083",   inch(3/4),      inch(0.083),   250, "silver"];
structural_1p000x0p120 = ["structural_1p000x0p120", "1 in OD x 0.120",     inch(1),        inch(0.120),   250, "silver"];
structural_1p250x0p120 = ["structural_1p250x0p120", "1-1/4 in OD x 0.120", inch(1 + 1/4),  inch(0.120),   250, "silver"];
structural_1p500x0p120 = ["structural_1p500x0p120", "1-1/2 in OD x 0.120", inch(1 + 1/2),  inch(0.120),   250, "silver"];
structural_1p750x0p120 = ["structural_1p750x0p120", "1-3/4 in OD x 0.120", inch(1 + 3/4),  inch(0.120),   250, "silver"];
structural_2p000x0p120 = ["structural_2p000x0p120", "2 in OD x 0.120",     inch(2),        inch(0.120),   250, "silver"];
structural_2p250x0p120 = ["structural_2p250x0p120", "2-1/4 in OD x 0.120", inch(2 + 1/4),  inch(0.120),   250, "silver"];
structural_2p500x0p188 = ["structural_2p500x0p188", "2-1/2 in OD x 0.188", inch(2 + 1/2),  inch(0.188),   250, "silver"];
structural_3p000x0p188 = ["structural_3p000x0p188", "3 in OD x 0.188",     inch(3),        inch(0.188),   250, "silver"];
structural_3p500x0p250 = ["structural_3p500x0p250", "3-1/2 in OD x 0.250", inch(3 + 1/2),  inch(0.250),   250, "silver"];
structural_4p000x0p250 = ["structural_4p000x0p250", "4 in OD x 0.250",     inch(4),        inch(0.250),   250, "silver"];

structural_tubes = [structural_0p500x0p065, structural_0p750x0p083, structural_1p000x0p120,
                    structural_1p250x0p120, structural_1p500x0p120, structural_1p750x0p120,
                    structural_2p000x0p120, structural_2p250x0p120, structural_2p500x0p188,
                    structural_3p000x0p188, structural_3p500x0p250, structural_4p000x0p250];

//! The smallest registered member whose section modulus carries `moment_Nmm` at `fb`, or
//! `undef` if nothing in the series does - which is a real answer, not a failure: it says
//! this configuration wants a member bigger than anything registered.
//!
//! Lives beside the list, because a default argument evaluates in the scope of the file
//! that defines the function.
function structural_smallest_for_moment(moment_Nmm, fb, from = structural_tubes) =
    let (ok = [for (s = from) if (structural_section_modulus(s) * fb >= moment_Nmm)
                   structural_od(s)])
        len(ok) == 0 ? undef
                     : [for (s = from) if (structural_od(s) == min(ok)) s][0];

//! The smallest registered member that carries a combined bending moment and torque, by
//! the maximum shear stress theory: an equivalent torque `sqrt(M^2 + T^2)` against the
//! polar modulus, which is twice the section modulus for a round section.
function structural_smallest_for_combined(moment_Nmm, torque_Nmm, fv,
                                          from = structural_tubes) =
    let (te = sqrt(moment_Nmm * moment_Nmm + torque_Nmm * torque_Nmm),
         ok = [for (s = from) if (2 * structural_section_modulus(s) * fv >= te)
                   structural_od(s)])
        len(ok) == 0 ? undef
                     : [for (s = from) if (structural_od(s) == min(ok)) s][0];

use <structural_tube.scad>; // structural_tube() draws the member these rows describe

//! The smallest registered member whose bore clears `d` mm - for a spacer tube that a bolt
//! has to pass through.
function structural_smallest_for_bore(d, from = structural_tubes) =
    let (ok = [for (s = from) if (structural_id(s) >= d) structural_od(s)])
        len(ok) == 0 ? undef
                     : [for (s = from) if (structural_od(s) == min(ok)) s][0];
