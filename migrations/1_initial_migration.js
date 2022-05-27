const Migrations = artifacts.require("Migrations");
const CredentialBox = artifacts.require("CredentialBox.sol");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(CredentialBox);
};
