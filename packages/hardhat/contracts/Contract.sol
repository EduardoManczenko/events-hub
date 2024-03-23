// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract token1155 is ERC1155 {
    address public owner;
    string public name;
    string public symbol;
    address usdContract;

    mapping(uint256 => uint256) ticketPrice;

    mapping(uint256 => uint256) ticketsMaxSupply;
    mapping(uint256 => uint256) ticketTotalSupply;

    struct dadosEvento {
        string description;
        uint256 dataEvento;
        string localEvento;
        string logo;
        string banner;
        uint256 totalArrecadado;
        uint256 totalArrecadadoDesejado;
    }

    dadosEvento public data;

    modifier onlyOwner() {
        require(msg.sender == owner, "ERRO: !owner");
        _;
    }

    constructor(
        dadosEvento memory data_,
        address owner_,
        string memory name_,
        string memory symbol_,
        address usdContract_,
        uint256[] memory ticketsPrice_,
        uint256[] memory ticketsMaxSupply_
    ) ERC1155("") {
        data = data_;
        owner = owner_;
        name = name_;
        symbol = symbol_;
        usdContract = usdContract_;

        for (uint256 i = 0; i < ticketsPrice_.length; i++) {
            ticketPrice[i + 1] = ticketsPrice_[i];
            ticketsMaxSupply[i + 1] = ticketsMaxSupply_[i];
        }
    }

    function mint(address account, uint256 id, uint256 amount) internal {
        require(ticketTotalSupply[id] + amount <= ticketsMaxSupply[id], "ERRO: Lote esgotado");
        ticketTotalSupply[id] += amount;
        _mint(account, id, amount, "");
    }

    function buyTicket(uint256 id, uint256 amount) external {
        ERC20 usd = ERC20(usdContract);
        require(usd.balanceOf(msg.sender) >= ticketPrice[id], "dont have balance");

        uint256 price = ticketPrice[id] * amount;

        bool usdTransfer = usd.transferFrom(msg.sender, address(this), price);
        require(usdTransfer);

        mint(msg.sender, id, amount);
        data.totalArrecadado += price;
    }

    function userExtorno(uint256 id, uint256 amount) external {
        ERC20 usd = ERC20(usdContract);
        require(balanceOf(msg.sender, id) <= amount, "ERRO: quantidade para o saque invalida");
        require(data.totalArrecadado < data.totalArrecadadoDesejado, "ERRO: evento viabilizado, extorno nao e possivel");
        require(block.timestamp >= data.dataEvento, "ERRO: o evento ainda nao atingiu sua data limite");
        uint256 price = ticketPrice[id] * amount;
        _burn(msg.sender, id, amount);
        usd.transfer(msg.sender, price);
    }

    function viewUserExtorno() external view returns (bool) {
        bool verify1 = data.totalArrecadado < data.totalArrecadadoDesejado;
        bool verify2 = block.timestamp >= data.dataEvento;
        return verify1 && verify2;
    }

    function ownerCollect() external onlyOwner {
        ERC20 usd = ERC20(usdContract);
        require(data.totalArrecadado >= data.totalArrecadadoDesejado, "ERRO: total a ser arrecadado nao foi atingido");
        uint256 total = usd.balanceOf(address(this));
        usd.transfer(owner, total);
    }

    function viewOwnerCollect() external view returns (bool) {
        return data.totalArrecadado >= data.totalArrecadadoDesejado;
    }

    function viewTicketPrice(uint256 id_) public view returns (uint256) {
        return ticketPrice[id_];
    }

    function viewTicketTotalSupply(uint256 id_) public view returns (uint256) {
        return ticketTotalSupply[id_];
    }

    function viewTicketMaxSupply(uint256 id_) public view returns (uint256) {
        return ticketsMaxSupply[id_];
    }

    function viewTicketData(uint256 id_) public view returns (uint256, uint256, uint256) {
        return (viewTicketPrice(id_), viewTicketTotalSupply(id_), viewTicketMaxSupply(id_));
    }

    function viewAllData() public view returns (dadosEvento memory, address, string memory, string memory) {
        return (data, owner, name, symbol);
    }
}

//["descricao teste",1715456792,"Rua dos bobos, N 0","url da logo","url do banner",0,50]
//0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
//nomeTeste
//NT

//[10,20,30]
//[2,5,10]

contract factoryERC1155 {
    address[] collections;

    function viewCollections() public view returns (address[] memory) {
        return collections;
    }

    function calcDaysForEvent(uint256 daysToAdd) public view returns (uint256) {
        uint256 secondsToAdd = daysToAdd * 1 days;
        return block.timestamp + secondsToAdd;
    }

    function createEvent(
        token1155.dadosEvento memory data_,
        address owner_,
        string memory name_,
        string memory symbol_,
        address usdContract_,
        uint256[] memory ticketsPrice_,
        uint256[] memory ticketsMaxSupply_
    ) public {
        token1155.dadosEvento memory newData = token1155.dadosEvento({
            description: data_.description,
            dataEvento: calcDaysForEvent(data_.dataEvento),
            localEvento: data_.localEvento,
            logo: data_.logo,
            banner: data_.banner,
            totalArrecadado: data_.totalArrecadado,
            totalArrecadadoDesejado: data_.totalArrecadadoDesejado
        });

        token1155 newEvent =
            new token1155(newData, owner_, name_, symbol_, usdContract_, ticketsPrice_, ticketsMaxSupply_);
        collections.push(address(newEvent));
    }
}

contract usdTeste is ERC20 {
    constructor(address user1, address user2) ERC20("USD", "USD") {
        _mint(user1, 10000 * 10 ** decimals());
        _mint(user2, 10000 * 10 ** decimals());
    }

    function mint(address user, uint256 amount) public {
        _mint(user, amount * 10 ** decimals());
    }
}
