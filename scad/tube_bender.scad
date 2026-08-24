//
//! A parametric manual rotary-draw tube bender, from 1/8 in to 2 in outside diameter.
//!
//! The machine is the swing-arm pattern that J D Squared and Pro-Tools have sold for
//! decades: a grooved forming die on a centre pivot, a U-strap clamping the tube to it, a
//! followbar reacting the bending load, and a drive link that rotates the die from a
//! handle. What is new here is that it is derived rather than drawn - the die comes from
//! the tube, the pins come from the loads they carry, and the base bolt pattern comes from
//! the torque it has to react.
//!
//! Every part of the working mechanism is built and derived: the forming die - machined
//! from one plate or stacked from flat-cut slices, behind the same interface - its plates,
//! the clamp, the followbar, the tapered frame and drive links, the die lock that holds the
//! die against springback between strokes, and a bench base or a pedestal.
//!
//! ## Driving it
//!
//! Open this file in OpenSCAD and use the **Customizer** (Window > Customizer). Everything
//! that decides what the machine is has a control there: the tube, the bend, the plate
//! stock, the die style, the mounting, and which part to look at. `tube_bender.json` beside
//! this file carries a few worked configurations to start from, including the 1-1/2 in
//! prototype and a sliced-die build for a shop with no mill.
//!
//! Nothing in the Customizer is a dimension of a part. Every part is derived from the tube
//! and the loads, so choosing a 1 in tube resizes the die, the pins, the links, the base
//! and the handle together - and the arithmetic behind that is echoed rather than hidden.
//! `just report` prints it, or read the console after any render.
//!
//! Why the numbers are what they are, and what each one rests on, is in
//! [docs/design-basis.md](docs/design-basis.md). What the Onshape prototype this was
//! started from actually measured, and which of its features survived, is in
//! [docs/reverse-engineering.md](docs/reverse-engineering.md).
//
include <NopSCADlib/core.scad>

include <purchased/tubes.scad>
include <purchased/pins.scad>
include <purchased/plates.scad>
include <purchased/structural_tubes.scad>
include <purchased/bolts.scad>

include <utils/bend.scad>;    // bend_operator_force_ceiling is a variable, so include
use <utils/layout.scad>
use <utils/pin_sizing.scad>
use <custom/forming_die.scad>
use <custom/drive_link.scad>
use <custom/frame_link.scad>
use <custom/base.scad>
use <custom/followbar.scad>
use <custom/die_plate.scad>
use <custom/clamp.scad>
use <custom/pedestal.scad>
use <custom/sliced_die.scad>
use <custom/die_lock.scad>

//
// CONFIGURATION - this block is the Customizer's tab set, and it is the interface to the
// whole model.
//
// Every parameter here is a LITERAL: a string, a number or a boolean. That is not a style
// preference, it is the only thing the Customizer can see. A variable assigned an
// identifier or an expression is invisible to it - which is why the registries are reached
// BY NAME here and turned into rows below. See AGENTS.md.
//
// Two more rules the Customizer imposes, both easy to break by accident:
//   - parameters must be in THIS file. Anything in an include or a use is ignored.
//   - parameters must appear before the first opening brace in the file, which is a long
//     way below but not infinitely far.
//
// The dropdown options are the registries' own names. An annotation cannot be computed, so
// they are written out - by `just customizer`, from the registries, and `just check` fails
// if the file and the registries have drifted apart. Do not edit them by hand.
//

/* [Tube] */

