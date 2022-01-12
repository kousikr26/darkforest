const Verifier = artifacts.require("Verifier");
const GameState = artifacts.require("GameState");
const MoveVerifier = artifacts.require("MoveVerifier");

contract('GameState',() => {


    it("should deploy the contract", async () => {
        const verifier = await Verifier.new();
        const moveVerifier = await MoveVerifier.new();
        const gameState = await GameState.new(verifier.address, moveVerifier.address);


        gameState = await GameState.deployed();
        assert(gameState.address !== '');
    });


});