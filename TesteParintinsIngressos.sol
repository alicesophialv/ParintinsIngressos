// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contract sem CPF
contract ParintinsIngressos {
    address public owner;

    struct Ingresso {
        uint id;
        string tipo;        // "Passaporte (3 noites)" ou "Avulso"
        string area;        // "Arquibancada Central", "Arquibancada Especial", "Cadeira Tipo 01" e "Cadeira Tipo 02" 
        string tipoPreco;   // "Inteira", "Meia"
        uint8 noite;        // 1, 2, 3 (para avulso)
        string lado;        // "Garantido" ou "Caprichoso"
        address comprador;
    }

    uint public ingressoCount;
    mapping(uint => Ingresso) public ingressos;

    // Preços: mapping tipo => area => tipoPreco => preco
    mapping(string => mapping(string => mapping(string => uint))) public precos;

    event IngressoVendido(
        uint id,
        string tipo,
        string area,
        string tipoPreco,
        uint8 noite,
        string lado,
        address comprador
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Somente o dono pode executar");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Definir preço para tipo, area e tipoPreco
    function setPreco(string memory _tipo, string memory _area, string memory _tipoPreco, uint _valor) public onlyOwner {
        precos[_tipo][_area][_tipoPreco] = _valor;
    }

    // Comprar passaporte (3 noites)
    function comprarPassaporte(string memory _area, string memory _tipoPreco, string memory _lado) public payable {
        string memory tipo = "Passaporte";
        uint preco = precos[tipo][_area][_tipoPreco];
        require(preco > 0, "Preco nao configurado");
        require(msg.value >= preco, "Valor insuficiente");

        ingressoCount++;
        ingressos[ingressoCount] = Ingresso({
            id: ingressoCount,
            tipo: tipo,
            area: _area,
            tipoPreco: _tipoPreco,
            noite: 0,
            lado: _lado,
            comprador: msg.sender
        });

        emit IngressoVendido(ingressoCount, tipo, _area, _tipoPreco, 0, _lado, msg.sender);
    }

    // Comprar ingresso avulso (1 noite)
    function comprarAvulso(string memory _area, string memory _tipoPreco, uint8 _noite, string memory _lado) public payable {
        require(_noite >= 1 && _noite <= 3, "Noite invalida");
        string memory tipo = "Avulso";
        uint preco = precos[tipo][_area][_tipoPreco];
        require(preco > 0, "Preco nao configurado");
        require(msg.value >= preco, "Valor insuficiente");

        ingressoCount++;
        ingressos[ingressoCount] = Ingresso({
            id: ingressoCount,
            tipo: tipo,
            area: _area,
            tipoPreco: _tipoPreco,
            noite: _noite,
            lado: _lado,
            comprador: msg.sender
        });

        emit IngressoVendido(ingressoCount, tipo, _area, _tipoPreco, _noite, _lado, msg.sender);
    }

    // Listar ingressos vendidos
    function listarIngressos() public view returns (Ingresso[] memory) {
        Ingresso[] memory todos = new Ingresso[](ingressoCount);
        for (uint i = 1; i <= ingressoCount; i++) {
            todos[i - 1] = ingressos[i];
        }
        return todos;
    }

    // Listar ingressos disponíveis para venda (tipo, area, tipoPreco e preço)
    function listarIngressosDisponiveis() public view returns (
        string[] memory tipos,
        string[] memory areas,
        string[] memory tiposPreco,
        uint[] memory valores
    ) {
        // Para simplificar, vamos definir arrays fixos das opções válidas,
        // pois com string mapping não conseguimos iterar direto.

        // Listas fixas de tipos, areas e tiposPreco (exemplo):
        string[2] memory tiposFixos = ["Passaporte", "Avulso"];
        string[4] memory areasFixas = ["Arquibancada Central", "Arquibancada Especial", "Cadeira Tipo 01", "Cadeira Tipo 02"];
        string[2] memory tiposPrecoFixos = ["Inteira", "Meia"];

        // Calcular quantos preços configurados para dimensionar arrays de retorno
        uint count = 0;
        for (uint t = 0; t < tiposFixos.length; t++) {
            for (uint a = 0; a < areasFixas.length; a++) {
                for (uint p = 0; p < tiposPrecoFixos.length; p++) {
                    if (precos[tiposFixos[t]][areasFixas[a]][tiposPrecoFixos[p]] > 0) {
                        count++;
                    }
                }
            }
        }

        tipos = new string[](count);
        areas = new string[](count);
        tiposPreco = new string[](count);
        valores = new uint[](count);

        uint index = 0;
        for (uint t = 0; t < tiposFixos.length; t++) {
            for (uint a = 0; a < areasFixas.length; a++) {
                for (uint p = 0; p < tiposPrecoFixos.length; p++) {
                    uint val = precos[tiposFixos[t]][areasFixas[a]][tiposPrecoFixos[p]];
                    if (val > 0) {
                        tipos[index] = tiposFixos[t];
                        areas[index] = areasFixas[a];
                        tiposPreco[index] = tiposPrecoFixos[p];
                        valores[index] = val;
                        index++;
                    }
                }
            }
        }
    }

    // Sacar saldo do contrato
    function sacar() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