// The tube this machine is built for. Tube is specified OD x wall; pipe is not, so look a
// pipe's real OD up in a pipe table and pick the tube row that matches it.
tube_name = "tube_1p500x0p095"; // [tube_0p125x0p028:1/8 in OD x 0.028 in wall, tube_0p250x0p035:1/4 in OD x 0.035 in wall, tube_0p375x0p049:3/8 in OD x 0.049 in wall, tube_0p500x0p049:1/2 in OD x 0.049 in wall, tube_0p625x0p049:5/8 in OD x 0.049 in wall, tube_0p750x0p065:3/4 in OD x 0.065 in wall, tube_0p875x0p065:7/8 in OD x 0.065 in wall, tube_1p000x0p065:1 in OD x 0.065 in wall, tube_1p125x0p065:1-1/8 in OD x 0.065 in wall, tube_1p250x0p065:1-1/4 in OD x 0.065 in wall, tube_1p375x0p083:1-3/8 in OD x 0.083 in wall, tube_1p500x0p095:1-1/2 in OD x 0.095 in wall, tube_1p625x0p095:1-5/8 in OD x 0.095 in wall, tube_1p750x0p095:1-3/4 in OD x 0.095 in wall, tube_2p000x0p120:2 in OD x 0.120 in wall]

// How much straight tube to draw either side of the bend, mm. Drawing only - nothing is
// sized from it.
tube_length = 600; // [100:50:2000]

/* [Bend] */

// Angle to bend, degrees. The die carries this plus the few degrees of overbend the tube
// springs back through.
bend_angle = 180; // [15:5:180]

// Centreline radius, mm. Leave at 0 for the tightest radius the trade actually sells at or
// above the 3 x OD mandrel-less floor, which is what you want unless you have a reason.
// Anything else is reported as a departure rather than refused.
clr_override_mm = 0; // 0.1

/* [Die] */

// "machined" cuts the die from one thick plate and needs a mill. "sliced" stacks flat
// plates a laser or waterjet can cut, and gives up groove wrap for it - how much is in the
// report, and it is never the full 180 degrees.
die_style = "machined"; // [machined, sliced]

// Stock the sliced die's slices are cut from. Thinner follows the groove better and costs
// more cuts. Ignored when the die is machined.
slice_plate_name = "plate_0p125in"; // [plate_0p125in:1/8 in, plate_0p1875in:3/16 in, plate_0p250in:1/4 in, plate_0p3125in:5/16 in, plate_0p375in:3/8 in, plate_0p500in:1/2 in, plate_0p625in:5/8 in, plate_0p750in:3/4 in, plate_1p000in:1 in, plate_1p250in:1-1/4 in, plate_1p500in:1-1/2 in, plate_1p750in:1-3/4 in, plate_2p000in:2 in, plate_2p250in:2-1/4 in, plate_2p500in:2-1/2 in]

// Stock for the plates that bolt to the die's faces. Their tails overhang the tube and are
// the only thing the clamp can pin to.
die_plate_name = "plate_0p250in"; // [plate_0p125in:1/8 in, plate_0p1875in:3/16 in, plate_0p250in:1/4 in, plate_0p3125in:5/16 in, plate_0p375in:3/8 in, plate_0p500in:1/2 in, plate_0p625in:5/8 in, plate_0p750in:3/4 in, plate_1p000in:1 in, plate_1p250in:1-1/4 in, plate_1p500in:1-1/2 in, plate_1p750in:1-3/4 in, plate_2p000in:2 in, plate_2p250in:2-1/4 in, plate_2p500in:2-1/2 in]

// How many bolts hold each die plate to the die.
die_plate_bolts = 6; // [3:12]

/* [Plate stock] */

// The drive links. These ARE the handle - there is no separate one.
drive_plate_name = "plate_0p250in"; // [plate_0p125in:1/8 in, plate_0p1875in:3/16 in, plate_0p250in:1/4 in, plate_0p3125in:5/16 in, plate_0p375in:3/8 in, plate_0p500in:1/2 in, plate_0p625in:5/8 in, plate_0p750in:3/4 in, plate_1p000in:1 in, plate_1p250in:1-1/4 in, plate_1p500in:1-1/2 in, plate_1p750in:1-3/4 in, plate_2p000in:2 in, plate_2p250in:2-1/4 in, plate_2p500in:2-1/2 in]

