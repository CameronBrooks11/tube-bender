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
//! The **Units** tab switches the report and the BOM between metric and imperial as a
//! whole system - length, force, moment, stress and mass together, because inches with
//! newtons is harder to check than either on its own. It changes nothing that is
//! calculated, and it changes no name: a tube is "1-1/2 in OD x 0.095 in wall" and plate is
//! ordered as "1/4 in" in both.
//!
//! Nothing in the Customizer is a dimension of a part. Every part is derived from the tube
//! and the loads, so choosing a 1 in tube resizes the die, the pins, the links, the base
//! and the handle together - and the arithmetic behind that is echoed rather than hidden.
//! `just report` prints it, or read the console after any render.
//!
//! ## Two words in the parts list that are NopSCADlib's, not ours
//!
//! Nothing here is printed. The list has a **"3D printed parts"** heading because that is
//! what NopSCADlib calls a part you make rather than buy, and under it are the three parts
//! with real depth to cut - the forming die, the clamp and the followbar - which are
//! **machined**. Everything flat is under **"CNC routed"**, which is right: those go to a
//! laser, waterjet or plasma table as the DXF files linked beside them.
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
use <utils/units.scad>
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

/* [Units] */

// Which system every REPORTED and every BOM number is written in. It changes nothing that
// is calculated - the model works in millimetres, newtons and megapascals throughout - and
// it changes no NAME: a tube is "1-1/2 in OD x 0.095 in wall" and plate is ordered as
// "1/4 in" in both, because those are identities rather than measurements.
//
// It moves the whole system rather than only lengths. Inches with newtons is harder to
// check than either on its own.
units = "metric"; // [metric:metric - mm, N, N.m, MPa, kg, imperial:imperial - in, lbf, lbf.ft, ksi, lb]

// A NUMBER YOU TYPE IN NEVER CHANGES MEANING when you change the system above. Its unit is
// in its name, and it stays what it says: `_mm` is millimetres, `_in` is inches, in both.
// The alternative - inputs that follow the toggle - would silently reinterpret every saved
// configuration the moment somebody switched, turning a 950 mm pedestal into a 24 m one.
//
// Which unit a given input takes follows the rule the whole model uses: something chosen
// off a catalogue takes the catalogue's unit, which for tube and die stock is inches;
// a free dimension takes the model's own, which is millimetres.

/* [Tube] */

// The tube this machine is built for. Tube is specified OD x wall; pipe is not, so look a
// pipe's real OD up in a pipe table and pick the tube row that matches it.
tube_name = "tube_1p500x0p095"; // [tube_0p125x0p028:1/8 in OD x 0.028 in wall, tube_0p250x0p035:1/4 in OD x 0.035 in wall, tube_0p375x0p049:3/8 in OD x 0.049 in wall, tube_0p500x0p049:1/2 in OD x 0.049 in wall, tube_0p625x0p049:5/8 in OD x 0.049 in wall, tube_0p750x0p065:3/4 in OD x 0.065 in wall, tube_0p875x0p065:7/8 in OD x 0.065 in wall, tube_1p000x0p065:1 in OD x 0.065 in wall, tube_1p125x0p065:1-1/8 in OD x 0.065 in wall, tube_1p250x0p065:1-1/4 in OD x 0.065 in wall, tube_1p375x0p083:1-3/8 in OD x 0.083 in wall, tube_1p500x0p095:1-1/2 in OD x 0.095 in wall, tube_1p625x0p095:1-5/8 in OD x 0.095 in wall, tube_1p750x0p095:1-3/4 in OD x 0.095 in wall, tube_2p000x0p120:2 in OD x 0.120 in wall]

// How much straight tube to draw either side of the bend, millimetres. Drawing only -
// nothing is sized from it.
tube_length_mm = 600; // [100:50:2000]

/* [Bend] */

// Angle to bend, degrees. The die carries this plus the few degrees of overbend the tube
// springs back through.
bend_angle = 180; // [15:5:180]

