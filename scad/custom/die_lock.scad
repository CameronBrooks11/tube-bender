/**
 * @file die_lock.scad
 * @brief The pin that holds the die while the drive pin is out
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description Draws no part of its own - it places a pin, and tells the frame link where
 * to carry it. Everything here is where and how big, not what shape.
 *
 * ## What it is for
 *
 * Between strokes the drive pin comes out, and until this exists NOTHING HOLDS THE DIE.
 * The tube springs back before it can be re-pinned and every stroke gives back part of
 * what the last one gained. JD2 fits a die lock pin, spring-loaded in a collar on the
 * frame link, that "slides along the upper surface of the forming die" until it drops into
 * a drive hole [JD2-M32 p.7, p.8].
 *
 * ## Why it can be reached at all
 *
 * Because the machine INDEXES. The drive link engages a hole, pulls one pitch, and swings
 * back to where it started while the die carries the next hole into place, so it never
 * leaves a band one pitch wide. The frame stands still. Put the two far enough apart in
 * ANGLE and the pin has a clear path down through the drive link's plane into the die.
 *
 * design-basis.md section 17 has the argument, and the claim it replaces - that the drive
 * links sweep every radius and so block everything - which is true about radius and beside
 * the point about collisions.
 *
 * ## Where it goes, and it is not a matter of taste
 *
 * ONE PITCH PAST THE LAST DRIVE HOLE, at the die's start position. That is the whole
 * answer and it is exact rather than chosen.
 *
 * Holes sit at `a_i = inset + i x pitch` for `i` in `0 .. n-1`. Stroke `k` ends with the
 * die turned through `k x pitch`, so hole `n - k` is then at
 *
 *     a_(n-k) + k x pitch = inset + (n - k) x pitch + k x pitch = inset + n x pitch
 *
 * - the same angle for EVERY `k` from 1 to `n`. Put the pin there and a hole arrives under
 * it at the end of every stroke without exception. Put it anywhere else and it engages on
 * some strokes and not others.
 *
 * At the die's start position that angle is just past the trailing edge of its arc, so at
 * the beginning of a bend the pin is over air. Correct: a straight tube has nothing to
 * spring back, and the die rotates into the pin during the first stroke.
 *
 * ## The frame link's angle is the wrong place, and the reason is worth keeping
 *
 * The obvious place is on the frame link's own axis, where there is already material. It
 * does not work, and not because of the phase - **because the die is not there.** The
 * frame link points at the followbar, which is off the die's arc at the start; the die's
 * sector only rotates over that angle in the last 45 degrees of the bend. Phasing the holes
 * to a pin at the frame link's axis locks the last two strokes of five and no others.
 *
 * The die's holes cover a window of only `(n-1) x pitch` in the die's own frame, and the
 * bend is longer than that window, so WHERE the pin sits decides which strokes it catches.
 * There is exactly one angle that catches all of them and the formula above is it.
 *
 * So the frame link grows a second arm to reach it. That is cheap - the same plate, one
 * more lobe off the same pivot - and the arm never has to clear anything, because it lives
 * in the frame links' own z bands. Only the PIN crosses the drive links' plane, and only
 * the pin needs the angular clearance below.
 *
 * ## Clearance
 *
 * The drive link's band must miss the pin by the link's half-width at the pin's radius plus
 * the pin's own. The separation is `n x pitch` by construction, which is most of a circle,
 * so this is a check rather than a constraint that shapes anything - but it is checked in
 * both directions round the circle, because a wide link on a small drive circle eats
 * angle fast.
 *
 * ## It goes all the way through
 *
 * Not a plunger hanging off the upper frame link. The angular exclusion holds at every
 * radius, so both drive links are clear of it and the pin can run the whole stack - upper
 * frame link to lower - as a symmetric double-shear joint like the frame pin.
 *
 * That is not tidiness, it is two pin sizes. Cantilevered off one link the span is from
 * that link's mid-plane to the die's, 39 mm at 1-1/2 in, and it wants 1-1/8 in. Through the
 * stack the span is the standard `(t_centre + t_outer) / 2` and it wants 7/8. A 1-1/8 in
 * spring plunger is not a plunger.
 *
 * The cost is that it is inserted and pulled by hand like the drive pin, where JD2's drops
 * in by itself. A spring collar over the through pin would get that back and is a fitting,
 * not a load path, so it is not modelled.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;

use <../purchased/pin.scad>
use <../purchased/plate.scad>
use <forming_die.scad>

include <../utils/bend.scad>;
include <../utils/pin_sizing.scad>;   // pin_allowable_bending_fraction is a variable

//! Radius the lock pin engages at, mm - the die's drive circle, because it drops into the
//! drive holes. Its own ring of holes was the alternative and buys nothing: the drive
//! circle is already as large as the die's material allows, which is where a lock wants to
//! be too, and a second ring is more holes in the same annulus.
function die_lock_radius(tube, clr, drive_pin_d) =
    forming_die_drive_radius(tube, clr, drive_pin_d);

//! Angle, degrees, the drive link's band must clear the lock pin by: the link's own
//! half-width at that radius, plus the pin's with a web either side of it.
function die_lock_clearance_deg(drive_link_w, lock_pin_d, web, radius) =
    bend_angular_half_width(drive_link_w, radius)
        + bend_angular_half_width(lock_pin_d + 2 * web, radius);

//! The lock pin's world angle, degrees: one pitch past the last drive hole, at the die's
//! start position. See the header - this is the only angle a hole reaches at the end of
//! every stroke, and it is exact.
function die_lock_angle_deg(inset_deg, pitch_deg, n_holes) =
    inset_deg + n_holes * pitch_deg;

//! Where the lock pin sits, [x, y] mm, in the frame everything else is drawn in.
function die_lock_pos(tube, clr, drive_pin_d, inset_deg, pitch_deg, n_holes) =
    let (r = die_lock_radius(tube, clr, drive_pin_d),
         a = die_lock_angle_deg(inset_deg, pitch_deg, n_holes))
        r * [cos(a), sin(a)];

//! Separation, degrees, between the stroke's home angle and the lock pin. The first stroke
//! begins with the drive pin in hole 0, at the inset, so this is just `n x pitch`.
function die_lock_separation_deg(pitch_deg, n_holes) = n_holes * pitch_deg;

//! Bending moment the lock arm carries at the pivot, N.mm, per link.
//!
//! The lock holds the die against springback, so the whole moment comes back through it
//! and out to the frame: `F x r` is the moment itself, shared by the two links. Sized on
//! the tube's fully plastic moment, which is the most the tube can be holding.
function die_lock_arm_moment_Nmm(moment_Nm) = moment_Nm * 1000 / 2;

//! Width the lock arm needs at the pivot, mm, on a net section through the pivot bore.
function die_lock_arm_width(moment_Nm, plate_t, fb_MPa, pivot_hole_d) =
    plate_width_for_moment(die_lock_arm_moment_Nmm(moment_Nm), plate_t, fb_MPa,
                           pivot_hole_d);

//! Everything the lock cannot do, named. Empty means nothing was violated.
function die_lock_departures(pitch_deg, n_holes, separation_deg, clearance_deg,
                             arm_width_mm, link_width_mm) = [
    // A die with no drive holes simply has no lock, the way it has no drive pin. That is
    // what the size IS, not a band it falls outside, and die_lock_report() says so in as
    // many words - so it is not listed here.
    if (n_holes > 0 && separation_deg < clearance_deg)
        str("the drive link's band reaches the lock pin - ", round(clearance_deg),
            " deg of clearance wanted against ", round(separation_deg), " deg of separation"),
    if (n_holes > 0 && separation_deg + pitch_deg + clearance_deg > 360)
        str("the drive band comes back round onto the lock pin - ",
            round(separation_deg + pitch_deg + clearance_deg), " deg of circle wanted"),
    if (n_holes > 0 && arm_width_mm > link_width_mm)
        str("the lock arm needs ", round(arm_width_mm),
            " mm of width and the frame link is only ", round(link_width_mm)),
];

//! Echo where the lock ends up and what it rests on.
module die_lock_report(tube, clr, drive_pin_d, lock_pin, drive_link_w, web, pitch_deg,
                       inset_deg, n_holes, moment_Nm, plate, link_w) {
    r     = die_lock_radius(tube, clr, drive_pin_d);
    a     = die_lock_angle_deg(inset_deg, pitch_deg, n_holes);
    clear = die_lock_clearance_deg(drive_link_w, pin_diameter(lock_pin), web, r);
    sep   = die_lock_separation_deg(pitch_deg, n_holes);
    arm   = die_lock_arm_width(moment_Nm, plate_thickness(plate),
                               pin_allowable_bending_fraction * plate_yield(plate),
                               pin_pivot_hole(pin_diameter(lock_pin)));

    if (n_holes == 0) {
        echo("die lock: none - this die has no drive holes to lock into");
    } else {
        echo(str("die lock: ", pin_size(lock_pin), " pin through the whole stack on r ",
                 round(r), " mm at ", round(a), " deg - one pitch past the last drive hole,",
                 " so a hole reaches it at the end of all ", n_holes, " strokes"));
        echo(str("          on its own arm off the frame link, ", round(arm),
                 " mm wide for ", round(die_lock_arm_moment_Nmm(moment_Nm) / 1000),
                 " N.m per link, drawn at the link's ", round(link_w)));
        echo(str("          the drive band must clear it by ", round(clear),
                 " deg and stands ", sep, " deg = ", n_holes, " pitches off"));
    }
}
