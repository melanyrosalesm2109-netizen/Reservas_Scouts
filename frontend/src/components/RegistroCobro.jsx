import { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import { cobrosDisponibles, moneda, registrarCobro } from "../services/pagoGestionService";

export default function RegistroCobro({ onCerrar, onRegistrado }) {
  const dialogo = useRef(null);
  const [reservas, setReservas] = useState([]);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");
  const [guardando, setGuardando] = useState(false);
  const [reservaId, setReservaId] = useState("");
  const [metodo, setMetodo] = useState("");
  const [archivo, setArchivo] = useState(null);
  const [tarjeta, setTarjeta] = useState({ numero: "", titular: "", vencimiento: "", cvv: "" });
  useEffect(() => {
    dialogo.current.showModal(); let vigente = true;
    cobrosDisponibles().then(datos => { if (vigente) setReservas(datos); }).catch(err => { if (vigente) setError(err.message); })
      .finally(() => { if (vigente) setCargando(false); });
    return () => { vigente = false; };
  }, []);
  const seleccion = reservas.find(r => r.reservaId === Number(reservaId));
  const transferencia = ["SINPE Móvil", "Transferencia bancaria"].includes(metodo);
  async function enviar(event) {
    event.preventDefault(); if (guardando || !seleccion) return;
    setGuardando(true); setError("");
    try {
      const pago = await registrarCobro({ reservaId: Number(reservaId), metodo, tarjeta: metodo === "Tarjeta" ? tarjeta : null }, archivo);
      onRegistrado(pago);
    } catch (err) { setError(err.message); }
    finally { setGuardando(false); }
  }
  return <dialog ref={dialogo} className="pago-gestion-dialog" aria-labelledby="registro-titulo" onCancel={e => { e.preventDefault(); if (!guardando) onCerrar(); }}>
    <header><div><h2 id="registro-titulo">Registrar cobro</h2><p>Solo reservas con saldo y sin otro pago pendiente.</p></div><button type="button" disabled={guardando} onClick={onCerrar} aria-label="Cerrar registro">×</button></header>
    <form onSubmit={enviar}>
      {error && <p className="mensaje-error" role="alert">{error}</p>}
      {cargando ? <p role="status">Consultando saldos…</p> : reservas.length === 0 ? <div className="cobro-vacio"><h3>No hay saldos disponibles para un nuevo cobro</h3>
        <p>Las reservas ya están cubiertas o tienen un pago pendiente. Atiende esos pagos desde su acción correspondiente para no duplicarlos.</p>
        <Link to="/notificaciones" onClick={onCerrar}>Ir a notificaciones</Link></div> : <fieldset disabled={guardando}>
        <label htmlFor="cobro-reserva">Reserva con saldo *</label><select id="cobro-reserva" required value={reservaId} onChange={e => setReservaId(e.target.value)}>
          <option value="">Selecciona una reserva</option>{reservas.map(r => <option key={r.reservaId} value={r.reservaId}>{r.codigo} · {r.solicitante} · Saldo {moneda(r.saldo)}</option>)}
        </select>
        <label htmlFor="cobro-monto">Saldo por registrar</label><input id="cobro-monto" value={seleccion ? moneda(seleccion.saldo) : ""} readOnly />
        <p className="pago-ayuda">El servidor calcula el saldo y vuelve a comprobarlo al guardar.</p>
        <label htmlFor="cobro-metodo">Método *</label><select id="cobro-metodo" value={metodo} required onChange={e => { setMetodo(e.target.value); setArchivo(null); }}>
          <option value="">Selecciona un método</option>{["Efectivo", "SINPE Móvil", "Transferencia bancaria", "Tarjeta"].map(m => <option key={m}>{m}</option>)}
        </select>
        {metodo === "Efectivo" && <p>El cupo queda guardado y la reserva pendiente de pago. Se aprobará cuando registres el dinero recibido; si vence el plazo sin pago se liberará el cupo.</p>}
        {transferencia && <><label htmlFor="cobro-archivo">Comprobante PDF, PNG o JPG (hasta 5 MB) *</label>
          <input id="cobro-archivo" key={metodo} type="file" accept="application/pdf,image/png,image/jpeg" required onChange={e => {
            const file = e.target.files[0]; setArchivo(null);
            if (file && (file.size > 5242880 || !["application/pdf", "image/png", "image/jpeg"].includes(file.type))) { setError("Adjunta un PDF, PNG o JPG de hasta 5 MB."); e.target.value = ""; return; }
            setError(""); setArchivo(file || null);
          }} /><p>El pago quedará pendiente de revisión.</p></>}
        {metodo === "Tarjeta" && <><p>Solo simulación: 4242 4242 4242 4242, código 123 y vencimiento vigente. Sin cobro real.</p>
          {[['numero', 'Número de prueba', 'text'], ['titular', 'Titular de prueba', 'text'], ['vencimiento', 'Vencimiento', 'month'], ['cvv', 'Código de prueba', 'password']].map(([name, label, type]) => <label key={name}>{label} *<input type={type} name={name} value={tarjeta[name]} autoComplete="off" required maxLength={name === "numero" ? 19 : name === "cvv" ? 3 : 100} onChange={e => setTarjeta(t => ({ ...t, [name]: e.target.value }))} /></label>)}</>}
      </fieldset>}
      <footer><button type="button" disabled={guardando} onClick={onCerrar}>Cancelar</button>{reservas.length > 0 && <button type="submit" className="pago-principal" disabled={guardando || !seleccion || !metodo || (transferencia && !archivo)}>{guardando ? "Guardando…" : "Registrar cobro"}</button>}</footer>
    </form>
  </dialog>;
}
