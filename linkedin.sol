// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
contract LinkedInSmartContract {
    struct Profile {
        string name;
        string headline;
        string[] skills;
        address[] connections;
        mapping(uint256 => string) messages;
    }

    mapping(address => Profile) public profiles;

    event ProfileCreated(address indexed user, string name, string headline);
    event ConnectionAdded(address indexed user, address indexed connection);
    event MessageSent(address indexed sender, address indexed receiver, string message);
    event MessageDeleted(address indexed sender, uint256 messageId);

    modifier onlyReceiver(address _receiver) {
        require(msg.sender == _receiver, "Only the receiver can see the message");
        _;
    }

    modifier onlySenderDeleteMsg(address _receiver, uint256 _messageId) {
        require(msg.sender == profiles[_receiver].connections[_messageId], "Only the sender can delete the message");
        _;
    }

    function createProfile(string memory _name, string memory _headline, string[] memory _skills) public {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_headline).length > 0, "Headline cannot be empty");

        Profile storage userProfile = profiles[msg.sender];
        require(bytes(userProfile.name).length == 0, "Profile already exists");

        userProfile.name = _name;
        userProfile.headline = _headline;
        userProfile.skills = _skills;

        emit ProfileCreated(msg.sender, _name, _headline);
    }

    function addConnection(address _connection) public {
        require(_connection != address(0), "Invalid address");
        require(_connection != msg.sender, "Cannot connect to yourself");

        Profile storage userProfile = profiles[msg.sender];
        require(bytes(userProfile.name).length > 0, "Profile does not exist");

        userProfile.connections.push(_connection);

        emit ConnectionAdded(msg.sender, _connection);
    }

    function sendMsg(address _receiver, string memory _message) public {
        Profile storage senderProfile = profiles[msg.sender];
        require(bytes(senderProfile.name).length > 0, "Profile does not exist");
        require(bytes(_message).length > 0, "Message cannot be empty");

        Profile storage receiverProfile = profiles[_receiver];
        require(bytes(receiverProfile.name).length > 0, "Receiver's profile does not exist");

        uint256 messageId = senderProfile.connections.length - 1;
        receiverProfile.messages[messageId] = _message;

        emit MessageSent(msg.sender, _receiver, _message);
    }

    function viewMsg(address _sender, uint256 _messageId) public view onlyReceiver(_sender) returns (string memory) {
        return profiles[msg.sender].messages[_messageId];
    }

    function deleteMsg(address _receiver, uint256 _messageId) public onlySenderDeleteMsg(_receiver, _messageId) {
        delete profiles[_receiver].messages[_messageId];
        emit MessageDeleted(msg.sender, _messageId);
    }

    function searchMessages(string memory _query) public view returns (string[] memory) {
        Profile storage user = profiles[msg.sender];
        uint256 msgCount = user.connections.length;

        string[] memory foundMessages = new string[](msgCount);
        uint256 foundCount = 0;

        for (uint256 i = 0; i < msgCount; i++) {
            string memory message = user.messages[i];
            if (bytes(message).length > 0 && contains(message, _query)) {
                foundMessages[foundCount] = message;
                foundCount++;
            }
        }

        string[] memory result = new string[](foundCount);
        for (uint256 j = 0; j < foundCount; j++) {
            result[j] = foundMessages[j];
        }

        return result;
    }

    function contains(string memory _str, string memory _subStr) internal pure returns (bool) {
        bytes memory strBytes = bytes(_str);
        bytes memory subStrBytes = bytes(_subStr);

        if (strBytes.length < subStrBytes.length) {
            return false;
        }

        uint256 j;
        for (uint256 i = 0; i <= strBytes.length - subStrBytes.length; i++) {
            for (j = 0; j < subStrBytes.length; j++) {
                if (strBytes[i + j] != subStrBytes[j]) {
                    break;
                }
            }
            if (j == subStrBytes.length) {
                return true;
            }
        }
        return false;
    }

    function getConnectionCount(address _user) public view returns (uint256) {
        return profiles[_user].connections.length;
    }
}