// Centreline radius, INCHES. Leave at 0 for the tightest radius the trade actually sells at
// or above the 3 x OD mandrel-less floor, which is what you want unless you have a reason.
// Anything else is reported as a departure rather than refused.
//
// Inches whichever system you are reporting in, because a CLR is chosen off a catalogue and
// every catalogue lists it in inches - 4-1/2, 5, 6, 7 - the same way the tube size is an
// imperial identity in both. See the note on input units above.
clr_override_in = 0; // 0.001

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

// Height of the working plane above the floor, millimetres. The pull this machine is
// sized on is only available to a BRACED operator, and the standard puts that at 510 to
// 1780 mm - the report says which side of the band this lands on.
pedestal_height_mm = 950; // [400:10:1800]

/* [View] */

// What to draw: the whole machine, or one part on its own to look at.
show = "assembly"; // [assembly, forming_die, die_plate, clamp, followbar, drive_link, frame_link, base, pedestal]

// Facets per circle. 90 is the built default; drop it to 30 while dragging sliders and put
// it back before exporting anything.
facets = 90; // [12:6:180]

/* [Hidden] */

$fn = facets;

// A special variable, so it is dynamically scoped and reaches every report module and every
// function they call without being threaded through signatures that have nothing else to do
// with it. See utils/units.scad.
$units = units;

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
clr = clr_override_in > 0 ? inch(clr_override_in) : bend_default_clr(tube);

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
// anchor_bolt now depends on the frame link's whole footprint, which depends on the ties,
// so it is derived below with them rather than here.

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

// The frame ties. Two bolts through spacer tubes, holding the frame links at a fixed gap so
// the frame stays a frame when a pin is pulled - and reacting the handle's own weight, which
// tries to lift the drive pair's tail off the upper frame link. See design-basis section 23.
//
// Sized like the drive pin's radius was: the spacer tube depends on the bolt and the tie's
// radius depends on the spacer, so a nominal bolt gets a first radius, and the real one
// follows from the bolt that comes out.
drive_taper  = drive_link_taper(drive_plate, op_force, handle,
                                is_undef(drive_hole_r) ? 0 : drive_hole_r,
                                pin_diameter(frame_pin), pin_diameter(drive_pin),
                                pin_diameter(spacer_bolt));
drive_mass   = drive_link_mass(drive_plate, drive_taper, drive_w_peak);
drive_lift   = drive_link_overhang_lift_N(drive_mass,
                                          drive_link_centroid_radius(drive_taper, drive_w_peak),
                                          clr, drive_w_peak);
// Floored at the drive links' own spacer bolt. The load never governs - it asks for about
// 3 mm even at 2 in - and the two spacers are the same job in the same plate on the same
// machine, so a frame tie smaller than the handle's own would be an odd thing to build.
tie_bolt     = bolt_smallest_at_least(
                   max(frame_link_tie_diameter(frame_link_tie_load_N(drive_lift, 2),
                                               bolt_material_yield),
                       pin_diameter(spacer_bolt)));
tie_tube     = structural_smallest_for_bore(bolt_clearance_hole_d(bolt_diameter(tie_bolt)));
tie_radius   = frame_link_tie_radius(tube, clr, structural_od(tie_tube));

// Where they can go. Everything that turns or sits between the frame links is taken out and
// what is left is the window; the ties are placed symmetrically in it, as far apart as it
// allows. A die with no drive holes swings the whole arc rather than one pitch, so its
// rotation and its drive band are both the arc.
die_rotation = n_drive_holes ? bend_indexed_rotation(n_drive_holes, forming_die_drive_pitch())
                             : forming_die_arc(bend_angle);
drive_swing  = n_drive_holes ? forming_die_drive_pitch() : forming_die_arc(bend_angle);
drive_w_tie  = drive_link_width_at(drive_plate, op_force, handle,
                                   is_undef(drive_hole_r) ? 0 : drive_hole_r,
                                   pin_diameter(frame_pin), pin_diameter(drive_pin),
                                   pin_diameter(spacer_bolt), tie_radius);
