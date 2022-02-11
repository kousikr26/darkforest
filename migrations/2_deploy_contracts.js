const Verifier = artifacts.require("Verifier");
const DarkForest = artifacts.require("DarkForest");
const MoveVerifier = artifacts.require("MoveVerifier");

module.exports = function (deployer) {
    deployer.deploy(Verifier).then(function() {
      return deployer.deploy(MoveVerifier).then(function(){
        return deployer.deploy(DarkForest, Verifier.address, MoveVerifier.address);
      })
      
    });    
};