// The frame links: the parts that do not turn. They carry the followbar and the die lock.
frame_plate_name = "plate_0p250in"; // [plate_0p125in:1/8 in, plate_0p1875in:3/16 in, plate_0p250in:1/4 in, plate_0p3125in:5/16 in, plate_0p375in:3/8 in, plate_0p500in:1/2 in, plate_0p625in:5/8 in, plate_0p750in:3/4 in, plate_1p000in:1 in, plate_1p250in:1-1/4 in, plate_1p500in:1-1/2 in, plate_1p750in:1-3/4 in, plate_2p000in:2 in, plate_2p250in:2-1/4 in, plate_2p500in:2-1/2 in]

// The base plate the lower frame link is welded to.
base_plate_name = "plate_0p375in"; // [plate_0p125in:1/8 in, plate_0p1875in:3/16 in, plate_0p250in:1/4 in, plate_0p3125in:5/16 in, plate_0p375in:3/8 in, plate_0p500in:1/2 in, plate_0p625in:5/8 in, plate_0p750in:3/4 in, plate_1p000in:1 in, plate_1p250in:1-1/4 in, plate_1p500in:1-1/2 in, plate_1p750in:1-3/4 in, plate_2p000in:2 in, plate_2p250in:2-1/4 in, plate_2p500in:2-1/2 in]

/* [Mounting] */

// "bench" bolts the base straight down onto whatever you have. "pedestal" stands it on a
// post, which is what the bigger sizes need to be usable.
mount = "pedestal"; // [bench, pedestal]

// Height of the working plane above the floor, mm. The 490 N pull this whole machine is
// sized on is only available to a BRACED operator, and the standard puts that at 510 to
// 1780 mm - the report says which side of the band this lands on.
pedestal_height = 950; // [400:10:1800]

/* [View] */

// What to draw: the whole machine, or one part on its own to look at.
show = "assembly"; // [assembly, forming_die, die_plate, clamp, followbar, drive_link, frame_link, base, pedestal]

// Facets per circle. 90 is the built default; drop it to 30 while dragging sliders and put
// it back before exporting anything.
facets = 90; // [12:6:180]

/* [Hidden] */

$fn = facets;

//
// The registry rows the names above stand for. A Customizer parameter can only be a
// literal, so the configuration holds names and this is where they become rows.
//
tube        = tube_by_name(tube_name);
drive_plate = plate_by_name(drive_plate_name);
frame_plate = plate_by_name(frame_plate_name);
base_plate  = plate_by_name(base_plate_name);
die_plate_stock = plate_by_name(die_plate_name);
slice_plate = plate_by_name(slice_plate_name);

// 0 means "the radius the catalogue would pick", which is the answer almost every time.
// An override is taken at face value; bend_departures() says if it is off the catalogue or
// under the mandrel-less floor.
clr = clr_override_mm > 0 ? clr_override_mm : bend_default_clr(tube);

//
// Everything below is derived. Read `just report` before believing any of it.
//
// The pins are the loop Phase 2 left open. Each is sized from the force it actually
// carries and the stack it actually crosses, then rounded up to the next pin in the
// series - and BENDING governs every one of them, by more than a factor of two over
// shear. Sizing on shear alone gives pins less than half these diameters.
//
// The drive pin is circular by nature: the die's drive radius depends on the hole, which
// depends on the pin. It is broken by sizing the pin against the drive radius a nominal
// pin would give, then re-deriving the radius from the pin that comes out. One pass, and
// the report shows both so a second pass can be judged by eye rather than assumed
// unnecessary.
//
moment    = bend_plastic_moment_Nm(tube);
socket    = drive_link_socket_radius(tube, clr);
handle    = bend_handle_length_mm(moment, socket);
layers    = layout_layers(tube, drive_plate, frame_plate, base_plate, die_plate_stock);
t_drive   = plate_thickness(drive_plate);
t_frame   = plate_thickness(frame_plate);
// The central member of every pivot joint: the die AND its plates, which are bolted to it
// and turn with it. Not the die alone - see layout_central_thickness().
t_centre  = layout_central_thickness(layers);

