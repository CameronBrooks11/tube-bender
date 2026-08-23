/**
 * @file clr_catalogue.scad
 * @brief The centreline radii the trade actually sells, per tube OD
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description Not a purchased part. The forming die in this machine is made, not bought,
 * so nothing here goes on a BOM - this is the record of which radii are CONVENTIONAL, so
 * that a die derived from arithmetic lands on a number a fabricator recognises and a bent
 * tube matches parts bent on somebody else's bender.
 *
 * Two catalogues, and between them they do not cover everything. Where they leave a gap
 * the default falls back to the bare 3 x OD minimum and says so, rather than snapping to
 * a radius nobody sells.
 *
 * Sources, see docs/references.md:
 *   [PROTOOLS-DIES]      3/4 in through 2-1/2 in - the full round-die matrix
 *   [SWAGELOK-MS-13-43]  1/8 in through 1/2 in - fixed radii on the hand bender
 *
 * Every entry falls between 2.8 and 4.8 D of bend, which is the empirical check on the
 * 3 x OD floor asserted in bend.scad. Sets no $fn.
 */

include <NopSCADlib/core.scad>;

use <../purchased/tube.scad>

//
// [ tube OD, [ centreline radii ] ], all in mm, ordered by OD.
//
// The 5/8 in row is missing on purpose: Swagelok stops at 1/2 in and Pro-Tools starts at
// 3/4 in, so nothing in either catalogue covers it. Inventing a radius to fill the hole
// would look exactly like a sourced one.
//
clr_catalogue = [
    [inch(1/8),     [inch(9/16)]],
    [inch(1/4),     [inch(9/16), inch(3/4)]],
    [inch(5/16),    [inch(15/16)]],
    [inch(3/8),     [inch(15/16)]],
    [inch(1/2),     [inch(1 + 1/2)]],
    [inch(3/4),     [inch(3), inch(3 + 1/2)]],
    [inch(7/8),     [inch(3), inch(3 + 1/2), inch(4), inch(4 + 1/2)]],
    [inch(1),       [inch(3), inch(3 + 1/2), inch(4), inch(4 + 1/2)]],
    [inch(1 + 1/8), [inch(3), inch(3 + 1/2), inch(4), inch(4 + 1/2)]],
    [inch(1 + 1/4), [inch(4), inch(4 + 1/2), inch(5), inch(6)]],
    [inch(1 + 3/8), [inch(4 + 1/2), inch(5), inch(6)]],
    [inch(1 + 1/2), [inch(4 + 1/2), inch(5), inch(6), inch(7)]],
    [inch(1 + 5/8), [inch(6), inch(7)]],
    [inch(1 + 3/4), [inch(6), inch(7)]],
    [inch(2),       [inch(6), inch(7)]],
    [inch(2 + 1/4), [inch(7)]],
    [inch(2 + 1/2), [inch(7)]],
];

//! Every catalogued radius for this tube's OD, or an empty list where neither catalogue
//! reaches. Matched on OD within a tenth of a millimetre, because the rows are inch
//! conversions and an exact float comparison would miss.
function clr_catalogued(tube) =
    let (hits = [for (row = clr_catalogue) if (abs(row[0] - tube_od(tube)) < 0.1) row[1]])
        len(hits) ? hits[0] : [];

//! The smallest catalogued radius at or above `floor_mm`, or `undef` if none reaches it.
//! `undef` propagates, which is the point - a caller that gets one has to decide.
function clr_smallest_at_least(tube, floor_mm) =
    let (above = [for (r = clr_catalogued(tube)) if (r >= floor_mm - 0.01) r])
        len(above) ? min(above) : undef;
