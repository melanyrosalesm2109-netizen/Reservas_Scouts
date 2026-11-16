# Genera comprobantes PNG ficticios solo para reservas con codigo DEMO-.
param([string]$Servidor = 'localhost', [switch]$SoloRevision)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Data
$conexion = New-Object System.Data.SqlClient.SqlConnection("Server=$Servidor;Database=reservasScouts;Integrated Security=True;Encrypt=False;TrustServerCertificate=True")
$conexion.Open()
try {
    $opciones = $conexion.CreateCommand()
    $opciones.CommandText = 'SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON; SET ANSI_PADDING ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;'
    [void]$opciones.ExecuteNonQuery()
    $consulta = $conexion.CreateCommand()
    $consulta.CommandText = @'
SELECT p.id,r.codigo,p.metodo,p.monto,p.estado
FROM dbo.pagos p JOIN dbo.reservas r ON r.id=p.reservaId
WHERE r.codigo LIKE N'DEMO-%'
AND p.metodo IN(N'SINPE M' + NCHAR(243) + N'vil',N'Transferencia bancaria')
AND NOT EXISTS(SELECT 1 FROM dbo.pagoComprobantes c WHERE c.pagoId=p.id)
ORDER BY p.id
'@
    if ($SoloRevision) {
        $consulta.CommandText = $consulta.CommandText.Replace("r.codigo LIKE N'DEMO-%'", "r.codigo LIKE N'DEMO-COMP-%'")
    }
    $tabla = New-Object System.Data.DataTable
    $lector = $consulta.ExecuteReader()
    $tabla.Load($lector)
    $lector.Close()
    $cantidad = 0
    foreach ($pago in $tabla.Rows) {
        $imagen = New-Object System.Drawing.Bitmap(900,560)
        $grafico = [System.Drawing.Graphics]::FromImage($imagen)
        $grafico.Clear([System.Drawing.Color]::White)
        $grafico.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $esSinpe = $pago.metodo.StartsWith('SINPE')
        $colorCabecera = if ($esSinpe) { [System.Drawing.Color]::FromArgb(25,94,76) } else { [System.Drawing.Color]::FromArgb(18,56,75) }
        $azul = New-Object System.Drawing.SolidBrush($colorCabecera)
        $gris = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70,80,85))
        $rojo = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150,45,40))
        $titulo = New-Object System.Drawing.Font('Arial',22,[System.Drawing.FontStyle]::Bold)
        $fuente = New-Object System.Drawing.Font('Arial',16)
        $aviso = New-Object System.Drawing.Font('Arial',18,[System.Drawing.FontStyle]::Bold)
        try {
            $grafico.FillRectangle($azul,0,0,900,110)
            $grafico.DrawString('COMPROBANTE DE DEMOSTRACION',$titulo,[System.Drawing.Brushes]::White,35,35)
            $grafico.DrawString('NO REPRESENTA UN PAGO REAL',$aviso,$rojo,35,135)
            $montoIlustrativo = [decimal]$pago.monto
            if ($pago.codigo -like 'DEMO-COMP-*-R') { $montoIlustrativo += 1000 }
            $lineas = @(
                ('Reserva: ' + $pago.codigo),
                ('Referencia ficticia: DEMO-COMP-' + $pago.id),
                ('Metodo: ' + $pago.metodo),
                ('Monto ilustrativo: CRC ' + $montoIlustrativo.ToString('N2',[System.Globalization.CultureInfo]::InvariantCulture)),
                ('Canal ficticio: ' + $(if ($esSinpe) { 'SINPE MOVIL - DEMO' } else { 'TRANSFERENCIA BANCARIA - DEMO' }))
            )
            $y = 195
            foreach ($linea in $lineas) {
                $grafico.DrawString($linea,$fuente,$gris,35,$y)
                $y += 45
            }
            $grafico.DrawString('Archivo ficticio para probar la revision de comprobantes.',$fuente,$azul,35,450)
            $grafico.DrawString('No es un documento emitido por un banco.',$fuente,$azul,35,490)
            $flujo = New-Object System.IO.MemoryStream
            try {
                $imagen.Save($flujo,[System.Drawing.Imaging.ImageFormat]::Png)
                $contenido = $flujo.ToArray()
                $transaccion = $conexion.BeginTransaction()
                try {
                    $guardar = $conexion.CreateCommand()
                    $guardar.Transaction = $transaccion
                    $guardar.CommandText = 'EXEC dbo.paComprobanteGuardar @pagoId,@nombre,@tipo,@contenido; UPDATE dbo.pagos SET comprobante=N''Comprobante adjunto'',updatedAt=SYSDATETIME() WHERE id=@pagoId;'
                    [void]$guardar.Parameters.Add('@pagoId',[System.Data.SqlDbType]::Int)
                    $guardar.Parameters['@pagoId'].Value = [int]$pago.id
                    [void]$guardar.Parameters.Add('@nombre',[System.Data.SqlDbType]::NVarChar,200)
                    $guardar.Parameters['@nombre'].Value = 'DEMO-' + $pago.codigo + '.png'
                    [void]$guardar.Parameters.Add('@tipo',[System.Data.SqlDbType]::NVarChar,60)
                    $guardar.Parameters['@tipo'].Value = 'image/png'
                    [void]$guardar.Parameters.Add('@contenido',[System.Data.SqlDbType]::VarBinary,-1)
                    $guardar.Parameters['@contenido'].Value = $contenido
                    [void]$guardar.ExecuteNonQuery()
                    $transaccion.Commit()
                } catch { $transaccion.Rollback(); throw }
                if ($cantidad -eq 0) {
                    $vista = Join-Path $PSScriptRoot '..\..\tmp\demo_comprobantes'
                    [void](New-Item -ItemType Directory -Force -Path $vista)
                    [System.IO.File]::WriteAllBytes((Join-Path $vista 'comprobante_demo.png'),$contenido)
                }
                $cantidad++
            } finally { $flujo.Dispose() }
        } finally {
            $titulo.Dispose(); $fuente.Dispose(); $aviso.Dispose()
            $azul.Dispose(); $gris.Dispose(); $rojo.Dispose()
            $grafico.Dispose(); $imagen.Dispose()
        }
    }
    Write-Output "Comprobantes ficticios agregados: $cantidad"
} finally { $conexion.Close(); $conexion.Dispose() }
