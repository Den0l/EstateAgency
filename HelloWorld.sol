// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract EstateAgency{

    enum EstateType {House, Flat, Loft} //перечисление типа недвижимости
    enum AdvertisementStatus {Opend, Closed} //перечесление для статуса обьявления
    
    struct Estate{  //структура для недвижимости
        uint estateId;
        uint size;
        string photo;
        bool isActive;
        address owner;
        uint rooms;
        EstateType esType;
    }

    struct Advertisement{ //структура для обьявления
        address owner;
        address buyer;
        uint price;
        uint dateTime;
        bool isActive;
        AdvertisementStatus adStatus;
        uint estateId;
    }

    Estate[] public estates;
    Advertisement[] public ads;

    event createdEstate(address owner, uint estateId, string photo, EstateType esType, uint dateTime);
    event createdAd(address owner, uint estateId, uint adId, uint price, uint dateTime);
    event updatedEstate(address owner, uint estateId, bool isActive, uint dateTime);
    event updatedAd(address owner, uint estateId, uint adId, AdvertisementStatus adStatus, uint dateTime);
    event estatePurchased(address owner, address buyer, uint estateId, uint adId, AdvertisementStatus adStatus, uint price, uint dateTime);
    event fundsBack(address to, uint amount, uint dateTime);

    modifier enouhtValue(uint value, uint price){
        require(value >= price, unicode"У вас недостаточно средств");
        _;
    }

    modifier onlyEstateOwner(uint estateId){
        require(estates[estateId].owner == msg.sender, unicode"Вы не владелец недвижимоси");
        _;
    }

    modifier isActiveEstate(uint estateId){
        require(estates[estateId].isActive, unicode"Недвижимость недоступна");
        _;
    }

    modifier isAdClosed(uint adId){
        require(ads[adId].adStatus != AdvertisementStatus.Closed, unicode"Данное объявление закрыто");
        _;
    }

    modifier notOwner(uint adId){
        require(ads[adId].owner != msg.sender, unicode"Владелец не может купить свою недвижимость");
        _;
    }


// нельзя создать дважды одно и тоже
  function createEstate( uint size, string memory photo, uint rooms, EstateType esType) public{
    require(size > 0, unicode"Площадь должна быть больше 0");
    for(uint i = 0; i < estates.length; i++)
    {
    require(estates[i].size != size ||
            estates[i].rooms != rooms ||
            estates[i].esType != esType,
            unicode"Такая недвижимость уже существует");
    }
    estates.push(Estate(estates.length+1, size, photo, true, msg.sender, rooms, esType));
    emit createdEstate(msg.sender, estates.length, photo, esType, block.timestamp);
  }

//создание объявления на наличие недвижимости, 
//недвижимость должна быть активной, 
//объявление может создать только владелец недвижимости, 
//мы не можем создать несколько объявлений по одной и той же недвижимости
  function createAd (uint price, uint estateId) public onlyEstateOwner(estateId) isActiveEstate(estateId){
    require(price > 0, unicode"Цена должна быть больше 0");
    for(uint i = 0; i < ads.length; i++)
    {
    require(estateId != ads[i].estateId, unicode"Такая недвижимость уже существует");
    }
    ads.push(Advertisement(msg.sender, address(0), price, block.timestamp, true, AdvertisementStatus.Opend, estateId));
    emit createdAd(msg.sender, estateId, ads.length, price, block.timestamp);
  }

//это может делать только владелец недвижимости. 
//и если мы меняем статус на false, то объявление (если оно есть) закрывается
  function updateEstateStatus(uint estateId, bool isActiveEs) public onlyEstateOwner(estateId) {
    if(!isActiveEs)
    {
      ads[estateId-1].adStatus = AdvertisementStatus.Closed;
      emit updatedAd(msg.sender, estateId, estateId-1, ads[estateId-1].adStatus, block.timestamp);
    }
    emit updatedEstate(msg.sender, estateId, isActiveEs, block.timestamp);
  }

//только владелец объявления, если статус closed, то мы не может открыть это объявдение заново
  function updateAdStatus(uint estateId, uint adId, AdvertisementStatus adStatus) public onlyEstateOwner(estateId) isActiveEstate(estateId) isAdClosed(adId){
    ads[adId-1].adStatus = adStatus;
    emit updatedAd(msg.sender, estateId, adId, ads[adId-1].adStatus, block.timestamp);

  }

//проверка на не владельца, проверка на достаточное количество средств, проверка на статус объявления (не closed)
  function buyEstate(uint estateId, uint adId) public payable notOwner(adId) isAdClosed(adId) enouhtValue(msg.value, ads[adId-1].price) {
    ads[adId-1].buyer = msg.sender;
    ads[adId-1].adStatus = AdvertisementStatus.Closed;
    estates[estateId-1].owner = msg.sender;
    emit estatePurchased(ads[adId-1].owner, ads[adId-1].buyer, estateId, adId, ads[adId-1].adStatus, ads[adId-1].price, block.timestamp);

  }

//мы не можем снять больше чем у нас есть
 function withDraw() public {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(address(this).balance);
    emit fundsBack(msg.sender, balance, block.timestamp);
  }

  function getBalance() public view returns(uint){
    return address(this).balance;
  }

  function getEstates() public view returns(Estate[] memory)
  {
    return estates;
  }
  function getAds() public view returns(Advertisement[] memory)
  {
    return ads;
  }
}