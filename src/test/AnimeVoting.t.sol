// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AnimeVoting} from "../src/AnimeVoting.sol";

contract AnimeVotingTest is Test {
    AnimeVoting public voting;
    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        voting = new AnimeVoting();
        voting.addCharacter("Naruto");
        voting.addCharacter("Goku");
    }

    function test_AddCharacter() public {
        voting.addCharacter("Luffy");
        assertEq(voting.getCharacterCount(), 3);
    }

    function test_Vote() public {
        vm.prank(user1);
        voting.vote(0);

        (, uint256 voteCount) = voting.characters(0);
        assertEq(voteCount, 1);
        assertTrue(voting.hasVoted(user1));
        assertEq(voting.votedFor(user1), 0);
    }

    function test_RevertIf_DoubleVote() public {
        vm.startPrank(user1);
        voting.vote(0);
        vm.expectRevert("Already voted");
        voting.vote(1);
        vm.stopPrank();
    }

    function test_RevertIf_InvalidCharacter() public {
        vm.prank(user1);
        vm.expectRevert("Invalid character");
        voting.vote(99);
    }

    function test_RevertIf_VotingClosed() public {
        voting.setVotingOpen(false);
        vm.prank(user1);
        vm.expectRevert("Voting is closed");
        voting.vote(0);
    }

    function test_GetWinner() public {
        vm.prank(user1);
        voting.vote(1);
        vm.prank(user2);
        voting.vote(1);

        (uint256 id, string memory name, uint256 votes) = voting.getWinner();
        assertEq(id, 1);
        assertEq(name, "Goku");
        assertEq(votes, 2);
    }

    function test_RevertIf_NonOwnerAddsCharacter() public {
        vm.prank(user1);
        vm.expectRevert("Not owner");
        voting.addCharacter("Levi");
    }
}
