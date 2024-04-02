// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract NFT is ERC721URIStorage {
  

    address payable owner;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemSold;

    uint listPrice=0.01 ether;

    constructor() ERC721("NFT", "NFT") {
        owner = payable(msg.sender);
    }

    struct ListedToken{
        uint256 token;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    mapping(uint256=>ListedToken) private idToListedToken;
    
    function updateListPrice(uint _price) public payable{
        require(msg.sender==owner,"Only owner can update the list price");
        listPrice=_price;
    }

    function getListPrice() public view returns(uint){
        return listPrice;
    }

    function getLatestIdToListedToken()public view returns(ListedToken memory){
        return idToListedToken[_tokenIds.current()];
    }

    function getListedForTokenId(uint256 TokenId)public view returns(ListedToken memory){
        return idToListedToken[TokenId];
    }

    function getCurrentTokens() public view returns(uint256){
        return _tokenIds.current();
    }

    function createToken(string memory tokenURI ,uint256 price)public payable returns( uint256 ){
        require(msg.value==listPrice,"Please send the correct amount to create the token");
        require(price>0,"Price should be greater than 0");  
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function createListedToken(uint256 tokenId,uint256 price) private{
        idToListedToken[tokenId]=ListedToken(tokenId,payable(address(this)),payable(msg.sender),price,true);
        _transfer(msg.sender,address(this),tokenId);
    }

    function getAllNFTS() public view returns(ListedToken[] memory){
        uint256 totalNFTs = _tokenIds.current();

        uint currIndex=0;
        ListedToken[] memory allNFTs = new ListedToken[](totalNFTs);
        for(uint256 i=0;i<totalNFTs;i++){
            uint ci=i+1;
            ListedToken memory listedToken = idToListedToken[ci];

            allNFTs[currIndex]=listedToken;

            currIndex+=1;
        }
        return allNFTs;
    }

    function getMyNFTs() public view returns(ListedToken[] memory){
        uint totalItemCunt=_tokenIds.current();
        uint itemCount=0;
        uint currentIndex=0;

        for(uint i=0;i<totalItemCunt;i++){
            uint ci=i+1;
            ListedToken memory listedToken = idToListedToken[ci];
            if(listedToken.owner==msg.sender||listedToken.seller==msg.sender){
                itemCount+=1;
            }
        }

        ListedToken[] memory myNFTs = new ListedToken[](itemCount);

        for(uint i=0;i<totalItemCunt;i++){
            uint ci=i+1;
            ListedToken memory listedToken = idToListedToken[ci];
            if(listedToken.owner==msg.sender||listedToken.seller==msg.sender){
                myNFTs[currentIndex]=listedToken;
                currentIndex+=1;
            }
        }

        return myNFTs;
    }

    function buyNFT(uint256 tokenId) public payable{
       uint price=idToListedToken[tokenId].price;
       require(msg.value==price,"Please send the correct amount to buy the token");
       address seller=idToListedToken[tokenId].seller;

        idToListedToken[tokenId].currentlyListed=false;
        idToListedToken[tokenId].seller=payable(msg.sender);

        _itemSold.increment();
        _transfer(address(this),msg.sender,tokenId);
        approve(address(this),tokenId);

        payable(owner).transfer(listPrice);
        payable(seller).transfer(msg.value);
    }

}