// Pass 1: a nominal drive pin, to get a drive radius to size against.
nominal_pin   = tube_od(tube) / 2;
nominal_r     = forming_die_drive_radius(tube, clr, nominal_pin);
drive_force_0 = bend_drive_pin_force_N(moment, nominal_r);
// The drive pin and the LOCK pin go in the same holes, at different angles, so they are
// one size and the hole is sized once. The lock crosses more of the stack - frame link to
// frame link, where the drive pin stops at the drive links - so its span governs both.
drive_pin     = pin_smallest_at_least(
                    pin_required_diameter(drive_force_0, t_centre, t_drive + t_frame,
                                          pin_material_yield));
lock_pin      = drive_pin;

// Pass 2: the radius the chosen pin actually gives, and the force that goes with it.
drive_radius = forming_die_drive_radius(tube, clr, pin_diameter(drive_pin));
drive_force  = bend_drive_pin_force_N(moment, drive_radius);

// The followbar's reaction, and the pin that carries it between the frame links.
followbar_force = bend_followbar_force_N(moment, bend_followbar_station(tube, clr));
followbar_pin   = pin_smallest_at_least(
                      pin_required_diameter(followbar_force, layout_frame_gap(layers),
                                            t_frame, pin_material_yield));

// The frame pin takes the drive pin's force and the tube's push on the die together. They
// need not act in the same direction, so adding them is conservative.
frame_force = drive_force + followbar_force;
frame_pin   = pin_smallest_at_least(
                  pin_required_diameter(frame_force, t_centre, t_drive + t_frame,
                                        pin_material_yield));

// The bolts that join the link pair at the grip. They carry the operator's own pull across
// the gap between the links, not the drive torque, so they are small - and each runs
// through a spacer tube, or tightening them would simply pull the pair together.
spacer_bolt  = pin_smallest_at_least(
                   pin_required_diameter(bend_operator_force_N(moment, handle),
                                         layout_drive_gap(layers), t_drive,
                                         pin_material_yield));
spacer_tube  = structural_smallest_for_bore(pin_pivot_hole(pin_diameter(spacer_bolt)));

// The clamp drags the tube round the die, so it carries the tangential force in the tube.
// Its two pins share that, through the die plates.
clamp_force = bend_clamp_force_N(moment, clr);
ustrap_pin  = pin_smallest_at_least(
                  pin_required_diameter(clamp_force / 2, clamp_height(tube),
                                        plate_thickness(die_plate_stock),
                                        pin_material_yield));
clamp_bolt  = bolt_smallest_at_least(tube_od(tube) / 4);
plate_bolt  = bolt_smallest_at_least(
                  sqrt(4 * die_plate_bolt_shear_N(moment, clr,
                           die_plate_bolt_radius(tube, clr, pin_diameter(frame_pin),
                                                 pin_diameter(drive_pin), tube_od(tube) / 4),
                           die_plate_bolts)
                       / (PI * pin_allowable_shear_fraction * bolt_material_yield)));

drive_angles = forming_die_drive_angles(tube, clr, pin_diameter(frame_pin),
                                        pin_diameter(drive_pin), bend_angle);
n_drive_holes = len(drive_angles);
drive_angle  = n_drive_holes ? drive_angles[0] : 0;
// undef on a die with no room for drive holes, and the link then draws no hole.
drive_hole_r = n_drive_holes ? drive_radius : undef;

// The base plate's footprint comes from the frame link, so the anchor radius is known
// before the bolt is. Size the bolt against a nominal inset, then the real inset - and so
// the real radius - follows from the bolt that comes out.
op_force     = bend_operator_force_N(moment, handle);
fb_pin_d     = pin_diameter(followbar_pin);
link_w       = frame_link_width(tube, clr, frame_plate, moment, pin_diameter(frame_pin),
                                fb_pin_d);
