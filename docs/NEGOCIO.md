# Negocio — Sistema Cuentas

Control de dinero que reemplaza un bloc de notas. Multiusuario: cada persona ve solo lo suyo; el
administrador da de alta a otros. El modelo exacto vive en `backend/docs/BD.md`; aquí está el vocabulario.

## Vocabulario
| Término | Significado |
|---|---|
| Pago recurrente | Acuerdo que se repite cada mes en un día fijo: **ingreso** (alguien me paga) o **gasto** (yo pago) |
| Vencimiento | Lo que toca pagar/cobrar de un pago recurrente en un mes concreto; estado derivado (pendiente, parcial, pagado, vencido) |
| Movimiento | La plata real que entró o salió (pago o abono); siempre con categoría y medio de pago |
| Categoría | Clasificación del movimiento; algunas son **capital** (se separa de lo operativo en el resumen) |
| Medio de pago | Nequi, Bancolombia, efectivo… obligatorio en todo movimiento |
| Contacto | Persona o entidad con la que se tiene el acuerdo |
| Finalizar | Cerrar un pago recurrente con fecha y nota («me devolvió el capital»), registrando el capital si aplica |

## Flujos principales
1. **Quién pagó y quién no:** vencimientos del mes con estado; desde cada fila se registra un pago o abono (no puede
   pasar del saldo).
2. **Movimiento rápido:** ingreso o gasto suelto, con categoría y medio de pago.
3. **Resumen del mes:** ingresos, gastos, balance, total por categoría y por medio de pago, capital aparte, por cobrar.
4. **Corregir:** solo lo descriptivo se edita; lo demás se **anula** con motivo (nunca se borra).
5. **Alta de usuarios:** solo el administrador.

## Reglas
- Un pago puede ser parcial; el estado del mes se deriva del servidor.
- Dinero en pesos colombianos completos, como texto desde el backend.
- Día de cobro 29–31 en meses cortos: ver `backend/docs/ESTADO.md` («Pendientes de decidir»).