drive_hw_tie = bend_angular_half_width(drive_w_tie, tie_radius);
drive_band   = [drive_home_deg - drive_hw_tie, drive_home_deg + drive_swing + drive_hw_tie];
tie_window   = frame_link_tie_window(
                   die_plate_tail_angles(tube, clr, pin_diameter(ustrap_pin)),
                   die_rotation, drive_band,
                   followbar_angles(tube, clr, fb_pin_d));
tie_angles   = frame_link_tie_angles(tie_window, tie_radius, structural_od(tie_tube),
                                     frame_link_tie_gap(tube));
tie_pos      = frame_link_tie_positions(tie_angles, tie_radius);

// The pedestal post carries the operator's pull as bending and the drive torque as
// torsion, at the same time.
post          = structural_smallest_for_combined(op_force * pedestal_height_mm, moment * 1000,
                                                 pin_allowable_shear_fraction * 250);
post_length   = pedestal_height_mm - layout_working_height(layers);
foot_bolt     = pedestal_foot_bolt(post, op_force, pedestal_height_mm, moment,
                                   bolt_material_yield, bolts);


// How much bolt to leave below the base plate for whatever it is bolted through and a nut,
// mm. REASONED, NOT CITED, and an allowance rather than a dimension: what the machine is
// mounted ON is not the model's to know. A thicker bench wants a longer bolt.
mount_allowance = 30;

// The base plate is cut to the frame link's own footprint - it is what the lower link is
// WELDED to - so it cannot be known until the link's last arm is placed. That is the ties,
// which is why the anchor bolt is chosen here rather than up with the other fasteners.
link_extents = frame_link_extents(tube, clr, frame_plate, moment, pin_diameter(frame_pin),
                                  fb_pin_d, lock_pos, tie_pos);
anchor_bolt  = base_anchor_bolt(link_extents, tube, moment, op_force, bolt_material_yield,
                                bolts);
base_rect_mm = base_rect(link_extents, tube, bolt_diameter(anchor_bolt));

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
base_report(base_rect_mm, tube, clr, base_plate, frame_plate, link_w, fb_pin_d, moment,
            op_force, anchor_bolt, bolt_material_yield, layout_working_height(layers));

if (mount == "pedestal")
    pedestal_report(post, base_plate, post_length, foot_bolt, bolt_material_yield,
                    op_force, pedestal_height_mm, moment);

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

//
// The frame ties. Reported after the lock because they live in the same window it does.
//
echo(str("frame tie: ", len(tie_pos), " x ", bolt_size(tie_bolt), " through ",
         structural_size(tie_tube), " spacers, on r ", fmt_length(tie_radius),
         len(tie_pos) == 0 ? " - NOWHERE, the window behind the die will not take one"
                           : str(" at ", [for (a = tie_angles) round(a)], " deg")));
echo(str("           the window behind the die is ", round(tie_window[1] - tie_window[0]),
         " deg wide, from ", round(tie_window[0]), " to ", round(tie_window[1]),
         " - clear of the tail, the drive band and the followbar"));
echo(str("           holding ", fmt_force(drive_lift), " of handle trying to lift the drive",
         " pair's tail off the upper frame link, ",
         fmt_force(frame_link_tie_load_N(drive_lift, len(tie_pos))), " per tie"));
echo(str("           handle is ", fmt_mass(2 * drive_mass), " with its centre of mass ",
         fmt_length(drive_link_centroid_radius(drive_taper, drive_w_peak)),
         " out, bearing on the die plate at r ", fmt_length(clr)));

tie_chord = frame_link_tie_chord(tie_angles, tie_radius);

if (len(tie_pos) == 0)
    echo("DEPARTURE: the frame links cannot be tied together - nothing but the pin heads holds the upper one down");

// A pair closer together than the link is wide is worth reporting but is not a departure.
// A tie's job is to hold the plate DOWN, which even one can do; what a short chord gives up
// is resisting rotation about the tie line, and the frame pin bearing in its hole does that
// at every size whether the ties are far apart or not.
else if (len(tie_pos) == 1)
    echo(str("           ONE tie, not two: this die has no drive holes, so the link swings",
             " the whole arc and leaves too little behind it to separate a pair"));
