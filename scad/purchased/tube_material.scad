/**
 * @file tube_material.scad
 * @brief Accessors for the rows in tube_materials.scad
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description A material is a specification plus a condition, and its strength is the
 * band the specification gives. Nothing here picks a number out of that band - callers
 * ask for the end they need and say which end they asked for.
 */

function tube_material_name(type)        = type[0];  //! Registry name
function tube_material_description(type) = type[1];  //! What to write on the BOM and the order
function tube_material_yield(type)       = type[2];  //! Yield strength band [min, max] MPa
function tube_material_colour(type)      = type[3];  //! Preview colour

//! Bottom of the yield band - the easiest tube of this specification to bend.
function tube_material_yield_min(type) = tube_material_yield(type)[0];

//! Top of the yield band - the hardest tube of this specification to bend, and therefore
//! the one every force and torque in this model is sized against.
function tube_material_yield_max(type) = tube_material_yield(type)[1];
