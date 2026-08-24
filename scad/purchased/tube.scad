/**
 * @file tube.scad
 * @brief Accessors for the rows in tubes.scad, and the stock they describe
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description Geometry and the bill of materials only. Section properties and everything
 * that follows from them - wall factor, D of bend, drive torque - live in utils/bend.scad,
 * because those are questions about a tube being bent round a particular die and this file
 * knows nothing about dies.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;

use <../utils/units.scad>

use <tube_material.scad>

function tube_name(type)     = type[0];  //! Registry name
function tube_size(type)     = type[1];  //! Imperial size, the identity you order by
function tube_od(type)       = type[2];  //! Outside diameter, mm
function tube_wall(type)     = type[3];  //! Wall thickness, mm
function tube_material(type) = type[4];  //! Row from tube_materials.scad

function tube_id(type) = tube_od(type) - 2 * tube_wall(type); //! Inside diameter, mm

//! Draw a straight length of tube, centred on the origin and running along z.
module tube(type, length) {
    // The key before the colon is the BOM's own identity for this part and stays in
    // millimetres in both systems, the way a part number would - it is what groups
    // identical items, not something anybody measures. Only the human half converts.
    vitamin(str("tube(", tube_name(type), ", ", length, "): Tube ", tube_size(type), ", ",
                tube_material_description(tube_material(type)), ", length ",
                fmt_length(length)));

    colour = tube_material_colour(tube_material(type));

    color(colour)
        render()
            difference() {
                cylinder(d = tube_od(type), h = length, center = true);
                cylinder(d = tube_id(type), h = length + 2 * eps, center = true);
            }
}
