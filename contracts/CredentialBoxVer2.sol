// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

// 추상컨트랙트인 오너헬퍼 생성
abstract contract OwnerHelper {
  address private owner;

  // 오너 변경 제안 함수 실행시 emit되는 이벤트
  event OwnerTransferPropose(address indexed _from, address indexed _to);

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // 배포시 초기값
  constructor() {
    owner = msg.sender;
  }

  // owner 변경 함수
  function transferOwnership(address _to) public onlyOwner {
    require(_to != owner);
    require(_to != address(0x0));
    owner = _to;
    emit OwnerTransferPropose(msg.sender, _to);
  }
}

// 추상 컨트랙트인 이슈어헬퍼 생성, 오너헬퍼 컨트랙트를 상속받는다.
abstract contract IssuerHelper is OwnerHelper {
  // issuer 목록을 저장하는 매핑
  mapping(address => bool) public issuers;

  // issuer가 추가/삭제될 때 emit되는 이벤트
  event AddIssuer(address indexed _issuer);
  event DelIssuer(address indexed _issuer);

  // issuer로 지정된 사람만 실행가능하도록 제한해주는 모디파이어
  modifier onlyIssuer() {
    require(isIssuer(msg.sender) == true);
    _;
  }

  // 초기세팅값, 배포자를 issuer로 지정한다.
  constructor() {
    issuers[msg.sender] = true;
  }

  // 입력받은 주소값이 issuer인지 확인시켜주는 함수
  function isIssuer(address _addr) public view returns (bool) {
    return issuers[_addr];
  }

  // issuer를 추가해주는 함수, 상속받은 onlyOwner 모디파이어를 사용한다.
  function addIssuer(address _addr) public onlyOwner returns (bool) {
    require(issuers[_addr] == false);
    issuers[_addr] = true;
    emit AddIssuer(_addr);
    return true;
  }

  // issuer를 삭제해주는 함수, 상속받은 onlyOwner 모디파이어를 사용한다.
  function delIssuer(address _addr) public onlyOwner returns (bool) {
    require(issuers[_addr] == true);
    issuers[_addr] = false;
    emit DelIssuer(_addr);
    return true;
  }
}

// CredentialBox 컨트랙트 생성, IssuerHelper를 상속받았는데, IssuerHelper는 onlyOwner를 상속받았기때문에
// CredentialBox는 IssuerHelper, ownerHelper를 둘 다 상속받은것이 된다.
contract CredentialBox is IssuerHelper {
  uint256 private idCount;
  mapping(uint8 => string) private alumniEnum;
  mapping(uint8 => string) private statusEnum;

  // Credential의 정보를 담고있는 struct 정의
  struct Credential {
    uint256 id;
    address issuer;
    uint8 alumniType;
    uint8 statusType;
    string value;
    uint256 createDate;
  }

  // mapping을 통해 개인의 주소에 Credential 타입의 struct을 담는다.
  mapping(address => Credential) private credentials;

  constructor() {
    idCount = 1;
    alumniEnum[0] = "SEB";
    alumniEnum[1] = "BEB";
    alumniEnum[2] = "AIB";
  }

  // credential을 발급해주는 함수
  function claimCredential(
    address _alumniAddress,
    uint8 _alumniType,
    string calldata _value
  ) public onlyIssuer returns (bool) {
    Credential storage credential = credentials[_alumniAddress];
    require(credential.id == 0);
    credential.id = idCount;
    credential.issuer = msg.sender;
    credential.alumniType = _alumniType;
    credential.statusType = 0;
    credential.value = _value;
    credential.createDate = block.timestamp;

    idCount += 1;

    return true;
  }

  // credential을 확일할 수 있는 함수, 이 함수에 기능으로 위에서 Credential을 만들 때 random한 값을 return 해 주고
  // 파라미터로 address와 발급받은 random한 값을 동시에 받았을 때 두 개를 대조하여 credential을 확인할 수 있도록 해주면 더 좋을 것 같다.
  function getCredential(address _alumniAddress)
    public
    view
    returns (Credential memory)
  {
    return credentials[_alumniAddress];
  }

  // aluumniType을 추가할 수 있도록 해주는 함수
  function addAlumniType(uint8 _type, string calldata _value)
    public
    onlyIssuer
    returns (bool)
  {
    require(bytes(alumniEnum[_type]).length == 0);
    alumniEnum[_type] = _value;
    return true;
  }

  // 입력값을 기준으로 등록되어있는 alumniType을 알려주는 함수
  function getAlumniType(uint8 _type) public view returns (string memory) {
    return alumniEnum[_type];
  }

  // statusType을 추가할 수 있게 해주는 함수
  function addStatusType(uint8 _type, string calldata _value)
    public
    onlyIssuer
    returns (bool)
  {
    require(bytes(statusEnum[_type]).length == 0);
    statusEnum[_type] = _value;
    return true;
  }

  // 입력값을 기준으로 등록되어있는 statusType을 알려주는 함수
  function getStatusType(uint8 _type) public view returns (string memory) {
    return statusEnum[_type];
  }

  // parameter로 받은 address의 statusType을 변경할 수 있게 해주는 함수
  function changeStatus(address _alumni, uint8 _type)
    public
    onlyIssuer
    returns (bool)
  {
    require(credentials[_alumni].id != 0);
    require(bytes(statusEnum[_type]).length != 0);
    credentials[_alumni].statusType = _type;
    return true;
  }
}