else
    echo(str("           the pair stands ", fmt_length(tie_chord), " apart, against a link ",
             fmt_length(link_w), " wide",
             tie_chord < link_w
                 ? " - closer than the link is wide, so lean on the frame pin for the rotation"
                 : ""));

// pin_size() is the pin's NAME - "7/8 in dia" in both systems, because that is what you
// order. The load beside it is a measurement and converts.
echo(str("pins:    frame ", pin_size(frame_pin), " (", fmt_force(frame_force), ", ",
         pin_governing_mode(frame_force, t_centre, t_drive + t_frame, pin_material_yield),
         "), drive ", pin_size(drive_pin), " (", fmt_force(drive_force), ", ",
         pin_governing_mode(drive_force, t_centre, t_drive, pin_material_yield), ")"));
echo(str("         followbar ", pin_size(followbar_pin), " (", fmt_force(followbar_force),
         "), U-strap ", pin_size(ustrap_pin)));
// A pin is bought in quarter-inch steps of length, so a stack never fills one exactly. The
// difference is washers, and a builder who is not told assembles a joint that rattles.
frame_grip = layout_pin_grip(layers, "frame link lower");
echo(str("         ordered in 1/4 in steps of length: the frame pin grips ",
         fmt_length(frame_grip), " and orders ", fmt_length(pin_usable_length(frame_grip)),
         ", so ", fmt_length(pin_slack(frame_grip)), " of washers under its head"));
// Every hole on this machine is vertical and every pin comes out, so nothing retains any of
// them - which is the reference machine's answer too. See pin.scad's header.
echo(str("         all of them drop in HEAD UP with no retainer, and every one comes out:",
         " the frame pin to change a die, the drive pin at every stroke, the lock by hand"));
echo(str("         frame, followbar and lock seat on the base plate; drive, U-strap and",
         " spacer hang in the stack, where the head is what holds them"));
// A head-seated pin is held up by its head and nothing else, so a row with no head looked
// up is a real gap rather than a drawing detail. Not a DEPARTURE - it is the same missing
// catalogue data the BOM already marks, and it closes when the rows are filled in.
head_seated = [["drive", drive_pin], ["U-strap", ustrap_pin], ["spacer", spacer_bolt]];
unknown_heads = [for (h = head_seated) if (!pin_head_is_known(h[1])) h[0]];
for (h = unknown_heads)
    echo(str("         TO ORDER: the ", h, " pin hangs in the stack on a head this registry",
             " has no dimensions for - that row has to be looked up, it is the only thing",
             " holding the pin up"));
echo(str("         drive radius ", fmt_bare_length(nominal_r), " nominal -> ",
         fmt_length(drive_radius), " with the chosen pin"));
echo(str("stack:   ", fmt_length(layout_height(layers)), " overall, ",
         fmt_length(layout_frame_gap(layers)), " between the frame links"));
if (n_drive_holes) {
    echo(str("cycle:   ", bend_strokes(bend_angle, forming_die_drive_pitch(), n_drive_holes),
             " strokes of ",
             fmt_length(bend_stroke_travel_mm(forming_die_drive_pitch(), handle)),
             " at the handle's end, re-pinning the drive pin between each"));
    echo(str("         ", n_drive_holes, " drive holes index ",
             bend_indexed_rotation(n_drive_holes, forming_die_drive_pitch()), " deg of the ",
             forming_die_arc(bend_angle), " deg groove",
             stroke_overrun > 0
                 ? str(", so the last is over-pulled to ",
                       round(forming_die_drive_pitch() + stroke_overrun), " deg and ",
                       fmt_length(bend_stroke_travel_mm(
                           forming_die_drive_pitch() + stroke_overrun, handle)))
                 : " and nothing is left to over-pull"));
} else {
    echo(str("cycle:   1 stroke of ",
             fmt_length(bend_stroke_travel_mm(forming_die_arc(bend_angle), handle)),
             " at the handle's end - this die has no drive holes, so the link takes it",
             " round in one go on the U-strap pin"));
}

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

