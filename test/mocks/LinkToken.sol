// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@solmate/tokens/ERC20.sol";

interface ERC677Receiver {
    function onTokenTransfer(address _sender, uint256 _value, bytes calldata _data) external;
}

contract LinkToken is ERC20 {
    uint256 constant INITIAL_SUPPLY = 1000000000000000000000000;

    constructor() ERC20("ChainLink Token", "LINK", 18) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    function transferAndCall(address _to, uint256 _value, bytes calldata _data)
        public
        virtual
        returns (bool success)
    {
        super.transfer(_to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        if (isContract(_to)) {
            contractFallback(_to, _value, _data);
        }
        return true;
    }

    function contractFallback(address _to, uint256 _value, bytes calldata _data) private {
        ERC677Receiver receiver = ERC677Receiver(_to);
        receiver.onTokenTransfer(msg.sender, _value, _data);
    }

    function isContract(address _addr) private view returns (bool hasCode) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }
        return length > 0;
    }
}