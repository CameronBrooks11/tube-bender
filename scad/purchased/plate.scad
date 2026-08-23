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

function plate_name(type)        = type[0];  //! Registry name
function plate_size(type)        = type[1];  //! Imperial thickness, the identity you order by
function plate_description(type) = type[2];  //! What to write on the BOM
function plate_thickness(type)   = type[3];  //! Thickness, mm
function plate_colour(type)      = type[4];  //! Preview colour

//! Declare the blank a 2D profile is cut from and pass the profile through. `w` and `d`
//! are the blank the profile has to fit inside, in mm.
module plate_2D(type, w, d) {
    vitamin(str("plate_2D(", plate_name(type), ", ", round(w), ", ", round(d), "): ",
                plate_description(type), " ", plate_size(type), ", blank ",
                round(w), "mm x ", round(d), "mm"));
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