module clamp_stl()
    clamp(tube, clr, pin_diameter(ustrap_pin), bolt_diameter(clamp_bolt));

module followbar_stl() followbar(tube, fb_pin_d);

//
// The flat parts. These are CUT, not made - a laser, waterjet or plasma table takes a 2D
// outline - so each one is a `<name>_dxf` module, which NopSCADlib exports to dxfs/<name>.dxf
// and bills under "CNC cut" rather than under "Printed".
//
// The solid drawn in the assembly is extruded from the same profile, and when the manual's
// views are posed NopSCADlib swaps in the exported FILE in its place. That is what makes it
// a check rather than a claim: if the cut file and the picture ever disagree, the picture
// is the one that changes.
//
// NOTE: OpenSCAD writes curves into a DXF as polylines at the current $fn, so a cutter gets
// whatever `facets` was set to. Put it back to 90 before exporting anything a shop will
// quote from.
//
module die_plate_dxf()
    die_plate_2D(tube, clr, die_plate_stock, bend_angle, pin_diameter(frame_pin),
                 pin_diameter(drive_pin), pin_diameter(ustrap_pin),
                 bolt_diameter(plate_bolt), die_plate_bolts);

module drive_link_dxf()
    drive_link_2D(tube, clr, drive_plate, pin_diameter(frame_pin), pin_diameter(drive_pin),
                  drive_hole_r, bend_operator_force_N(moment, handle), handle,
                  pin_diameter(spacer_bolt));

module frame_link_dxf()
    frame_link_2D(tube, clr, frame_plate, moment, pin_diameter(frame_pin), fb_pin_d,
                  lock_pos, pin_diameter(lock_pin), tie_pos, bolt_diameter(tie_bolt));

module base_dxf()
    base_2D(base_rect_mm, base_plate, bolt_diameter(anchor_bolt));

module pedestal_foot_dxf()
    pedestal_foot_2D(post, base_plate, bolt_diameter(foot_bolt));

//
// The same parts, placed: which stock each is cut from, what it is called on the BOM, and
// what colour it takes in the manual. Written once here rather than at each use, because
// the three travel together and drift if they are copied.
//
module base_part()
    routed_plate(base_plate, "base", pp4_colour) base_dxf();

module die_plate_part()
    routed_plate(die_plate_stock, "die_plate", pp4_colour) die_plate_dxf();

module drive_link_part()
    routed_plate(drive_plate, "drive_link", pp2_colour) drive_link_dxf();

module frame_link_part()
    routed_plate(frame_plate, "frame_link", pp3_colour) frame_link_dxf();

module pedestal_foot_part()
    routed_plate(base_plate, "pedestal_foot", pp3_colour) pedestal_foot_dxf();

//! The pedestal is a WELDMENT, not a part: a purchased post with a cut foot welded to it.
//! Drawn with the top of the post at z = 0, running down.
module pedestal_weldment() {
    translate_z(-post_length)
        structural_tube(post, post_length);

    translate_z(-post_length - plate_thickness(base_plate))
        pedestal_foot_part();
}

//
// THE BUILD, IN FOUR STAGES.
//
// Three things are made up on the bench before anything goes together, and each is a real
// step rather than a way of grouping the drawing: a weldment that has to cool, a bolted
// group that never comes apart again, and a pair of links that has to be joined before the
// die will fit between them.
//
// NopSCADlib turns the comment above each of these into a section of readme.md, so what is
// written here is the build instructions - not a note to whoever edits the file next.
//

