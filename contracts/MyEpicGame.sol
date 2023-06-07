// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

// Contrato NFT para herdar.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Funcoes de ajuda que o OpenZeppelin providencia.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Helper que escrevemos para codificar em Base64
import "./libraries/Base64.sol";

// Nosso contrato herda do ERC721, que eh o contrato padrao de
// NFT!
contract MyEpicGame is ERC721 {
    // Nos vamos segurar os atributos dos nossos personagens em uma
    //struct. Sinta-se livre para adicionar o que quiser como um
    //atributo! (ex: defesa, chance de critico, etc).
    struct CharacterAttributes {
        uint characterIndex;
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint mana;
        uint maxMana;
        uint attackDamage;
    }

    struct BigBoss {
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint mana;
        uint maxMana;
        uint attackDamage;
    }

    BigBoss public bigBoss;

    // O tokenId eh o identificador unico das NFTs, eh um numero
    // que vai incrementando, como 0, 1, 2, 3, etc.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Uma pequena array vai nos ajudar a segurar os dados padrao dos
    // nossos personagens. Isso vai ajudar muito quando mintarmos nossos
    // personagens novos e precisarmos saber o HP, dano de ataque e etc.
    CharacterAttributes[] defaultCharacters;

    // Criamos um mapping do tokenId => atributos das NFTs.
    mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

    // Um mapping de um endereco => tokenId das NFTs, nos da um
    // jeito facil de armazenar o dono da NFT e referenciar ele
    // depois.
    mapping(address => uint256) public nftHolders;

    event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
    event AttackComplete(uint newBossHp, uint newPlayerHp);

    // Dados passados no contrato quando ele for criado inicialmente,
    // inicializando os personagens.
    // Vamos passar esse valores do run.js
    constructor(
        string[] memory characterNames,
        string[] memory characterImageURIs,
        uint[] memory characterHp,
        uint[] memory characterMana,
        uint[] memory characterAttackDmg,
        string memory bossName, // Essas novas variáveis serão passadas via run.js ou deploy.js
        string memory bossImageURI,
        uint bossHp,
        uint bossMana,
        uint bossAttackDamage
    )
    ERC721("Heroes", "HERO")
    {
        // Inicializa o boss. Salva na nossa variável global de estado "bigBoss".
        bigBoss = BigBoss({
            name: bossName,
            imageURI: bossImageURI,
            hp: bossHp,
            maxHp: bossHp,
            mana: bossMana,
            maxMana: bossMana,
            attackDamage: bossAttackDamage
        });

        console.log("Boss inicializado com sucesso %s com HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);

        // Faz um loop por todos os personagens e salva os valores deles no
        // contrato para que possamos usa-los depois para mintar as NFTs
        for(uint i = 0; i < characterNames.length; i += 1) {
        defaultCharacters.push(CharacterAttributes({
            characterIndex: i,
            name: characterNames[i],
            imageURI: characterImageURIs[i],
            hp: characterHp[i],
            maxHp: characterHp[i],
            mana: characterMana[i],
            maxMana: characterMana[i],
            attackDamage: characterAttackDmg[i]
        }));

        CharacterAttributes memory c = defaultCharacters[i];
        console.log("Personagem inicializado: %s com %s de HP e %s de Mana", c.name, c.hp, c.mana);
        console.log("Veja a aparencia dele em %s", c.imageURI);
        console.log("------------------------------------------------");
        }

        // Eu incrementei tokenIds aqui para que minha primeira NFT tenha o ID 1.
        // Mais nisso na aula!
        _tokenIds.increment();
    }

    // Usuarios vao poder usar essa funcao e pegar a NFT baseado no personagem que mandarem!
    function mintCharacterNFT(uint _characterIndex) external {
    // Pega o tokenId atual (começa em 1 já que incrementamos no constructor).
    uint256 newItemId = _tokenIds.current();

    // A funcao magica! Atribui o tokenID para o endereço da carteira de quem chamou o contrato.

    _safeMint(msg.sender, newItemId);

    // Nos mapeamos o tokenId => os atributos dos personagens. Mais disso abaixo

    nftHolderAttributes[newItemId] = CharacterAttributes({
      characterIndex: _characterIndex,
      name: defaultCharacters[_characterIndex].name,
      imageURI: defaultCharacters[_characterIndex].imageURI,
      hp: defaultCharacters[_characterIndex].hp,
      maxHp: defaultCharacters[_characterIndex].maxHp,
      mana: defaultCharacters[_characterIndex].mana,
      maxMana: defaultCharacters[_characterIndex].maxMana,
      attackDamage: defaultCharacters[_characterIndex].attackDamage
    });

    console.log("Mintou NFT c/ tokenId %s e characterIndex %s", newItemId, _characterIndex);

    // Mantem um jeito facil de ver quem possui a NFT
    nftHolders[msg.sender] = newItemId;

    // Incrementa o tokenId para a proxima pessoa que usar.
    _tokenIds.increment();

    emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

        string memory strHp = Strings.toString(charAttributes.hp);
        string memory strMaxHp = Strings.toString(charAttributes.maxHp);
        string memory strMana = Strings.toString(charAttributes.hp);
        string memory strMaxMana = Strings.toString(charAttributes.maxHp);
        string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);

        string memory json = Base64.encode(
        abi.encodePacked(
            '{"name": "',
            charAttributes.name,
            ' -- NFT #: ',
            Strings.toString(_tokenId),
            '", "description": "Esta NFT da acesso ao meu jogo NFT!", "image": "',
            charAttributes.imageURI,
            '", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'},{ "trait_type": "Mana Points", "value": ',strMana,', "max_value":',strMaxMana,'}, { "trait_type": "Attack Damage", "value": ',
            strAttackDamage,'} ]}'
        )
        );

        string memory output = string(
        abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function attackBoss() public {
        // Pega o estado da NFT do jogador.
        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];

        console.log("\nJogador com personagem %s ira atacar. Tem %s de HP e %s de PA", player.name, player.hp, player.attackDamage);
        console.log("Boss %s tem %s de HP e %s de PA", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);

        // Checa se o hp do jogador é maior que 0.
        require (
            player.hp > 0,
            "Erro: personagem deve ter HP para atacar o boss."
        );

        // Checa que o hp do boss é maior que 0.
        require (
            bigBoss.hp > 0,
            "Erro: Boss deve ter HP para ser atacado."
        );

        // Permite que o jogador ataque o boss.
        if (bigBoss.hp < player.attackDamage) {
            bigBoss.hp = 0;
        } else {
            bigBoss.hp = bigBoss.hp - player.attackDamage;
        }

        // Permite que o boss ataque o jogador.
        if (player.hp < bigBoss.attackDamage) {
            player.hp = 0;
        } else {
            player.hp = player.hp - bigBoss.attackDamage;
        }

        console.log("Jogador atacou o boss. Boss ficou com HP: %s", bigBoss.hp);
        console.log("Boss atacou o jogador. Jogador ficou com hp: %s\n", player.hp);

        emit AttackComplete(bigBoss.hp, player.hp);
    }

    function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
         // Pega o tokenId do personagem NFT do usuário
        // Se o usuário tiver um tokenId no map, retorne seu personagem
        // Senão, retorne um personagem vazio

        // Pega o tokenId do personagem NFT do usuario
        uint256 userNftTokenId = nftHolders[msg.sender];
        // Se o usuario tiver um tokenId no map, retorne seu personagem
        if (userNftTokenId > 0) {
            return nftHolderAttributes[userNftTokenId];
        }
        // Senão, retorne um personagem vazio
        else {
            CharacterAttributes memory emptyStruct;
            return emptyStruct;
        }
    }

    function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
        return defaultCharacters;
    }

    function getBigBoss() public view returns (BigBoss memory) {
        return bigBoss;
    }

}
