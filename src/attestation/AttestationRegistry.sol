// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Attestation as PrimusAttestation, IPrimusZKTLS} from "zkTLS-contracts/src/IPrimusZKTLS.sol";
import {Attestation} from "../types/Common.sol";
import {IAttestationRegistry} from "../IAttestationRegistry.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {UintString} from "forge-gas-snapshot/src/utils/UintString.sol";

import {JsonParser} from "../utils/JsonParser.sol";

struct CexInfo {
    // The cex name
    string cexName;
    // jsonPath to get
    string parsePath;
}

contract AttestationRegistry is Ownable, IAttestationRegistry {
    using JsonParser for string;
    using UintString for string;
    // Attestation with address mapping

    mapping(address => Attestation[]) public attestationsOfAddress;
    // Cex info mapping cex url => CexInfo
    mapping(string => CexInfo) public cexInfoMapping;
    // IPrimusZKTLS contract
    IPrimusZKTLS internal primusZKTLS;
    // submission fee
    uint256 public submissionFee;
    // fee recipient
    address payable public feeRecipient;

    // SetPrimusZKTLS PrimusZKTLS contract set event
    event SetPrimusZKTLS(address _origenPrimus, address _primusAddress);
    // AttestationSubmitted event
    event AttestationSubmitted(address recipient, string cexName, uint256 value, uint256 timestamp);
    // SetSubmisssionFee event
    event SetSubmisssionFee(uint256 _origenSubmissionFee, uint256 _submissionFee);
    // fee received event
    event FeeReceived(address sender, uint256 amount);
    // SetFeeRecipient event
    event SetFeeRecipient(address _origenFeeRecipient, address _feeRecipient);
    // SetCexAndJsonPath event
    event SetCexAndJsonPath(string[] cexUrl, string[] cexName, string[] parsePath);
    // cexUrl to cexName added event
    event UrlToCexInfoAdded(string indexed cexUrl, string cexName);
    // cexUrl to cexName removed event
    event UrlToCexInfoRemoved(string indexed cexUrl);


    /**
     *  @dev Constructor
     *  @param _primusZKTLS The address of the IPrimusZKTLS contract
     *  @param _submissionFee The submission fee
     *  @param _feeRecipient The fee recipient
     */
    constructor(address _primusZKTLS, uint256 _submissionFee, address payable _feeRecipient) Ownable(msg.sender) {
        primusZKTLS = IPrimusZKTLS(_primusZKTLS);
        submissionFee = _submissionFee;
        feeRecipient = _feeRecipient;
    }

    /**
     *  @dev set IPrimusZKTLS contract instance
     *  @param _primusZKTLS The address of the IPrimusZKTLS contract
     *
     *
     */
    function setPrimusZKTLS(address _primusZKTLS) public onlyOwner {
        address _origenPrimus = address(primusZKTLS);
        primusZKTLS = IPrimusZKTLS(_primusZKTLS);
        emit SetPrimusZKTLS(_origenPrimus, _primusZKTLS);
    }

    /**     
     *  @dev set submissionFee
     *  @param _submissionFee The submission fee
     *
     *
     */
    function setSubmissionFee(uint256 _submissionFee) public onlyOwner {
        submissionFee = _submissionFee;
        emit SetSubmisssionFee(submissionFee, _submissionFee);
    }

    /**
     * @dev set feeRecipient
     * @param _feeRecipient The fee recipient
     *
     */
    function setFeeRecipient(address payable _feeRecipient) public onlyOwner {
        feeRecipient = _feeRecipient;
        emit SetFeeRecipient(feeRecipient, _feeRecipient);
    }

    /**
     *  @dev setCexAndJsonPath
     *  @param _cexUrls The cex URL addresses
     *  @param _cexNames The cex names such as "binance" "okx" etc.
     *  @param _jsonPaths The json paths
     */
    function setCexAndJsonPath(string[] memory _cexUrls, string[] memory _cexNames, string[] memory _jsonPaths)
        external
        onlyOwner
    {
        require(_cexUrls.length == _cexNames.length && _cexNames.length == _jsonPaths.length, "Array length mismatch");
        for (uint256 i = 0; i < _cexUrls.length; ++i) {
            cexInfoMapping[_cexUrls[i]] = CexInfo({cexName: _cexNames[i], parsePath: _jsonPaths[i]});
        }
        emit SetCexAndJsonPath(_cexUrls, _cexNames, _jsonPaths);
    }

    /**
     *  @dev getCexInfoDetail
     *  @param _cexUrl The cex URL address
     *  @return CexInfo
     *
     */
    function getCexInfoDetail(string memory _cexUrl) external view returns (CexInfo memory) {
        require(bytes(cexInfoMapping[_cexUrl].cexName).length > 0, "URL not found");
        return cexInfoMapping[_cexUrl];
    }

    /**
     * @dev Add or update the mapping of URL to exchange name and parsePath
     * @param _cexUrl The cex URL address
     * @param _cexName The cex name such as "binance" "okx" etc.
     * @param _jsonPath The parsing path
     */
    function addUrlToCexInfo(string memory _cexUrl, string memory _cexName, string memory _jsonPath)
        external
        onlyOwner
    {
        cexInfoMapping[_cexUrl] = CexInfo({cexName: _cexName, parsePath: _jsonPath});
        emit UrlToCexInfoAdded(_cexUrl, _cexName);
    }

    /**
     * @dev Remove the mapping of URL to cex info
     * @param _cexUrl The cex URL address
     */
    function removeUrlToCexInfo(string memory _cexUrl) external onlyOwner {
        require(bytes(cexInfoMapping[_cexUrl].cexName).length > 0, "URL not found");
        delete cexInfoMapping[_cexUrl];
        emit UrlToCexInfoRemoved(_cexUrl);
    }

    /**
     * @dev submit attestation
     * @param _attestation The attestation data to be verified
     * @return attestationId The attestationId of the submitted attestation
     */
    function submitAttestation(PrimusAttestation calldata _attestation) public payable returns (bool) {
        require(msg.value >= submissionFee, "Insufficient fee");

        // send fee to feeRecipient
        if (submissionFee > 0) {
            (bool sent,) = feeRecipient.call{value: msg.value}("");
            require(sent, "Failed to send fee");
            emit FeeReceived(msg.sender, msg.value);
        }

        require(_attestation.recipient == msg.sender, "Invalid recipient");
        require(_attestation.reponseResolve.length > 0, "Invalid response resolve");
        // verify the attestation is valid
        primusZKTLS.verifyAttestation(_attestation);
        // verify the url is valid
        string memory url = _attestation.request.url;
        string memory baseUrl = extractBaseUrl(url);
        CexInfo memory cexInfo = cexInfoMapping[baseUrl];
        require(bytes(cexInfo.cexName).length > 0, "Unsupported URL");

        // verify the parsePath is valid
        require(
            keccak256(bytes(cexInfo.parsePath)) == keccak256(bytes(_attestation.reponseResolve[0].parsePath)),
            "Invalid parsePath for the expected cex parsePath"
        );

        // verify the value is valid
        string memory valueString = _attestation.attConditions.extractValue("value");
        require(bytes(valueString).length > 0, "Invalid value for the Attestation");

        uint256 value = valueString.stringToUint();
        string memory operaStr = _attestation.attConditions.extractValue("op");
        require(
            keccak256(bytes(operaStr)) == keccak256(bytes(">")) || keccak256(bytes(operaStr)) == keccak256(bytes(">=")),
            "Invalid operation for the Attestation"
        );

        attestationsOfAddress[msg.sender].push(
            Attestation(_attestation.recipient, cexInfo.cexName, uint32(value), _attestation.timestamp)
        );

        emit AttestationSubmitted(_attestation.recipient, cexInfo.cexName, value, _attestation.timestamp);
        return true;
    }

    /**
     * @dev Get attestations by recipient
     * @param recipient The recipient address
     * @return Attestation[] memory
     */
    function getAttestationByRecipient(address recipient) public view returns (Attestation[] memory) {
        require(recipient != address(0), "Invalid address");
        return attestationsOfAddress[recipient];
    }

    /**
     * @dev Extract the base URL (ignoring query parameters)
     * @param url The full URL
     * @return The base URL without query parameters
     */
    function extractBaseUrl(string memory url) internal pure returns (string memory) {
        bytes memory urlBytes = bytes(url);
        uint256 queryStart = urlBytes.length;
        for (uint256 i = 0; i < urlBytes.length; i++) {
            if (urlBytes[i] == "?") {
                queryStart = i;
                break;
            }
        }
        bytes memory baseUrlBytes = new bytes(queryStart);
        for (uint256 i = 0; i < queryStart; i++) {
            baseUrlBytes[i] = urlBytes[i];
        }
        return string(baseUrlBytes);
    }
}
