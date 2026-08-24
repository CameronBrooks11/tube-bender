//
// Dumps the registry rows a Customizer dropdown has to offer, for scripts/customizer.py.
//
// Not part of the model. It lives outside scad/ on purpose: `just check-scad` walks that
// directory and requires every file in it to be either an entry point that renders or a
// component that renders nothing, and this is neither - it is a report for a tool.
//
include <../scad/purchased/tubes.scad>
include <../scad/purchased/plates.scad>

for (t = tubes)  echo(str("OPT|tube|",  tube_name(t),  "|", tube_size(t)));
for (p = plates) echo(str("OPT|plate|", plate_name(p), "|", plate_size(p)));
