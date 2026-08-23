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

use <NopSCADlib/utils/maths.scad>
use <../purchased/pin.scad>
use <../purchased/plate.scad>

include <../utils/bend.scad>;
include <../utils/pin_sizing.scad>;   // pin_allowable_bending_fraction is a variable, so include

//! Radius at which the link stops being structure and starts being handle, mm.
//!
//! THE LINK IS THE HANDLE. There is no separate handle member and no joint between them,
//! which is how the prototype does it and it is the right answer here for a reason worth
//! writing down: the moment at a handle's root is essentially the FULL bending moment
//! whatever the handle's length, because `F x (L - r)` with `F x L = Mp` is `Mp` for any
//! small `r`. So a bolted-on handle needs a root section as big as the link's, plus a
//! joint that carries it, plus the fit of that joint - and at 1-1/2 in the smallest tube
//! whose bore clears the link pair is a 3 in member weighing the same as the plate it
//! would replace. The joint buys nothing.
//!
//! REASONED, NOT CITED: the die's outer radius plus one tube diameter is where the grip
//! may begin - outside everything the die sweeps and outside the tube standing proud of it.
function drive_link_socket_radius(tube, clr) = clr + tube_od(tube);

//! Where the two spacer bolts that join the link pair sit, as radii, mm.
//!
//! Both inside the grip - at its two ends - where they also stop the pair splaying under a
//! two-handed pull. An earlier version put them just INBOARD of the grip, which is fine on
//! a long handle and lands them inside the die's own sweep on a short one; the three
//! smallest sizes asserted.
function drive_link_spacer_radii(handle_length_mm, bolt_d) =
    let (e = plate_eye_radius(pin_pivot_hole(bolt_d)))
        [handle_length_mm - bend_handle_grip_length + e, handle_length_mm - e];

//! How many steps the taper is drawn in.
drive_link_taper_steps = 24;

//! Width the link needs at radius `r`, mm - the peak width inboard of the drive hole, and
//! the section for the local moment outboard of it, floored where the grip needs to be
//! held and the spacer bolts need their edge distance.
function drive_link_width_at(plate, handle_force_N, handle_length_mm, drive_radius_mm,
                             frame_pin_d, drive_pin_d, spacer_bolt_d, r) =
    let (peak = drive_link_width(plate, handle_force_N, handle_length_mm, drive_radius_mm,
                                 frame_pin_d, drive_pin_d),
         fb   = pin_allowable_bending_fraction * plate_yield(plate),
         tip  = 2 * plate_eye_radius(pin_pivot_hole(spacer_bolt_d)))
        r <= drive_radius_mm ? peak
        : max(tip, min(peak, plate_width_for_moment(
                  handle_force_N * (handle_length_mm - r) / 2,
                  plate_thickness(plate), fb)));

//! The taper's sample radii and the width at each, as `[r, w]`.
//!
//! The requirement goes as the square root of the distance to the handle's end, which is
//! CONCAVE, so a straight line between two points on it dips BELOW it in between. Each
//! sample therefore carries the width required one step further IN - the wider figure - so
//! every straight segment of the hull envelopes the curve it is approximating rather than
//! cutting the corner off it.
function drive_link_taper(plate, handle_force_N, handle_length_mm, drive_radius_mm,
                          frame_pin_d, drive_pin_d, spacer_bolt_d) =
    let (n = drive_link_taper_steps,
         step = (handle_length_mm - drive_radius_mm) / n)
        [for (i = [0 : n])
             let (r = drive_radius_mm + i * step)
                 [r, drive_link_width_at(plate, handle_force_N, handle_length_mm,
                                         drive_radius_mm, frame_pin_d, drive_pin_d,
                                         spacer_bolt_d, max(drive_radius_mm, r - step))]];

