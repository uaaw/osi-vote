// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AnimeVoting} from "../src/AnimeVoting.sol";

contract AnimeVotingTest is Test {
    AnimeVoting public voting;

    uint64 constant START  = 1000;
    uint64 constant COMMIT_END = 2000;
    uint64 constant REVEAL_END = 3000;

    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);

    function setUp() public {
        vm.warp(START - 1);
        voting = new AnimeVoting(START, COMMIT_END, REVEAL_END);
        voting.addCharacter("Naruto");
        voting.addCharacter("Goku");

        voting.addToWhitelist(user1, 1);
        voting.addToWhitelist(user2, 3); /* user2はVIPで3票分 */
        voting.addToWhitelist(user3, 1);
    }

    /* ---- whitelist ---- */

    function test_RevertIf_NonWhitelistedCommits() public {
        vm.warp(START);
        vm.prank(address(0x99));
        vm.expectRevert("Not whitelisted");
        voting.commitVote(bytes32(0));
    }

    /* ---- commit-reveal ---- */

    function _makeHash(address voter, uint256 characterId, bytes32 salt) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(characterId, salt, voter));
    }

    function test_CommitAndReveal() public {
        bytes32 salt = keccak256("secret");
        bytes32 hash = _makeHash(user1, 0, salt);

        vm.warp(START);
        vm.prank(user1);
        voting.commitVote(hash);

        vm.warp(COMMIT_END + 1);
        vm.prank(user1);
        voting.revealVote(0, salt);

        (, uint32 voteCount) = voting.characters(0);
        assertEq(voteCount, 1);
    }

    function test_RevertIf_WrongHash() public {
        bytes32 salt = keccak256("secret");
        bytes32 hash = _makeHash(user1, 0, salt);

        vm.warp(START);
        vm.prank(user1);
        voting.commitVote(hash);

        vm.warp(COMMIT_END + 1);
        vm.prank(user1);
        vm.expectRevert("Hash mismatch");
        voting.revealVote(1, salt); /* 違うキャラクターIDでリビール */
    }

    function test_RevertIf_DoubleCommit() public {
        bytes32 hash = _makeHash(user1, 0, keccak256("s"));

        vm.warp(START);
        vm.startPrank(user1);
        voting.commitVote(hash);
        vm.expectRevert("Already committed");
        voting.commitVote(hash);
        vm.stopPrank();
    }

    function test_RevertIf_RevealOutsidePeriod() public {
        bytes32 salt = keccak256("secret");
        vm.warp(START);
        vm.prank(user1);
        voting.commitVote(_makeHash(user1, 0, salt));

        /* コミット期間中にリビールしようとする */
        vm.prank(user1);
        vm.expectRevert("Outside reveal period");
        voting.revealVote(0, salt);
    }

    /* ---- weighted voting ---- */

    function test_WeightedVoting() public {
        bytes32 salt = keccak256("s");

        vm.warp(START);
        vm.prank(user2);
        voting.commitVote(_makeHash(user2, 0, salt));

        vm.warp(COMMIT_END + 1);
        vm.prank(user2);
        voting.revealVote(0, salt);

        (, uint32 voteCount) = voting.characters(0);
        assertEq(voteCount, 3); /* user2のweightは3 */
    }

    /* ---- delegation ---- */

    function test_Delegation() public {
        bytes32 salt = keccak256("s");

        vm.warp(START);

        /* user3がuser1に委任 */
        vm.prank(user3);
        voting.delegate(user1);

        /* user1がコミット */
        vm.prank(user1);
        voting.commitVote(_makeHash(user1, 0, salt));

        vm.warp(COMMIT_END + 1);
        vm.prank(user1);
        voting.revealVote(0, salt);

        /* user1(1) + user3から委任(1) = 2票 */
        (, uint32 voteCount) = voting.characters(0);
        assertEq(voteCount, 2);
    }

    function test_RevertIf_DelegatedUserCommits() public {
        vm.warp(START);
        vm.startPrank(user3);
        voting.delegate(user1);
        vm.expectRevert("Vote is delegated");
        voting.commitVote(bytes32(0));
        vm.stopPrank();
    }

    /* ---- getWinner ---- */

    function test_GetWinner() public {
        bytes32 salt1 = keccak256("s1");
        bytes32 salt2 = keccak256("s2");

        vm.warp(START);
        vm.prank(user1);
        voting.commitVote(_makeHash(user1, 1, salt1));
        vm.prank(user2);
        voting.commitVote(_makeHash(user2, 1, salt2)); /* user2 weight=3 */

        vm.warp(COMMIT_END + 1);
        vm.prank(user1);
        voting.revealVote(1, salt1);
        vm.prank(user2);
        voting.revealVote(1, salt2);

        (uint256 id, string memory name, uint32 votes) = voting.getWinner();
        assertEq(id, 1);
        assertEq(name, "Goku");
        assertEq(votes, 4); /* 1 + 3 */
    }
}