anchor_bolt  = base_anchor_bolt(tube, clr, link_w, fb_pin_d, moment, op_force,
                                bolt_material_yield, bolts);

// The die lock. One pitch past the last drive hole, on the drive circle - the one angle a
// hole reaches at the end of every stroke. The frame link grows an arm to it.
drive_inset    = forming_die_drive_inset(tube, clr, pin_diameter(drive_pin));
lock_pos       = n_drive_holes ? die_lock_pos(tube, clr, pin_diameter(drive_pin),
                                              drive_inset, forming_die_drive_pitch(),
                                              n_drive_holes)
                               : undef;

// A pin the series cannot reach comes back undef and propagates through everything
// downstream without a word - the frame link's width, the base's bolt pattern, the report.
// Name it here, at the one place that knows which pin it was.
assert(!is_undef(drive_pin),     "no registered pin is big enough for the DRIVE pin - extend pins.scad");
assert(!is_undef(frame_pin),     "no registered pin is big enough for the FRAME pin - extend pins.scad");
assert(!is_undef(followbar_pin), "no registered pin is big enough for the FOLLOWBAR pin - extend pins.scad");
assert(!is_undef(ustrap_pin),    "no registered pin is big enough for the U-STRAP pin - extend pins.scad");
assert(!is_undef(spacer_bolt),   "no registered pin is big enough for the SPACER bolts - extend pins.scad");

bend_report(tube, clr, handle);
forming_die_report(tube, clr, bend_angle, pin_diameter(frame_pin),
                   pin_diameter(drive_pin));
drive_link_report(tube, clr, drive_plate, pin_diameter(frame_pin),
                  pin_diameter(drive_pin), drive_hole_r, bend_operator_force_N(moment, handle),
                  handle, pin_diameter(spacer_bolt));
frame_link_report(tube, clr, frame_plate, moment, pin_diameter(frame_pin), fb_pin_d);
followbar_report(tube, clr, fb_pin_d, followbar_force);
die_plate_report(tube, clr, die_plate_stock, bend_angle, pin_diameter(frame_pin),
                 pin_diameter(drive_pin), pin_diameter(ustrap_pin), plate_bolt,
                 bolt_material_yield, die_plate_bolts, moment);
clamp_report(tube, clr, pin_diameter(ustrap_pin), clamp_bolt, clamp_force);
sliced_die_report(tube, clr, slice_plate);
base_report(tube, clr, base_plate, link_w, fb_pin_d, moment, op_force, anchor_bolt,
            bolt_material_yield, layout_working_height(layers));

// The pedestal post carries the operator's pull as bending and the drive torque as
// torsion, at the same time.
post          = structural_smallest_for_combined(op_force * pedestal_height, moment * 1000,
                                                 pin_allowable_shear_fraction * 250);
post_length   = pedestal_height - layout_working_height(layers);
foot_bolt     = pedestal_foot_bolt(post, op_force, pedestal_height, moment,
                                   bolt_material_yield, bolts);

if (mount == "pedestal")
    pedestal_report(post, base_plate, post_length, foot_bolt, bolt_material_yield,
                    op_force, pedestal_height, moment);

// The drive links turn with the die; the followbar and its pin do not move. What has to
// fit between the followbar's keep-outs is ONE STROKE, not the whole bend - the link is
// indexed, so it swings a pitch and comes back. A die with no drive holes is the exception
// and is checked as one.
//
// The width that matters is the DRIVE link's, not the frame link's - the frame link is
// what stands still - and it is asked for at the followbar's radius, where the collision
// would happen, rather than at the drive hole where the link is at its widest.
fb_radius = frame_link_reach(tube, clr, fb_pin_d);
// Two widths, and they are not interchangeable. The link tapers, so what sweeps past the
// followbar out at fb_radius is much narrower than what sweeps past the die lock in at the
// drive circle - where the link is at its peak width, because that is where its moment is.
drive_w_peak = drive_link_width(drive_plate, op_force, handle, drive_hole_r,
                                pin_diameter(frame_pin), pin_diameter(drive_pin));
