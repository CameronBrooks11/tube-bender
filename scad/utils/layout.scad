/**
 * @file layout.scad
 * @brief Where every plate in the stack sits, as one expression
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description Draws nothing. The stack is stated once, here, and read back by everything
 * that has to place a part or work out how long a pin must be. The recurring defect this
 * exists to prevent is one physical fact stated twice in two places, which agree until one
 * of them moves.
 *
 * ## The order, and why
 *
 * frame link / drive link / **forming die** / drive link / frame link
 *
 * The die is in the middle because it is the thing being driven and the thing the tube
 * wraps; its mid-plane is z = 0 and the tube centreline lies in it. The drive links are
 * next to it so the drive pin crosses the shortest possible span - pin bending goes with
 * that span, and bending is what sizes every pin on this machine. The frame links are
 * outermost because they are what the base grabs. Both reference machines stack this way.
 *
 * ## Clearance
 *
 * REASONED, NOT CITED: 0.5 mm at each interface. Every interface here sees relative
 * rotation at some point in a bend - the drive links turn against the frame links always,
 * and against the die whenever the drive pin is out for repositioning. In practice a
 * washer goes in these gaps; the model leaves them as gaps because a washer is a size
 * nobody has chosen yet.
 *
 * Sets no $fn.
 */

include <NopSCADlib/core.scad>;

use <../purchased/plate.scad>
use <../custom/forming_die.scad>

layout_running_clearance = 0.5;

//! The stack, bottom to top, as `[name, z of underside, thickness]`. Everything that
//! places a part reads this rather than adding thicknesses up again.
function layout_layers(tube, drive_plate, frame_plate) =
    let (td  = forming_die_thickness(tube),
         tdl = plate_thickness(drive_plate),
         tfl = plate_thickness(frame_plate),
         c   = layout_running_clearance)
    [
        ["frame link lower", -td / 2 - 2 * c - tdl - tfl, tfl],
        ["drive link lower", -td / 2 - c - tdl,           tdl],
        ["forming die",      -td / 2,                     td ],
        ["drive link upper",  td / 2 + c,                 tdl],
        ["frame link upper",  td / 2 + 2 * c + tdl,       tfl],
    ];

//! Underside of a named layer, mm.
function layout_z(layers, name) =
    [for (l = layers) if (l[0] == name) l[1]][0];

//! Thickness of a named layer, mm.
function layout_thickness(layers, name) =
    [for (l = layers) if (l[0] == name) l[2]][0];

//! Underside of the whole stack, mm.
function layout_bottom(layers) = layers[0][1];

//! Top of the whole stack, mm.
function layout_top(layers) = layers[len(layers) - 1][1] + layers[len(layers) - 1][2];

//! Overall height of the stack, mm.
function layout_height(layers) = layout_top(layers) - layout_bottom(layers);

//! How long a pin has to be to cross from `from_layer`'s underside to the top of the
//! stack, plus what a cotter needs beyond it.
function layout_pin_length(layers, from_layer, cotter_allowance = 6) =
    layout_top(layers) - layout_z(layers, from_layer) + cotter_allowance;

//! Clear distance between the frame links' inner faces, mm. Anything mounted between the
//! frame links - the followbar, the handle - is this thick.
function layout_frame_gap(layers) =
    layout_z(layers, "frame link upper") -
    (layout_z(layers, "frame link lower") + layout_thickness(layers, "frame link lower"));
