/**
 * @file structural_tube.scad
 * @brief Accessors for the rows in structural_tubes.scad, and the members they describe
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description Section properties live here because they are properties of the row, not of
 * whatever is using it. Drawn along +z from the origin.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;

use <../utils/units.scad>

function structural_name(type)  = type[0];  //! Registry name
function structural_size(type)  = type[1];  //! Imperial size, the identity you order by
function structural_od(type)    = type[2];  //! Outside diameter, mm
function structural_wall(type)  = type[3];  //! Wall thickness, mm
function structural_yield(type) = type[4];  //! Specified minimum yield strength, MPa
function structural_colour(type)= type[5];  //! Preview colour

function structural_id(type) = structural_od(type) - 2 * structural_wall(type); //! Bore, mm

//! Elastic section modulus, mm^3.
function structural_section_modulus(type) =
    let (D = structural_od(type), d = structural_id(type))
        PI * (pow(D, 4) - pow(d, 4)) / (32 * D);

//! Mass per metre, kg, at 7850 kg/m^3 for steel.
function structural_mass_per_m(type) =
    let (D = structural_od(type), d = structural_id(type))
        PI / 4 * (D * D - d * d) * 1000 * 7850 / 1e9;

//! Draw a length of the member, running up +z from the origin.
module structural_tube(type, length) {
    // The key before the colon is the BOM's own identity for this part and stays in
    // millimetres in both systems, the way a part number would - it is what groups
    // identical items, not something anybody measures. Only the human half converts.
    vitamin(str("structural_tube(", structural_name(type), ", ", round(length), "): Tube ",
                structural_size(type), " in wall, mild steel, length ", fmt_length(length)));

    color(structural_colour(type))
        render()
            difference() {
                cylinder(d = structural_od(type), h = length);
                translate_z(-eps)
                    cylinder(d = structural_id(type), h = length + 2 * eps);
            }
}