drive_w   = drive_link_width_at(drive_plate, op_force, handle,
                                is_undef(drive_hole_r) ? 0 : drive_hole_r,
                                pin_diameter(frame_pin), pin_diameter(drive_pin),
                                pin_diameter(spacer_bolt), fb_radius);
stroke_overrun = bend_stroke_overrun(bend_angle, n_drive_holes, forming_die_drive_pitch());

// The band is placed, not just sized: each stroke starts where the drive link picks up a
// hole, which at the start of a bend is the first hole's own angle.
drive_home_deg = drive_inset;
followbar_deg  = atan2(frame_link_followbar_pos(tube, clr, fb_pin_d)[1],
                       frame_link_followbar_pos(tube, clr, fb_pin_d)[0]);

for (d = bend_mechanism_departures(bend_angle, drive_w, bend_followbar_length(tube),
                                   fb_radius, forming_die_drive_pitch(), n_drive_holes,
                                   drive_home_deg, followbar_deg))
    echo(str("DEPARTURE: ", d));

echo(str("sweep:   ", round(bend_available_sweep(drive_w, bend_followbar_length(tube), fb_radius)),
         " deg free of the followbar; ",
         n_drive_holes ? str("one stroke is ", forming_die_drive_pitch(), " deg and the last is ",
                             round(forming_die_drive_pitch() + stroke_overrun))
                       : str("no drive holes, so the link swings the whole ",
                             forming_die_arc(bend_angle)),
         " deg"));

die_lock_report(tube, clr, pin_diameter(drive_pin), lock_pin, drive_w_peak, die_web(tube),
                forming_die_drive_pitch(), drive_inset, n_drive_holes, moment, frame_plate,
                link_w);

lock_clearance = die_lock_clearance_deg(drive_w_peak, pin_diameter(lock_pin), die_web(tube),
                                        die_lock_radius(tube, clr, pin_diameter(drive_pin)));
lock_arm_w     = die_lock_arm_width(moment, t_frame,
                                    pin_allowable_bending_fraction * plate_yield(frame_plate),
                                    pin_pivot_hole(pin_diameter(lock_pin)));

for (d = die_lock_departures(forming_die_drive_pitch(), n_drive_holes,
                             die_lock_separation_deg(forming_die_drive_pitch(),
                                                     n_drive_holes),
                             lock_clearance, lock_arm_w, link_w))
    echo(str("DEPARTURE: ", d));

echo(str("pins:    frame ", pin_size(frame_pin), " (", round(frame_force), " N, ",
         pin_governing_mode(frame_force, t_centre, t_drive + t_frame, pin_material_yield),
         "), drive ", pin_size(drive_pin), " (", round(drive_force), " N, ",
         pin_governing_mode(drive_force, t_centre, t_drive, pin_material_yield), ")"));
echo(str("         followbar ", pin_size(followbar_pin), " (", round(followbar_force),
         " N), U-strap ", pin_size(ustrap_pin)));
echo(str("         drive radius ", nominal_r, " mm nominal -> ", drive_radius,
         " mm with the chosen pin"));
echo(str("stack:   ", layout_height(layers), " mm overall, ", layout_frame_gap(layers),
         " mm between the frame links"));
if (n_drive_holes) {
    echo(str("cycle:   ", bend_strokes(bend_angle, forming_die_drive_pitch(), n_drive_holes),
             " strokes of ",
             round(bend_stroke_travel_mm(forming_die_drive_pitch(), handle) / 10) / 100,
             " m at the handle's end, re-pinning the drive pin between each"));
    echo(str("         ", n_drive_holes, " drive holes index ",
             bend_indexed_rotation(n_drive_holes, forming_die_drive_pitch()), " deg of the ",
             forming_die_arc(bend_angle), " deg groove",
             stroke_overrun > 0
                 ? str(", so the last is over-pulled to ",
                       round(forming_die_drive_pitch() + stroke_overrun), " deg and ",
                       round(bend_stroke_travel_mm(forming_die_drive_pitch() + stroke_overrun,
                                                   handle) / 10) / 100, " m")
                 : " and nothing is left to over-pull"));
} else {
    echo(str("cycle:   1 stroke of ",
             round(bend_stroke_travel_mm(forming_die_arc(bend_angle), handle) / 10) / 100,
             " m at the handle's end - this die has no drive holes, so the link takes it",
             " round in one go on the U-strap pin"));
}

