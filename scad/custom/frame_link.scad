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

use <../utils/units.scad>
use <../purchased/bolt.scad>
use <../purchased/pin.scad>
use <../purchased/plate.scad>
use <followbar.scad>
use <forming_die.scad>   // die_web(), the web the tie gap reuses

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

//! Every point the link's outline has to reach: the pivot, the followbar, the die lock if
//! there is one, and the ties. In this link's own frame, which IS the world's.
function frame_link_points(tube, clr, followbar_pin_d, lock_pos = undef, tie_pos = []) =
    concat([[0, 0], frame_link_followbar_pos(tube, clr, followbar_pin_d)],
           is_undef(lock_pos) ? [] : [lock_pos],
           tie_pos);

//! Bounding box of the finished link, [[x0, y0], [x1, y1]] mm - every arm, plus half a
//! width all round because each arm ends in a round eye of that diameter.
//!
//! The base plate is cut from this. It is what the lower link is WELDED to, so it has to
//! cover the link rather than a rectangle drawn round the followbar arm when that was the
//! only arm there was.
function frame_link_extents(tube, clr, plate, moment_Nm, frame_pin_d, followbar_pin_d,
                            lock_pos = undef, tie_pos = []) =
    let (w  = frame_link_width(tube, clr, plate, moment_Nm, frame_pin_d, followbar_pin_d),
         ps = frame_link_points(tube, clr, followbar_pin_d, lock_pos, tie_pos),
         xs = [for (q = ps) q[0]],
         ys = [for (q = ps) q[1]])
        [[min(xs) - w / 2, min(ys) - w / 2], [max(xs) + w / 2, max(ys) + w / 2]];

//
// THE FRAME TIES
//
// A pair of bolts, each through a spacer tube, holding the two frame links at a fixed gap.
// See docs/design-basis.md section 23 for why they exist; in one line, without them the
// frame is not a frame - it is two plates resting on three loose pins, and pulling one to
// change a die takes the top one off with it.
//

//! Radial gap left between anything that turns and a tie, mm. `die_web()` reused: it is the
//! same kind of quantity - how much room to leave beside something - and it scales with the
//! tube the way everything else here does.
function frame_link_tie_gap(tube) = die_web(tube);

//! The angular window behind the die that nothing ever enters, [start, end] degrees.
//!
//! Three things sweep or sit in the space between the frame links, and all three start at
//! the front of the machine, so they merge into ONE blocked band containing zero:
//!
//! - the die plate's tail, which occupies `tail_angles` and carries that through the die's
//!   whole `rotation_deg`;
//! - the drive links, whose material covers their swing plus their own half-width;
//! - the followbar, which does not move but is a big block and reaches further round than
//!   the tail does.
//!
//! What is left is the arc from the far end of that band round to its near end, and that is
//! where a tie can go. It comes out between 125 and 190 degrees wide across the whole size
//! range - a lot more room than it sounds like it should be.
function frame_link_tie_window(tail_angles, rotation_deg, drive_band, followbar_angles) =
    [max(rotation_deg + tail_angles[1], drive_band[1], followbar_angles[1]),
     360 + min(tail_angles[0], drive_band[0], followbar_angles[0])];

//! Radius the ties sit on, mm - clear of the die and its plates, by a web.
//!
//! The die's body and its plates' sectors are both the CLR, and the tail never comes round
//! here, so the CLR is what has to be cleared rather than the much larger circle the tail
//! sweeps.
function frame_link_tie_radius(tube, clr, spacer_od) =
    clr + frame_link_tie_gap(tube) + spacer_od / 2;

//! Where the ties go, as angles in degrees: two of them, one, or `[]` if the window will not
//! take even one.
//!
//! Placed symmetrically about the middle of the window and pushed as far apart as it allows,
//! because a tie is worth what its lever arm is worth. Not at the window's edges: each keeps
//! its own half-width plus a web off the boundary, so a tie is never the thing a passing
//! tail has to miss by a hair.
//!
//! ONE where two will not fit apart. On a die with no drive holes the link swings the whole
//! arc rather than one pitch, so the window is a third of what it is elsewhere, and pushing
//! a pair as far apart as that allows puts them a millimetre from each other - which is not
//! two fastenings, it is one slot. A single tie still holds the plate down, which is the job;
//! what it gives up is resisting rotation about itself, and the frame pin does that anyway.
function frame_link_tie_angles(window, radius_mm, spacer_od, gap_mm) =
    let (across = spacer_od + 2 * gap_mm,
         hw     = bend_angular_half_width(across, radius_mm),
         mid    = (window[0] + window[1]) / 2,
         half   = (window[1] - window[0]) / 2 - hw,
         chord  = 2 * radius_mm * sin(half))
        half <= 0      ? []
      : chord < across ? [mid]
      :                  [mid - half, mid + half];

