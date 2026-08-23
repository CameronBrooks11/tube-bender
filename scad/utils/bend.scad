/**
 * @file bend.scad
 * @brief What a tube and a die imply: bendability ratios, drive torque, handle, anchorage
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description Nothing in this file draws anything. It is the arithmetic that decides
 * whether a configuration is a machine or a wish, and it is meant to be read before any
 * geometry exists - see docs/design-basis.md.
 *
 * Every quantity here is reported, and the ones that sit outside a published band are
 * NAMED rather than reduced to a boolean, because a configuration that is out on one
 * count is a different thing from one that is out on three and a caller that only learns
 * `false` cannot tell them apart.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;
include <pin_sizing.scad>;   // the allowable fractions are variables

use <../purchased/tube.scad>
use <../purchased/tube_material.scad>
use <clr_catalogue.scad>

//
// Design ceilings. Each one is a citation, not a preference.
//

//! Largest horizontal pull a designer may require of a braced operator using both hands,
//! FAA HFDS 2003 (amended 2009) Exhibit 14.5.3.1, from MIL-HDBK-759B. With ordinary
//! traction rather than a braced stance the same table gives 200-310 N.
bend_operator_force_ceiling = 490;

//! Minimum centreline radius, as a multiple of tube OD, for bending without an internal
//! mandrel. The industry rule of thumb; below 2 D a mandrel is generally required.
bend_min_d_of_bend = 3;

//! The OD band in which a manual machine is the right answer. The lower end is where the
//! Swagelok hand bender starts, the upper is where both reference manual benders stop and
//! where the derived handle length stops being a hand tool.
bend_od_range = [inch(1/8), inch(2)];

//! Safety factor on base anchor bolt shear. REASONED, NOT CITED: nothing found sets a
//! factor for a hand-operated bender, and the failure mode is a machine that walks across
//! the bench rather than a bolt that fractures, so this is a stiffness margin.
bend_anchor_safety_factor = 4;

//
// Bendability ratios. Both are ratios of the same two-or-three quantities and they run in
// OPPOSITE directions, which is how they get confused: a LARGER D of bend is easier, a
// SMALLER wall factor is easier. Trade summaries invert wall factor often enough that the
// definition is spelled out here rather than assumed.
//

//! Wall factor, `Fw = OD / wall`. Thin wall gives a HIGH wall factor and a HARDER bend.
function bend_wall_factor(tube) = tube_od(tube) / tube_wall(tube);

//! D of bend, `Fd = CLR / OD`. A LARGER number is an easier bend.
function bend_d_of_bend(tube, clr) = clr / tube_od(tube);

//! Tightest centreline radius this machine should be asked for, mm.
function bend_min_clr(tube) = bend_min_d_of_bend * tube_od(tube);

//! The centreline radius to build unless told otherwise: the smallest radius the trade
//! actually sells at or above the 3 x OD floor. Where neither catalogue reaches this OD
//! there is nothing to snap to, so it falls back to the bare floor - which is a departure,
//! not a default, and bend_departures() names it.
function bend_default_clr(tube) =
    let (c = clr_smallest_at_least(tube, bend_min_clr(tube)))
        is_undef(c) ? bend_min_clr(tube) : c;

//! Whether this radius is one somebody sells for this OD.
function bend_clr_is_catalogued(tube, clr) =
    len([for (r = clr_catalogued(tube)) if (abs(r - clr) < 0.01) r]) > 0;

//
// Clamp and overbend - what the die has to carry beyond the bend itself.
//

//! Floor on the clamp's grip length, as a multiple of tube OD, for a SMOOTH clamp cavity.
//!
//! Bend Tooling: "A minimum value for L, if the clamp die cavity is smooth, is around two
//! times the tube diameter" [BENDTOOLING-CLAMP]. Benderparts says the same - smooth clamps
//! start around 2 x OD of engagement, serrated around 1 x [BENDERPARTS-FORMULAS].
//!
//! An earlier version of this file used 3, from a summary of a trade article that could
//! not be retrieved to check. The two sources that WERE read both say 2, and the tail of
//! the die is a third shorter for it. Serrating or knurling the cavity permits about half
//! this - Bend Tooling again - which is not modelled, because a serrated clamp is a
//! surface finish this model has no way to describe.
bend_grip_factor = 2;

//! Rigidity constant `k` in the clamp length below. Bend Tooling gives the relation as
//! `T x (Kr x 2.5) - R` with Kr a rigidity constant [BENDTOOLING]; Benderparts gives Kr a
//! default of 2 [BENDERPARTS-FORMULAS], so k is 5.
bend_clamp_rigidity_k = 5;

//! Length of tube the clamp grips, mm: `L = OD x k - CLR`, floored at the smooth-cavity
//! minimum.
//!
//! The two terms are not independent. k = 5 with a floor of 2 means the formula returns
//! exactly the floor at 3 D of bend, 3 x OD at a 2 D bend, and the floor for anything
//! easier - so the clamp lengthens only as the bend gets tight, which is the behaviour
//! the sources describe. Every die in this machine's range sits at 3 D or above, so the
//! floor governs; the formula is kept because the floor is not the reason it governs.
function bend_clamp_length(tube, clr) =
    max(tube_od(tube) * bend_clamp_rigidity_k - clr,
        bend_grip_factor * tube_od(tube));

//! Degrees of overbend the die must carry past the target angle so the tube springs back
//! to it. JD2 measures 3 to 4 degrees on 1-1/2 in x 0.120 in welded mild steel and says
//! chromoly springs back roughly twice as far [JD2-M32 p.9, p.11].
//!
//! REASONED, NOT CITED: 5 degrees. It is JD2's measured band plus a margin, on one
//! material and one size. Springback scales with yield over modulus and with D of bend,
//! and Bend Tooling states outright that no effective formula for it exists
//! [BENDTOOLING] - so this is a die allowance, not a prediction. Bend to a template.
bend_overbend_degrees = 5;

//
// Drive torque.
//

//! Plastic section modulus of the tube section, mm^3.
function bend_plastic_modulus(tube) =
    (pow(tube_od(tube), 3) - pow(tube_id(tube), 3)) / 6;

//! Fully plastic bending moment of the tube, N.m, at the top of its material's yield band.
//!
//! This is a FLOOR on the drive torque, not the answer. It ignores strain hardening, the
//! friction of the followbar and the U-strap, and the fact that the hinge travels round
//! the die. The real torque is higher by an amount no source read here quantifies.
function bend_plastic_moment_Nm(tube) =
    tube_material_yield_max(tube_material(tube)) * bend_plastic_modulus(tube) / 1000;

//! Grip a handle has to offer beyond wherever it attaches, mm.
//!
//! One hand breadth: 10.0 cm at the 99th percentile male, FAA HFDS Exhibit 14.3.2.1
//! item 45 [HFDS-2009]. A handle shorter than this is not a handle, whatever the
//! arithmetic says the leverage could be.
bend_handle_grip_length = 100;

//! Handle length, mm: long enough to put `moment_Nm` on the die at `force_N`, and long
//! enough to hold.
//!
//! THE FORCE CEILING IS A MAXIMUM, NOT A TARGET, and taking it as a target breaks at the
//! small end. A 1/8 in tube needs 1.4 N.m, which at 490 N is a handle 2.8 mm long -
//! shorter than the machine it bolts to, so the moment between the socket and the handle's
//! end came out NEGATIVE and the link width came out `nan`. The sweep found it; nothing
//! at 1/2 in and up would have.
//!
//! Where the grip governs, the operator simply pulls less than the ceiling. Ask for the
//! real figure with bend_operator_force_N() and report it - it is the more interesting
//! number anyway, because it says how hard the machine actually is to work.
function bend_handle_length_mm(moment_Nm, socket_radius_mm,
                               force_N = bend_operator_force_ceiling) =
    max(moment_Nm / force_N * 1000, socket_radius_mm + bend_handle_grip_length);

//! Operator pull, N, implied by a handle of `length_mm`. The inverse, for checking a
//! handle somebody has already decided on against the ceiling.
function bend_operator_force_N(moment_Nm, length_mm) = moment_Nm / (length_mm / 1000);

//! Force on the drive pin, N, for a pin engaging the die at `radius_mm` from the pivot.
//! The whole drive torque passes through this one pin, so the drive circle wants to be as
//! large as the die's material allows.
function bend_drive_pin_force_N(moment_Nm, radius_mm) = moment_Nm / (radius_mm / 1000);

//
// The followbar, and what it does to the frame.
//

//! Length of tube the followbar bears on, mm.
//!
//! REASONED, NOT CITED: 2 x OD. A sliding pressure die's length is given by Bend Tooling
//! as `Lp = R x pi x (B/180) + T x Kr` [BENDTOOLING], but that is the distance a die
//! TRAVELS with the tube, and this machine's followbar is fixed while the tube is drawn
//! through it - so the formula does not apply and no source read covers the fixed case.
//! Two diameters matches the clamp's grip factor and the prototype's guide, which bore on
//! 2.1 x OD.
function bend_followbar_length(tube) = 2 * tube_od(tube);

//! Gap between the die's tail and the start of the followbar, mm. REASONED, NOT CITED:
//! a quarter of the tube OD, so the two never touch as the die swings past.
function bend_followbar_gap(tube) = tube_od(tube) / 4;

//! Distance from the point of bend to the middle of the followbar, mm - the lever the
//! followbar reacts the bending moment on.
function bend_followbar_station(tube, clr) =
    bend_clamp_length(tube, clr) + bend_followbar_gap(tube) + bend_followbar_length(tube) / 2;

//! Force the followbar presses the tube with, N.
//!
//! The straight tube between the point of bend and the followbar carries only the
//! followbar's force, so for the moment at the point of bend to reach `Mp` that force must
//! be `Mp / station`. Moving the followbar further downstream lightens it and gives up
//! control of the tube; moving it closer does the opposite. Nothing here optimises that
//! trade - the station comes from the geometry above and this reports what it costs.
function bend_followbar_force_N(moment_Nm, station_mm) = moment_Nm / (station_mm / 1000);

//
// Sweep. The drive links turn with the die and reach past everything; the followbar and
// its pin stand still in their path. Nothing stops them meeting except keeping the bend
// out of that sector.
//

//! Angular half-width, degrees, that a bar of `width_mm` occupies at `radius_mm`.
function bend_angular_half_width(width_mm, radius_mm) =
    radius_mm <= width_mm / 2 ? 90 : asin(width_mm / 2 / radius_mm);

//! Degrees of sector the drive link must be kept clear of, either side of the followbar:
//! the link's own half-width plus the followbar's, at the followbar's radius.
function bend_followbar_keepout(link_width_mm, followbar_length_mm, radius_mm) =
    bend_angular_half_width(link_width_mm, radius_mm)
        + bend_angular_half_width(followbar_length_mm, radius_mm);

//! Degrees of swing left for the drive link once the followbar's keep-out is taken out of
//! the circle. The bend plus its overbend has to fit inside this.
function bend_available_sweep(link_width_mm, followbar_length_mm, radius_mm) =
    360 - 2 * bend_followbar_keepout(link_width_mm, followbar_length_mm, radius_mm);

//
// Sizing a plate in bending. Used for both links.
//

//! Elastic section modulus, mm^3, of a plate `t` thick and `w` wide bent in its own plane,
//! with a hole of `d` on the neutral axis.
function plate_section_modulus(t, w, d = 0) = t * (pow(w, 3) - pow(d, 3)) / (6 * w);

//! Width, mm, a plate `t` thick needs to carry `moment_Nmm` in its own plane with a hole
//! of `d` through it, at the allowable `fb`.
//!
//! Solved by iteration because the net section makes it a cubic: `w^3 - ws^2 w - d^3 = 0`,
//! where `ws` is the width a solid section would need. Five passes of
//! `w <- cbrt(ws^2 w + d^3)` from `w = ws` is well converged - the map is a contraction
//! near the root and the residual is under a hundredth of a millimetre by the fourth.
function plate_width_for_moment(moment_Nmm, t, fb, d = 0) =
    let (ws = sqrt(6 * moment_Nmm / (fb * t)),
         w1 = pow(ws * ws * ws + pow(d, 3), 1/3),
         w2 = pow(ws * ws * w1 + pow(d, 3), 1/3),
         w3 = pow(ws * ws * w2 + pow(d, 3), 1/3),
         w4 = pow(ws * ws * w3 + pow(d, 3), 1/3),
         w5 = pow(ws * ws * w4 + pow(d, 3), 1/3))
        w5;

//
// Anchorage. The tube's far end is free, so the base reacts a TORQUE about the vertical
// pivot axis plus the operator's pull - not a weight. See docs/design-basis.md section 10.
//

//! Shear per bolt, N, for a two-bolt base pattern spanning `span_mm`.
//!
//! Two bolts a distance `s` apart resisting a torque `M` about the point between them each
//! sit `s/2` from it, so the couple is `F x s` and `F = M / s`. No factor of two: an
//! earlier version of this carried one, which asked for a span twice what the model it
//! described requires. Conservative, but not the stated model, and it put the anchor bolts
//! off the end of the frame link.
//!
//! The operator's own pull adds directly and is shared, hence `F/2`.
function bend_anchor_bolt_shear_N(moment_Nm, span_mm, force_N = bend_operator_force_ceiling) =
    moment_Nm / (span_mm / 1000) + force_N / 2;

//! Shear an anchor bolt of `d` mm may carry, N, with the safety factor applied.
function bend_anchor_bolt_allowable_N(d, yield_MPa) =
    pin_allowable_shear_fraction * yield_MPa * PI * d * d / 4 / bend_anchor_safety_factor;

//! Diameter, mm, an anchor bolt has to be to carry `force_N` at that allowable.
function bend_anchor_bolt_diameter(force_N, yield_MPa) =
    sqrt(4 * force_N * bend_anchor_safety_factor
             / (PI * pin_allowable_shear_fraction * yield_MPa));

//
// Departures.
//

//! The names of every published band this tube and CLR fall outside, as a list. Empty
//! means nothing was violated; the caller decides what to do about a non-empty one.
// Radii are compared in MILLIMETRES with a tolerance, never as a ratio against a whole
// number. Every radius here is an inch conversion, so a die that is exactly 3 D lands on
// 2.99999... and a bare `< 3` test reports a departure on the very radius the rule picked.
// Four of the fifteen registered sizes tripped it before this comment existed.
clr_tolerance = 0.01;

//! As bend_departures, plus the ones that need the machine's geometry rather than only
//! the tube's. Kept separate so the tube-only checks can run before anything is designed.
function bend_mechanism_departures(bend_angle, link_width_mm, followbar_length_mm,
                                   radius_mm) = [
    if (bend_angle + bend_overbend_degrees
            > bend_available_sweep(link_width_mm, followbar_length_mm, radius_mm))
        "the drive link cannot swing the bend without sweeping through the followbar",
];

function bend_departures(tube, clr) = [
    if (clr < bend_min_clr(tube) - clr_tolerance)
        "D of bend below 3, needs a mandrel",
    if (tube_od(tube) < bend_od_range[0]) "OD below the 1/8 in floor",
    if (tube_od(tube) > bend_od_range[1]) "OD above the 2 in manual ceiling",
    if (!bend_clr_is_catalogued(tube, clr))
        len(clr_catalogued(tube)) == 0
            ? "no catalogue covers this OD, so the CLR is the bare 3 x OD floor"
            : is_undef(clr_smallest_at_least(tube, bend_min_clr(tube)))
                ? "every radius sold for this OD is tighter than 3 x OD - the trade bends this size harder than the rule"
                : "CLR is not one of the radii sold for this OD",
];

//! Echo everything the configuration implies, before any of it is drawn.
module bend_report(tube, clr, handle_length_mm, force_N = bend_operator_force_ceiling) {
    fd  = bend_d_of_bend(tube, clr);
    fw  = bend_wall_factor(tube);
    mp  = bend_plastic_moment_Nm(tube);
    l   = handle_length_mm;
    f   = bend_operator_force_N(mp, l);
    dep = bend_departures(tube, clr);

    echo(str("tube:    ", tube_size(tube), ", ",
             tube_material_description(tube_material(tube))));
    echo(str("         OD ", tube_od(tube), " mm, wall ", tube_wall(tube),
             " mm, wall factor ", fw, " (thin wall is a high number)"));
    echo(str("bend:    CLR ", clr, " mm = ", fd, " D of bend; minimum without a mandrel is ",
             bend_min_clr(tube), " mm"));
    echo(str("         radii sold for this OD: ",
             len(clr_catalogued(tube)) ? clr_catalogued(tube) : "none in either catalogue"));
    echo(str("torque:  plastic moment ", mp, " N.m at yield ",
             tube_material_yield_max(tube_material(tube)),
             " MPa - a FLOOR, friction and hardening are not in it"));
    echo(str("handle:  ", l, " mm, needing ", round(f), " N of pull - the ceiling a designer",
             " may require is ", force_N, " N",
             l > 1500 ? "; this wants two hands and a braced stance" : ""));

    if (len(dep) == 0)
        echo("checks:  inside every band checked");
    else
        for (d = dep) echo(str("DEPARTURE: ", d));
}
