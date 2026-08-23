/**
 * @file frame_link.scad
 * @brief The plate that holds still: pivot, followbar, base
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description A pair of these are the outermost layers of the stack. They carry the frame
 * pin that the die and the drive links turn on, they hold the followbar out against the
 * tube, and they are what the base bolts to.
 *
 * ## The load
 *
 * The followbar pushes the tube towards the die; the tube pushes back, and that reaction
 * runs out to the end of this link. Treated here as a cantilever from the pivot, which is
 * conservative: the base takes some of it, but where the base grabs is not decided yet and
 * a link sized as a cantilever cannot be made worse by adding a support.
 *
 * ## Why it can run straight over the die
 *
 * It sits a plate's thickness clear of the die and the tube in z, so it needs no radial
 * clearance from either and the shortest path from the pivot to the followbar is a
 * straight bar. The prototype dog-legs instead; nothing found requires that.
 *
 * ## It carries no bolts of its own
 *
 * The pair is already joined at both ends - by the frame pin at the pivot and the
 * followbar pin at the far end - so a separate pair of frame bolts would be a third
 * fixing on a two-point member. It was tried: sized to react the drive torque into the
 * base they wanted a span the link does not have. At 1/8 in the whole link is 22 mm long
 * and the required span came out NEGATIVE; at 2 in it wanted a bolt bigger than the
 * series carries. The load path was wrong, not the bolts.
 *
 * The lower link is welded to the base plate instead, and the torque leaves through four
 * anchor bolts at the base's corners - four bolts on a wide rectangle rather than two on
 * a narrow one, which divides the shear by four and doubles the arm at the same time.
 *
 * ## It carries the die lock, on a second arm
 *
 * A pin at the die's drive radius drops into a drive hole and holds the die while the
 * drive pin is out. die_lock.scad derives where it has to be - one pitch past the last
 * drive hole - and that is nowhere near the followbar, so this link grows a SECOND ARM off
 * the same pivot to reach it.
 *
 * The two arms carry unrelated loads and neither helps the other: the followbar arm reacts
 * the tube's push as a cantilever, the lock arm reacts the springback moment back into the
 * frame. Both are drawn at this link's one width, which the followbar sizes and which the
 * report checks against what the lock arm needs.
 *
 * The arm itself never has to clear anything - it lives in the frame links' own z bands,
 * clear of the die and the drive links the same way the followbar arm already runs
 * straight over the die. Only the PIN crosses the drive links' plane, and die_lock.scad
 * checks that angle.
 *
 * The position arrives as an argument rather than being derived here: it depends on the
 * die's hole count and phase, and a link cannot read the die it is being placed against.
 *
 * ## What is not here
 *
 * The followbar itself, declared as an interface and left.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;

use <../purchased/bolt.scad>
use <../purchased/pin.scad>
use <../purchased/plate.scad>
use <followbar.scad>

include <../utils/bend.scad>;
include <../utils/pin_sizing.scad>;   // pin_allowable_bending_fraction is a variable, so include

//! Where the followbar's pin sits, [x, y] mm. Outboard of the tube, downstream of the
//! die's tail by the followbar's station.
//!
//! The outboard offset used to be a placeholder - one tube diameter, on the prototype's
//! precedent - because the followbar did not exist to derive it from. It does now, and it
//! puts the pin 19 mm closer in than the guess did, which shortens this link's reach and
//! with it the moment it carries.
function frame_link_followbar_pos(tube, clr, followbar_pin_d) =
    [clr + followbar_pin_offset(tube, followbar_pin_d),
     -bend_followbar_station(tube, clr)];

//! Distance from the pivot to the followbar's pin, mm - the link's lever arm.
function frame_link_reach(tube, clr, followbar_pin_d) = norm(frame_link_followbar_pos(tube, clr, followbar_pin_d));

//! Peak bending moment in ONE link, N.mm, taken at the pivot.
function frame_link_moment_Nmm(tube, clr, moment_Nm, followbar_pin_d) =
    bend_followbar_force_N(moment_Nm, bend_followbar_station(tube, clr))
        * frame_link_reach(tube, clr, followbar_pin_d) / 2;

//! Width of the link, mm.
function frame_link_width(tube, clr, plate, moment_Nm, frame_pin_d, followbar_pin_d) =
    let (hole = pin_pivot_hole(frame_pin_d),
         fb   = pin_allowable_bending_fraction * plate_yield(plate),
         wb   = plate_width_for_moment(frame_link_moment_Nmm(tube, clr, moment_Nm, followbar_pin_d),
                                       plate_thickness(plate), fb, hole))
        max(wb,
            2 * plate_eye_radius(hole),
            2 * plate_eye_radius(pin_pivot_hole(followbar_pin_d)));

//! Unit vector from the pivot towards the followbar - the axis the link lies on.
function frame_link_axis(tube, clr, followbar_pin_d) =
    frame_link_followbar_pos(tube, clr, followbar_pin_d) / frame_link_reach(tube, clr, followbar_pin_d);

//! One frame link, lying on z = 0, pivot at the origin. `lock_pos` is where the die lock
//! pin passes through, in this link's own frame - which is the world's, because the frame
//! links are the parts that do not turn. Undef on a die with no drive holes to lock into.
module frame_link(tube, clr, plate, moment_Nm, frame_pin_d, followbar_pin_d,
                  lock_pos = undef, lock_pin_d = 0) {
    w    = frame_link_width(tube, clr, plate, moment_Nm, frame_pin_d, followbar_pin_d);
    fb   = frame_link_followbar_pos(tube, clr, followbar_pin_d);
    axis = frame_link_axis(tube, clr, followbar_pin_d);
    lock = !is_undef(lock_pos);

    render_2D_plate(plate)
      plate_2D(plate,
               (lock ? abs(fb[0]) + abs(lock_pos[0]) : abs(fb[0])) + w,
               (lock ? abs(fb[1]) + abs(lock_pos[1]) : abs(fb[1])) + w)
        offset(0)
            difference() {
                union() {
                    hull() {
                        circle(d = w);
                        translate(fb) circle(d = w);
                    }

                    if (lock)
                        hull() {
                            circle(d = w);
                            translate(lock_pos) circle(d = w);
                        }
                }

                circle(d = pin_pivot_hole(frame_pin_d));

                translate(fb)
                    circle(d = pin_pivot_hole(followbar_pin_d));

                if (lock)
                    translate(lock_pos) circle(d = pin_pivot_hole(lock_pin_d));
            }
}

//! Echo what the link comes out as.
module frame_link_report(tube, clr, plate, moment_Nm, frame_pin_d, followbar_pin_d) {
    w  = frame_link_width(tube, clr, plate, moment_Nm, frame_pin_d, followbar_pin_d);
    fb = frame_link_followbar_pos(tube, clr, followbar_pin_d);
    p  = bend_followbar_force_N(moment_Nm, bend_followbar_station(tube, clr));

    echo(str("frame link: ", plate_size(plate), " plate, ", w, " mm wide, reach ",
             frame_link_reach(tube, clr, followbar_pin_d), " mm"));
    echo(str("            followbar pin at [", fb[0], ", ", fb[1], "] mm, ",
             round(p), " N on it, station ", bend_followbar_station(tube, clr),
             " mm downstream"));
    echo(str("            peak moment ", round(frame_link_moment_Nmm(tube, clr, moment_Nm, followbar_pin_d) / 1000),
             " N.m per link at the pivot, as a cantilever"));
}
