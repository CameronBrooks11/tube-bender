//
//! A parametric manual rotary-draw tube bender, from 1/8 in to 2 in outside diameter.
//!
//! The machine is the swing-arm pattern that J D Squared and Pro-Tools have sold for
//! decades: a grooved forming die on a centre pivot, a U-strap clamping the tube to it, a
//! followbar reacting the bending load, and a drive link that rotates the die from a
//! handle. What is new here is that it is derived rather than drawn - the die comes from
//! the tube, the handle comes from a force budget, and the base bolt pattern comes from
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

use <utils/bend.scad>
use <custom/forming_die.scad>

$fn = 90;

//
// Configuration. This becomes a set of config_<target>.scad files once there is more than
// one thing to vary; for now the prototype size is the one being checked against.
//
tube       = tube_1p500x0p095;
clr        = bend_default_clr(tube);
bend_angle = 180;

// Pins are still chosen here rather than derived. The drive pin's load is reported by
// forming_die_report() so the choice can be checked; deriving it needs the drive link's
// geometry, which does not exist yet.
frame_pin  = pin_0p750x3p750;
drive_pin  = pin_0p750x3p750;
ustrap_pin = pin_0p750x3p750;

tube_length = 600;

bend_report(tube, clr);
forming_die_report(tube, clr, bend_angle,
                   pin_diameter(frame_pin), pin_diameter(drive_pin),
                   pin_diameter(ustrap_pin));

module forming_die_stl()
    forming_die(tube, clr, bend_angle,
                pin_diameter(frame_pin), pin_diameter(drive_pin),
                pin_diameter(ustrap_pin));

//! The tube is shown straight, as it goes in. Nothing holds it yet.
module main_assembly()
assembly("main") {
    stl_colour(pp1_colour) stl("forming_die") forming_die_stl();

    translate([clr, -tube_length / 2 + forming_die_tail_length(tube, clr) / 2, 0])
        rotate([90, 0, 0])
            tube(tube, tube_length);
}

main_assembly();
