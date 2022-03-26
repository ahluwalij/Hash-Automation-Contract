/*
       /|  /|          /|  /|          /|  /|          /|  /|          /|  /|          /|  /|          /|  /|   
   ___//__//__     ___//__//__     ___//__//__     ___//__//__     ___//__//__     ___//__//__     ___//__//__  
  '--//--//---'   '--//--//---'   '--//--//---'   '--//--//---'   '--//--//---'   '--//--//---'   '--//--//---' 
 ___//__//__     ___//__//__     ___//__//__     ___//__//__     ___//__//__     ___//__//__     ___//__//__    
'--//--//---'   '--//--//---'   '--//--//---'   '--//--//---'   '--//--//---'   '--//--//---'   '--//--//---'   
  |/  |/          |/  |/          |/  |/          |/  |/          |/  |/          |/  |/          |/  |/        
      .·¨'`;        ,.·´¨;\                   ,.,   '                   ,. -,          .·¨'`;        ,.·´¨;\   
     ';   ;'\       ';   ;::\                ;´   '· .,            ,.·'´,    ,'\        ';   ;'\       ';   ;::\  
     ;   ;::'\      ,'   ;::';             .´  .-,    ';\      ,·'´ .·´'´-·'´::::\'      ;   ;::'\      ,'   ;::'; 
     ;  ;::_';,. ,.'   ;:::';°           /   /:\:';   ;:'\'   ;    ';:::\::\::;:'       ;  ;::_';,. ,.'   ;:::';°
   .'     ,. -·~-·,   ;:::'; '         ,'  ,'::::'\';  ;::';   \·.    `·;:'-·'´        .'     ,. -·~-·,   ;:::'; '
   ';   ;'\::::::::;  '/::::;       ,.-·'  '·~^*'´¨,  ';::;    \:`·.   '`·,  '        ';   ;'\::::::::;  '/::::;  
    ;  ';:;\;::-··;  ;::::;        ':,  ,·:²*´¨¯'`;  ;::';      `·:'`·,   \'          ;  ';:;\;::-··;  ;::::;   
    ':,.·´\;'    ;' ,' :::/  '       ,'  / \::::::::';  ;::';       ,.'-:;'  ,·\         ':,.·´\;'    ;' ,' :::/  '  
     \:::::\    \·.'::::;         ,' ,'::::\·²*'´¨¯':,'\:;   ,·'´     ,.·´:::'\         \:::::\    \·.'::::;     
       \;:·´     \:\::';          \`¨\:::/          \::\'    \`*'´\::::::::;·'‘          \;:·´     \:\::';      
                  `·\;'            '\::\;'            '\;'  '   \::::\:;:·´                          `·\;'       
                     '               `¨'                        '`*'´‘                                 '        
       /|  /|          /|  /|          /|  /|          /|  /|          /|  /|          /|  /|          /|  /|   
   ___//__//__     ___//__//__     ___//__//__     ___//__//__     ___//__//__     ___//__//__     ___//__//__  
  '--//--//---'   '--//--//---'   '--//--//---'   '--//--//---'   '--//--//---'   '--//--//---'   '--//--//---' 
 ___//__//__     ___//__//__     ___//__//__     ___//__//__     ___//__//__     ___//__//__     ___//__//__    
'--//--//---'   '--//--//---'   '--//--//---'   '--//--//---'   '--//--//---'   '--//--//---'   '--//--//---'   
  |/  |/          |/  |/          |/  |/          |/  |/          |/  |/          |/  |/          |/  |/        

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Hash is ERC721, Ownable {

    using Strings for uint;
    using Counters for Counters.Counter;

    string private _tokenURI;
    string private _contractURI;
    bytes private _password;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _bannedCounter;
    
    uint public maxSupply = 9999;
    uint public tokenPrice = 0.01 ether;
    bool public saleStarted = false;
    bool public transfersEnabled = false;

    mapping(uint => uint) public expirationTimes;
    mapping(uint => uint) public banned;

    //When Looking Up If A Token Is Banned, Use The Token ID, Not It's Banned Index
    uint public bannedMapSize;

    constructor(
        string memory tokenURI_,
        string memory contractURI_
    ) ERC721("Hash", "#") {
        _tokenURI = tokenURI_;
        _contractURI = contractURI_;
    }

//  ==============================PUBLIC FUNCTIONS==============================
    
    //@dev Mint a Single Token Using A Password
    function mint(string memory password) 
    isPasswordCorrect(password)
    public payable {
        uint tokenIndex = _tokenIdCounter.current() + 1;
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        require(saleStarted, "Sale has not started.");
        require(balanceOf(msg.sender) == 0, "User already holds a token.");
        require(msg.value == tokenPrice, "Incorrect Ether amount sent.");
        require(tokenIndex <= maxSupply, "Minted token would exceed total supply.");

        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenIndex);
        expirationTimes[tokenIndex] = block.timestamp + 30 days;
    }

    /*@dev Function That Adds 30 Days To The Expiration Date. 
           If The Token Is Expired, The New Expiration Date Will Be
           The Date The Token Is Renewed Plus 30 Days.
    */
    //@param _tokenId The token ID to extend/renew.
    function renewToken(uint _tokenId) 
    public payable {
        require(tx.origin == msg.sender, "Caller must not be a contract.");
        require(msg.value == tokenPrice, "Incorrect Ether amount.");
        require(_exists(_tokenId), "Token does not exist.");

        uint _currentexpirationTimes = expirationTimes[_tokenId];

        if (block.timestamp > _currentexpirationTimes) {
            expirationTimes[_tokenId] = block.timestamp + 30 days;
        } else {
            expirationTimes[_tokenId] += 30 days;
        }
    }

