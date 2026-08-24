<a name="TOP"></a>
# Tube-bender
A parametric manual rotary-draw tube bender, from 1/8 in to 2 in outside diameter.

The machine is the swing-arm pattern that J D Squared and Pro-Tools have sold for
decades: a grooved forming die on a centre pivot, a U-strap clamping the tube to it, a
followbar reacting the bending load, and a drive link that rotates the die from a
handle. What is new here is that it is derived rather than drawn - the die comes from
the tube, the pins come from the loads they carry, and the base bolt pattern comes from
the torque it has to react.

Every part of the working mechanism is built and derived: the forming die - machined
from one plate or stacked from flat-cut slices, behind the same interface - its plates,
the clamp, the followbar, the tapered frame and drive links, the die lock that holds the
die against springback between strokes, and a bench base or a pedestal.

## Driving it

Open this file in OpenSCAD and use the **Customizer** (Window > Customizer). Everything
that decides what the machine is has a control there: the tube, the bend, the plate
stock, the die style, the mounting, and which part to look at. `tube_bender.json` beside
this file carries a few worked configurations to start from, including the 1-1/2 in
prototype and a sliced-die build for a shop with no mill.

The **Units** tab switches the report and the BOM between metric and imperial as a
whole system - length, force, moment, stress and mass together, because inches with
newtons is harder to check than either on its own. It changes nothing that is
calculated, and it changes no name: a tube is "1-1/2 in OD x 0.095 in wall" and plate is
ordered as "1/4 in" in both.

Nothing in the Customizer is a dimension of a part. Every part is derived from the tube
and the loads, so choosing a 1 in tube resizes the die, the pins, the links, the base
and the handle together - and the arithmetic behind that is echoed rather than hidden.
`just report` prints it, or read the console after any render.

Why the numbers are what they are, and what each one rests on, is in
[docs/design-basis.md](docs/design-basis.md). What the Onshape prototype this was
started from actually measured, and which of its features survived, is in
[docs/reverse-engineering.md](docs/reverse-engineering.md).

![Main Assembly](assemblies/main_assembled.png)

<span></span>

