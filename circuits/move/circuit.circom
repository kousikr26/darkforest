pragma circom 2.0.0;

include "../mimcsponge.circom";
include "../comparators.circom";



template Main() {
    // Previous coordinates
    signal input prevX;
    signal input prevY;
    // New coordinates
    signal input x;
    signal input y;
    // Auxiliary variables
    signal input maxMovement;
    signal input maxRadius;
    // Output hashes
    signal output newHash;
    signal output prevHash;



    // check x^2 + y^2 < maxRadius^2 
    component comp = LessThan(64);

    signal xSq;
    signal ySq;
    signal maxRSq;
    xSq <== x * x;
    ySq <== y * y;
    maxRSq <== maxRadius * maxRadius;

    comp.in[0] <== xSq + ySq;
    comp.in[1] <== maxRSq + 1;
    comp.out === 1;

    // Check if change in coordinates is less than maxMovement
    component comp2 = LessThan(64);    
    signal delXSq;
    signal delYSq;
    delXSq <== (x - prevX) * (x - prevX);
    delYSq <== (y - prevY) * (y - prevY);

    comp2.in[0] <== delXSq + delYSq;
    comp2.in[1] <== maxMovement * maxMovement + 1;
    comp2.out === 1;


    // Compute the MIMCS Hash of new and old coordinates
    component mimc = MiMCSponge(2, 220, 1);
    mimc.ins[0] <== x;
    mimc.ins[1] <== y;
    mimc.k <== 0;

    newHash <== mimc.outs[0];

    component mimc2 = MiMCSponge(2, 220, 1);
    mimc2.ins[0] <== prevX;
    mimc2.ins[1] <== prevY;
    mimc2.k <== 0;
    prevHash <== mimc2.outs[0];


}

component main {public [maxMovement, maxRadius]} = Main();