//! Mass of one link, kg, at 7850 kg/m^3 - reported because a 2 m plate is a real thing to
//! pick up and the model should say so rather than let it arrive as a surprise.
//!
//! Integrated over the taper rather than taken as a rectangle: the link is only as wide as
//! the moment needs it and that falls off all the way out, so a constant-width figure is
//! about half again too heavy.
function drive_link_mass(plate, taper, width_mm) =
    let (area = width_mm * (taper[0][0] + width_mm)
                + sumv([for (i = [1 : len(taper) - 1])
                           (taper[i][1] + taper[i - 1][1]) / 2
                               * (taper[i][0] - taper[i - 1][0])]))
        area * plate_thickness(plate) * 7850 / 1e9;

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
                  handle_force_N, handle_length_mm, spacer_bolt_d) {
    w  = drive_link_width(plate, handle_force_N, handle_length_mm, drive_radius_mm,
                          frame_pin_d, drive_pin_d);
    rs = drive_link_socket_radius(tube, clr);
    sp = drive_link_spacer_radii(handle_length_mm, spacer_bolt_d);
    taper = drive_link_taper(plate, handle_force_N, handle_length_mm,
                             is_undef(drive_radius_mm) ? 0 : drive_radius_mm,
                             frame_pin_d, drive_pin_d, spacer_bolt_d);
    drive_radius_mm_or_pivot = is_undef(drive_radius_mm) ? 0 : drive_radius_mm;

    assert(is_undef(drive_radius_mm) || drive_radius_mm < rs,
           "drive link: the drive hole is outside where the grip starts - check the die's drive radius");
    assert(sp[0] > rs,
           "drive link: the spacer bolts land inside the die's sweep - the handle is too short to grip");

    render_2D_plate(plate)
      plate_2D(plate, handle_length_mm + w, w)
        // offset(0) for the same reason the die needs one: the hull and the eyes meet on
        // seams that union leaves degenerate, and the extrusion of that will not build.
        offset(0)
            difference() {
                union() {
                    hull() {
                        circle(d = w);
                        translate([drive_radius_mm_or_pivot, 0]) circle(d = w);
                    }

                    for (i = [1 : len(taper) - 1])
                        hull() {
                            translate([taper[i - 1][0], 0]) circle(d = taper[i - 1][1]);
                            translate([taper[i][0], 0]) circle(d = taper[i][1]);
                        }
                }

                circle(d = pin_pivot_hole(frame_pin_d));

                // No drive hole on a die too small to have any. JD2 drives those by
                // running the link's leading edge against the U-strap pin instead
                // [JD2-M32 p.7]; that contact face is the U-strap's to define, so this
                // link simply has nothing there rather than a hole with no mate.
                if (!is_undef(drive_radius_mm))
                    translate([drive_radius_mm, 0])
                        circle(d = pin_index_hole(drive_pin_d));

                for (r = sp)
                    translate([r, 0])
                        circle(d = pin_pivot_hole(spacer_bolt_d));
            }
}

//! Echo what the link comes out as.
module drive_link_report(tube, clr, plate, frame_pin_d, drive_pin_d, drive_radius_mm,
                         handle_force_N, handle_length_mm, spacer_bolt_d) {
    w  = drive_link_width(plate, handle_force_N, handle_length_mm, drive_radius_mm,
                          frame_pin_d, drive_pin_d);
    m  = drive_link_moment_Nmm(handle_force_N, handle_length_mm,
                               is_undef(drive_radius_mm) ? 0 : drive_radius_mm);
    hi = drive_link_handle_interface(tube, clr, handle_force_N, handle_length_mm);
    tp = drive_link_taper(plate, handle_force_N, handle_length_mm,
                          is_undef(drive_radius_mm) ? 0 : drive_radius_mm,
                          frame_pin_d, drive_pin_d, spacer_bolt_d);

    echo(str("drive link: ", plate_size(plate), " plate, ", w, " mm wide, ",
             round(handle_length_mm), " mm long - it IS the handle, grip beyond r ",
             round(hi[0]), " mm"));
    echo(str("            ", round(drive_link_mass(plate, tp, w) * 100) / 100,
             " kg each, so ", round(2 * drive_link_mass(plate, tp, w) * 10) / 10,
             " kg of handle for the pair, tapered from ", round(w), " mm to ",
             round(tp[len(tp) - 1][1]), " mm"));
    echo(str("            peak moment ", round(m / 1000), " N.m per link ",
             is_undef(drive_radius_mm) ? "at the pivot - NO DRIVE HOLE, this die is too small; the link must bear on the U-strap pin"
                                       : "at the drive hole",
             ", allowable ", pin_allowable_bending_fraction * plate_yield(plate), " MPa"));

}
