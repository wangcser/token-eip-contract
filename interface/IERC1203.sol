contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC1203 is ERC20 {
    function totalSupply(uint256 _class) public view returns (uint256);
    function balanceOf(address _owner, uint256 _class) public view returns (uint256);
    function transfer(address _to, uint256 _class, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _class, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender, uint256 _class) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _class, uint256 _value) public returns (bool);

    function fullyDilutedTotalSupply() public view returns (uint256);
    function fullyDilutedBalanceOf(address _owner) public view returns (uint256);
    function fullyDilutedAllowance(address _owner, address _spender) public view returns (uint256);
    function convert(uint256 _fromClass, uint256 _toClass, uint256 _value) public returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint256 _class, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _class, uint256 _value);
    event Convert(uint256 indexed _fromClass, uint256 indexed _toClass, uint256 _value);
}