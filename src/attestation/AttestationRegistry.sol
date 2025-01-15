// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Attestation as PrimusAttestation, IPrimusZKTLS} from "zkTLS-contracts/src/IPrimusZKTLS.sol";
import {Attestation} from "../types/Common.sol";
import {IAttestationRegistry} from '../IAttestationRegistry.sol';
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {UintString} from "forge-gas-snapshot/src/utils/UintString.sol";

import {JsonParser} from "../utils/JsonParser.sol";

contract AttestationRegistry is Ownable,IAttestationRegistry {
    using JsonParser for string;
    using UintString for string;

    // Attestation with AttestationId mapping
    mapping(bytes32 => Attestation) public attestations;
    // Attestation with address mapping
    mapping(address => bytes32[]) public attestationsOfAddress;
    // DexUrlCheckList mapping url => cexName
    mapping(string => string) public cexCheckList;
    // cexJsonPathList mapping cexName =>reponseResolve[0].parsePath
    mapping(string => string) public cexJsonPathList;

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

    /**
     *  @dev Constructor
     *  @param _primusZKTLS The address of the IPrimusZKTLS contract
     *  @param _submissionFee The submission fee
     *  @param _feeRecipient The fee recipient
     *  @notice The constructor sets the IPrimusZKTLS contract, submission fee, and fee recipient
     * **/
    constructor(address _primusZKTLS, uint256 _submissionFee, address payable _feeRecipient)  Ownable(msg.sender){
        setPrimusZKTLS(_primusZKTLS);
        setSubmissionFee(_submissionFee);
        setFeeRecipient(_feeRecipient);
    }

    /**
     *  @dev setCexCheckListAndJsonPath
     *  @param _dexUrls The dexUrls
     *  @param _dexName The dexName
     *  @param _jspnPath The jspnPath
     *  @notice The setCexCheckListAndJsonPath sets the cexCheckList and cexJsonPathList 
     * **/
    function setCexCheckListAndJsonPath(string[] memory _dexUrls, string[] memory _dexName, string[] memory _jspnPath) external onlyOwner {
        require(_dexUrls.length == _dexName.length && _dexName.length == _jspnPath.length, "Array length mismatch");
        for (uint256 i = 0; i < _dexUrls.length; i++) {
          cexCheckList[_dexUrls[i]] = _dexName[i];
          cexJsonPathList[_dexName[i]] = _jspnPath[i];
        }
    }    

    /**
     * @dev Add or update the mapping of URL to exchange name
     * @param url The URL address
     * @param exchange The exchange name
     * @notice The addUrlToExchange function adds or updates the mapping of URL to exchange name
    */
    function addUrlToExchange(string memory url, string memory exchange) external onlyOwner {
        cexCheckList[url] = exchange;
        emit UrlToExchangeAdded(url, exchange);
    }

    /**
     * @dev Remove the mapping of URL to exchange name
     * @param url The URL address
     * @notice The removeUrlToExchange function removes the mapping of URL to exchange name
    */
    function removeUrlToExchange(string memory url) external onlyOwner {
        require(bytes(cexCheckList[url]).length > 0, "URL not found");
        delete cexCheckList[url];
        emit UrlToExchangeRemoved(url);
    }

    /**
     * @dev Add or update the mapping of exchange name to parsePath
     * @param exchange The exchange name
     * @param parsePath The parsing path
     * @notice The addExchangeToParsePath function adds or updates the mapping of exchange name to parsePath
    */
    function addExchangeToParsePath(string memory exchange, string memory parsePath) external onlyOwner {
        cexJsonPathList[exchange] = parsePath;
        emit ExchangeToParsePathAdded(exchange, parsePath);
    }

    /**
     * @dev Remove the mapping of exchange name to parsePath
     * @param exchange The exchange name
     * @notice The removeExchangeToParsePath function removes the mapping of exchange name to parsePath
    */
    function removeExchangeToParsePath(string memory exchange) external onlyOwner {
        require(bytes(cexJsonPathList[exchange]).length > 0, "Exchange not found");
        delete cexJsonPathList[exchange];
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

    /**
     * @dev Set the dex check list
     * @param _dexUrl The url of the dex
     * @param _dexName The name of the dex
     * @notice The setcexCheckList function sets the dex check list
     * */
    function setcexCheckList(string memory _dexUrl, string memory _dexName) public onlyOwner {
        cexCheckList[_dexUrl] = _dexName;
    }

    /**
     * @dev Extract the base URL (ignoring query parameter
     * @param url The full URL
     * @return The base URL without query parameters
    */
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

    /**
     * @dev submit attestation
     * @param _attestation The attestation data to be verified
     * @notice The function verifies the attestation data and submits it to the IPrimusZKTLS contract
     * @return attestationId The attestationId of the submitted attestation
    */
    function submitAttestation(PrimusAttestation calldata _attestation) public payable returns (bytes32){
        require(msg.value >= submissionFee, "Insufficient fee");
        
        // send fee to feeRecipient
        if (submissionFee > 0) {
            (bool sent, ) = feeRecipient.call{value: msg.value}("");
            require(sent, "Failed to send fee");
            emit FeeReceived(msg.sender, msg.value);
        }
 
        // verify the attestation is valid
        primusZKTLS.verifyAttestation(_attestation);
        // verify the url is bsc or other chain
        require(_attestation.recipient == msg.sender, "Invalid recipient");
        require(_attestation.timestamp > 0 && _attestation.timestamp <= block.timestamp, "Invalid timestamp");

        string memory url = _attestation.request.url;
        string memory baseUrl = extractBaseUrl(url);
        string memory exchange = cexCheckList[baseUrl];
        require(bytes(exchange).length > 0, "Unsupported URL");

        // verify the parsePath is valid
        string memory expectedParsePath = cexJsonPathList[exchange];
        string memory actualParsePath = _attestation.reponseResolve[0].parsePath;
        require(
            keccak256(bytes(expectedParsePath)) == keccak256(bytes(actualParsePath)),
            "Invalid parsePath for the exchange"
        );
        // verify the value is valid
        string memory valueString = _attestation.attConditions.extractValue("value");
        uint256 value = valueString.stringToUint();
        // verify the operation is valid
        string memory operaStr = _attestation.attConditions.extractValue("op");
        require(
            keccak256(bytes(operaStr)) == keccak256(bytes(">")) || keccak256(bytes(operaStr)) == keccak256(bytes(">=")),
            "Invalid operation for the Attestation"
        );
        bytes32 attestationId = keccak256(
            abi.encodePacked(_attestation.recipient, url, exchange, actualParsePath, operaStr, valueString, _attestation.timestamp)
        );
        // save the attestation
        attestations[attestationId] = Attestation(attestationId, _attestation.recipient, exchange, operaStr,uint32(value), _attestation.timestamp);
        attestationsOfAddress[msg.sender].push(attestationId);
        // emit the AttestationSubmitted event
        emit AttestationSubmitted(attestationId, _attestation.recipient, exchange, value, _attestation.timestamp);
        
        return attestationId;
    }

    /**
     * @dev getAttestationByRecipient
     * @param recipient address
     * @return Attestation[] memory
     * @notice get all attestations of the recipient
     * **/
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