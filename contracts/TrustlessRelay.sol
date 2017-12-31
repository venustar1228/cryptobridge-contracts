pragma solidity ^0.4.18;

import "./Merkle.sol";
import "tokens/Token.sol";  // truffle package (install with `truffle install tokens`)
import "tokens/HumanStandardToken.sol";

contract TrustedRelay {

  event HeaderRoot(address indexed origin, bytes32 indexed root, uint256 indexed i, address submitter);


  address public admin;
  // Reward for successfully contesting a headerRoot
  uint256 public bountyWei = 1000000000000000;
  // Number of blocks included in a headerRoot
  uint256 public width = 1024;
  // The root of a Merkle tree made of consecutive block headers.
  // These are indexed by the address of the TrustlessRelay contract on the
  // origin chain. This also serves as the identity of the chain itself.
  // The associatin between address-id and chain-id is stored off-chain but it
  // must be 1:1 and unique.
  mapping(address => bytes32[]) headerRoots;

  // Save a hash to an append-only array of headerRoots associated with the
  // given origin chain address-id.
  function saveHeaderRoot(bytes32 root, address origin) public onlyAdmin() {
    headerRoots[origin].push(root);
    HeaderRoot(origin, root, headerRoots[origin].length, msg.sender);
  }

  // Anyone can contest a header that has been stored and can overwrite it if
  // they can prove that it is incorrect.
  // address    origin       The address-id of the origin chain
  // uint256    loc          The index of the headerRoot in question in headerRoots
  // bytes32[2] partners     Partners for the transaction and header that are leaves
  //                         of their respective Merkle trees
  //                         [txPartner, headerPartner]
  // uint256[2] indices      Indices of the leaf pairs in the respective Merkle
  //                         trees: [txIndex, headerIndex]
  // bool[2]    isLeft       Tells us if the tx and header are on the left side
  //                         at the leaf level. [txIsLeft, headerIsLeft]
  // bytes      data         Four sets of data. Each set is prefixed with 32 bytes
  //                         indicating the length of the data.
  //                         [txData, txNodes, headerData, headerNodes]
  //
  //                         tx/header data are the streams that go into forming
  //                         the transaction hash and header, respectively. These
  //                         are leaves on the respective trees and are next to
  //                         their respective partners.
  //                         tx/header nodes are the corresponding nodes on the
  //                         respective Merkle trees, starting at the lowest
  //                         levels. These nodes are bytes32 hashes.
  function contestHeader(address origin, uint256 loc, bytes32 partners,
  uint256[2] indices, bool[2] isLeft, bytes data) public {
    bytes32 txHash = Merkle.getTxHash(txData);
    bytes32 txRoot;
    if (txIsLeft == true) {
      txRoot = Merkle.getRoot([txHash, txPartner], txI, txNodes);
    } else {
      txRoot = Merkle.getRoot([txPartner, txHash], txI, txNodes);
    }
    bytes32 headerHash = Merkle.getHeaderHash(headerData);
    bytes32 headerRoot;
    if (headerIsLeft == true) {
      headerRoot = Merkle.getRoot([headerHash, headerPartner], headerI, headerNodes);
    } else {
      headerRoot = Merkle.getRoot([headerPartner, headerHash], headerI, headerNodes);
    }
    require(headerRoots[origin][loc] != headerRoot);
    headerRoots[origin][loc] = headerRoot;
    msg.sender.send(bountyWei);
  }


  function TrustedRelay() {
    admin = msg.sender;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }
}