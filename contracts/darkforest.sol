// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;
import "hardhat/console.sol";
// Interface for the Spawn verifier contract
interface IVerifier {
     function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) external view returns (bool r);
}
// Interface for the Move verifier contract
interface IMoveVerifier {
     function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[2] memory input
        ) external view returns (bool r);
}

contract DarkForest {
    // Declare interfaces
    IVerifier verifier;
    IMoveVerifier move_verifier;

    // Declare global variables
    uint public minDist = 32;
    uint public maxDist = 64;

    // Declare player counter that also acts as ID
    uint public num_players = 0;

    uint[] public all_locations;

    // Declare events
    event Spawn(uint loc, uint num_players);
    event Move(uint player_id, uint prevloc, uint newloc, uint collected_resources, uint collecting_resources);
    event PlayerDetails(uint player_id, uint location, uint arrival_time, uint collected_resources, uint collecting_resources);
    event PlanetDetails(bool isPlanet, uint resources);

    // Declare structs for player, location and planet
    struct Player {
        uint player_id;
        uint location;
        uint arrival_time;
        uint collected_resources;
        uint collecting_resources;
        bool player_present;
    }
    struct Location {
        uint arrival_time;
        bool location_present;
    }
    struct Planet {
        bool planet_present;
        uint resources_remaining;
        bool planet_exists;
    }
    // Declare mappings
    mapping (uint => Player) player_locations; // Mapping of locations to Players
    mapping (uint => Location) spawned_locations; // Mapping of location hashes to Location struct
    mapping (uint => Player[]) other_players; // When a location has more than one player, this is used to store the other players
    mapping (uint => Planet) planet_resources; // Mapping of location to Planet struct

    constructor(address verifier_address, address move_verifier_address) {
        // Initialize interfaces
        verifier = IVerifier(verifier_address);
        move_verifier = IMoveVerifier(move_verifier_address);
    }

    // Spawn a new player
    function spawn_player(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public {
        uint location_hash = input[0];
        console.log("Spawning player at location: %s",location_hash);
        console.log("Player present at location : %s ", player_locations[location_hash].player_present);
        // Require that proof is valid, the location is not already occupied and location was not spawned in 5 minutes ago
        require(verifier.verifyProof(a, b, c, input), "Submitted proof is invalid");
        require(!player_locations[location_hash].player_present, "Spawned location is not empty");
        require((!spawned_locations[location_hash].location_present) || (block.timestamp > spawned_locations[location_hash].arrival_time + 300), "Location has been spawned in recently");
        
        num_players+=1;

        // Create new player and add to mapping
        Player memory newplayer = Player(num_players, location_hash, block.timestamp, 0, 0, true);
        player_locations[location_hash] = newplayer;

        // Save the location as having spawned in to prevent respawn in 5 minutes
        Location memory newlocation = Location(block.timestamp, true);
        spawned_locations[location_hash] = newlocation;

        all_locations.push(location_hash);

        // Emit a spawn event
        emit Spawn(location_hash, num_players);

    }

    // Move a player
    function move_player(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[2] memory input,
        uint collect_amount
    ) public {
        // Extract the old and new location hashes from input
        uint new_location_hash = input[0];
        uint old_location_hash = input[1];

        // Check the resources of the new planet that player is moving to
        uint new_planet_resources;
        bool new_planet_isPlanet;
        (new_planet_isPlanet, new_planet_resources)  = planet_details(new_location_hash);

        // Chech if proof is valid, the players previous location matches the state on the chain
        require(move_verifier.verifyProof(a, b, c, input), "Submitted proof is invalid");
        require(player_locations[old_location_hash].player_present, "Player submitted invalid previous location");

        // Check if player has moved within 30 secongs and if the requested resources is less than the amount planet has
        require(block.timestamp > player_locations[old_location_hash].arrival_time + 30, "Player has moved recently");
        require((collect_amount>=0) && (collect_amount <= new_planet_resources), "Collect amount must be less than available resources");

        // Store the player who is moving
        Player memory moving_player = player_locations[old_location_hash];
        
        // If the player is moving to a new location
        if (new_location_hash != old_location_hash){
            // Store all the resources collected on the old planet
            moving_player.collected_resources = moving_player.collecting_resources;
            moving_player.collecting_resources = 0;
            // Change the player's location
            moving_player.location = new_location_hash;

            // If the new location already has a player
            if (player_locations[new_location_hash].player_present){
                // Fetch the existing player
                Player memory other_player = player_locations[new_location_hash];
                // Give all the resources collected by them to the moving player
                moving_player.collecting_resources = other_player.collecting_resources;
                // Reset their resource counter
                other_player.collecting_resources = 0;
                // Push the existing player into the mapping array
                other_players[new_location_hash].push(other_player);
                // Update the location mapping
                player_locations[new_location_hash] = moving_player;
            } else {  
                // If the new location is emptu

                // Collect the resources the user requested
                moving_player.collecting_resources += collect_amount;
                // Decrement the planets resources
                update_planet_details(new_location_hash, new_planet_resources - collect_amount);
                // Update the location mapping
                player_locations[new_location_hash] = moving_player;
            }
            // Delete the old location from mapping
            delete player_locations[old_location_hash];
            all_locations.push(new_location_hash);
            // If there exists other players put them in the main mapping
            if (other_players[old_location_hash].length > 0){
                player_locations[old_location_hash] = other_players[old_location_hash][other_players[old_location_hash].length - 1];
                other_players[old_location_hash].pop();
            } 
        }
        else{
            // If the player is moving to the same location
            moving_player.collecting_resources += collect_amount;
            // Decrement the planets resources
            update_planet_details(new_location_hash, new_planet_resources - collect_amount);
            // Update the location mapping
            player_locations[new_location_hash] = moving_player;
        }
        emit Move(moving_player.player_id, old_location_hash, new_location_hash, moving_player.collected_resources, moving_player.collecting_resources);
    }

    // Get the resources available on a planet
    // Performs the mapping uniformly i.e equal probability to have 0, 1, 2, 3 resources
    function planet_details(uint location_hash) public returns (bool isPlanet, uint resources){
        // If planet exists in mapping fetch the most recent value
        if (planet_resources[location_hash].planet_exists){
            return (planet_resources[location_hash].planet_present, planet_resources[location_hash].resources_remaining);
        }
        else{
            // Function to compute the resources based on hash
            uint planet_type = location_hash % 4;
            if (planet_type == 0) {
                isPlanet = false;
                resources = 0;
            }
            else if (planet_type == 1){
                isPlanet = true;
                resources = 1;
            }
            else if (planet_type == 2){
                isPlanet = true;
                resources = 2;
            }
            else if (planet_type == 3){
                isPlanet = true;
                resources = 3;
            }
            // Add the calculated resorces to the mapping
            planet_resources[location_hash] = Planet(isPlanet, resources, true);
            return (planet_resources[location_hash].planet_present, planet_resources[location_hash].resources_remaining);
        }
        
    }
    // Emit the planet details
    function get_planet_details(uint location_hash) public view returns (bool isPlanet, uint resources){
       if (planet_resources[location_hash].planet_exists){
            return (planet_resources[location_hash].planet_present, planet_resources[location_hash].resources_remaining);
        }
        else{
            uint planet_type = location_hash % 4;
            if (planet_type == 0) {
                isPlanet = false;
                resources = 0;
            }
            else if (planet_type == 1){
                isPlanet = true;
                resources = 1;
            }
            else if (planet_type == 2){
                isPlanet = true;
                resources = 2;
            }
            else if (planet_type == 3){
                isPlanet = true;
                resources = 3;
            }
            // Add the calculated resorces to the mapping
            return (isPlanet, resources);
        }
    }

    // Update the details of a planet
    function update_planet_details(uint location_hash, uint resources) public {
        planet_resources[location_hash].resources_remaining = resources;
    }
    function get_leaderboard() public view returns (uint[] memory){
        uint count = 0;
        for(uint i = 0; i<all_locations.length; i++){
            if (player_locations[all_locations[i]].player_present){
                count+=1;
            }
        }
        uint[] memory leaderboard = new uint[](2*count);
        uint index = 0;
        for(uint i = 0; i<all_locations.length; i++){
            if (player_locations[all_locations[i]].player_present){
                leaderboard[index] = player_locations[all_locations[i]].player_id;
                leaderboard[index+1] = player_locations[all_locations[i]].collected_resources;
                index+=2;
            }
        }
        console.log(leaderboard.length);
        return leaderboard;
    }
    // Get all players at a location
    function get_players_at(uint location)public {
        if (player_locations[location].player_present){
            emit PlayerDetails(player_locations[location].player_id, player_locations[location].location, player_locations[location].arrival_time, player_locations[location].collected_resources, player_locations[location].collecting_resources);
        }
        if (other_players[location].length > 0){
            for (uint i = 0; i < other_players[location].length; i++){
                emit PlayerDetails(other_players[location][i].player_id, other_players[location][i].location, other_players[location][i].arrival_time, other_players[location][i].collected_resources, other_players[location][i].collecting_resources);
            }
        }

    }
}