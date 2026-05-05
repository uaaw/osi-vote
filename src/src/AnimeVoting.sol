// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AnimeVoting {
    struct Character {
        string name;
        uint256 voteCount;
    }

    address public owner;
    bool public votingOpen;
    Character[] public characters;

    mapping(address => bool) public hasVoted;
    mapping(address => uint256) public votedFor;

    event CharacterAdded(uint256 indexed id, string name);
    event Voted(address indexed voter, uint256 indexed characterId);
    event VotingStatusChanged(bool isOpen);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier whenOpen() {
        require(votingOpen, "Voting is closed");
        _;
    }

    constructor() {
        owner = msg.sender;
        votingOpen = true;
    }

    function addCharacter(string calldata _name) external onlyOwner {
        require(bytes(_name).length > 0, "Name is empty");
        characters.push(Character({name: _name, voteCount: 0}));
        emit CharacterAdded(characters.length - 1, _name);
    }

    /* 一アドレス一票・変更不可 */
    function vote(uint256 _characterId) external whenOpen {
        require(!hasVoted[msg.sender], "Already voted");
        require(_characterId < characters.length, "Invalid character");

        hasVoted[msg.sender] = true;
        votedFor[msg.sender] = _characterId;
        characters[_characterId].voteCount++;

        emit Voted(msg.sender, _characterId);
    }

    function setVotingOpen(bool _isOpen) external onlyOwner {
        votingOpen = _isOpen;
        emit VotingStatusChanged(_isOpen);
    }

    function getCharacters() external view returns (Character[] memory) {
        return characters;
    }

    function getCharacterCount() external view returns (uint256) {
        return characters.length;
    }

    /* 最多得票キャラクターを返す */
    function getWinner() external view returns (uint256 winnerId, string memory winnerName, uint256 winnerVotes) {
        require(characters.length > 0, "No characters");

        for (uint256 i = 1; i < characters.length; i++) {
            if (characters[i].voteCount > characters[winnerId].voteCount) {
                winnerId = i;
            }
        }

        winnerName = characters[winnerId].name;
        winnerVotes = characters[winnerId].voteCount;
    }
}
