// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Token.sol";

contract Exchange {
    address public feeAccount;
    uint256 public feePercent;
    mapping(address => mapping(address => uint256)) public tokens;

    // Order mapping
    mapping(uint256 => _Order) public orders;
    uint256 public orderCount;
    mapping(uint256 => bool) public orderCancelled;

    struct _Order {
        // Attributes of the order
        uint256 id; // Unique identifier for order
        address user; // User who made the order
        address tokenGet; // Address of token they receive
        uint256 amountGet; // Amount they receive
        address tokenGive; // Address of token they give
        uint256 amountGive; // Amount they give
        uint256 timestamp; // When order was created
    }

    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(
        address token,
        address user,
        uint256 amount,
        uint256 balance
    );

    event Order(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );

    event Cancel(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );

    constructor(address _feeAccount, uint256 _feePercent) {
        feeAccount = _feeAccount;
        feePercent = _feePercent;
    }

    // Deposit & Withdraw Tokens
    function depositToken(address _token, uint256 _amount) public {
        // Transfer tokens to exchange
        require(Token(_token).transferFrom(msg.sender, address(this), _amount));
        // Update user balance
        tokens[_token][msg.sender] = tokens[_token][msg.sender] + _amount;
        // Emit an event
        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function withdrawToken(address _token, uint256 _amount) public {
        // Ensure user has enough funds to withdraw
        require(tokens[_token][msg.sender] >= _amount);
        // Transfer token to user
        Token(_token).transfer(msg.sender, _amount);
        // Update user balance
        tokens[_token][msg.sender] = tokens[_token][msg.sender] - _amount;
        // Emit event
        emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    // Check Balances
    function balanceOf(
        address _token,
        address _user
    ) public view returns (uint256) {
        return tokens[_token][_user];
    }

    function makeOrder(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive
    ) public {
        // Token Give (the token they want to spend) - which token and how much
        // Token Get (the token they want to receive) - which token and how much

        // Require token balance
        require(balanceOf(_tokenGive, msg.sender) >= _amountGive);

        // Create Order
        orderCount = orderCount + 1;

        orders[orderCount] = _Order(
            orderCount, // id 1, 2, 3, ...
            msg.sender, // user
            _tokenGet, // tokenGet
            _amountGet, // amountGet
            _tokenGive, // tokenGive
            _amountGive, // amountGive
            block.timestamp // timestamp
        );

        // Emit event
        emit Order(
            orderCount,
            msg.sender,
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            block.timestamp
        );
    }

    function cancelOrder(uint256 _id) public {
        // Fetching order
        _Order storage _order = orders[_id];

        // Ensure caller of function is owner of order
        require(address(_order.user) == msg.sender);

        // order msut exist
        require(_order.id == _id);

        // Cancel order
        orderCancelled[_id] = true;

        // Emit event
        emit Cancel(
            _order.id,
            msg.sender,
            _order.tokenGet,
            _order.amountGet,
            _order.tokenGive,
            _order.amountGive,
            block.timestamp
        );
    }

    //-------------------------------------------
    // Executing Orders
    function fillOrder(uint256 _id) public {
        // Fetch order
        _Order storage _order = orders[_id];
        // Swap tokens (Trading)

        // Execute the trade
        _trade(
            _order.id,
            _order.user,
            _order.tokenGet,
            _order.amountGet,
            _order.tokenGive,
            _order.amountGive
        );
    }

    function _trade(
        uint256 _orderId,
        address _user,
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive
    ) internal {
        // Do trade here

        // msg.sender in this case is user2 who is filling the order
        // _user in this case is user1 who placed the order

        // We deduct mDAI from msg.sender (user2) balance and add to _user (user1) balance
        tokens[_tokenGet][msg.sender] =
            tokens[_tokenGet][msg.sender] -
            _amountGet;

        tokens[_tokenGet][_user] = tokens[_tokenGet][_user] + _amountGet;

        // We deduct DAPP from msg.sender (user1) balance and add to _user (user2) balance
        tokens[_tokenGive][_user] = tokens[_tokenGive][_user] - _amountGive;
        tokens[_tokenGive][msg.sender] =
            tokens[_tokenGive][msg.sender] +
            _amountGive;
    }
}
