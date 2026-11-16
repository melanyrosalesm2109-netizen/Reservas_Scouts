const fs = require("node:fs");
const path = require("node:path");
const { chromium } = require("../../frontend/node_modules/playwright");

(async () => {
  const raiz = path.resolve(__dirname, "../..");
  fs.mkdirSync(path.join(raiz, "output/pdf"), { recursive: true });
  fs.mkdirSync(path.join(raiz, "tmp/pdf-qa"), { recursive: true });
  const browser = await chromium.launch({ channel: "chrome", headless: true });
  try {
    for (const [nombre, codigo, metodo, monto, referencia] of [
      ["sinpe-ia-demo", "DEMO-CAL-005", "SINPE Movil", "CRC 15 000,00", "DEMO-PDF-SINPE-005"],
      ["transferencia-ia-demo", "DEMO-CAL-002", "Transferencia bancaria", "CRC 25 000,00", "DEMO-PDF-TRANSFER-002"]
    ]) {
      const page = await browser.newPage({ viewport: { width: 816, height: 1056 } });
      const html = '<html><head><meta charset="utf-8"><title>Comprobante ficticio DEMO</title><style>@page{size:letter;margin:0}*{box-sizing:border-box}body{margin:0;font-family:Arial,sans-serif;color:#12384b;background:white}.page{width:8.5in;height:11in;padding:54px;position:relative;overflow:hidden}.header{background:#12384b;color:white;padding:24px;border-bottom:5px solid #d6af62}.brand{font-size:26px;font-weight:bold}.label{letter-spacing:3px;font-size:11px;margin-top:10px}.notice{color:#ac2929;border:2px solid #ac2929;padding:15px;margin:26px 0;font-size:17px;font-weight:bold;text-align:center}h1{font-size:27px;margin:30px 0 10px}p{font-size:14px;line-height:1.7}.amount{padding:22px;background:#e6f2ed;font-size:30px;font-weight:bold;margin:24px 0}table{width:100%;border-collapse:collapse;font-size:14px}td{padding:15px 7px;border-bottom:1px solid #d8dfdf}td:first-child{width:38%;color:#657a86}.footer{position:absolute;bottom:55px;left:54px;right:54px;border-top:2px solid #d6af62;padding-top:18px;font-size:12px;color:#657a86}.watermark{position:absolute;top:560px;left:65px;transform:rotate(-25deg);font-size:57px;font-weight:bold;opacity:.09;color:#a32424;white-space:nowrap;pointer-events:none}</style></head><body><main class="page"><div class="header"><div class="brand">Banco Bosque DEMO</div><div class="label">BANCA FICTICIA PARA PRUEBAS</div></div><div class="notice">DEMO - NO ES UN PAGO REAL</div><h1>Comprobante de '+metodo+'</h1><p>Documento ficticio para explorar la revision de pagos en Reservas Scouts.</p><div class="amount">'+monto+'</div><table><tr><td>Reserva</td><td>'+codigo+'</td></tr><tr><td>Referencia ficticia</td><td>'+referencia+'</td></tr><tr><td>Fecha del ejemplo</td><td>14/11/2026</td></tr><tr><td>Ordenante</td><td>Persona Demo</td></tr><tr><td>Beneficiario</td><td>Reservas Scouts DEMO</td></tr><tr><td>Cuenta de ejemplo</td><td>DEMO-0000</td></tr><tr><td>Estado del ejemplo</td><td>Pendiente de revision</td></tr></table><div class="watermark">COMPROBANTE FICTICIO</div><div class="footer">Generado con asistencia de IA para demostracion del sistema. Sin validez bancaria.<br>No acredita transferencias, depositos ni cobros reales.</div></main></body></html>';
      await page.setContent(html);
      await page.pdf({ path: path.join(raiz, "output/pdf", nombre + ".pdf"), format: "Letter", printBackground: true, margin: { top: 0, bottom: 0, left: 0, right: 0 } });
      await page.screenshot({ path: path.join(raiz, "tmp/pdf-qa", nombre + "-layout.png"), fullPage: true });
      await page.close();
    }
  } finally { await browser.close(); }
})();