//! **Stage 1 - the base weldment.** The lower frame link is welded flat to the base plate,
//! and this is the joint the whole drive torque leaves through, so it is worth getting
//! right before anything else exists to be in the way.
//!
//! Fillet **both edges** of the link where it lands on the plate, everywhere it lands - the
//! run from the pivot to the followbar eye is what the report sizes, and the lock and tie
//! arms want the same bead round them. The plate is cut to the link's own outline plus a
//! margin, so if an arm is hanging over an edge something has gone wrong before the welder
//! got here. The leg is not written here on purpose - it is a
//! function of the plate you chose, so `just report` is where it lives and a number in this
//! sentence would be a lie for every configuration but one. It comes out at the code
//! minimum for every size in the range, with a factor of about six in hand on the load, so
//! what to be careful about is fusion and distortion rather than size. Tack both ends,
//! check the link is still flat and still square to the plate, then run it.
//!
//! On a pedestal build the post is welded to the underside of the plate at the same
//! setting, and to its foot at the other end. Both are a ring of fillet round the post's
//! outside diameter; the bore in the foot is there so a second pass can be run inside it.
//! Those two ARE load-sized rather than minimum-sized - the report says which - so they
//! want a real bead, not a tack.
module base_assembly()
assembly("base") {
    translate_z(layout_z(layers, "base"))
        base_part();

    // Not exploded. The post is obviously a separate piece, and moving it would leave the
    // foot bolts - which are placed in the main assembly, like the anchor bolts, because
    // they go into the floor rather than into this weldment - hanging in mid air.
    if (mount == "pedestal")
        translate_z(layout_z(layers, "base"))
            pedestal_weldment();

    explode(30)
        translate_z(layout_z(layers, "frame link lower"))
            frame_link_part();
}

//! **Stage 2 - the die.** The two die plates bolt to the faces of the forming die and never
//! come off again. They are what the clamp pins to, so their tails have to line up with
//! each other: bolt one on, use it to spot the other, and check the two tails are parallel
//! before anything is tightened.
//!
//! The bolts sit on a circle between the hub and the drive holes. The report gives the
//! shear in each against its allowable; they carry the clamp's whole drag on the tube plus
//! the moment that drag makes about the pivot, so they are not incidental fixings.
module die_assembly()
assembly("die") {
    stl_colour(pp1_colour) stl("forming_die") forming_die_stl();

    for (layer = ["die plate lower", "die plate upper"])
        explode(layer == "die plate upper" ? 30 : -30)
            translate_z(layout_z(layers, layer))
                die_plate_part();

    // Six bolts through both plates and the die. They were drilled for and never billed.
    for (p = plate_bolt_pos)
        explode(60)
            translate(concat(p, [layout_z(layers, "die plate upper")
                                     + layout_thickness(layers, "die plate upper")]))
                rotate([180, 0, 0])
                    bolt(plate_bolt, layout_central_thickness(layers));
}

//! **Stage 3 - the handle.** The two drive links are joined by the two spacer bolts at the
//! grip, each running through a length of tube that sets the gap and stops the pair being
//! pulled together when the bolts are done up. Without those tubes the bolts close the fork
//! and the die will not go in.
//!
//! Join them at the grip end only. The pivot end has to stay open, because that is where
//! the die assembly slides in at the next stage.
module handle_assembly()
assembly("handle") {
    for (layer = ["drive link lower", "drive link upper"])
        explode(layer == "drive link upper" ? 45 : -45)
            translate_z(layout_z(layers, layer))
                rotate(drive_angle)
                    drive_link_part();

    for (r = drive_link_spacer_radii(handle, pin_diameter(spacer_bolt)))
        rotate(drive_angle)
            translate([r, 0, layout_z(layers, "drive link lower")]) {
                pin(spacer_bolt, layout_pin_grip(layers, "drive link lower"), "stack");

                translate_z(t_drive)
                    structural_tube(spacer_tube, layout_drive_gap(layers));
            }
}

