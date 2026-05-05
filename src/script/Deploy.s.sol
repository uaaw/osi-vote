// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {AnimeVoting} from "../src/AnimeVoting.sol";

contract DeployAnimeVoting is Script {
    function run() external returns (AnimeVoting) {
        /* コミット期間: デプロイから1日後まで、リビール期間: さらに1日 */
        uint64 commitStart = uint64(block.timestamp);
        uint64 commitEnd   = commitStart + 1 days;
        uint64 revealEnd   = commitEnd   + 1 days;

        vm.startBroadcast();

        AnimeVoting voting = new AnimeVoting(commitStart, commitEnd, revealEnd);

        voting.addCharacter("Naruto");
        voting.addCharacter("Goku");
        voting.addCharacter("Levi");
        voting.addCharacter("Luffy");
        voting.addCharacter("Gojo");

        vm.stopBroadcast();
        return voting;
    }
}
