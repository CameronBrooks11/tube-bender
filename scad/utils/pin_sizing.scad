/**
 * @file pin_sizing.scad
 * @brief What diameter a pin has to be, from the load and the stack it crosses
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description Draws nothing. Every pin in this machine is loaded in double shear - a
 * central member between two outer ones - and the two ways it can fail are checked
 * separately because THEY DO NOT AGREE. On this machine bending governs by a factor of
 * about two and a half, and sizing on shear alone gives a pin less than half the diameter
 * the reference machines use.
 *
 * ## The bending model
 *
 * The pin is taken as a simply supported beam: the central member's load `F` as a point
 * load at midspan, each outer member reacting `F/2` at its own centroid. The span between
 * those centroids is `t_centre + t_outer`, so
 *
 *     M = F (t_centre + t_outer) / 4
 *
 * That is the standard conservative treatment of a clevis pin - it ignores that the load
 * is distributed across each member's thickness, which is why it is conservative. A pin
 * with no clearance and perfectly rigid members would see less.
 *
 * ## Allowables
 *
 * AISC allowable stress design, as stated in the Engineering Journal: "tension,
 * Ft = 0.6Fy, and that in shear, Fv = 0.4Fy" [AISC-GOEL]. Those fractions carry their own
 * factor of safety against the von Mises shear yield of ~0.6Fy.
 *
 * Bending uses the TENSION allowable, 0.6Fy. AISC allows more for a solid round section;
 * taking the tension figure is deliberately conservative and costs a few percent on the
 * diameter.
 *
 * Bearing on the plates is REPORTED rather than allowed for. No bearing allowable was
 * found in a source that could be read, and inventing one would put a fabricated number
 * in the load path - see docs/design-basis.md.
 *
 * Sets no $fn.
 */

include <NopSCADlib/core.scad>;

//! AISC allowable shear as a fraction of yield [AISC-GOEL].
pin_allowable_shear_fraction = 0.4;

//! AISC allowable tension as a fraction of yield [AISC-GOEL], used here for bending too.
pin_allowable_bending_fraction = 0.6;

//
// Stresses in a pin that has already been chosen. These are what get reported.
//

//! Shear stress, MPa, in a pin of `d` mm carrying `force_N` across two shear planes.
function pin_shear_stress(force_N, d) = 2 * force_N / (PI * d * d);

//! Bending moment, N.mm, in a pin crossing a `t_centre` member between two `t_outer` ones.
function pin_bending_moment(force_N, t_centre, t_outer) =
    force_N * (t_centre + t_outer) / 4;

//! Bending stress, MPa, in a pin of `d` mm.
function pin_bending_stress(force_N, d, t_centre, t_outer) =
    32 * pin_bending_moment(force_N, t_centre, t_outer) / (PI * pow(d, 3));

//! Bearing stress, MPa, of a pin of `d` mm on a member of `t` mm carrying `force_N`.
function pin_bearing_stress(force_N, d, t) = force_N / (d * t);

//
// Diameters those stresses imply.
//

//! Diameter, mm, at which the shear allowable is exactly reached.
function pin_diameter_for_shear(force_N, yield_MPa) =
    sqrt(2 * force_N / (PI * pin_allowable_shear_fraction * yield_MPa));

//! Diameter, mm, at which the bending allowable is exactly reached.
function pin_diameter_for_bending(force_N, t_centre, t_outer, yield_MPa) =
    pow(32 * pin_bending_moment(force_N, t_centre, t_outer)
            / (PI * pin_allowable_bending_fraction * yield_MPa), 1/3);

//! The diameter the pin actually has to be: whichever failure mode governs.
function pin_required_diameter(force_N, t_centre, t_outer, yield_MPa) =
    max(pin_diameter_for_shear(force_N, yield_MPa),
        pin_diameter_for_bending(force_N, t_centre, t_outer, yield_MPa));

//! Which mode governs, as a name rather than a flag.
function pin_governing_mode(force_N, t_centre, t_outer, yield_MPa) =
    pin_diameter_for_bending(force_N, t_centre, t_outer, yield_MPa)
        >= pin_diameter_for_shear(force_N, yield_MPa) ? "bending" : "shear";
