/**
 * @file forming_die.scad
 * @brief The part the tube bends around: a grooved disc segment with a tangent clamp tail
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description One machined part. The roadmap has it decomposed into stacked flat-cut
 * plates so it can be made without a mill, and that decomposition wants doing properly
 * rather than as a slicing afterthought - see docs/design-basis.md section 9.
 *
 * ## Frame
 *
 * The die pivots on the origin and its MID-PLANE IS z = 0, so the tube centreline is at
 * z = 0 throughout the machine. The tube's straight leg comes in along -y at x = CLR,
 * meets the die at (CLR, 0), and the bend runs counter-clockwise from there. The tail
 * that carries the clamp is therefore at negative y, and its end face - at y = -clamp
 * length - is the flat the tube is scribed against when a bend is set up [JD2-M32 p.9].
 *
 * ## What sets each dimension
 *
 * - **thickness** is the tube OD plus a land above and below the groove. The land is not
 *   decoration: a groove of exactly OD/2 in a die of exactly OD comes to a feather edge
 *   at both faces.
 * - **outer radius** is the CLR exactly. It cannot be more - the tube's own outer surface
 *   is at CLR + OD/2 and the followbar has to reach it - and it cannot be less or the
 *   groove would be cut away.
 * - **arc** is the bend angle plus the overbend the tube springs back through.
 * - **tail length** is the clamp's grip length, 2 x OD for a smooth cavity.
 * - **drive circle** is as large as the material between the groove root and the hole
 *   allows, because the whole drive torque goes through one pin.
 * - **tail depth** is the groove and a web behind it, and nothing else. It used to clear a
 *   U-strap pin that the die has not carried since the clamp moved to the die plates.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;

use <../purchased/tube.scad>
use <../purchased/pin.scad>

// INCLUDE, not use. `use` brings a file's modules and functions but NOT its variables, so
// a file that only `use`s these gets undef for every constant they declare - and undef
// propagates silently through arithmetic. Both of these carry constants this file reads:
// `plates` behind plate_smallest_at_least(), and bend_overbend_degrees behind the arc.
include <../purchased/plates.scad>;
include <../utils/bend.scad>;

//
// Allowances. All three are machining judgement rather than derived quantities, and all
// three are marked as such.
//

//! Flat rim left above and below the groove, so the groove does not come to a feather
//! edge at the die's faces.
//!
//! REASONED, NOT CITED: 1/8 in. No source read gives a land. An eighth is about the
//! smallest edge worth breaking on a part this size, and it makes the die exactly a
//! quarter inch thicker than the tube - which, because tube ODs step in eighths, lands
//! every die in this machine's range on a stock plate thickness. That is a happy
//! coincidence rather than a reason, but it is why this number rather than 3 mm.
die_rim_land = inch(1/8);

//! Material left between a hole and the nearest edge or groove.
//!
//! REASONED, NOT CITED: a quarter of the tube OD, floored at 3 mm. The floor is about the
//! thinnest web worth machining and hoping to keep; the quarter scales it so a 2 in die
//! does not get a 3 mm web.
function die_web(tube) = max(3, tube_od(tube) / 4);

//! Angular pitch of the drive holes. The drive pin is moved to the next hole each time
//! the drive link runs out of swing, so this SHOULD equal that swing - which the frame
//! sets, not the die. Until the frame exists it is the prototype's 36 degrees, and the
//! frame will report a departure if the two disagree.
die_drive_hole_pitch = 36;

//! The same, reachable across a `use` boundary - a variable is not.
function forming_die_drive_pitch() = die_drive_hole_pitch;

//
// Derived geometry. Every consumer reads these rather than recomputing them.
//

//! Radius of the groove, mm. The allowance is where a production die's profile would go:
//! JD2 states plainly that the tube does not fully seat in a real forming die, and that it
//! matters more as the wall gets thinner [JD2-M32 p.4].
//!
//! Default 0 - a true half-round. NO SOURCE READ GIVES THE PROFILE. A claim that the part
//! line sits on the tube centreline with the bend die holding 50 % and the clamp and
//! pressure dies somewhat less was cited here from a search summary; the page it was
//! attributed to does not contain it, and it is withdrawn rather than re-attributed. An
//! invented curve here would sit in the load path looking like a derived one.
die_groove_allowance = 0;

function forming_die_groove_radius(tube) = tube_od(tube) / 2 + die_groove_allowance;

//! Thickness, mm.
function forming_die_thickness(tube) =
    tube_od(tube) + 2 * die_rim_land;

//! Outer radius, mm - the same as the CLR, and not a free choice.
function forming_die_outer_radius(clr) = clr;

//! Radius of the deepest point of the groove, mm. Everything that has to stay inside the
//! die's material is measured against this, not against the outer radius.
function forming_die_root_radius(tube, clr) = clr - forming_die_groove_radius(tube);

//! Total swept angle of the groove, degrees: the bend plus its overbend.
function forming_die_arc(bend_angle) = bend_angle + bend_overbend_degrees;

//! Length of the tangent tail, mm - the clamp's grip length.
function forming_die_tail_length(tube, clr) = bend_clamp_length(tube, clr);

//! Radius of the hub around the pivot, mm.
//!
//! The die's sector alone does NOT enclose its own pivot. The apex of a sector is a
//! corner, so a bore drilled there is only as enclosed as the sector is wide - a 185
//! degree die leaves 175 degrees of that bore open to air, and the first render showed
//! exactly that: a half-round slot where the pivot should be. Every real die carries a
//! full hub. This is it.
function forming_die_hub_radius(tube, frame_pin_d) =
    pin_pivot_hole(frame_pin_d) / 2 + die_web(tube);

//! Radial depth of the tail, mm: the groove, and a web behind it.
//!
//! It used to carry a U-strap pin as well, from the design that pinned the clamp INTO the
//! die's tail. That design does not exist any more - §15 of the design basis works through
//! why the clamp cannot reach the die at all, and it is pinned to the die plates instead,
//! whose tails overhang the tube where nothing else can.
//!
//! The pin went, the hole in the die did not. It stayed drilled through the tail with
//! nothing to put in it, and the tail stayed sized to clear it: 63.5 mm deep at 1-1/2 in
//! where 28.6 carries the groove. Same fault as the drive link that drew a hole for a die
//! with no drive holes, found the same way - by asking what mates with what.
function forming_die_tail_depth(tube) =
    forming_die_groove_radius(tube) + die_web(tube);

//! Largest drive circle the material allows, mm: the hole and its web have to stay inside
//! the groove root.
function forming_die_drive_radius(tube, clr, drive_pin_d) =
    forming_die_root_radius(tube, clr) - die_web(tube) - pin_index_hole(drive_pin_d) / 2;

//! Smallest drive circle the centre bore allows, mm.
function forming_die_drive_radius_min(tube, frame_pin_d, drive_pin_d) =
    pin_pivot_hole(frame_pin_d) / 2 + die_web(tube) + pin_index_hole(drive_pin_d) / 2;

//! Whether there is any annulus at all for drive holes. JD2 reaches the same conclusion
//! by hand - "die sets with a radius smaller than 3 in will generally not have drive holes
//! because there is no room to drill them" [JD2-M32 p.4] - but their pins are one size for
//! the whole 1/2 to 2 in range, so their cutoff is not ours. This derives it.
function forming_die_has_drive_holes(tube, clr, frame_pin_d, drive_pin_d) =
    forming_die_drive_radius(tube, clr, drive_pin_d)
        >= forming_die_drive_radius_min(tube, frame_pin_d, drive_pin_d);

//! Angle a drive hole must be inset from the die's radial edges to keep its web, degrees.
function forming_die_drive_inset(tube, clr, drive_pin_d) =
    let (r = forming_die_drive_radius(tube, clr, drive_pin_d),
         clearance = pin_index_hole(drive_pin_d) / 2 + die_web(tube))
        clearance >= r ? 90 : asin(clearance / r);

//! The angles the drive holes sit at, degrees, or an empty list where none fit.
function forming_die_drive_angles(tube, clr, frame_pin_d, drive_pin_d, bend_angle) =
    let (inset = forming_die_drive_inset(tube, clr, drive_pin_d),
         span  = forming_die_arc(bend_angle) - 2 * inset)
        !forming_die_has_drive_holes(tube, clr, frame_pin_d, drive_pin_d) || span < 0
            ? []
            : [for (i = [0 : floor(span / die_drive_hole_pitch)])
                   inset + i * die_drive_hole_pitch];

//! The plate the die is machined from, or `undef` if nothing in the registry is thick
//! enough. Faced to thickness afterwards - stock does not step in eighths above an inch.
function forming_die_blank(tube) = plate_smallest_at_least(forming_die_thickness(tube));

//! Plan size of the blank, [x, y] mm, before anything is cut off it.
function forming_die_blank_plan(tube, clr) =
    [2 * clr, clr + forming_die_tail_length(tube, clr)];

//
// Geometry.
//

// The die's plan outline: a sector from the pivot out to the CLR, the hub that encloses
// the pivot, and the tangent tail that carries the clamp.
module forming_die_outline(tube, clr, bend_angle, frame_pin_d) {
    arc   = forming_die_arc(bend_angle);
    depth = forming_die_tail_depth(tube);
    lc    = forming_die_tail_length(tube, clr);
    steps = max(8, ceil(arc / 3));

    // offset(0) is not decoration. Three regions meet along the seam at y = 0, and the
    // union leaves degenerate vertices there; extruding that and cutting the groove
    // across it gives CGAL a mesh it calls not closed and refuses to render. Clipper
    // merges the seam and the same model builds. Removing this brings the failure back.
    offset(0)
        union() {
            polygon([[0, 0],
                     for (i = [0 : steps]) let (a = arc * i / steps) clr * [cos(a), sin(a)]]);

            circle(r = forming_die_hub_radius(tube, frame_pin_d));

            translate([clr - depth, -lc])
                square([depth, lc]);
        }
}

//! The forming die. `bend_angle` is the bend it has to be able to make, before overbend.
//! Tapping drill for a bolt threaded into the die, mm. 85 % of nominal is the usual
//! approximation for a 75 % thread in steel; a real tap chart beats it and the difference
//! does not reach any other dimension here.
function forming_die_tap_drill(bolt_d) = 0.85 * bolt_d;

//! The forming die. `plate_bolts` are the positions the die plates screw into, passed in
//! rather than derived here because the plates are derived FROM the die and a file cannot
//! read the file that reads it.
module forming_die(tube, clr, bend_angle = 180,
                   frame_pin_d, drive_pin_d,
                   plate_bolts = [], plate_bolt_d = 0) {
    t      = forming_die_thickness(tube);
    gr     = forming_die_groove_radius(tube);
    arc    = forming_die_arc(bend_angle);
    lc     = forming_die_tail_length(tube, clr);
    drives = forming_die_drive_angles(tube, clr, frame_pin_d, drive_pin_d, bend_angle);
    r_drv  = forming_die_drive_radius(tube, clr, drive_pin_d);

    assert(clr > gr + die_web(tube),
           "forming die: the groove would cut through the pivot - CLR is too small for this tube");
    assert(!is_undef(forming_die_blank(tube)),
           "forming die: no registered plate is thick enough for this blank");
    assert(forming_die_hub_radius(tube, frame_pin_d)
               < forming_die_root_radius(tube, clr) - die_web(tube),
           "forming die: the pivot hub reaches the groove - the frame pin is too big for this die");
    assert(forming_die_tail_depth(tube) < clr,
           "forming die: the tail is deeper than the die's radius - the groove would cut past the pivot");

    // The BOM has to say what to BUY, not only what to make. NopSCADlib files the .stl
    // under "Printed" because those are its only two categories for a made part; this die
    // is machined, and the line below is the stock it is machined from.
    blank = forming_die_blank(tube);
    plan  = forming_die_blank_plan(tube, clr);
    vitamin(str("forming_die_blank(", plate_name(blank), "): ", plate_description(blank),
                " ", plate_size(blank), ", blank ", round(plan[0]), "mm x ", round(plan[1]),
                "mm, faced to ", t, "mm"));

    difference() {
        linear_extrude(t, center = true)
            forming_die_outline(tube, clr, bend_angle, frame_pin_d);

        // The groove, round the bend and on down the tail.
        rotate_extrude(angle = arc)
            translate([clr, 0])
                circle(r = gr);

        translate([clr, -lc - eps, 0])
            rotate([-90, 0, 0])
                cylinder(r = gr, h = lc + 2 * eps);

        // The pivot the whole machine turns on.
        cylinder(d = pin_pivot_hole(frame_pin_d), h = t + 2 * eps, center = true);

        // Drive holes, deliberately loose - the pin is repositioned by hand mid-bend.
        for (a = drives)
            rotate(a)
                translate([r_drv, 0])
                    cylinder(d = pin_index_hole(drive_pin_d), h = t + 2 * eps, center = true);

        // Tapped through for the die plates, one from each face.
        for (p = plate_bolts)
            translate(p)
                cylinder(d = forming_die_tap_drill(plate_bolt_d), h = t + 2 * eps,
                         center = true);
    }
}

//! Echo what the die comes out as, before it is drawn.
module forming_die_report(tube, clr, bend_angle, frame_pin_d, drive_pin_d) {
    blank  = forming_die_blank(tube);
    drives = forming_die_drive_angles(tube, clr, frame_pin_d, drive_pin_d, bend_angle);
    r_drv  = forming_die_drive_radius(tube, clr, drive_pin_d);
    plan   = forming_die_blank_plan(tube, clr);
    force  = bend_drive_pin_force_N(bend_plastic_moment_Nm(tube), r_drv);

    echo(str("die:     radius ", clr, " mm x ", forming_die_thickness(tube),
             " thick, ", forming_die_arc(bend_angle), " deg of groove"));
    echo(str("         groove r ", forming_die_groove_radius(tube), " mm, root at ",
             forming_die_root_radius(tube, clr), " mm, tail ",
             forming_die_tail_length(tube, clr), " mm long"));
    echo(str("         clamp grips ", bend_clamp_length(tube, clr), " mm = ",
             bend_clamp_length(tube, clr) / tube_od(tube), " x OD, smooth cavity"));
    echo(str("blank:   ", is_undef(blank) ? "NONE THICK ENOUGH IN THE REGISTRY"
                                          : str(plate_size(blank), " plate, ",
                                                round(plan[0]), " x ", round(plan[1]), " mm")));

    if (len(drives))
        echo(str("drive:   ", len(drives), " holes on r ", r_drv, " mm at ",
                 die_drive_hole_pitch, " deg pitch, ", round(force), " N on the pin"));
    else
        echo(str("drive:   no room for drive holes - needs r ",
                 forming_die_drive_radius_min(tube, frame_pin_d, drive_pin_d),
                 " mm, the groove root only allows ", r_drv,
                 " mm. Drive on the U-strap pin, as JD2 does for small dies."));
}
