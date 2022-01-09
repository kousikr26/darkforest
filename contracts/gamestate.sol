// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

interface IVerifier {
     function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[3] memory input
        ) external view returns (bool r);
}

contract GameState {
    IVerifier verifier;
    uint public minDist = 32;
    uint public maxDist = 64;
    uint public location_hash;
    struct Player {
        uint location_hash;
        uint spawn_time;
        bool player_present;
        bool location_isspawned;
    }
    mapping (uint => Player) spawned_locations;

    constructor(address verifier_address) {
        verifier = IVerifier(verifier_address);
    }
    function spawn_player(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[3] memory input
    ) public {
        location_hash = input[0];
        require(verifier.verifyProof(a, b, c, input), "Submitted proof is invalid");
        require(!spawned_locations[location_hash].player_present, "Spawned location is not empty");
        require(!(spawned_locations[location_hash].location_isspawned) || (block.timestamp > spawned_locations[location_hash].spawn_time + 300), "Location has been spawned in recently");
        

        Player memory newplayer = Player(location_hash, block.timestamp, true, true);
        spawned_locations[location_hash] = newplayer;

    }
}