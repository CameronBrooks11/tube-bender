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

$fn = 90;

//
// Configuration. This becomes a set of config_<target>.scad files once there is more than
// one thing to vary; for now the prototype size is the one being checked against.
//
tube = tube_1p500x0p095;
clr  = bend_default_clr(tube);

tube_length = 600;

bend_report(tube, clr);

//! Nothing is assembled yet. This is the tube the rest of the machine is derived from.
module main_assembly()
assembly("main") {
    tube(tube, tube_length);
}

main_assembly();
