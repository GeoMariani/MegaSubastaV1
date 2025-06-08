# 🧾 SubastaA – Contrato Inteligente de Subasta con Extensión de Tiempo

Este contrato Solidity permite realizar una subasta segura y automatizada en la red Ethereum. Está diseñado para gestionar ofertas, registrar múltiples pujas por dirección, extender el tiempo si se recibe una nueva oferta cerca del cierre, y permitir la distribución segura de fondos al finalizar el proceso.

---

## 🚀 Funcionalidades Principales

- **Subasta con tiempo configurable.**
- **Extensión automática**: Si una oferta válida llega en los últimos `N` segundos, el plazo se extiende.
- **Múltiples ofertas** por un mismo usuario.
- **Retiro de fondos** para todos los oferentes no ganadores (menos una comisión).
- **Pago automático al vendedor** al finalizar.
- **Reclamo de saldo restante** por parte del organizador de la subasta.

---

## 🧱 Roles en la Subasta

- `vendedor`: Quien ofrece el objeto en subasta. Recibe el pago del mayor postor.
- `ownerSubasta`: Quien despliega el contrato y administra la subasta.
- `oferenteGanador`: Dirección del mejor postor.

---

## 🧮 Comisión y lógica de retiro

- Se aplica una **comisión del 2%** sobre los retiros de los usuarios no ganadores.
- El oferente ganador **solo puede reclamar sus ofertas menores** a la ganadora, si las hubiera.

---

## ⏱️ Extensión de la Subasta

- Si una nueva oferta válida llega durante los últimos `segundosFinalesAdicionales`, el plazo se **extiende automáticamente** una única vez.
- Se emite el evento `TiempoExtendido` con el nuevo vencimiento.

---

## 🔐 Seguridad y Validaciones

- Validaciones en cada paso: tiempo, permisos, saldos, estado de la subasta.
- Se impide que se reclamen fondos más de una vez o fuera de las condiciones esperadas.

---

## 📤 Eventos Registrados

- `NuevaOferta`: Cada vez que se recibe una oferta válida.
- `TiempoExtendido`: Si el plazo se extiende por una oferta en el último tramo.
- `SubastaTerminada`: Al cerrar oficialmente la subasta.
- `RetiroRealizado`: Cuando un oferente retira sus fondos no ganadores.
- `PagoAlVendedor`: Cuando el vendedor recibe el pago del mayor postor.
- `FondosReclamadosPorOwner`: Cuando el organizador recupera el saldo restante.

---

## 🧪 Uso Básico

1. **Deploy del contrato** pasando:
   - Dirección del vendedor.
   - Dirección del owner.
   - Duración de la subasta (en segundos).
   - Tiempo de extensión si aplica (en segundos).
2. **Ofertar** mediante `realizarOferta()` (enviar ETH).
3. **Finalizar**: `ownerCierraSubasta()` luego del tiempo.
4. **Retirar fondos**: `retirarOfertasNoGanadoras()`, según corresponda.
5. **Pagar al vendedor**: `vendedorReclamaPago()`.
6. **Reclamar saldo restante**: `ownerRetiraFondosRestantes()`.

---

## 🛡️ Recomendaciones

- El contrato no acepta pujas si se cerró o venció el plazo.
- Se prevé que los retiros y pagos no fallen. Si ocurre un error, la transacción revierte.
- La comisión del 2% se queda en el contrato para ser reclamada por el owner.
