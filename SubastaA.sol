// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract SubastaA {

    uint256 expires;
    address public vendedor; //recibirá el monto que ganó la subasta, puede ser por Boton "CobrarTopeSubasta"
    address public ownerSubasta; //puede reclamar los fondos que queden en el contrato al final de todo el proceso para que no se pierdan
    //Cada oferta se guarda en una estructura que almacena la tupla ddress de usuario y monto ofertado
    //Admite que un mismo usuario haga varias ofertas
    struct Oferta {
        address usuario;
        uint256 monto;
    }
    //Array de todas las ofertas
    Oferta[] public listaDeOfertas;
    bool public subastaCerrada;//inicia en False
    bool public pagadoAlVendedor; //para no pagar mas de una vez al Vendedor
    //Oferta Maxima
    address public oferenteGanador; 
    uint256 public ofertaGanadora;
    //Otro dato relacionado a la oferta maxima es su 10% superador, como nueva oferta minima aceptable 
    uint256 public sugerenciaOfertaMinima;
    //uint256 public valorTemporal;

    //Eventos a registrar
    event NuevaOferta(address indexed usuario, uint256 monto);
    event SubastaTerminada(address ganador, uint256 monto);
    event RetiroRealizado(address indexed usuario, uint256 monto);
    event PagoAlVendedor(address vendedor, uint256 monto);
 
    constructor(address _vendedor, uint256 duration,address _ownerSubasta) {
        vendedor = _vendedor;
        expires = block.timestamp + duration;
        ownerSubasta = _ownerSubasta;
    }

   //Acepta el dinero de las oferentes
    function realizarOferta() external payable {
        // Bajo ciertas condiciones
        // Monto de oferta mayor a cero
        require(msg.value>0,"El numero debe ser mayor a cero");
        // Montos de oferta mayor o igual a sugerenciaOfertaMinima
        require(msg.value>=sugerenciaOfertaMinima,"Su oferta no supera en medida suficiente a la Mejor Oferta hasta el momento");
        // No aceptar ofertas una vez cumplido el plazo
        require(block.timestamp <= expires, "El plazo de la subasta ha expirado");
        // No permito ofertas una vez finaliza la subasta
        require(!subastaCerrada,"La subasta ya ha cerrado");

        // Registrar la nueva oferta
        listaDeOfertas.push(Oferta({
        usuario: msg.sender,  
        monto: msg.value
        }));
        
        // Si es la mayor oferta, actualizar el máximo
        if (msg.value > ofertaGanadora) {
                ofertaGanadora = msg.value;
                oferenteGanador = msg.sender;
                sugerenciaOfertaMinima = ofertaGanadora + (ofertaGanadora / 20); // Proxima ganadora deberá superar a mayorOferta en 5%

        }

        //Registrar evento por oferta nueva
        emit NuevaOferta(msg.sender, msg.value);

    }

    //Ver todas las ofertas registradas hasta el momento
    function verTodasLasOfertas() public view returns (Oferta[] memory) {
       return listaDeOfertas;   
    }
    
    // En cada momento que querramos podemos ver cuanto tiempo le queda a la Subasta
    function verTiempoRestante() external view returns (uint256 secondsLeft) {
        if (subastaCerrada) {
            return 0;
        }
        //uint256 endTime = startTime + duration;
        if (block.timestamp >= expires) {
            return 0;
        }
        return expires - block.timestamp;
    }

    // Reclamar devolución de Ofertas no ganadoras
    function retirarOfertasNoGanadoras() public {
        //require(subastaCerrada, "La subasta debe estar cerrada");
        //require(msg.sender != maximoOfertante, "El ganador no puede retirar");

        uint256 montoARetirar = 0;
        //Retiro de montos ofertados para las oferentes no ganadores
        if (msg.sender!=oferenteGanador) {

            //sumamos todas las ofertas efectuadas por el msg.sender que retira
            for (uint256 i = 0; i < listaDeOfertas.length; i++) {
                if (listaDeOfertas[i].usuario == msg.sender) {
                    montoARetirar += listaDeOfertas[i].monto;
                    // Evitamos doble retiro: ponemos en cero la oferta ya contabilizada
                    listaDeOfertas[i].monto = 0;
                }
            }

            require(montoARetirar > 0, "No tenes fondos para retirar");

            //payable(msg.sender).transfer(montoARetirar);
            bool exito = payable(msg.sender).send(montoARetirar);
            require(exito, "Error al enviar el retiro");

            emit RetiroRealizado(msg.sender, montoARetirar);
        
        } else {
            //Caso: Si retira el oferenteGanador debemos permitirle retirar ofertas menores a la ganadora si existieran
            //sumamos todas las ofertas efectuadas por el msg.sender menos la ofertaGanadora
            for (uint256 i = 0; i < listaDeOfertas.length; i++) {
                if (listaDeOfertas[i].usuario == msg.sender && listaDeOfertas[i].monto < ofertaGanadora)  {
                    montoARetirar += listaDeOfertas[i].monto;
                    // Evitamos doble retiro: ponemos en cero la oferta ya contabilizada
                    listaDeOfertas[i].monto = 0;
                }
            }

            require(montoARetirar > 0, "No tenes fondos para retirar");

            //payable(msg.sender).transfer(montoARetirar);
            bool exito = payable(msg.sender).send(montoARetirar);
            require(exito, "Error al enviar el retiro");

            emit RetiroRealizado(msg.sender, montoARetirar);
        }    
    }

    // Cerrar Subasta 
    // Solo el ownerSubasta
    function cerrarSubasta() public {
        require(block.timestamp >= expires, "La subasta aun no ha expirado");
        require(!subastaCerrada, "La subasta ya fue cerrada");
        require(msg.sender==ownerSubasta,"Solo propietario de la subasta no puede cerrar la misma");

        subastaCerrada = true;

        emit SubastaTerminada(oferenteGanador, ofertaGanadora);
    }

    function vendedorReclamaPago() public {
        require(subastaCerrada, "La subasta aun no ha sido cerrada");
        require(!pagadoAlVendedor, "El vendedor ya recibio el pago");
        require(ofertaGanadora > 0, "No hubo ofertas");
        require(msg.sender==vendedor,"Solo el vendedor peude solicitar el monto maximo de la subasta");

        (bool exito, ) = payable(vendedor).call{value: ofertaGanadora}("");
        require(exito, "No se pudo pagar al vendedor");

        pagadoAlVendedor = true;
        
        emit PagoAlVendedor(vendedor, ofertaGanadora);
    }

}