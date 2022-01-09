const Verifier = artifacts.require("Verifier");
const GameState = artifacts.require("GameState");

module.exports = function (deployer) {
    deployer.deploy(Verifier).then(function() {
      return deployer.deploy(GameState, Verifier.address);
    });    
};

