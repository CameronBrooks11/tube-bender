/**
 * @file plate.scad
 * @brief Accessors for the rows in plates.scad, and the parts cut from them
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description A plate part is a 2D profile and a thickness. The profile is the caller's -
 * these modules only declare what stock it consumes, name it for the cutter, and extrude it.
 *
 * plate_2D() names the BLANK, not the finished profile, because a blank is what you order
 * and what a cutting shop quotes. A part list that says "one 1/4 in plate part" cannot be
 * bought from.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;

use <../utils/units.scad>

function plate_name(type)        = type[0];  //! Registry name
function plate_size(type)        = type[1];  //! Imperial thickness, the identity you order by
function plate_description(type) = type[2];  //! What to write on the BOM
function plate_thickness(type)   = type[3];  //! Thickness, mm
function plate_colour(type)      = type[4];  //! Preview colour
function plate_yield(type)       = type[5];  //! Specified minimum yield strength, MPa

//! Distance from a hole's centre to the edge of the plate around it, mm.
//!
//! REASONED, NOT CITED: 1.5 x the hole diameter. It is the common shop rule of thumb for
//! edge distance on a bolt or pin hole, and the Onshape prototype independently landed on
//! it - its links carry r30 eyes on d20 holes, which is exactly 1.5 d. That is
//! corroboration, not a source.
//!
//! The forming die uses a different and tighter rule for the material between its drive
//! holes and the groove root, because that is not a free edge in a plate: the section is
//! six times thicker and there is material above and below the groove.
function plate_eye_radius(hole_d) = 1.5 * hole_d;

//! Declare the blank a 2D profile is cut from and pass the profile through. `w` and `d`
//! are the blank the profile has to fit inside, in mm.
module plate_2D(type, w, d) {
    // The key before the colon is the BOM's own identity for this part and stays in
    // millimetres in both systems, the way a part number would - it is what groups
    // identical items, not something anybody measures. Only the human half converts.
    vitamin(str("plate_2D(", plate_name(type), ", ", round(w), ", ", round(d), "): ",
                plate_description(type), " ", plate_size(type), ", blank ",
                fmt_bare_length(w), " x ", fmt_length(d)));
    children();
}

//! Put a plate part where it belongs in an assembly: colour it, name it for the BOM and
//! for the DXF export, and extrude the profile that comes back.
//!
//! **The profile is the deliverable.** A flat part is CUT, not printed - it goes to a
//! laser, waterjet or plasma table as a 2D outline - so it is billed as a routed part and
//! the solid drawn in the assembly is made from the same profile the cutter gets, rather
//! than being a second description of it. NopSCADlib swaps in the exported DXF itself when
//! it poses the assembly for a render, which is what makes that a check rather than a
//! claim: if the two ever disagree, the picture is the one that changes.
//!
//! `colour` is this part's colour in the assembly, the way stl_colour() is for a made
//! part. NopSCADlib has no dxf_colour() to mirror that, so it is set here - on the geometry
//! for the assembly view, and on $dxf_colour for the part's own render. Left off, a part
//! is the colour of the stock it is cut from.
module routed_plate(type, name, colour = undef) {
    c = is_undef(colour) ? plate_colour(type) : colour;
    $dxf_colour = c;

    color(c)
        render()
            linear_extrude(plate_thickness(type))
                dxf(name)
                    children();
}
