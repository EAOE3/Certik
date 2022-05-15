pragma solidity =0.7.6;
// Developed by Orcania (https://orcania.io/)

interface IOCA{
         
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

    function multipleTransfer(address[] calldata recipients, uint256[] calldata amount) external;
    function multipleTransfer(address[] calldata recipients, uint256 amount) external;
    
    function multipleTransferFrom(address sender, address[] calldata recipient, uint256[] calldata amount) external;
    function multipleTransferFrom(address sender, address[] calldata recipient, uint256 amount) external;

    function O_transfer(address recipient, uint256 amount) external;
    function O_transferFrom(address sender, address recipient, uint256 amount) external;

    function approve(address spender, uint256 amount) external; 
    function increaseAllowance(address spender, uint256 addedValue) external;
    function decreaseAllowance(address spender, uint256 subtractedValue) external;   
    function clearAllowance(address[] calldata users) external;

    function burn(uint256 amount) external;
    function mint(address user, uint256 amount) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value); 
  
}

abstract contract OMS { //Orcania Management Standard

    address private _owner;
    mapping(address => uint256) private _manager;
    
    event OwnershipTransfer(address indexed newOwner);
    event SetManager(address indexed manager, uint256 state);

    constructor() {
        _owner = msg.sender;
        _manager[msg.sender] = 1;

        emit SetManager(msg.sender, 1);
    }

    //Modifiers ==========================================================================================================================================
    modifier Owner() {
        require(msg.sender == _owner, "OMS: NOT_OWNER");
        _;  
    }

    modifier Manager() {
      require(_manager[msg.sender] == 1, "OMS: NOT_MANAGER");
      _;  
    }

    //Read functions =====================================================================================================================================
    function owner() external view returns (address) {
        return _owner;
    }

    function manager(address user) external view returns(bool) {
        return _manager[user] == 1;
    }
    
    //Write functions ====================================================================================================================================
    function setNewOwner(address user) external Owner {
        _owner = user;
        emit OwnershipTransfer(user);
    }

    function setManager(address user, uint256 state) external Owner {
        _manager[user] = state;
        emit SetManager(user, state);
    }


}

abstract contract OrcaniaMath {

    function add(uint256 num1, uint256 num2) internal view returns(uint256 sum) {
        sum = num1 + num2;
        require(sum > num1, "OVERFLOW");
    }

    function sub(uint256 num1, uint256 num2) internal view returns(uint256 out) {
        out = num1 - num2;
        require(num1 > out, "UNDERFLOW");
    }

    function mul(uint256 num1, uint256 num2) internal view returns(uint256 out) {
        out = num1 * num2;
        require(out / num1 == num2, "OVERFLOW");
    }

}