// The base is drawn in the frame link's own frame, so its features have to be turned onto
// the link's axis to sit under it.
function rotate_pt(axis, p) = [axis[0] * p[0] - axis[1] * p[1],
                               axis[1] * p[0] + axis[0] * p[1]];

plate_bolt_pos = die_plate_bolt_positions(tube, clr, pin_diameter(frame_pin),
                                          pin_diameter(drive_pin),
                                          bolt_diameter(plate_bolt), bend_angle,
                                          die_plate_bolts);

// Both dies present the same interfaces, so nothing downstream chooses between them.
module forming_die_stl()
    if (die_style == "sliced")
        sliced_die(tube, clr, slice_plate, bend_angle, pin_diameter(frame_pin),
                   pin_diameter(drive_pin), plate_bolt_pos, bolt_diameter(plate_bolt));
    else
        forming_die(tube, clr, bend_angle, pin_diameter(frame_pin),
                    pin_diameter(drive_pin), plate_bolt_pos, bolt_diameter(plate_bolt));

module die_plate_stl()
    die_plate(tube, clr, die_plate_stock, bend_angle, pin_diameter(frame_pin),
              pin_diameter(drive_pin), pin_diameter(ustrap_pin),
              bolt_diameter(plate_bolt), die_plate_bolts);

module clamp_stl()
    clamp(tube, clr, pin_diameter(ustrap_pin), bolt_diameter(clamp_bolt));

module drive_link_stl()
    drive_link(tube, clr, drive_plate, pin_diameter(frame_pin), pin_diameter(drive_pin),
               drive_hole_r, bend_operator_force_N(moment, handle), handle,
               pin_diameter(spacer_bolt));

module frame_link_stl()
    frame_link(tube, clr, frame_plate, moment, pin_diameter(frame_pin), fb_pin_d,
               lock_pos, pin_diameter(lock_pin));

module followbar_stl() followbar(tube, fb_pin_d);

module pedestal_stl() pedestal(post, base_plate, post_length, bolt_diameter(foot_bolt));

module base_stl()
    base(tube, clr, base_plate, link_w, fb_pin_d, bolt_diameter(anchor_bolt));