//! Those angles as [x, y] positions, mm.
function frame_link_tie_positions(angles, radius_mm) =
    [for (a = angles) radius_mm * [cos(a), sin(a)]];

//! Straight-line distance between the two ties, mm - what the pair is actually worth.
//!
//! Two ties an inch apart are one fastening with two bolts in it: they hold the plate down
//! but they cannot stop it turning about the line between them. The window is wide at every
//! size that has drive holes and narrow at the two that do not, so this is the number to
//! look at rather than the count.
function frame_link_tie_chord(angles, radius_mm) =
    len(angles) < 2 ? 0 : 2 * radius_mm * sin((angles[1] - angles[0]) / 2);

//! Tension in each tie, N.
//!
//! The load is the handle's own weight trying to lift the drive pair's tail off the upper
//! frame link - see drive_link_overhang_lift_N(). Shared equally, which is the conservative
//! reading: the pins take some of it and are not counted on for any.
function frame_link_tie_load_N(lift_N, n_ties) = n_ties == 0 ? 0 : lift_N / n_ties;

//! Diameter a tie needs to carry that in tension, mm.
function frame_link_tie_diameter(load_N, yield_MPa) =
    sqrt(4 * load_N / (PI * pin_allowable_bending_fraction * yield_MPa));

//! The profile one frame link is cut from, on z = 0 with the pivot at the origin.
//! `lock_pos` is where the die lock pin passes through, and `tie_pos` is where the frame
//! ties do - both in this link's own frame, which IS the world's, because the frame links
//! are the parts that do not turn. `lock_pos` is undef on a die with no drive holes to lock
//! into; `tie_pos` is an empty list where the window behind the die will not take ties.
module frame_link_2D(tube, clr, plate, moment_Nm, frame_pin_d, followbar_pin_d,
                     lock_pos = undef, lock_pin_d = 0, tie_pos = [], tie_bolt_d = 0) {
    w    = frame_link_width(tube, clr, plate, moment_Nm, frame_pin_d, followbar_pin_d);
    fb   = frame_link_followbar_pos(tube, clr, followbar_pin_d);
    lock = !is_undef(lock_pos);
    // The real span, from the same point list the base plate is cut from - not a sum of
    // magnitudes that happened to be right while there were only two arms.
    ext  = frame_link_extents(tube, clr, plate, moment_Nm, frame_pin_d, followbar_pin_d,
                              lock_pos, tie_pos);

    plate_2D(plate, ext[1][0] - ext[0][0], ext[1][1] - ext[0][1])
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

                    // One arm per tie, off the same pivot, the way the lock arm is. They
                    // reach into the window behind the die, where the lock arm already
                    // points, so on most sizes the three merge into one lobe.
                    for (t = tie_pos)
                        hull() {
                            circle(d = w);
                            translate(t) circle(d = w);
                        }
                }

                circle(d = pin_pivot_hole(frame_pin_d));

                translate(fb)
                    circle(d = pin_pivot_hole(followbar_pin_d));

                if (lock)
                    translate(lock_pos) circle(d = pin_pivot_hole(lock_pin_d));

                for (t = tie_pos)
                    translate(t) circle(d = bolt_clearance_hole_d(tie_bolt_d));
            }
}

//! Echo what the link comes out as.
module frame_link_report(tube, clr, plate, moment_Nm, frame_pin_d, followbar_pin_d) {
    w  = frame_link_width(tube, clr, plate, moment_Nm, frame_pin_d, followbar_pin_d);
    fb = frame_link_followbar_pos(tube, clr, followbar_pin_d);
    p  = bend_followbar_force_N(moment_Nm, bend_followbar_station(tube, clr));

    echo(str("frame link: ", plate_size(plate), " plate, ", fmt_length(w), " wide, reach ",
             fmt_length(frame_link_reach(tube, clr, followbar_pin_d))));
    // A coordinate pair, so the unit goes once on the outside.
    echo(str("            followbar pin at [", fmt_bare_length(fb[0]), ", ",
             fmt_bare_length(fb[1]), "] ", fmt_length_unit(), ", ", fmt_force(p),
             " on it, station ", fmt_length(bend_followbar_station(tube, clr)),
             " downstream"));
    echo(str("            peak moment ",
             fmt_moment(frame_link_moment_Nmm(tube, clr, moment_Nm, followbar_pin_d) / 1000),
             " per link at the pivot, as a cantilever"));
}
