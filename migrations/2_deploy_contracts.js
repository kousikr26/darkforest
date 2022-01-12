const Verifier = artifacts.require("Verifier");
const GameState = artifacts.require("GameState");
const MoveVerifier = artifacts.require("MoveVerifier");

module.exports = function (deployer) {
    deployer.deploy(Verifier).then(function() {
      return deployer.deploy(MoveVerifier).then(function(){
        return deployer.deploy(GameState, Verifier.address, MoveVerifier.address);
      })
      
    });    
};