//! **Stage 4 - the machine.** Everything stacks bottom up on the base weldment, in the
//! order the stack itself is in: lower drive link, die assembly, upper drive link, upper
//! frame link.
//!
//! The handle pair is a fork joined only at its far end, so the die assembly slides into it
//! from the pivot end rather than being lowered in. Line the two up, drop the frame pin
//! through the lot, and fit its retainer at the top.
//!
//! Then the followbar, on its own pin between the frame links; the clamp, pinned to the die
//! plates' tails with its bolt left slack until a tube is in; and the die lock pin, which
//! goes in from the top through whichever drive hole has come round under it.
//!
//! **Every pin drops in head up and nothing retains it** - no cotters, no clips. That is the
//! reference machine's answer, not a shortcut: searched end to end, its manual has no
//! retainer of any kind on any pin [JD2-M32]. It works because every hole here is vertical
//! and the die turns about a vertical axis, so a pin that is upright at the start of a bend
//! is upright at the end. And it has to work that way, because all of them come out - the
//! frame pin to change a die, the drive pin at every stroke, the lock pin by hand.
//!
//! The frame, followbar and lock pins land on the base plate. The drive, U-strap and spacer
//! pins hang in the stack, where the head is the only thing holding them up.
//!
//! **The frame ties go in before the pins do.** Two bolts down through the upper frame link,
//! a spacer tube, the lower link and the base plate, to nuts underneath. The TUBE is what
//! sets the gap, so they can be pulled up hard without pinching the die and the drive links
//! between the frame plates - and they have to be pulled up hard, because they are what makes
//! the frame a frame. Without them the top plate is resting on three loose pins and comes off
//! with the first one you pull.
//!
//! Copy the reference machine's order exactly, because it is a good one: **ties hand tight,
//! pins in, then tighten the ties** - "as tightly as possible, while insuring the two pins
//! are perfectly vertical and slide easily through their respective holes" [JD2-M32 p.1].
//! The pins are the gauge. A pin that binds once the ties are down means the plates are not
//! parallel, and it is much easier to find out now than after the die is in.
//!
//! Last, the four anchor bolts at the base's corners, heads up, down through the mounting
//! surface to nuts underneath. **Do not use the machine before those are in.** They are the
//! only thing reacting the drive torque, and everything above them is sized on the
//! assumption that the base does not move.
//!
//! Take the pins as the alignment gauge while you tighten them, which is JD2's own
//! procedure and worth copying exactly: bolts hand tight, pins in, then "tighten the nuts
//! as tightly as possible, while insuring the two pins are perfectly vertical and slide
//! easily through their respective holes" [JD2-M32 p.1]. A pin that binds after the bolts
//! are pulled down means the plate is not flat, and that is much easier to fix now.
//!
//! And before every bend, from the same manual: **make sure all pins are completely seated
//! in their holes.** Their words for why - "failure to do this may cause damage to the
//! bender links or worse yet the operator may slip and fall".
module main_assembly()
assembly("main") {
    // BACKWARDS ON PURPOSE. NopSCADlib lists sub-assemblies in REVERSE order of first
    // appearance - bom.py inserts each one at the front of the list as it opens - so the
    // calls have to run backwards for the manual's contents to read forwards, stage 1
    // first. Reordering these changes the document, not the machine.
    handle_assembly();

    die_assembly();

    base_assembly();

    translate([clr, 0, 0])
        stl_colour(pp2_colour) stl("clamp") clamp_stl();

    for (p = die_plate_clamp_pins(tube, clr, pin_diameter(ustrap_pin)))
        translate(concat(p, [layout_z(layers, "die plate lower")]))
            pin(ustrap_pin, layout_z(layers, "die plate upper")
                            + layout_thickness(layers, "die plate upper")
                            - layout_z(layers, "die plate lower"),
                "stack");

    // The bolt that stops the tube sliding through the clamp, in from outboard.
    translate([clr + clamp_depth(tube, pin_diameter(ustrap_pin))
                   + bolt_head_height(clamp_bolt),
               -forming_die_tail_length(tube, clr) / 2, 0])
        rotate([0, -90, 0])
            bolt(clamp_bolt, clamp_depth(tube, pin_diameter(ustrap_pin))
                                 - forming_die_groove_radius(tube));

    translate(concat(frame_link_followbar_pos(tube, clr, fb_pin_d)
                         - [followbar_pin_offset(tube, fb_pin_d), 0], [0]))
        stl_colour(pp1_colour) stl("followbar") followbar_stl();

    translate(concat(frame_link_followbar_pos(tube, clr, fb_pin_d),
                     [layout_z(layers, "frame link lower")]))
        // Seats on the base plate, so no head; the cotter above the upper frame link is
        // what holds that link down, because this machine has no frame bolts.
        pin(followbar_pin, layout_pin_grip(layers, "frame link lower"), "base");

    explode(60)
        translate_z(layout_z(layers, "frame link upper"))
            frame_link_part();

    translate_z(layout_z(layers, "frame link lower"))
        pin(frame_pin, layout_pin_grip(layers, "frame link lower"), "base");

    // The frame ties: two bolts down through the upper link, a spacer tube, the lower link
    // and the base plate, to nuts underneath. The tube is what sets the gap, so tightening
    // them cannot pinch the die and the drive links between the frame plates - which is the
    // whole reason a tie here is a bolt through a tube rather than just a bolt.
    for (t = tie_pos)
        translate(concat(t, [layout_z(layers, "frame link upper")
                                 + layout_thickness(layers, "frame link upper")])) {
            rotate([180, 0, 0])
                bolt(tie_bolt, layout_z(layers, "frame link upper")
                                   + layout_thickness(layers, "frame link upper")
                                   - layout_z(layers, "base") + mount_allowance);

            translate_z(-(layout_thickness(layers, "frame link upper")
                          + layout_frame_gap(layers)))
                structural_tube(tie_tube, layout_frame_gap(layers));
        }

    // Four anchor bolts at the base's corners, heads up, running down through whatever
    // the machine is bolted to.
    for (p = base_anchor_positions(base_rect_mm, bolt_diameter(anchor_bolt)))
        translate(concat(p, [layout_z(layers, "base") + layout_thickness(layers, "base")]))
            rotate([180, 0, 0])
                bolt(anchor_bolt, layout_thickness(layers, "base") + mount_allowance);

    // Four more through the pedestal's foot, the same way.
    if (mount == "pedestal")
        for (p = pedestal_foot_bolts(post, bolt_diameter(foot_bolt)))
            translate(concat(p, [layout_z(layers, "base") - post_length]))
                rotate([180, 0, 0])
                    bolt(foot_bolt, plate_thickness(base_plate) + mount_allowance);

    // The die lock, through the whole stack into whichever drive hole is under it. The
    // assembly is drawn with the die at zero, and at zero the lock is just past the die's
    // trailing edge with nothing under it - which is right. A straight tube has nothing to
    // spring back; the die turns into the pin during the first stroke.
    if (!is_undef(lock_pos))
        translate(concat(lock_pos, [layout_z(layers, "frame link lower")]))
            // Nothing on either end. It seats on the base plate and it is LIFTED to
            // release the die, which is what JD2 does - theirs is parked by lifting and
            // rotating it so a cross roll pin rests on the frame [JD2-M32 p.8].
            pin(lock_pin, layout_pin_grip(layers, "frame link lower"), "base");

    if (!is_undef(drive_hole_r))
        rotate(drive_angle)
            translate([drive_hole_r, 0, layout_z(layers, "drive link lower")])
                // Hangs in the stack, so its own head is the stop - and that head is all
                // a pin pulled at every stroke should have on it.
                pin(drive_pin, layout_pin_grip(layers, "drive link lower"), "stack");

    translate([clr, -tube_length_mm / 2 + forming_die_tail_length(tube, clr) / 2, 0])
        rotate([90, 0, 0])
            tube(tube, tube_length_mm);
}

//! Draw whatever `show` asks for. NopSCADlib's make_all does not come through here - it
//! generates its own wrapper and calls the assembly and the `*_stl()` and `*_dxf()` modules
//! directly - so this is purely the interactive view, and a part selector costs the build
//! nothing.
module show_part(name) {
    if      (name == "assembly")    main_assembly();
    else if (name == "forming_die") forming_die_stl();
    else if (name == "die_plate")   die_plate_part();
    else if (name == "clamp")       clamp_stl();
    else if (name == "followbar")   followbar_stl();
    else if (name == "drive_link")  drive_link_part();
    else if (name == "frame_link")  frame_link_part();
    else if (name == "base")        base_part();
    else if (name == "pedestal")    pedestal_weldment();
    else assert(false, str("show: no such part - ", name));
}

show_part(show);
