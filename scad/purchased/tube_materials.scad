//
// Tube materials, as conditions of a specification rather than as adjectives.
// DO NOT FORMAT THIS FILE, it is manually spaced out for readability.
//
// A row states what the standard says and nothing more. ASTM A513 specifies mechanical
// properties as BANDS across grades 1008 through 1026, not as single numbers, so the band
// is what is registered. Picking a midpoint would invent a precision the specification
// does not have, and the drive torque in utils/bend.scad is computed at the TOP of the
// band because that is the tube that is hardest to bend.
//
// Source: Totten Tubes, "Hardness Limits and Tensile Properties for A513 Steel Round
// Tubing" - https://www.tottentubes.com/astm-a513-specification-information
// See docs/references.md [TOTTEN-A513] and docs/design-basis.md section 6.
//
// Deliberately absent: 4130 chromoly. The JD2 manual repeatedly contrasts it with mild
// steel and it is what people actually build roll cages from, so it belongs here - but no
// source for its yield has been read, and a plausible number registered beside two sourced
// ones acquires their authority. It gets a row when it gets a citation.
//
//                       ["name"          "description"                          yield MPa    colour  ]
//                                                                              [min,  max]

A513_T1       = ["A513_T1",      "ASTM A513 Type 1 ERW mild steel, as-welded",  [207,  310], "silver"];
A513_NORM     = ["A513_NORM",    "ASTM A513 mild steel, normalized",            [159,  276], "silver"];
A513_T5_DOM   = ["A513_T5_DOM",  "ASTM A513 Type 5 DOM mild steel, as-drawn",   [345,  483], "silver"];
A513_T5_SR    = ["A513_T5_SR",   "ASTM A513 Type 5 DOM, stress-relieved",       [310,  448], "silver"];

tube_materials = [A513_T1, A513_NORM, A513_T5_DOM, A513_T5_SR];

use <tube_material.scad>
