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

use <../purchased/tube.scad>
use <../purchased/tube_material.scad>

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

//! Handle length, mm, that puts `moment_Nm` on the die at `force_N` of operator pull.
function bend_handle_length_mm(moment_Nm, force_N = bend_operator_force_ceiling) =
    moment_Nm / force_N * 1000;

//! Operator pull, N, implied by a handle of `length_mm`. The inverse, for checking a
//! handle somebody has already decided on against the ceiling.
function bend_operator_force_N(moment_Nm, length_mm) = moment_Nm / (length_mm / 1000);

//
// Anchorage. The tube's far end is free, so the base reacts a TORQUE about the vertical
// pivot axis plus the operator's pull - not a weight. See docs/design-basis.md section 10.
//

//! Shear per bolt, N, for a two-bolt base pattern spanning `span_mm`.
function bend_anchor_bolt_shear_N(moment_Nm, span_mm, force_N = bend_operator_force_ceiling) =
    moment_Nm / (span_mm / 1000) + force_N / 2;

//! Smallest two-bolt span, mm, that keeps each bolt under `bolt_shear_capacity_N` with
//! the safety factor applied.
function bend_anchor_min_span_mm(moment_Nm, bolt_shear_capacity_N) =
    moment_Nm / (bolt_shear_capacity_N / bend_anchor_safety_factor / 2) * 1000;

//
// Departures.
//

//! The names of every published band this tube and CLR fall outside, as a list. Empty
//! means nothing was violated; the caller decides what to do about a non-empty one.
function bend_departures(tube, clr) = [
    if (bend_d_of_bend(tube, clr) < bend_min_d_of_bend) "D of bend below 3, needs a mandrel",
    if (tube_od(tube) < bend_od_range[0]) "OD below the 1/8 in floor",
    if (tube_od(tube) > bend_od_range[1]) "OD above the 2 in manual ceiling",
];

//! Echo everything the configuration implies, before any of it is drawn.
module bend_report(tube, clr, force_N = bend_operator_force_ceiling) {
    fd  = bend_d_of_bend(tube, clr);
    fw  = bend_wall_factor(tube);
    mp  = bend_plastic_moment_Nm(tube);
    l   = bend_handle_length_mm(mp, force_N);
    dep = bend_departures(tube, clr);

    echo(str("tube:    ", tube_size(tube), ", ",
             tube_material_description(tube_material(tube))));
    echo(str("         OD ", tube_od(tube), " mm, wall ", tube_wall(tube),
             " mm, wall factor ", fw, " (thin wall is a high number)"));
    echo(str("bend:    CLR ", clr, " mm = ", fd, " D of bend; minimum without a mandrel is ",
             bend_min_clr(tube), " mm"));
    echo(str("torque:  plastic moment ", mp, " N.m at yield ",
             tube_material_yield_max(tube_material(tube)),
             " MPa - a FLOOR, friction and hardening are not in it"));
    echo(str("handle:  ", l, " mm at ", force_N, " N of pull",
             l > 1500 ? "  <-- longer than a person's reach; this wants two hands and a wall"
                      : ""));

    if (len(dep) == 0)
        echo("checks:  inside every band checked");
    else
        for (d = dep) echo(str("DEPARTURE: ", d));
}
