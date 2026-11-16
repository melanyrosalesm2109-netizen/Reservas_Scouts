param([string]$Servidor = 'localhost')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Data
$raiz=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$archivos=@(
    @{ Codigo='DEMO-FLUJO-002'; Archivo='output\comprobantes-demo\sinpe-ia-demo.png'; Tipo='image/png'; Monto=25000 },
    @{ Codigo='DEMO-FLUJO-003'; Archivo='output\comprobantes-demo\transferencia-ia-demo.png'; Tipo='image/png'; Monto=15000 },
    @{ Codigo='DEMO-CAL-005'; Archivo='output\pdf\sinpe-ia-demo.pdf'; Tipo='application/pdf'; Monto=15000 },
    @{ Codigo='DEMO-CAL-002'; Archivo='output\pdf\transferencia-ia-demo.pdf'; Tipo='application/pdf'; Monto=25000 }
)
$conexion=New-Object System.Data.SqlClient.SqlConnection("Server=$Servidor;Database=reservasScouts;Integrated Security=True;Encrypt=False;TrustServerCertificate=True")
$conexion.Open()
$transaccion=$conexion.BeginTransaction()
try {
    foreach($archivo in $archivos) {
        $ruta=Join-Path $raiz $archivo.Archivo
        $contenido=[System.IO.File]::ReadAllBytes($ruta)
        if($contenido.Length -gt 5*1024*1024) { throw 'El archivo supera 5 MB.' }
        $comando=$conexion.CreateCommand()
        $comando.Transaction=$transaccion
        $comando.CommandText=@'
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
SET ANSI_PADDING ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
DECLARE @id INT;
SELECT @id=p.id FROM dbo.pagos p JOIN dbo.reservas r ON r.id=p.reservaId
WHERE r.codigo=@codigo AND p.monto=@monto AND p.metodo IN(N'Transferencia bancaria',N'SINPE M'+NCHAR(243)+N'vil');
IF @id IS NULL THROW 51200,'No se encontro el pago DEMO esperado.',1;
IF EXISTS(SELECT 1 FROM dbo.pagoComprobantes WHERE pagoId=@id)
    UPDATE dbo.pagoComprobantes SET nombre=@nombre,tipo=@tipo,contenido=@contenido WHERE pagoId=@id;
ELSE EXEC dbo.paComprobanteGuardar @id,@nombre,@tipo,@contenido;
UPDATE dbo.pagos SET comprobante=N'Comprobante adjunto',updatedAt=SYSDATETIME() WHERE id=@id;
'@
        [void]$comando.Parameters.Add('@codigo',[System.Data.SqlDbType]::NVarChar,20)
        $comando.Parameters['@codigo'].Value=$archivo.Codigo
        [void]$comando.Parameters.Add('@monto',[System.Data.SqlDbType]::Decimal)
        $comando.Parameters['@monto'].Value=[decimal]$archivo.Monto
        [void]$comando.Parameters.Add('@nombre',[System.Data.SqlDbType]::NVarChar,200)
        $comando.Parameters['@nombre'].Value=[System.IO.Path]::GetFileName($ruta)
        [void]$comando.Parameters.Add('@tipo',[System.Data.SqlDbType]::NVarChar,60)
        $comando.Parameters['@tipo'].Value=$archivo.Tipo
        [void]$comando.Parameters.Add('@contenido',[System.Data.SqlDbType]::VarBinary,-1)
        $comando.Parameters['@contenido'].Value=$contenido
        [void]$comando.ExecuteNonQuery()
    }
    $transaccion.Commit()
    Write-Output 'Adjuntos actualizados: dos imagenes IA y dos PDF ficticios.'
} catch { $transaccion.Rollback(); throw }
finally { $conexion.Close(); $conexion.Dispose() }