---
## Table of Contents
1. [Parts list](#Parts_list)
1. [Main Assembly](#main_assembly)

<span></span>
[Top](#TOP)

---
<a name="Parts_list"></a>
## Parts list
| <span style="writing-mode: vertical-rl; text-orientation: mixed;">Main</span> | <span style="writing-mode: vertical-rl; text-orientation: mixed;">TOTALS</span> |  |
|---:|---:|:---|
|  | | **Vitamins** |
| &nbsp;&nbsp;4&nbsp; |  &nbsp;&nbsp;4&nbsp; | &nbsp;&nbsp; Bolt hex head 1/2 in x 44.45 mm, with nut and washers, NO ORDER NUMBER - this row is a hole in the BOM |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp; Cotter pin to suit a 1-1/8 in dia clevis pin, NO ORDER NUMBER - this row is a hole in the BOM |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp; Cotter pin to suit a 3/4 in dia clevis pin, NO ORDER NUMBER - this row is a hole in the BOM |
| &nbsp;&nbsp;2&nbsp; |  &nbsp;&nbsp;2&nbsp; | &nbsp;&nbsp; Cotter pin to suit a 5/16 in dia clevis pin, NO ORDER NUMBER - this row is a hole in the BOM |
| &nbsp;&nbsp;2&nbsp; |  &nbsp;&nbsp;2&nbsp; | &nbsp;&nbsp; Cotter pin to suit a 5/8 in dia clevis pin, NO ORDER NUMBER - this row is a hole in the BOM |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp; Pin clevis 1-1/8 in dia x 88.9 mm usable, NO ORDER NUMBER - this row is a hole in the BOM |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp; Pin clevis 3/4 in dia x 88.9 mm usable, 98306A868 |
| &nbsp;&nbsp;2&nbsp; |  &nbsp;&nbsp;2&nbsp; | &nbsp;&nbsp; Pin clevis 5/16 in dia x 82.55 mm usable, NO ORDER NUMBER - this row is a hole in the BOM |
| &nbsp;&nbsp;2&nbsp; |  &nbsp;&nbsp;2&nbsp; | &nbsp;&nbsp; Pin clevis 5/8 in dia x 57.15 mm usable, NO ORDER NUMBER - this row is a hole in the BOM |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp; Pin clevis 7/8 in dia x 82.55 mm usable, NO ORDER NUMBER - this row is a hole in the BOM |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp; Pin clevis 7/8 in dia x 88.9 mm usable, NO ORDER NUMBER - this row is a hole in the BOM |
| &nbsp;&nbsp;2&nbsp; |  &nbsp;&nbsp;2&nbsp; | &nbsp;&nbsp; Pin clip to suit a 7/8 in dia clevis pin that is pulled every stroke, NO ORDER NUMBER - this row is a hole in the BOM |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp; Plate mild steel 1-3/4 in, blank 228.6 x 190.5 mm, faced to 44.45 mm |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp; Plate mild steel 1-3/4 in, blank 54.37 x 76.2 mm, faced to 44.45 mm |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp; Plate mild steel 1-3/4 in, blank 57.55 x 76.2 mm, faced to 44.45 mm |
| &nbsp;&nbsp;2&nbsp; |  &nbsp;&nbsp;2&nbsp; | &nbsp;&nbsp; Plate mild steel 1/4 in, blank 2034.1 x 86.93 mm |
| &nbsp;&nbsp;2&nbsp; |  &nbsp;&nbsp;2&nbsp; | &nbsp;&nbsp; Plate mild steel 1/4 in, blank 228.6 x 190.5 mm |
| &nbsp;&nbsp;2&nbsp; |  &nbsp;&nbsp;2&nbsp; | &nbsp;&nbsp; Plate mild steel 1/4 in, blank 309.09 x 232.97 mm |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp; Plate mild steel 3/8 in, blank 171.45 x 171.45 mm |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp; Plate mild steel 3/8 in, blank 283.44 x 173.85 mm |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp; Tube 1-1/2 in OD x 0.095 in wall, ASTM A513 Type 1 ERW mild steel, as-welded, length 600 mm |
| &nbsp;&nbsp;2&nbsp; |  &nbsp;&nbsp;2&nbsp; | &nbsp;&nbsp; Tube 1/2 in OD x 0.065 in wall, mild steel, length 58.15 mm |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp; Tube 2-1/4 in OD x 0.120 in wall, mild steel, length 898.2 mm |
| &nbsp;&nbsp;35&nbsp; | &nbsp;&nbsp;35&nbsp; | &nbsp;&nbsp;Total vitamins count |
|  | | **3D printed parts** |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp;clamp.stl |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp;followbar.stl |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp;forming_die.stl |
| &nbsp;&nbsp;3&nbsp; | &nbsp;&nbsp;3&nbsp; | &nbsp;&nbsp;Total 3D printed parts count |
|  | | **CNC routed parts** |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp;base.dxf |
| &nbsp;&nbsp;2&nbsp; |  &nbsp;&nbsp;2&nbsp; | &nbsp;&nbsp;die_plate.dxf |
| &nbsp;&nbsp;2&nbsp; |  &nbsp;&nbsp;2&nbsp; | &nbsp;&nbsp;drive_link.dxf |
| &nbsp;&nbsp;2&nbsp; |  &nbsp;&nbsp;2&nbsp; | &nbsp;&nbsp;frame_link.dxf |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp;pedestal_foot.dxf |
| &nbsp;&nbsp;8&nbsp; | &nbsp;&nbsp;8&nbsp; | &nbsp;&nbsp;Total CNC routed parts count |

<span></span>
[Top](#TOP)

---
<a name="main_assembly"></a>
## Main Assembly
### Vitamins
|Qty|Description|
|---:|:----------|
|4| Bolt hex head 1/2 in x 44.45 mm, with nut and washers, NO ORDER NUMBER - this row is a hole in the BOM|
|1| Cotter pin to suit a 1-1/8 in dia clevis pin, NO ORDER NUMBER - this row is a hole in the BOM|
|1| Cotter pin to suit a 3/4 in dia clevis pin, NO ORDER NUMBER - this row is a hole in the BOM|
|2| Cotter pin to suit a 5/16 in dia clevis pin, NO ORDER NUMBER - this row is a hole in the BOM|
|2| Cotter pin to suit a 5/8 in dia clevis pin, NO ORDER NUMBER - this row is a hole in the BOM|
|1| Pin clevis 1-1/8 in dia x 88.9 mm usable, NO ORDER NUMBER - this row is a hole in the BOM|
|1| Pin clevis 3/4 in dia x 88.9 mm usable, 98306A868|
|2| Pin clevis 5/16 in dia x 82.55 mm usable, NO ORDER NUMBER - this row is a hole in the BOM|
|2| Pin clevis 5/8 in dia x 57.15 mm usable, NO ORDER NUMBER - this row is a hole in the BOM|
|1| Pin clevis 7/8 in dia x 82.55 mm usable, NO ORDER NUMBER - this row is a hole in the BOM|
|1| Pin clevis 7/8 in dia x 88.9 mm usable, NO ORDER NUMBER - this row is a hole in the BOM|
|2| Pin clip to suit a 7/8 in dia clevis pin that is pulled every stroke, NO ORDER NUMBER - this row is a hole in the BOM|
|1| Plate mild steel 1-3/4 in, blank 228.6 x 190.5 mm, faced to 44.45 mm|
|1| Plate mild steel 1-3/4 in, blank 54.37 x 76.2 mm, faced to 44.45 mm|
|1| Plate mild steel 1-3/4 in, blank 57.55 x 76.2 mm, faced to 44.45 mm|
|2| Plate mild steel 1/4 in, blank 2034.1 x 86.93 mm|
|2| Plate mild steel 1/4 in, blank 228.6 x 190.5 mm|
|2| Plate mild steel 1/4 in, blank 309.09 x 232.97 mm|
|1| Plate mild steel 3/8 in, blank 171.45 x 171.45 mm|
|1| Plate mild steel 3/8 in, blank 283.44 x 173.85 mm|
|1| Tube 1-1/2 in OD x 0.095 in wall, ASTM A513 Type 1 ERW mild steel, as-welded, length 600 mm|
|2| Tube 1/2 in OD x 0.065 in wall, mild steel, length 58.15 mm|
|1| Tube 2-1/4 in OD x 0.120 in wall, mild steel, length 898.2 mm|


### 3D Printed parts

| 1 x [clamp.stl](stls/clamp.stl) | 1 x [followbar.stl](stls/followbar.stl) | 1 x [forming_die.stl](stls/forming_die.stl) |
|---|---|---|
| ![clamp.stl](stls/clamp.png) | ![followbar.stl](stls/followbar.png) | ![forming_die.stl](stls/forming_die.png) 



### CNC Routed parts

| 1 x [base.dxf](dxfs/base.dxf) | 2 x [die_plate.dxf](dxfs/die_plate.dxf) | 2 x [drive_link.dxf](dxfs/drive_link.dxf) |
|---|---|---|
| ![base.dxf](dxfs/base.png) | ![die_plate.dxf](dxfs/die_plate.png) | ![drive_link.dxf](dxfs/drive_link.png) 


| 2 x [frame_link.dxf](dxfs/frame_link.dxf) | 1 x [pedestal_foot.dxf](dxfs/pedestal_foot.dxf) |
|---|---|
| ![frame_link.dxf](dxfs/frame_link.png) | ![pedestal_foot.dxf](dxfs/pedestal_foot.png) 



### Assembly instructions
![main_assembly](assemblies/main_assembly.png)

The stack, with the tube where it goes in. The handle, the followbar, the U-strap and
the base are not built yet.

![main_assembled](assemblies/main_assembled.png)

<span></span>
[Top](#TOP)
