/**
 * @file drive_link.scad
 * @brief The plate that turns the die: pivot, drive pin, handle
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description A pair of these sandwich the die, one above and one below. Both turn on the
 * frame pin at the origin; both carry the drive pin that engages one of the die's drive
 * holes; and between them, at the outer end, the handle attaches.
 *
 * ## Where the moment is
 *
 * Not at the pivot. Cut the link just outside the pivot eye and the piece outboard of the
 * cut carries the handle force at the handle's length and the drive pin's force at the
 * drive radius - and those two are in balance, because that balance is what the machine
 * is. The internal moment there is zero. It rises going outward and peaks AT THE DRIVE
 * HOLE, which is also where the section is weakest, so that is the one place the width is
 * sized for.
 *
 * ## What is not here
 *
 * The handle. This file declares the interface - a radius, and the moment and force
 * delivered there - and stops. Sizing the handle is the same section-modulus problem as
 * the base, and both belong with whatever reacts the load into the world.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;

use <../purchased/pin.scad>
use <../purchased/plate.scad>

include <../utils/bend.scad>;
include <../utils/pin_sizing.scad>;   // pin_allowable_bending_fraction is a variable, so include

//! Radius the handle attaches at, mm.
//!
//! REASONED, NOT CITED: the die's outer radius plus one tube diameter. The link itself
//! passes over the die and the tube - it is a plate's thickness clear of both in z, so it
//! needs no radial clearance at all - but the handle hangs BETWEEN the two links, in the
//! die's own z band, so it has to start outside everything the die sweeps.
function drive_link_socket_radius(tube, clr) = clr + tube_od(tube);

//! Peak bending moment in ONE link, N.mm, at the drive hole.
function drive_link_moment_Nmm(handle_force_N, handle_length_mm, drive_radius_mm) =
    handle_force_N * (handle_length_mm - drive_radius_mm) / 2;

//! Width of the link, mm: the wider of what bending needs at the net section through the
//! drive hole, and what the eyes need to keep their edge distance.
//!
//! `drive_radius_mm` is undef on a die too small to carry drive holes. There is then no
//! hole to weaken the section and no radius to measure the moment from, so the moment is
//! taken at the pivot and the section is solid.
function drive_link_width(plate, handle_force_N, handle_length_mm, drive_radius_mm,
                          frame_pin_d, drive_pin_d) =
    let (driven = !is_undef(drive_radius_mm),
         hole = driven ? pin_index_hole(drive_pin_d) : 0,
         fb   = pin_allowable_bending_fraction * plate_yield(plate),
         wb   = plate_width_for_moment(
                    drive_link_moment_Nmm(handle_force_N, handle_length_mm,
                                          driven ? drive_radius_mm : 0),
                    plate_thickness(plate), fb, hole))
        max(wb,
            driven ? 2 * plate_eye_radius(hole) : 0,
            2 * plate_eye_radius(pin_pivot_hole(frame_pin_d)));

//! The handle interface: `[radius, moment N.mm, force N]` delivered to it.
function drive_link_handle_interface(tube, clr, handle_force_N, handle_length_mm) =
    let (r = drive_link_socket_radius(tube, clr))
        [r, handle_force_N * (handle_length_mm - r), handle_force_N];

//! One drive link, lying on z = 0, pivot at the origin, drive hole out along +x.
module drive_link(tube, clr, plate, frame_pin_d, drive_pin_d, drive_radius_mm,
                  handle_force_N, handle_length_mm) {
    w  = drive_link_width(plate, handle_force_N, handle_length_mm, drive_radius_mm,
                          frame_pin_d, drive_pin_d);
    rs = drive_link_socket_radius(tube, clr);

    assert(is_undef(drive_radius_mm) || drive_radius_mm < rs,
           "drive link: the drive hole is outside the handle socket - check the die's drive radius");

    render_2D_plate(plate)
      plate_2D(plate, rs + w, w)
        // offset(0) for the same reason the die needs one: the hull and the eyes meet on
        // seams that union leaves degenerate, and the extrusion of that will not build.
        offset(0)
            difference() {
                hull() {
                    circle(d = w);
                    translate([rs, 0]) circle(d = w);
                }

                circle(d = pin_pivot_hole(frame_pin_d));

                // No drive hole on a die too small to have any. JD2 drives those by
                // running the link's leading edge against the U-strap pin instead
                // [JD2-M32 p.7]; that contact face is the U-strap's to define, so this
                // link simply has nothing there rather than a hole with no mate.
                if (!is_undef(drive_radius_mm))
                    translate([drive_radius_mm, 0])
                        circle(d = pin_index_hole(drive_pin_d));
            }
}

//! Echo what the link comes out as.
module drive_link_report(tube, clr, plate, frame_pin_d, drive_pin_d, drive_radius_mm,
                         handle_force_N, handle_length_mm) {
    w  = drive_link_width(plate, handle_force_N, handle_length_mm, drive_radius_mm,
                          frame_pin_d, drive_pin_d);
    m  = drive_link_moment_Nmm(handle_force_N, handle_length_mm,
                               is_undef(drive_radius_mm) ? 0 : drive_radius_mm);
    hi = drive_link_handle_interface(tube, clr, handle_force_N, handle_length_mm);

    echo(str("drive link: ", plate_size(plate), " plate, ", w, " mm wide, out to r ",
             hi[0], " mm"));
    echo(str("            peak moment ", round(m / 1000), " N.m per link ",
             is_undef(drive_radius_mm) ? "at the pivot - NO DRIVE HOLE, this die is too small; the link must bear on the U-strap pin"
                                       : "at the drive hole",
             ", allowable ", pin_allowable_bending_fraction * plate_yield(plate), " MPa"));
    echo(str("            handle interface: ", round(hi[1] / 1000), " N.m and ", hi[2],
             " N at r ", hi[0], " mm - sized with the base, not here"));
}
