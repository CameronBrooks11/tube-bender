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
//! Why the numbers are what they are, and what each one rests on, is in
//! [docs/design-basis.md](docs/design-basis.md). What the Onshape prototype this was
//! started from actually measured, and which of its features survived, is in
//! [docs/reverse-engineering.md](docs/reverse-engineering.md).
//
include <NopSCADlib/core.scad>

include <purchased/tubes.scad>
include <purchased/pins.scad>
include <purchased/plates.scad>

include <utils/bend.scad>;    // bend_operator_force_ceiling is a variable, so include
use <utils/layout.scad>
use <utils/pin_sizing.scad>
use <custom/forming_die.scad>
use <custom/drive_link.scad>
use <custom/frame_link.scad>

$fn = 90;

//
// Configuration. This becomes a set of config_<target>.scad files once there is more than
// one thing to vary; for now the prototype size is the one being checked against.
//
tube        = tube_1p500x0p095;
clr         = bend_default_clr(tube);
bend_angle  = 180;

drive_plate = plate_0p250in;
frame_plate = plate_0p250in;

tube_length = 600;

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
layers    = layout_layers(tube, drive_plate, frame_plate);
t_drive   = plate_thickness(drive_plate);
t_frame   = plate_thickness(frame_plate);
t_die     = forming_die_thickness(tube);

// Pass 1: a nominal drive pin, to get a drive radius to size against.
nominal_pin   = tube_od(tube) / 2;
nominal_r     = forming_die_drive_radius(tube, clr, nominal_pin);
drive_force_0 = bend_drive_pin_force_N(moment, nominal_r);
drive_pin     = pin_smallest_at_least(
                    pin_required_diameter(drive_force_0, t_die, t_drive, pin_material_yield));

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
                  pin_required_diameter(frame_force, t_die, t_drive + t_frame,
                                        pin_material_yield));

// The U-strap holds the tube to the die against the same force the followbar applies.
ustrap_pin = pin_smallest_at_least(
                 pin_required_diameter(followbar_force, t_die, t_frame, pin_material_yield));

drive_angles = forming_die_drive_angles(tube, clr, pin_diameter(frame_pin),
                                        pin_diameter(drive_pin), bend_angle);
drive_angle  = len(drive_angles) ? drive_angles[0] : 0;
// undef on a die with no room for drive holes, and the link then draws no hole.
drive_hole_r = len(drive_angles) ? drive_radius : undef;

bend_report(tube, clr, handle);
forming_die_report(tube, clr, bend_angle, pin_diameter(frame_pin),
                   pin_diameter(drive_pin), pin_diameter(ustrap_pin));
drive_link_report(tube, clr, drive_plate, pin_diameter(frame_pin),
                  pin_diameter(drive_pin), drive_hole_r, bend_operator_force_N(moment, handle), handle);
frame_link_report(tube, clr, frame_plate, moment, pin_diameter(frame_pin),
                  pin_diameter(followbar_pin));

echo(str("pins:    frame ", pin_size(frame_pin), " (", round(frame_force), " N, ",
         pin_governing_mode(frame_force, t_die, t_drive + t_frame, pin_material_yield),
         "), drive ", pin_size(drive_pin), " (", round(drive_force), " N, ",
         pin_governing_mode(drive_force, t_die, t_drive, pin_material_yield), ")"));
echo(str("         followbar ", pin_size(followbar_pin), " (", round(followbar_force),
         " N), U-strap ", pin_size(ustrap_pin)));
echo(str("         drive radius ", nominal_r, " mm nominal -> ", drive_radius,
         " mm with the chosen pin"));
echo(str("stack:   ", layout_height(layers), " mm overall, ", layout_frame_gap(layers),
         " mm between the frame links"));

module forming_die_stl()
    forming_die(tube, clr, bend_angle, pin_diameter(frame_pin),
                pin_diameter(drive_pin), pin_diameter(ustrap_pin));

module drive_link_stl()
    drive_link(tube, clr, drive_plate, pin_diameter(frame_pin), pin_diameter(drive_pin),
               drive_hole_r, bend_operator_force_N(moment, handle), handle);

module frame_link_stl()
    frame_link(tube, clr, frame_plate, moment, pin_diameter(frame_pin),
               pin_diameter(followbar_pin));

//! The stack, with the tube where it goes in. The handle, the followbar, the U-strap and
//! the base are not built yet.
module main_assembly()
assembly("main") {
    stl_colour(pp1_colour) stl("forming_die") forming_die_stl();

    // The links are drawn with their drive hole on +x, so the pair has to be turned to
    // whichever die drive hole the pin is in. Drawing them at zero while the pin sits at
    // the hole angle puts the pin through solid plate.
    for (layer = ["drive link lower", "drive link upper"])
        translate_z(layout_z(layers, layer))
            rotate(drive_angle)
                stl_colour(pp2_colour) stl("drive_link") drive_link_stl();

    for (layer = ["frame link lower", "frame link upper"])
        translate_z(layout_z(layers, layer))
            stl_colour(pp3_colour) stl("frame_link") frame_link_stl();

    translate_z(layout_bottom(layers))
        pin(frame_pin, layout_pin_length(layers, "frame link lower"));

    if (!is_undef(drive_hole_r))
        rotate(drive_angle)
            translate([drive_hole_r, 0, layout_z(layers, "drive link lower")])
                pin(drive_pin, layout_pin_length(layers, "drive link lower"));

    translate([clr, -tube_length / 2 + forming_die_tail_length(tube, clr) / 2, 0])
        rotate([90, 0, 0])
            tube(tube, tube_length);
}

main_assembly();
