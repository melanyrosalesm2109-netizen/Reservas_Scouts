import { useEffect, useMemo, useState } from "react";
import { bloquearHorario, liberarHorario, consultarPoliticaPago } from "../services/reservaPagoService";
import { fechaPlazoPago } from "../services/pagoGestionService";
import "./PagoReserva.css";

export default function PagoReserva({ espacio, inicio, fin, disponible, procesando, onCambio }) {
  const [bloqueo, setBloqueo] = useState(null);
  const [error, setError] = useState("");
  const [ahora, setAhora] = useState(Date.now);
  const [intento, setIntento] = useState(0);
  const [metodo, setMetodo] = useState("");
  const [archivo, setArchivo] = useState(null);
  const [politica, setPolitica] = useState(null);
  useEffect(() => {
    let vigente = true;
    consultarPoliticaPago().then(datos => { if (vigente && Number.isFinite(datos?.efectivoGraciaMinutos)) setPolitica(datos); }).catch(() => {});
    return () => { vigente = false; };
  }, []);
  const limite = politica && inicio && fin ? Math.min(Date.parse(`${inicio}-06:00`) + politica.efectivoGraciaMinutos * 60000, Date.parse(`${fin}-06:00`)) : NaN;
  const [errorArchivo, setErrorArchivo] = useState("");
  const [tarjeta, setTarjeta] = useState({ numero: "", titular: "", vencimiento: "", cvv: "" });
  const rango = `${espacio?.id || ""}|${inicio}|${fin}`;
  const listo = Boolean(espacio && disponible && inicio && fin && new Date(fin) > new Date(inicio));

  useEffect(() => {
    let vigente = true;
    let token;
    const timer = setTimeout(async () => {
      setBloqueo(null); setError("");
      if (!listo) return;
      try {
        const datos = await bloquearHorario({ espacioId: espacio.id, fechaInicio: inicio, fechaFin: fin });
        token = datos.token;
        if (!vigente) { await liberarHorario(token); return; }
        const venceLocal = Date.now() + (Date.parse(datos.vence) - Date.parse(datos.ahora));
        setAhora(Date.now());
        setBloqueo({ ...datos, rango, venceLocal });
      } catch (err) { if (vigente) setError(err.message); }
    }, 400);
    return () => { vigente = false; clearTimeout(timer); if (token) void liberarHorario(token).catch(() => {}); };
  }, [espacio?.id, inicio, fin, listo, rango, intento]);

  useEffect(() => {
    const timer = setInterval(() => setAhora(Date.now()), 250);
    return () => clearInterval(timer);
  }, []);

  const segundos = bloqueo?.rango === rango ? Math.max(0, Math.ceil((bloqueo.venceLocal - ahora) / 1000)) : 0;
  const transferencia = metodo === "SINPE Móvil" || metodo === "Transferencia bancaria";
  const pagoListo = Boolean(metodo && (!transferencia || archivo) && (metodo !== "Tarjeta" ||
    (tarjeta.numero && tarjeta.titular.trim() && tarjeta.vencimiento && tarjeta.cvv)));
  const datos = useMemo(() => ({ token: bloqueo?.token, rango, metodo, archivo, tarjeta,
    valido: Boolean(listo && bloqueo?.rango === rango && segundos > 0 && pagoListo) }),
    [bloqueo, rango, metodo, archivo, tarjeta, listo, segundos, pagoListo]);
  useEffect(() => { onCambio(datos); }, [datos, onCambio]);

  const cambiarTarjeta = event => setTarjeta(anterior => ({ ...anterior, [event.target.name]: event.target.value }));
  return <section className="pago-reserva" aria-label="Pago de la reserva">
    <h3>Pago de la reserva</h3>
    <p className="pago-reserva-total">Total: {Number(espacio?.costo || 0).toLocaleString("es-CR", { style: "currency", currency: "CRC" })}</p>
    {!listo ? <p>Selecciona un espacio y fechas disponibles para iniciar el plazo de dos minutos.</p> : error ?
      <div role="alert"><p>{error}</p><button type="button" onClick={() => setIntento(i => i + 1)}>Intentar de nuevo</button></div> : !bloqueo || bloqueo.rango !== rango ?
      <p role="status">Apartando tu horario…</p> : segundos > 0 ?
      <p className="pago-reserva-reloj" role="timer">Horario apartado para ti: {Math.floor(segundos / 60)}:{String(segundos % 60).padStart(2, "0")} restantes</p> :
      <div role="alert"><p>El plazo terminó. El horario quedó libre para otros usuarios.</p><button type="button" onClick={() => setIntento(i => i + 1)}>Volver a consultar y apartar</button></div>}
    <fieldset disabled={procesando || !listo || segundos <= 0 || Boolean(error)}>
      <label htmlFor="reserva-metodo">Método de pago <span className="required-mark" aria-hidden="true">*</span></label>
      <select id="reserva-metodo" value={metodo} required onChange={e => { setMetodo(e.target.value); setArchivo(null); setErrorArchivo(""); setTarjeta({ numero: "", titular: "", vencimiento: "", cvv: "" }); }}>
        <option value="">Selecciona un método</option>
        {["SINPE Móvil", "Transferencia bancaria", "Tarjeta", "Efectivo"].map(m => <option key={m}>{m}</option>)}
      </select>
      {transferencia && <div className="pago-reserva-adjunto">
        <p>Adjunta el comprobante. El pago y la reserva quedarán pendientes hasta que recepción o administración lo revise.</p>
        <label htmlFor="reserva-comprobante">Comprobante PDF, PNG o JPG (máximo 5 MB) <span className="required-mark" aria-hidden="true">*</span></label>
        <input key={metodo} id="reserva-comprobante" type="file" accept="application/pdf,image/png,image/jpeg" required onChange={e => {
          const file = e.target.files[0]; setArchivo(null); setErrorArchivo("");
          if (file && (file.size > 5 * 1024 * 1024 || !["application/pdf", "image/png", "image/jpeg"].includes(file.type))) {
            setErrorArchivo("Selecciona un PDF, PNG o JPG de hasta 5 MB."); e.target.value = ""; return;
          }
          setArchivo(file || null);
        }} />
        {errorArchivo && <p role="alert">{errorArchivo}</p>}
      </div>}
      {metodo === "Efectivo" && <p>Tu cupo quedará guardado y la reserva pendiente de pago. Se aprobará al confirmar el efectivo recibido. {Number.isFinite(limite) ? `Puedes pagar hasta el ${fechaPlazoPago(new Date(limite).toISOString())}.` : "Consulta el plazo de pago en Mis reservas."} Al vencer sin pago se libera el cupo.</p>}
      {metodo === "Tarjeta" && <div>
        <p>Simulación sin cobro real. Usa 4242 4242 4242 4242, código 123 y un vencimiento vigente. Otros números se rechazan. No ingreses datos de una tarjeta real.</p>
        <div className="pago-tarjeta-grid">
          <label>Número de prueba <span className="required-mark" aria-hidden="true">*</span><input name="numero" inputMode="numeric" autoComplete="off" maxLength={19} required value={tarjeta.numero} onChange={cambiarTarjeta} /></label>
          <label>Titular de prueba <span className="required-mark" aria-hidden="true">*</span><input name="titular" autoComplete="off" maxLength={100} required value={tarjeta.titular} onChange={cambiarTarjeta} /></label>
          <label>Vencimiento <span className="required-mark" aria-hidden="true">*</span><input type="month" name="vencimiento" required value={tarjeta.vencimiento} onChange={cambiarTarjeta} /></label>
          <label>Código de prueba <span className="required-mark" aria-hidden="true">*</span><input name="cvv" type="password" autoComplete="off" maxLength={3} required value={tarjeta.cvv} onChange={cambiarTarjeta} /></label>
        </div>
      </div>}
    </fieldset>
  </section>;
}
