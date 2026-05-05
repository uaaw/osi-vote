// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AnimeVoting {
    struct Character {
        string name;
        uint32 voteCount; /* uint32でstorageを節約 */
    }

    /* slot0: owner(20byte) + commitStart(8byte) = 28byte でpack */
    address public owner;
    uint64 public commitStart;
    /* slot1: commitEnd(8byte) + revealEnd(8byte) でpack */
    uint64 public commitEnd;
    uint64 public revealEnd;

    Character[] public characters;

    mapping(address => bool) public whitelist;
    mapping(address => uint32) public voteWeight;

    /* 委任 */
    mapping(address => address) public delegateTo;
    mapping(address => uint32) public delegatedWeight;
    mapping(address => bool) public hasDelegated;

    /* コミット・リビール */
    mapping(address => bytes32) public commitHash;
    mapping(address => bool) public hasCommitted;
    mapping(address => bool) public hasRevealed;

    event CharacterAdded(uint256 indexed id, string name);
    event Whitelisted(address indexed addr, uint32 weight);
    event Delegated(address indexed from, address indexed to);
    event Committed(address indexed voter);
    event Voted(address indexed voter, uint256 indexed characterId, uint32 weight);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Not whitelisted");
        _;
    }

    constructor(uint64 _commitStart, uint64 _commitEnd, uint64 _revealEnd) {
        require(_commitStart < _commitEnd && _commitEnd < _revealEnd, "Invalid times");
        owner = msg.sender;
        commitStart = _commitStart;
        commitEnd = _commitEnd;
        revealEnd = _revealEnd;
    }

    function addCharacter(string calldata _name) external onlyOwner {
        require(bytes(_name).length > 0, "Name is empty");
        characters.push(Character({name: _name, voteCount: 0}));
        emit CharacterAdded(characters.length - 1, _name);
    }

    function addToWhitelist(address _addr, uint32 _weight) external onlyOwner {
        require(_weight > 0, "Weight must be > 0");
        /* 委任後のweight変更はdelegatedWeightと不整合になるため禁止 */
        require(!hasDelegated[_addr], "Cannot change weight after delegation");
        whitelist[_addr] = true;
        voteWeight[_addr] = _weight;
        emit Whitelisted(_addr, _weight);
    }

    function removeFromWhitelist(address _addr) external onlyOwner {
        /* 委任済みの場合は委任先のdelegatedWeightから減算 */
        if (hasDelegated[_addr]) {
            delegatedWeight[delegateTo[_addr]] -= voteWeight[_addr];
        }
        whitelist[_addr] = false;
        voteWeight[_addr] = 0;
    }

    /* コミット前に自分のvoteWeightを別アドレスへ移譲する */
    function delegate(address _to) external onlyWhitelisted {
        require(block.timestamp >= commitStart && block.timestamp <= commitEnd, "Outside commit period");
        require(_to != msg.sender, "Cannot delegate to self");
        require(whitelist[_to], "Delegate not whitelisted");
        require(!hasDelegated[msg.sender], "Already delegated");
        require(!hasCommitted[msg.sender], "Already committed");
        /* A→B→C のチェーン委任を禁止。Aのweightが消失するバグを防ぐ */
        require(!hasDelegated[_to], "Delegate has already delegated");

        hasDelegated[msg.sender] = true;
        delegateTo[msg.sender] = _to;
        delegatedWeight[_to] += voteWeight[msg.sender];

        emit Delegated(msg.sender, _to);
    }

    /* コミット: keccak256(abi.encodePacked(characterId, salt, msg.sender)) を提出 */
    /* msg.senderを含めることでフロントランニングを防止 */
    function commitVote(bytes32 _hash) external onlyWhitelisted {
        require(block.timestamp >= commitStart && block.timestamp <= commitEnd, "Outside commit period");
        require(!hasCommitted[msg.sender], "Already committed");
        require(!hasDelegated[msg.sender], "Vote is delegated");

        commitHash[msg.sender] = _hash;
        hasCommitted[msg.sender] = true;

        emit Committed(msg.sender);
    }

    /* リビール: コミット時と同じcharacterIdとsaltを提出して票を確定 */
    function revealVote(uint256 _characterId, bytes32 _salt) external onlyWhitelisted {
        require(block.timestamp > commitEnd && block.timestamp <= revealEnd, "Outside reveal period");
        require(hasCommitted[msg.sender], "No commit found");
        require(!hasRevealed[msg.sender], "Already revealed");
        require(_characterId < characters.length, "Invalid character");

        bytes32 expected = keccak256(abi.encodePacked(_characterId, _salt, msg.sender));
        require(commitHash[msg.sender] == expected, "Hash mismatch");

        hasRevealed[msg.sender] = true;

        /* 委任されたweightを加算して投票 */
        uint32 effectiveWeight = voteWeight[msg.sender] + delegatedWeight[msg.sender];
        characters[_characterId].voteCount += effectiveWeight;

        emit Voted(msg.sender, _characterId, effectiveWeight);
    }

    function getCharacters() external view returns (Character[] memory) {
        return characters;
    }

    function getCharacterCount() external view returns (uint256) {
        return characters.length;
    }

    function isCommitPhase() external view returns (bool) {
        return block.timestamp >= commitStart && block.timestamp <= commitEnd;
    }

    function isRevealPhase() external view returns (bool) {
        return block.timestamp > commitEnd && block.timestamp <= revealEnd;
    }

    /* 同票の場合はIDが小さいキャラクターが勝者となる */
    function getWinner() external view returns (uint256 winnerId, string memory winnerName, uint32 winnerVotes) {
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
