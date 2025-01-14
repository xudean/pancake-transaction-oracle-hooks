// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Attestation as PrimusAttestation, IPrimusZKTLS} from "zkTLS-contracts/src/IPrimusZKTLS.sol";
import {Attestation} from "../types/Common.sol";
import {IAttestationRegistry} from '../IAttestationRegistry.sol';
import "openzeppelin/contracts/access/Ownable.sol";
import "../utils/stringToUnits.sol";


// import "@Arachnid/solidity-stringutils/strings.sol";
import {JsonParser} from "../utils/JsonParser.sol";

contract AttestationRegistry is Ownable,IAttestationRegistry {
    using JsonParser for string;
    using StringToUintExtension for string;

    // Attestation with AttestationId mapping
    mapping(bytes32 => Attestation) public attestations;
    // Attestation with address mapping
    mapping(address => bytes32[]) public attestationsOfAddress;
    // DexUrlCheckList mapping url => dexName
    mapping(string => string) public dexCheckList;
    // SupportedPlatforms mapping dexName =>reponseResolve[0].parsePath
    mapping(string => string) public supportedPlatforms;

    // IPrimusZKTLS contract    
    IPrimusZKTLS internal primusZKTLS;
    // submission fee
    uint256 public submissionFee;
    // fee recipient
    address payable public feeRecipient;

    // AttestationSubmitted event
    event AttestationSubmitted(bytes32 attestationId, address recipient,string exchange ,uint256 value, uint256 timestamp);
    // fee received event
    event FeeReceived(address sender, uint256 amount);
    // url to exchange added event
    event UrlToExchangeAdded(string indexed url, string exchange);
    // url to exchange removed event
    event UrlToExchangeRemoved(string indexed url);
    // exchange to parsePath added event
    event ExchangeToParsePathAdded(string indexed exchange, string parsePath);
    // exchange to parsePath removed event
    event ExchangeToParsePathRemoved(string indexed exchange);

    /// @dev Constructor
    /// @param _primusZKTLS The address of the IPrimusZKTLS contract
    /// @param _submissionFee The submission fee
    /// @param _feeRecipient The fee recipient
    /// @notice The constructor sets the IPrimusZKTLS contract, submission fee, and fee recipient
    constructor(address _primusZKTLS, uint256 _submissionFee, address payable _feeRecipient)  Ownable(msg.sender){
        setPrimusZKTLS(_primusZKTLS);
        setSubmissionFee(_submissionFee);
        setFeeRecipient(_feeRecipient);
    }

    /// @dev Add or update the mapping of URL to exchange name
    /// @param url The URL address
    /// @param exchange The exchange name
    function addUrlToExchange(string memory url, string memory exchange) external onlyOwner {
        dexCheckList[url] = exchange;
        emit UrlToExchangeAdded(url, exchange);
    }

    /// @dev Remove the mapping of URL to exchange name
    /// @param url The URL address
    function removeUrlToExchange(string memory url) external onlyOwner {
        require(bytes(dexCheckList[url]).length > 0, "URL not found");
        delete dexCheckList[url];
        emit UrlToExchangeRemoved(url);
    }

    /// @dev Add or update the mapping of exchange name to parsePath
    /// @param exchange The exchange name
    /// @param parsePath The parsing path
    function addExchangeToParsePath(string memory exchange, string memory parsePath) external onlyOwner {
        supportedPlatforms[exchange] = parsePath;
        emit ExchangeToParsePathAdded(exchange, parsePath);
    }

    /// @dev Remove the mapping of exchange name to parsePath
    /// @param exchange The exchange name
    function removeExchangeToParsePath(string memory exchange) external onlyOwner {
        require(bytes(supportedPlatforms[exchange]).length > 0, "Exchange not found");
        delete supportedPlatforms[exchange];
        emit ExchangeToParsePathRemoved(exchange);
    }

    // set IPrimusZKTLS contract instance
    function setPrimusZKTLS(address _primusZKTLS) public onlyOwner {
        primusZKTLS = IPrimusZKTLS(_primusZKTLS);
    }
    // set submissionFee  
    function setSubmissionFee(uint256 _submissionFee) public onlyOwner {
        submissionFee = _submissionFee;
    }
    // set feeRecipient
    function setFeeRecipient(address payable _feeRecipient) public onlyOwner {
        feeRecipient = _feeRecipient;
    }

    /// @dev Set the dex check list
    // @param _dexUrl The url of the dex
    // @param _dexName The name of the dex
    function setDexCheckList(string memory _dexUrl, string memory _dexName) public onlyOwner {
        dexCheckList[_dexUrl] = _dexName;
    }

    /// @dev Extract the base URL (ignoring query parameters)
    /// @param url The full URL
    /// @return The base URL without query parameters
    function extractBaseUrl(string memory url) internal pure returns (string memory) {
        bytes memory urlBytes = bytes(url);

        // Find the position of the '?' character
        uint256 queryStart = urlBytes.length;
        for (uint256 i = 0; i < urlBytes.length; i++) {
            if (urlBytes[i] == "?") {
                queryStart = i;
                break;
            }
        }

        // Create a new bytes array for the base URL
        bytes memory baseUrlBytes = new bytes(queryStart);
        for (uint256 i = 0; i < queryStart; i++) {
            baseUrlBytes[i] = urlBytes[i];
        }

        return string(baseUrlBytes);
    }


    /// @dev submit attestation
    /// @param _attestation The attestation data to be verified
    /// @notice The function verifies the attestation data and submits it to the IPrimusZKTLS contract
    /// @return attestationId The attestationId of the submitted attestation
    function submitAttestation(PrimusAttestation calldata _attestation) public payable returns (bytes32){
        require(msg.value >= submissionFee, "Insufficient fee");
        
        // send fee to feeRecipient
        (bool sent, ) = feeRecipient.call{value: msg.value}("");
        require(sent, "Failed to send fee");
        emit FeeReceived(msg.sender, msg.value);
        
        // verify the attestation is valid
        primusZKTLS.verifyAttestation(_attestation);
        // verify the url is bsc or other chain
        require(_attestation.recipient == msg.sender, "Invalid recipient");
        require(_attestation.timestamp > 0 && _attestation.timestamp <= block.timestamp, "Invalid timestamp");

        string memory url = _attestation.request.url;
        string memory baseUrl = extractBaseUrl(url);
        string memory exchange = dexCheckList[baseUrl];
        require(bytes(exchange).length > 0, "Unsupported URL");

        // verify the parsePath is valid
        string memory expectedParsePath = supportedPlatforms[exchange];
        string memory actualParsePath = _attestation.reponseResolve[0].parsePath;
        require(
            keccak256(bytes(expectedParsePath)) == keccak256(bytes(actualParsePath)),
            "Invalid parsePath for the exchange"
        );
        // verify the value is valid
        string memory valueString = _attestation.attConditions.extractValue("value");
        uint256 value = valueString.stringToUint();
        bytes32 attestationId = keccak256(
            abi.encodePacked(_attestation.recipient, url, exchange, actualParsePath, valueString,_attestation.timestamp)
        );
        // save the attestation
        attestations[attestationId] = Attestation(attestationId, _attestation.recipient, exchange, uint32(value), _attestation.timestamp);
        attestationsOfAddress[msg.sender].push(attestationId);
        // emit the AttestationSubmitted event
        emit AttestationSubmitted(attestationId, _attestation.recipient, exchange, value, _attestation.timestamp);
        
        return attestationId;
    }

    function getAttestationByRecipient(address recipient) public view returns (Attestation[] memory){
        bytes32[] memory attestationIds = attestationsOfAddress[recipient];
        Attestation[] memory myAttestations = new Attestation[](attestationIds.length);
        for (uint i = 0; i < attestationIds.length; i++) {
            Attestation memory myAttestation = attestations[attestationIds[i]];
            if (myAttestation.recipient == recipient) {
                myAttestations[i] = myAttestation;
            }
        }
        return myAttestations;
    }

}