//! The stack, with the tube where it goes in. The handle, the followbar, the U-strap and
//! the base are not built yet.
module main_assembly()
assembly("main") {
    stl_colour(pp1_colour) stl("forming_die") forming_die_stl();

    for (layer = ["die plate lower", "die plate upper"])
        translate_z(layout_z(layers, layer))
            stl_colour(pp4_colour) stl("die_plate") die_plate_stl();

    translate([clr, 0, 0])
        stl_colour(pp2_colour) stl("clamp") clamp_stl();

    for (p = die_plate_clamp_pins(tube, clr, pin_diameter(ustrap_pin)))
        translate(concat(p, [layout_z(layers, "die plate lower")]))
            pin(ustrap_pin, layout_z(layers, "die plate upper")
                            + layout_thickness(layers, "die plate upper")
                            - layout_z(layers, "die plate lower") + 6);

    // The links are drawn with their drive hole on +x, so the pair has to be turned to
    // whichever die drive hole the pin is in. Drawing them at zero while the pin sits at
    // the hole angle puts the pin through solid plate.
    for (layer = ["drive link lower", "drive link upper"])
        translate_z(layout_z(layers, layer))
            rotate(drive_angle)
                stl_colour(pp2_colour) stl("drive_link") drive_link_stl();

    translate(concat(frame_link_followbar_pos(tube, clr, fb_pin_d)
                         - [followbar_pin_offset(tube, fb_pin_d), 0], [0]))
        stl_colour(pp1_colour) stl("followbar") followbar_stl();

    translate(concat(frame_link_followbar_pos(tube, clr, fb_pin_d),
                     [layout_z(layers, "frame link lower")]))
        pin(followbar_pin, layout_pin_length(layers, "frame link lower"));

    for (layer = ["frame link lower", "frame link upper"])
        translate_z(layout_z(layers, layer))
            stl_colour(pp3_colour) stl("frame_link") frame_link_stl();

    if (mount == "pedestal")
        translate_z(layout_z(layers, "base"))
            stl_colour(pp3_colour) stl("pedestal") pedestal_stl();

    translate_z(layout_z(layers, "base"))
        rotate(atan2(frame_link_axis(tube, clr, fb_pin_d)[1], frame_link_axis(tube, clr, fb_pin_d)[0]))
            stl_colour(pp4_colour) stl("base") base_stl();

    translate_z(layout_z(layers, "frame link lower"))
        pin(frame_pin, layout_pin_length(layers, "frame link lower"));

    // Four anchor bolts at the base's corners, heads up, running down through whatever
    // the machine is bolted to.
    for (p = base_anchor_positions(tube, clr, link_w, fb_pin_d,
                                   plate_eye_radius(bolt_clearance_hole_d(
                                       bolt_diameter(anchor_bolt))) + 1))
        translate(concat(rotate_pt(frame_link_axis(tube, clr, fb_pin_d),
                                   p + [frame_link_reach(tube, clr, fb_pin_d) / 2, 0]),
                         [layout_z(layers, "base") + layout_thickness(layers, "base")]))
            rotate([180, 0, 0])
                bolt(anchor_bolt, layout_thickness(layers, "base") + 30);

    // The die lock, through the whole stack into whichever drive hole is under it. The
    // assembly is drawn with the die at zero, and at zero the lock is just past the die's
    // trailing edge with nothing under it - which is right. A straight tube has nothing to
    // spring back; the die turns into the pin during the first stroke.
    if (!is_undef(lock_pos))
        translate(concat(lock_pos, [layout_z(layers, "frame link lower")]))
            pin(lock_pin, layout_pin_length(layers, "frame link lower"));

    if (!is_undef(drive_hole_r))
        rotate(drive_angle)
            translate([drive_hole_r, 0, layout_z(layers, "drive link lower")])
                pin(drive_pin, layout_pin_length(layers, "drive link lower"));

    for (r = drive_link_spacer_radii(handle, pin_diameter(spacer_bolt)))
        rotate(drive_angle)
            translate([r, 0, layout_z(layers, "drive link lower")]) {
                pin(spacer_bolt, layout_pin_length(layers, "drive link lower"));

                translate_z(t_drive)
                    structural_tube(spacer_tube, layout_drive_gap(layers));
            }

    translate([clr, -tube_length / 2 + forming_die_tail_length(tube, clr) / 2, 0])
        rotate([90, 0, 0])
            tube(tube, tube_length);
}

//! Draw whatever `show` asks for. NopSCADlib's make_all does not come through here - it
//! generates its own wrapper and calls the assembly and the `*_stl()` modules directly -
//! so this is purely the interactive view, and a part selector costs the build nothing.
module show_part(name) {
    if      (name == "assembly")    main_assembly();
    else if (name == "forming_die") forming_die_stl();
    else if (name == "die_plate")   die_plate_stl();
    else if (name == "clamp")       clamp_stl();
    else if (name == "followbar")   followbar_stl();
    else if (name == "drive_link")  drive_link_stl();
    else if (name == "frame_link")  frame_link_stl();
    else if (name == "base")        base_stl();
    else if (name == "pedestal")    pedestal_stl();
    else assert(false, str("show: no such part - ", name));
}

show_part(show);