//  ==============================MODIFIERS==============================
    
    modifier isPasswordCorrect(string memory password) {
        if (msg.sender != owner()) {
        require(keccak256(abi.encodePacked(password)) == keccak256(_password),"Password is incorrect");
        }
        _;
    }

    modifier isTokenBanned(uint _tokenId) {
        bool present = false;
        for (uint i= 0; i <= _bannedCounter.current(); i++) {
            if (_tokenId == banned[i]) {
                present = true;
                }
                }
        require(present == false,"Key is Banned");
        _;
    }

//  ==============================OWNER FUNCTIONS==============================

    //@dev Bans Specified Key And Makes It's UNIX Expiration Time 1
    function ban(uint _tokenId) external onlyOwner {
        banned[_bannedCounter.current() + 1] = _tokenId;
        expirationTimes[_tokenId] = 1;
        _bannedCounter.increment();
    }

    //@dev Bans Specified Key And Makes It's UNIX Expiration Time The Date Of Unban Plus 30 Days
    function unban(uint _tokenId) external onlyOwner {
            if(banned[_tokenId] == _tokenId){
                banned[_tokenId] = 0;
                _bannedCounter.decrement();
                expirationTimes[_tokenId] = block.timestamp + 30 days;
            }
    }

    //@dev Get Password.
    function getPassword() external onlyOwner view returns (bytes memory){
        return _password;
    }

    //@dev Set Password Using String Input.
    function setPasswordString(string memory password) external onlyOwner {
        _password = "";
        _password = abi.encodePacked(password);
    }

    //@dev Set Password Using Byte Input.
    function setPassword(bytes memory password) external onlyOwner {
        _password = "";
        _password = password;
    }

    //@dev Mint A Token To An Inputted Address.
    //@param _receiver Address To Recieve The Gifted Token.
    function ownerGift(address _receiver) public onlyOwner {

        uint tokenIndex = _tokenIdCounter.current() + 1;

        require(_receiver != address(0), "Receiver cannot be zero address.");
        require(tokenIndex <= maxSupply, "Minted token would exceed total supply.");

        if (msg.sender != _receiver) {
            //require(balanceOf(_receiver) == 0, "User already holds a token.");
        }

        _tokenIdCounter.increment();

        _safeMint(_receiver, tokenIndex);
        expirationTimes[tokenIndex] = block.timestamp + 30 days;
    }

    //@dev Owner function that is used to extend/renew multiple token's expiry dates.
    //@param _tokenId The token ID to extend/renew.
    function ownerRenew(uint[] calldata _tokenIds) external onlyOwner {
        require(_tokenIds.length > 0, "Invalid array length.");

        for (uint i=0; i<_tokenIds.length; i++) {
            require(_exists(_tokenIds[i]), "Token does not exist.");
            
            uint _currentexpirationTimes = expirationTimes[_tokenIds[i]];

            if (block.timestamp > _currentexpirationTimes) {
                expirationTimes[_tokenIds[i]] = block.timestamp + 30 days;
            } else {
                expirationTimes[_tokenIds[i]] += 30 days;
            }
        }
    }

    //@dev Replaces the Current Price.
    function setPrice(uint _updatedTokenPrice) external onlyOwner {
        require(tokenPrice != _updatedTokenPrice, "Price has not changed.");
        tokenPrice = _updatedTokenPrice/1000000000000000000 ;
    }

    //@dev Add Tokens to Max Supply; Restock Function.
    function addTokens(uint _newTokens) external onlyOwner {
        maxSupply += _newTokens;
    }

    //@dev Subtracts Tokens from Max Supply.
    function removeTokens(uint _numTokens) external onlyOwner {
        require(maxSupply - _numTokens >= totalSupply(), "Supply cannot fall below minted tokens.");
        maxSupply -= _numTokens;
    }

    //@dev Replaces the Current tokenURI.
    function setTokenURI(string calldata tokenURI_) external onlyOwner {
        _tokenURI = tokenURI_;
    }


    //@dev Replaces the Current contractURI.
    function setContractURI(string calldata contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    //@dev Withdraw Balance.
    function withdrawBalance() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    //@dev Toggle Sale.
    function toggleSale() public onlyOwner {
        saleStarted = !saleStarted;
    }

    //@dev Toggle Transfers.
    function toggleTransfers() public onlyOwner {
        transfersEnabled = !transfersEnabled;
    }

//  ==============================OVERRIDE FUNCTIONS==============================

    //@dev Overrides Default safeTransferFrom To Allow Transfers To Be Disabled.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) isTokenBanned(tokenId)
    public virtual override{
        if (msg.sender != owner()) {
            require(transfersEnabled, "Token transfers are currently disabled.");
            require(balanceOf(to) == 0, "User already holds a token.");
        }
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Transfer caller is not owner nor approved.");
        require(expirationTimes[tokenId] > block.timestamp, "This token is expired.");
        _safeTransfer(from, to, tokenId, _data);
    }

    //@dev Overrides Default transferFrom To Allow Transfers To Be Disabled.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) isTokenBanned(tokenId)
    public virtual override {
        if (msg.sender != owner()) {
            require(transfersEnabled, "Token transfers are currently disabled.");
            require(balanceOf(to) == 0, "User already holds a token.");
        }
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Transfer caller is not owner nor approved.");
        require(expirationTimes[tokenId] > block.timestamp, "This token is expired.");
        _transfer(from, to, tokenId);
    }

//  ==============================UTILITY FUNCTIONS==============================

    //@dev Returns the tokenURI For A Specific Token.
    function tokenURI(uint _tokenId) 
    public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(_tokenURI, _tokenId.toString(),".json"));
    }

    //@dev Returns the Current contractURI.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    //@dev Returns Total Tokens Minted.
    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }

    //@dev Returns Total Tokens Banned.
    function totalBanned() public view returns (uint) {
        return _bannedCounter.current();
    }

}