contract OCA is IOCA, OMS, OrcaniaMath {
    string private _name = "Orcania";
    string private _symbol = "OCA";

    mapping (address => uint256) private _balances;
    mapping (address/*owner*/ => mapping(address/*spender*/ => uint256/*amount*/)) private _allowances;
    
    uint256 private _totalSupply = 250000000 * 10**18;
    
    constructor ()  {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    //Read functions=========================================================================================================================
    function name() external view override returns (string memory) {
        return _name;
    }
    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    function decimals() external view override returns (uint8) {
        return 18;
    }
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowances[owner_][spender];//[_allowancesRound[owner_]];
    }

    //Owner Write Functions========================================================================================================================
    function changeData(string calldata name, string calldata symbol) external Owner {
        _name = name;
        _symbol = symbol;
    }   

    //User write functions=========================================================================================================================
    function transfer(address recipient, uint256 amount) external override returns(bool){
       require((_balances[msg.sender] -= amount) < (uint256(-1) - amount), "INSUFFICIENT_BALANCE");
        
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
            
        return true;
    }

    function O_transfer(address recipient, uint256 amount) external override {
       require((_balances[msg.sender] -= amount) < (uint256(-1) - amount), "INSUFFICIENT_BALANCE");
        
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns(bool){
        require((_allowances[sender][msg.sender] -= amount) <= (uint256(-1) - amount), "INSUFFICIENT_ALLOWANCE");
        require((_balances[sender] -= amount) < (uint256(-1) - amount), "INSUFFICIENT_BALANCE");
            
        _balances[recipient] += amount; 
            
        emit Transfer(sender, recipient, amount);
            
        return true;
    }

    function O_transferFrom(address sender, address recipient, uint256 amount) external override {
        require((_allowances[sender][msg.sender] -= amount) <= (uint256(-1) - amount), "INSUFFICIENT_ALLOWANCE");
        require((_balances[sender] -= amount) < (uint256(-1) - amount), "INSUFFICIENT_BALANCE");
            
        _balances[recipient] += amount; 
            
        emit Transfer(sender, recipient, amount);
    }

    function multipleTransfer(address[] calldata recipient, uint256[] calldata amount) external override {

        uint256 total;
        uint256 length = amount.length;
            
        for(uint256 t; t < length; ++t){
            address rec = recipient[t];
            uint256 amt = amount[t];

            total += amt;
            require(total >= amt, "OVERFLOW");
            
            _balances[rec] += amt;
            emit Transfer(msg.sender, rec, amt);
        }
        
        require((_balances[msg.sender] -= total) < (uint256(-1) - total), "INSUFFICIENT_BALANCE");
    }

    function multipleTransferFrom(address sender, address[] calldata recipient, uint256[] calldata amount) external override {

        uint256 total;
        uint256 length = amount.length;
            
        for(uint256 t; t < length; ++t){
            address rec = recipient[t];
            uint256 amt = amount[t];

            total += amt;
            require(total >= amt, "OVERFLOW");
            
            _balances[rec] += amt;
            emit Transfer(sender, rec, amt); 
        }
        
        require((_allowances[sender][msg.sender] -= total) <= (uint256(-1) - total), "INSUFFICIENT_ALLOWANCE");
        require((_balances[sender] -= total) < (uint256(-1) - total), "INSUFFICIENT_BALANCE");
    }

    function multipleTransfer(address[] calldata recipient, uint256 amount) external override{

        uint256 length = recipient.length;
        uint256 total = mul(length, amount);

        require((_balances[msg.sender] -= total) < (uint256(-1) - total), "INSUFFICIENT_BALANCE");

        for(uint256 t; t < length; ++t){
            address rec = recipient[t];
            
            _balances[rec] += amount;
            emit Transfer(msg.sender, rec, amount);
        }
        
    }

    function multipleTransferFrom(address sender, address[] calldata recipient, uint256 amount) external override {

        uint256 length = recipient.length;
        uint256 total = mul(length, amount);

        require((_allowances[sender][msg.sender] -= total) <= (uint256(-1) - total), "INSUFFICIENT_ALLOWANCE");
        require((_balances[sender] -= total) < (uint256(-1) - total), "INSUFFICIENT_BALANCE");

        for(uint256 t; t < length; ++t){
            address rec = recipient[t];
            
            _balances[rec] += amount;
            emit Transfer(sender, rec, amount); 
        }
        
    }

    function approve(address spender, uint256 amount) external override {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);   
    }
    function increaseAllowance(address spender, uint256 addedValue) external override {
        _allowances[msg.sender][spender] += addedValue;
        
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);   
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external override {
        if(subtractedValue >  _allowances[msg.sender][spender]){_allowances[msg.sender][spender] = 0;}
        else{_allowances[msg.sender][spender] -= subtractedValue;}

        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);   
    }
    function clearAllowance(address[] calldata users) external override{
        uint256 length = users.length;

        for(uint256 t; t < length; ++t) {_allowances[msg.sender][users[t]] = 0;}
    }

    function burnAddress0() external {
        _totalSupply -= _balances[address(0)];
        _balances[address(0)] = 0;
    }
    
    //App write functions=========================================================================================================================

    //Used by the OM Beacon contract to burn OCA being payed as txn fees and any OCA being transfered
    function burn(uint256 amount) external override {
        require((_balances[msg.sender] -= amount) < (uint256(-1) - amount), "INSUFFICIENT_BALANCE");
        
        _totalSupply -= amount;
        
        emit Transfer(msg.sender, address(0), amount);
    }
    
    //Used to mint validator nodes on the Multichain their rewards / transfered OCA
    function mint(address user, uint256 amount) external Manager override {
        require(amount < 500000000000000000000000000, "MINT_LIMIT_EXCEEDED");
        require((_totalSupply += amount) < 500000000000000000000000001, "MINT_LIMIT_EXCEEDED");
        
        _balances[user] += amount;

        emit Transfer(address(0), user, amount);
    }


}
