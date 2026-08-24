/**
 * @file units.scad
 * @brief How a number is written down, in whichever system the builder works in
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description Draws nothing and CHANGES NOTHING. Every calculation in this model is in
 * millimetres, newtons and megapascals and stays that way; this is the last step before a
 * number reaches a human, and it is the only place a unit ever appears.
 *
 * ## It is a system, not a length setting
 *
 * Converting lengths and leaving forces in newtons gives a report that is harder to check
 * than either pure system - you cannot carry a sanity calculation across mixed units in
 * your head. So the toggle moves everything together:
 *
 *     metric     mm    N      N.m      MPa       kg
 *     imperial   in    lbf    lbf.ft   ksi/psi   lb
 *
 * There is a second reason. Half the sources this model rests on are imperial-native, and
 * the conversion puts their numbers back into the form they were published in: A36 plate
 * comes back as 36 ksi, which is the number the grade is NAMED for and which 250 MPa
 * conceals.
 *
 * ## A name is not a measurement
 *
 * `tube_size()`, `plate_size()` and `pin_size()` return "1-1/2 in OD x 0.095 in wall",
 * "1/4 in", "7/8 in dia" - and they do so in BOTH systems, because those are identities.
 * They are what is stamped on the die and what you type into an order form. A metric
 * builder still orders 1/4 in plate. Only measurements convert. See design-basis.md
 * section 8.
 *
 * ## Why ksi for strength and psi for bearing
 *
 * Both are stress and they take different units in the trade, because they differ by
 * four orders of magnitude. Structural allowables are quoted in ksi - AISC does, and A36 is
 * named for its 36 - while what a machine bears onto a bench is quoted in psi. Putting the
 * base's 0.01 MPa into ksi gives 0.0000015 and tells nobody anything.
 *
 * ## How the setting travels
 *
 * `$units`, a special variable, so it is DYNAMICALLY scoped: set once at the top of
 * tube_bender.scad it reaches every report module and every function they call, across
 * `use` boundaries, without being threaded through a signature that has nothing else to do
 * with it. It can also be overridden for one call - `some_report($units = "imperial")` -
 * which is how a metric build can print one imperial line if it ever needs to.
 *
 * Unset means metric. A part file rendered on its own has no configuration to read.
 *
 * ## Precision
 *
 * One fixed number of decimals per quantity, and OpenSCAD trims trailing zeros for free -
 * so a length only shows thousandths of an inch when it genuinely has them.
 *
 * The two systems do NOT get the same number of decimals. They get whatever gives them
 * comparable ABSOLUTE resolution, because a decimal place is worth a different amount in
 * each: one newton is 0.22 lbf, so integer newtons and integer pounds-force are a factor of
 * four apart in what they resolve. Matching digits instead of resolution would make one
 * system's report quietly coarser than the other's.
 *
 *     quantity   metric      imperial      resolution, in metric terms
 *     length     0.01 mm     0.001 in      0.010 / 0.025 mm
 *     force      1 N         0.1 lbf       1.0   / 0.44  N
 *     moment     0.1 N.m     0.1 lbf.ft    0.10  / 0.14  N.m
 *     stress     0.1 MPa     0.01 ksi      0.10  / 0.069 MPa
 *     pressure   0.001 MPa   0.1 psi       0.0010/ 0.00069 MPa
 *     mass       0.01 kg     0.01 lb       0.010 / 0.0045 kg
 *
 * Every one of these is finer than anything this machine is made to, which is deliberate:
 * rounding is for reading, and it should never be the reason two numbers fail to add up.
 *
 * Sets no $fn.
 */

include <NopSCADlib/core.scad>;

//
// Conversion factors. Every one of these is EXACT by definition rather than measured, so
// none of them is a citation - they are the definitions of the imperial units in SI terms.
//
//   international inch      25.4 mm                     (1959 international yard and pound)
//   pound, mass             0.45359237 kg               (same)
//   standard gravity        9.80665 m/s^2               (3rd CGPM, 1901)
//   pound-force             0.45359237 x 9.80665 N      (mass x standard gravity)
//   foot                    0.3048 m
//   psi                     lbf / inch^2
//

units_mm_per_inch  = 25.4;
units_kg_per_lb    = 0.45359237;
units_N_per_lbf    = 0.45359237 * 9.80665;              // 4.4482216152605
units_Nm_per_lbfft = units_N_per_lbf * 0.3048;          // 1.3558179483314
units_MPa_per_ksi  = units_N_per_lbf / (0.0254 * 0.0254) / 1000;  // 6.89475729316836
units_MPa_per_psi  = units_MPa_per_ksi / 1000;

//! Whether the report is being written in imperial. Unset is metric - a part file rendered
//! on its own has no configuration to read.
function units_imperial() = !is_undef($units) && $units == "imperial";

//! Round to `dp` decimal places. OpenSCAD drops trailing zeros when it makes a string, so
//! this gives an integer for a big number and a decimal for a small one from one rule.
function units_round(x, dp) = round(x * pow(10, dp)) / pow(10, dp);

//
// The formatters. Each takes the model's own unit and returns a string WITH the unit on it,
// because a number and its unit travelling separately is how they end up mismatched.
//

//! A length, from mm.
function fmt_length(mm) =
    units_imperial() ? str(units_round(mm / units_mm_per_inch, 3), " in")
                     : str(units_round(mm, 2), " mm");

//! A force, from N.
function fmt_force(N) =
    units_imperial() ? str(units_round(N / units_N_per_lbf, 1), " lbf")
                     : str(units_round(N, 0), " N");

//! A moment or a torque, from N.m.
function fmt_moment(Nm) =
    units_imperial() ? str(units_round(Nm / units_Nm_per_lbfft, 1), " lbf.ft")
                     : str(units_round(Nm, 1), " N.m");

//! A material stress or allowable, from MPa. See the header for why this is ksi and
//! fmt_pressure() is psi.
function fmt_stress(MPa) =
    units_imperial() ? str(units_round(MPa / units_MPa_per_ksi, 2), " ksi")
                     : str(units_round(MPa, 1), " MPa");

//! A bearing or contact pressure, from MPa.
function fmt_pressure(MPa) =
    units_imperial() ? str(units_round(MPa / units_MPa_per_psi, 1), " psi")
                     : str(units_round(MPa, 3), " MPa");

//! A mass, from kg.
function fmt_mass(kg) =
    units_imperial() ? str(units_round(kg / units_kg_per_lb, 2), " lb")
                     : str(units_round(kg, 2), " kg");

//! A length with no unit written on it, for a list or a coordinate pair where repeating the
//! unit on every entry is noise. The CALLER must then say which it is - fmt_unit() gives
//! the word.
function fmt_bare_length(mm) =
    units_imperial() ? units_round(mm / units_mm_per_inch, 3) : units_round(mm, 2);

//! The name of the length unit in force, for a caller using fmt_bare_length().
function fmt_length_unit() = units_imperial() ? "in" : "mm";
