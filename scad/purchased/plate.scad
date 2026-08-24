/**
 * @file plate.scad
 * @brief Accessors for the rows in plates.scad, and the parts cut from them
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description A plate part is a 2D profile and a thickness. The profile is the caller's -
 * these modules only declare what stock it consumes and extrude it.
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

//! Extrude a 2D profile to the plate's thickness and give it the plate's colour, sitting
//! on z = 0.
module render_2D_plate(type) {
    color(plate_colour(type))
        render()
            linear_extrude(plate_thickness(type))
                children();
}
