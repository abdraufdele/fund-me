// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;
import {PriceConverter} from "../src/PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    using PriceConverter for uint256;
    error TransactionFailed();

    uint256 public constant MINIMUM_USD = 5e18;
    mapping(address => uint256) private addressToAmountFunded;
    address[] private funders;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    modifier OnlyOwner() {
        require(i_owner == msg.sender, "Not Owner");
        _;
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD,
            "Not enough eth sent"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x694AA1769357215DE4FAC081bf1f309aDC325306
        // );
        return s_priceFeed.version();
    }

    function withdraw() public OnlyOwner {
        for (
            uint funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) {
            revert TransactionFailed();
        }
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /*views/getters*/
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 Index) external view returns (address) {
        return funders[Index];
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return addressToAmountFunded[fundingAddress];
    }
}
