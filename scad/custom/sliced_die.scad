/**
 * @file sliced_die.scad
 * @brief The forming die as a stack of flat-cut plates, for a shop with no mill
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description Same die, different realisation. Every dimension comes from the same
 * functions in forming_die.scad - the arc, the hub, the tail, the drive circle, the groove
 * root - so the rest of the machine cannot tell which one it is bolted to. Only the way
 * the groove is made differs: machined in one piece, or approximated by the rims of a
 * stack of plates that a laser or waterjet can cut flat.
 *
 * ## What a stack cannot do, stated plainly
 *
 * The groove is a half-round, and near its edges its surface runs almost parallel to the
 * die's axis - `dr/dz` goes to infinity at the part line. **No horizontal slicing can
 * follow that.** A stack always falls away from the true groove somewhere, and the further
 * out it goes the worse it gets.
 *
 * So each slice is cut to the groove's radius at its own edge NEAREST THE MID-PLANE. That
 * choice means the stack is everywhere at or inside the true groove and never proud of it:
 * the tube gets line contact on each slice's rim rather than being embossed by corners
 * standing into its path. Cutting to each slice's mid-height would halve the gaps and put
 * every corner into the tube instead, which is the wrong trade for a formed surface.
 *
 * What that costs is **wrap**. The outermost slice whose rim still touches the tube sets
 * how far round the section the die actually supports it, and the report gives that figure
 * against the 180 degrees a machined groove holds. Thinner slices buy more of it.
 *
 * A stepped die suits thick wall and punishes thin - which is what wall factor measures,
 * so the report gives that too.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;

use <NopSCADlib/utils/maths.scad>
use <../purchased/bolt.scad>
use <../purchased/pin.scad>
use <../purchased/plate.scad>
use <forming_die.scad>

include <../utils/bend.scad>;

//! How many slices the die is cut into.
function sliced_die_count(tube, slice_plate) =
    ceil(forming_die_thickness(tube) / plate_thickness(slice_plate));

//! Actual slice thickness, mm - the stack has to come out at the die's thickness, so the
//! registered plate is what you order and this is what it is faced to if it must be.
function sliced_die_slice_thickness(tube, slice_plate) =
    forming_die_thickness(tube) / sliced_die_count(tube, slice_plate);

//! The groove's radius at height `z` from the mid-plane, mm - the true surface the stack
//! is approximating.
function sliced_die_groove_radius(tube, clr, z) =
    let (gr = forming_die_groove_radius(tube))
        abs(z) >= gr ? clr : clr - sqrt(gr * gr - z * z);

//! Underside of slice `i`, mm.
function sliced_die_slice_z(tube, slice_plate, i) =
    -forming_die_thickness(tube) / 2 + i * sliced_die_slice_thickness(tube, slice_plate);

//! Outer radius of slice `i`, mm: the groove's radius at whichever of its two edges is
//! nearer the mid-plane, so the slice never stands into the tube's path.
function sliced_die_slice_radius(tube, clr, slice_plate, i) =
    let (z0 = sliced_die_slice_z(tube, slice_plate, i),
         z1 = z0 + sliced_die_slice_thickness(tube, slice_plate))
        sliced_die_groove_radius(tube, clr, min(abs(z0), abs(z1)));

//! How far slice `i` falls away from the true groove at its far edge, mm.
function sliced_die_slice_gap(tube, clr, slice_plate, i) =
    let (z0 = sliced_die_slice_z(tube, slice_plate, i),
         z1 = z0 + sliced_die_slice_thickness(tube, slice_plate))
        sliced_die_groove_radius(tube, clr, max(abs(z0), abs(z1)))
            - sliced_die_slice_radius(tube, clr, slice_plate, i);

//! The worst of those gaps, mm.
function sliced_die_max_gap(tube, clr, slice_plate) =
    max([for (i = [0 : sliced_die_count(tube, slice_plate) - 1])
             sliced_die_slice_gap(tube, clr, slice_plate, i)]);

//! Degrees of the tube's section the stack actually supports, against the 180 a machined
//! groove holds. Taken from the outermost slice rim that still reaches the tube.
function sliced_die_wrap(tube, clr, slice_plate) =
    let (gr = forming_die_groove_radius(tube),
         zs = [for (i = [0 : sliced_die_count(tube, slice_plate)])
                   let (z = abs(sliced_die_slice_z(tube, slice_plate, i)))
                       if (z < gr) z])
        2 * asin(max(zs) / gr);

//! One slice's 2D profile - the die's own outline, at that slice's radius.
module sliced_die_slice_2D(tube, clr, slice_plate, i, bend_angle, frame_pin_d, drive_pin_d,
                           ustrap_pin_d, plate_bolts, plate_bolt_d) {
    r      = sliced_die_slice_radius(tube, clr, slice_plate, i);
    arc    = forming_die_arc(bend_angle);
    lc     = forming_die_tail_length(tube, clr);
    depth  = forming_die_tail_depth(tube, ustrap_pin_d);
    steps  = max(8, ceil(arc / 3));
    drives = forming_die_drive_angles(tube, clr, frame_pin_d, drive_pin_d, bend_angle);
    r_drv  = forming_die_drive_radius(tube, clr, drive_pin_d);

    offset(0)
        difference() {
            union() {
                polygon([[0, 0],
                         for (j = [0 : steps]) let (a = arc * j / steps)
                             r * [cos(a), sin(a)]]);

                circle(r = forming_die_hub_radius(tube, frame_pin_d));

                translate([r - depth, -lc])
                    square([depth, lc]);
            }

            circle(d = pin_pivot_hole(frame_pin_d));

            for (a = drives)
                rotate(a) translate([r_drv, 0])
                    circle(d = pin_index_hole(drive_pin_d));

            translate(forming_die_ustrap_pin_pos(tube, clr, ustrap_pin_d))
                circle(d = pin_index_hole(ustrap_pin_d));

            for (p = plate_bolts)
                translate(p) circle(d = bolt_clearance_hole_d(plate_bolt_d));
        }
}

//! The whole stack, mid-plane on z = 0, in the die's own frame.
module sliced_die(tube, clr, slice_plate, bend_angle, frame_pin_d, drive_pin_d,
                  ustrap_pin_d, plate_bolts = [], plate_bolt_d = 0) {
    n = sliced_die_count(tube, slice_plate);
    t = sliced_die_slice_thickness(tube, slice_plate);

    vitamin(str("sliced_die_blank(", plate_name(slice_plate), "): ",
                plate_description(slice_plate), " ", plate_size(slice_plate), ", ", n,
                " slices, blank ", round(2 * clr), "mm x ",
                round(clr + forming_die_tail_length(tube, clr)), "mm each"));

    for (i = [0 : n - 1])
        translate_z(sliced_die_slice_z(tube, slice_plate, i))
            color(plate_colour(slice_plate))
                linear_extrude(t)
                    sliced_die_slice_2D(tube, clr, slice_plate, i, bend_angle, frame_pin_d,
                                        drive_pin_d, ustrap_pin_d, plate_bolts,
                                        plate_bolt_d);
}

//! Echo what the stack approximates, and what it gives up doing so.
module sliced_die_report(tube, clr, slice_plate) {
    n    = sliced_die_count(tube, slice_plate);
    gap  = sliced_die_max_gap(tube, clr, slice_plate);
    wrap = sliced_die_wrap(tube, clr, slice_plate);

    echo(str("sliced die: ", n, " x ", plate_size(slice_plate), " slices, ",
             round(sliced_die_slice_thickness(tube, slice_plate) * 100) / 100,
             " mm each after facing"));
    echo(str("            supports ", round(wrap), " deg of the tube's section against 180",
             " machined, and falls up to ", round(gap * 100) / 100,
             " mm away from the groove between rims"));
    echo(str("            wall factor here is ",
             round(bend_wall_factor(tube) * 10) / 10,
             " - a stepped groove suits thick wall and marks thin"));
}
