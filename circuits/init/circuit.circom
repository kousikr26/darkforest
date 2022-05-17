pragma circom 2.0.0;

include "../mimcsponge.circom";
include "../comparators.circom";
// function findGCD (x, y){
//     var p = x;
//     var q = y;
//     if (p == 0){
//         return q;
//     }
//     return findGCD(q%p, p);
// }

// template IsPrimeGCD() {
//     signal input x;
//     signal input y;
//     signal output out;
//     var gcd = findGCD(x, y);
//     var isprime = 1;
//     for (var i = 2; i*i <= gcd; i++){
//         if (gcd%i == 0){
//             isprime = 0;
//         }
//     }
//     if (gcd == 1){
//         isprime = 0;
//     }
//     out <-- isprime;

// }


template Main() {
    signal input x;
    signal input y;


    signal output h;

    // // Check if gcd is prime
    // component gcdcomp = IsPrimeGCD();
    // gcdcomp.x <== x;
    // gcdcomp.y <== y;
    // gcdcomp.out === 1;


    /* check x^2 + y^2 < r^2 */
    component comp = LessThan(64);
    component comp2 = GreaterThan(64);
    signal xSq;
    signal ySq;
    signal maxRSq;
    signal minRSq;
    xSq <== x * x;
    ySq <== y * y;
    maxRSq <== 1024 * 1024;
    minRSq <== 32 * 32;

    comp.in[0] <== xSq + ySq;
    comp.in[1] <== maxRSq;
    comp.out === 1;

    comp2.in[0] <== xSq + ySq;
    comp2.in[1] <== minRSq;
    comp2.out === 1;

    /* check MiMCSponge(x,y) = pub */
    component mimc = MiMCSponge(2, 220, 1);

    mimc.ins[0] <== x;
    mimc.ins[1] <== y;
    mimc.k <== 0;

    h <== mimc.outs[0];
}

component main = Main();