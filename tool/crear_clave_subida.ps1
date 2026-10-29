# Crea la clave de subida (upload key) para firmar Radios Peru Mix en Google Play
# y guarda la contrasena en android\key.properties (archivo que NO se sube a GitHub).
#
# Uso: powershell -NoProfile -ExecutionPolicy Bypass -File tool\crear_clave_subida.ps1

$ErrorActionPreference = 'Stop'
$keytool = Join-Path $env:USERPROFILE 'dev\jdk-21\bin\keytool.exe'
$keystore = Join-Path $env:USERPROFILE 'keys\radiosperumix-upload.jks'
$keyProperties = Join-Path (Split-Path -Parent $PSScriptRoot) 'android\key.properties'

Write-Host ''
Write-Host '=== Clave de subida de Radios Peru Mix para Google Play ===' -ForegroundColor Cyan
Write-Host ''

if (Test-Path $keystore) {
    Write-Host "Ya existe una clave en $keystore. No se crea otra." -ForegroundColor Yellow
    Read-Host 'Pulsa Enter para cerrar'
    return
}

function Read-PlainPassword([string]$prompt) {
    $secure = Read-Host $prompt -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

while ($true) {
    $password = Read-PlainPassword 'Escribe una contrasena (minimo 6 caracteres)'
    if ($password.Length -lt 6) {
        Write-Host 'Debe tener al menos 6 caracteres. Intenta de nuevo.' -ForegroundColor Yellow
        continue
    }
    if ($password -match '\s') {
        Write-Host 'No uses espacios. Intenta de nuevo.' -ForegroundColor Yellow
        continue
    }
    $confirm = Read-PlainPassword 'Repite la contrasena'
    if ($password -ceq $confirm) { break }
    Write-Host 'Las contrasenas no coinciden. Intenta de nuevo.' -ForegroundColor Yellow
}

New-Item -ItemType Directory -Force (Split-Path $keystore) | Out-Null
& $keytool -genkeypair -keystore $keystore -storetype PKCS12 `
    -keyalg RSA -keysize 2048 -validity 10000 -alias upload `
    -storepass $password -keypass $password `
    -dname 'CN=Radios Peru Mix, O=Radios Peru Mix, C=PE'

if (-not (Test-Path $keystore)) {
    Write-Host 'No se pudo crear la clave.' -ForegroundColor Red
    Read-Host 'Pulsa Enter para cerrar'
    return
}

# En un archivo .properties la barra invertida debe escribirse doble.
$escaped = $password.Replace('\', '\\')
$content = @(
    '# Clave de subida de Google Play. Este archivo NO se sube a GitHub.'
    '# Guarda una copia del .jks y de la contrasena en un lugar seguro.'
    "storePassword=$escaped"
    "keyPassword=$escaped"
    'keyAlias=upload'
    'storeFile=C:/Users/ADMIN/keys/radiosperumix-upload.jks'
)
[IO.File]::WriteAllLines($keyProperties, $content)
$password = $null; $confirm = $null; $escaped = $null

Write-Host ''
Write-Host "Listo. Clave creada en $keystore" -ForegroundColor Green
Write-Host 'La contrasena quedo guardada en android\key.properties.'
Write-Host 'Haz una copia de seguridad del archivo .jks y anota tu contrasena.'
Write-Host ''
Read-Host 'Pulsa Enter para cerrar esta ventana'
