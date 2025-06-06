// SPDX-License-Identifier: GPL-3.0
// Al final casi la totalidad de la Oferta ganadore va a ir al vendedor
// La duracion podria ser ingresada por parámetro

pragma solidity >=0.8.2 <0.9.0;

contract MegaSubasta {
    uint256 expires;
    address vendedor;
    mapping(address => uint) ofertas;
   // bool subastaClosed;
    address maximoOfertante; 
    uint256 ofertaMinima;
    uint256 mayorOferta;
    event DevolucionConComision(
        address indexed reclamante,
        uint256 montoDevuelto,
        uint256 comisionRetenida,
        string mensaje
    );

    bool SubastaOpen = false; // Estado inicial: cerrado

    constructor(address _vendedor, uint256 duration) {
        vendedor = _vendedor;
        expires = block.timestamp + duration;
        SubastaOpen = true;
        // Para la primera oferta el maximoOfertante es el vendedor y la oferta mínima no tiene importancia
        maximoOfertante = vendedor;
        ofertaMinima = 0;
    }


    function ofertar() external payable {
        // Aceptar la oferta bajo ciertas condiciones
        
        require(SubastaOpen, "La subasta no se encuentra abierta.");
        require(block.timestamp <= expires, "El plazo de la subasta ha expirado");
        require(msg.value > 0, "Must send ETH to donate");
        
        // No se permite que el actual maximoOfertante vuelva a ofertar
        require(msg.sender != maximoOfertante, "Usted ya es el maximo ofertante.");
        
        // Acumula el monto donado por el msg.sender pero sólo si vale la pena
        // es decir si la nueva oferta superará en un 10% a la maxima registrada
        uint256 ofertaAnterior = ofertas[msg.sender];
        uint256 ofertaTotal = ofertaAnterior + msg.value;
        
         require(ofertaTotal > ofertaMinima, "El monto a donar debe superar en un 10% a la mejor Oferta registrada hasta el momento"); // Validar el monto de la donación
        
        // Actualiza la oferta acumulada
        ofertas[msg.sender] = ofertaTotal;

        // Si es la mayor oferta, actualizar el máximo
        if (ofertaTotal > mayorOferta) {
                mayorOferta = ofertaTotal;
                maximoOfertante = msg.sender;
                ofertaMinima = mayorOferta + (mayorOferta / 10); // 10% más

        }
    }

    function ConocerOfertaDeLaCuenta(address ofertante) external view returns (uint256) {
        return ofertas[ofertante];
    }

    // En cada momento que querramos podemos ver cuanto tiempo le queda a la MegaSubasta
    function getTimeRemaining() external view returns (uint256 secondsLeft) {
        if (!SubastaOpen) {
            return 0;
        }
        //uint256 endTime = startTime + duration;
        if (block.timestamp >= expires) {
            return 0;
        }
        return expires - block.timestamp;
    }

    // En cada momento que querramos podemos ver Maximos ofertante y oferta
    function verMaximaOferta() external view returns (address, uint256) {
    return (maximoOfertante, mayorOferta);
    }
    
    // Queremos conocer balance del contrato
    function VerSaldoContrato() external view returns (uint256) {
    return address(this).balance;
    }
    
    function cerrarSubasta() external {
        require(block.timestamp >= expires, "La subasta no se encuentra abierta.");
         // La subasta ya ha finalizado pero podemos cerrarlo si queramos
          SubastaOpen = false; 
    }
    
    // voy a implementar una función para que cada ofertante peuda reclamar la devolucion de su oferta 
    // (ya que me encontré que el contrato como 'sender' no tiene gas suficiente para devolver todos los importes)
    function reclamarDevolucion() external {
        // EL maximo Ofertante (ganador) no pude reclamar devolucion
        require(msg.sender != maximoOfertante, "Eres el ganador de la Subasta, no puedes reclamarlo");
        // Solo puede reclamar una vez cerrada la Subasta 
        require(!SubastaOpen, "La subasta aun se encuentra abierta.");
        
        uint256 monto = ofertas[msg.sender];
        require(monto > 0, "No hay fondos para devolverte");

        uint256 comision = (monto * 2) / 100;
        uint256 aDevolver = monto - comision;

        (bool enviado, ) = msg.sender.call{value: aDevolver}("");
        require(enviado, "Fallo la devolucion");
        // Marcar como devuelto si pudo devolverlo
        ofertas[msg.sender] = 0;

        // Emitir evento para informar la devolución con comisión
        emit DevolucionConComision(
            msg.sender,
            aDevolver,
            comision,
            "Se retuvo el 2% de comision por gastos de subasta"
        );

    }
}