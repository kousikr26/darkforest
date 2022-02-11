const Verifier = artifacts.require("Verifier");
const DarkForest = artifacts.require("DarkForest");
const MoveVerifier = artifacts.require("MoveVerifier");

contract('DarkForest',() => {


    it("should deploy the contract", async () => {
        const verifier = await Verifier.new();
        const moveVerifier = await MoveVerifier.new();
        const darkForest = await DarkForest.new(verifier.address, moveVerifier.address);


        darkForest = await DarkForest.deployed();
        assert(darkForest.address !== '');
    });


});