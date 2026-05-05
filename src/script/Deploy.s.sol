// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {AnimeVoting} from "../src/AnimeVoting.sol";

contract DeployAnimeVoting is Script {
    function run() external returns (AnimeVoting) {
        vm.startBroadcast();

        AnimeVoting voting = new AnimeVoting();

        /* 初期キャラクター登録 */
        voting.addCharacter("Naruto");
        voting.addCharacter("Goku");
        voting.addCharacter("Levi");
        voting.addCharacter("Luffy");
        voting.addCharacter("Gojo");

        vm.stopBroadcast();
        return voting;
    }
}
