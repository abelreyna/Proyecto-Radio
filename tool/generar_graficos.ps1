# Genera el ícono de Radios Perú Mix y los gráficos de la ficha de Google Play.
# Uso (desde la raíz del proyecto):  powershell -File tool\generar_graficos.ps1
#
# Salidas:
#   assets/icon/icon.png             1024x1024, ícono completo (iOS y Play)
#   assets/icon/icon_foreground.png  1024x1024, capa frontal del ícono adaptable
#   assets/icon/splash.png           768x768,   logo de la pantalla de carga
#   assets/icon/splash_android12.png 1152x1152, ídem para Android 12 o superior
#   play_store/icon-512.png          512x512,   ícono de la ficha de Play
#   play_store/feature-graphic.png   1024x500,  imagen destacada de Play

Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$red = [System.Drawing.Color]::FromArgb(255, 0xD9, 0x10, 0x23)
$darkRed = [System.Drawing.Color]::FromArgb(255, 0x9E, 0x0B, 0x1A)
$white = [System.Drawing.Color]::White

function New-RoundedRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = 2 * $r
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function New-Graphics($bitmap) {
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    $g.SmoothingMode = 'AntiAlias'
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.PixelOffsetMode = 'HighQuality'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    return $g
}

# Dibuja la radio blanca (con huecos transparentes) en un cuadrado de lado $s
# cuya esquina superior izquierda es ($ox, $oy).
function Draw-Glyph($g, [float]$ox, [float]$oy, [float]$s) {
    $brush = New-Object System.Drawing.SolidBrush($white)
    $hole = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Transparent)
    function P([float]$v) { return $v * $s }

    # Ondas de transmisión sobre la radio
    $pen = New-Object System.Drawing.Pen($white, (P 0.045))
    $pen.StartCap = 'Round'; $pen.EndCap = 'Round'
    foreach ($r in 0.11, 0.20) {
        $g.DrawArc($pen, $ox + (P (0.30 - $r)), $oy + (P (0.36 - $r)), (P (2 * $r)), (P (2 * $r)), 215, 110)
    }

    # Antena
    $pen2 = New-Object System.Drawing.Pen($white, (P 0.05))
    $pen2.StartCap = 'Round'; $pen2.EndCap = 'Round'
    $g.DrawLine($pen2, $ox + (P 0.70), $oy + (P 0.40), $ox + (P 0.86), $oy + (P 0.10))
    $g.FillEllipse($brush, $ox + (P 0.81), $oy + (P 0.05), (P 0.10), (P 0.10))

    # Cuerpo
    $body = New-RoundedRect ($ox + (P 0.04)) ($oy + (P 0.38)) (P 0.92) (P 0.56) (P 0.11)
    $g.FillPath($brush, $body)

    # Huecos: parlante, pantalla y perillas
    $g.CompositingMode = 'SourceCopy'
    $g.FillEllipse($hole, $ox + (P 0.13), $oy + (P 0.47), (P 0.38), (P 0.38))
    $g.CompositingMode = 'SourceOver'
    $g.FillEllipse($brush, $ox + (P 0.20), $oy + (P 0.54), (P 0.24), (P 0.24))
    $g.CompositingMode = 'SourceCopy'
    $g.FillEllipse($hole, $ox + (P 0.28), $oy + (P 0.62), (P 0.08), (P 0.08))
    $screen = New-RoundedRect ($ox + (P 0.58)) ($oy + (P 0.50)) (P 0.28) (P 0.13) (P 0.035)
    $g.FillPath($hole, $screen)
    $g.FillEllipse($hole, $ox + (P 0.585), $oy + (P 0.71), (P 0.10), (P 0.10))
    $g.FillEllipse($hole, $ox + (P 0.755), $oy + (P 0.71), (P 0.10), (P 0.10))
    $g.CompositingMode = 'SourceOver'
}

function New-GlyphBitmap([int]$canvas, [float]$glyphRatio) {
    $bmp = New-Object System.Drawing.Bitmap($canvas, $canvas, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = New-Graphics $bmp
    $g.Clear([System.Drawing.Color]::Transparent)
    $s = $canvas * $glyphRatio
    Draw-Glyph $g (($canvas - $s) / 2) (($canvas - $s) / 2) $s
    $g.Dispose()
    return $bmp
}

function Fill-Background($g, [int]$w, [int]$h) {
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $red, $darkRed, 45.0)
    $g.FillRectangle($grad, $rect)
}

function New-FullIcon([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = New-Graphics $bmp
    Fill-Background $g $size $size
    $glyph = New-GlyphBitmap $size 0.64
    $g.DrawImage($glyph, 0, 0, $size, $size)
    $glyph.Dispose(); $g.Dispose()
    return $bmp
}

function Save-Png($bmp, [string]$relative) {
    $path = Join-Path $root $relative
    New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    "  $relative"
}

"Generando graficos:"
Save-Png (New-FullIcon 1024) 'assets/icon/icon.png'
# Zona segura del ícono adaptable: el dibujo ocupa el 56 % central.
Save-Png (New-GlyphBitmap 1024 0.56) 'assets/icon/icon_foreground.png'
Save-Png (New-GlyphBitmap 768 0.66) 'assets/icon/splash.png'
# Android 12+ recorta el logo de la pantalla de carga en un círculo de 768 px.
Save-Png (New-GlyphBitmap 1152 0.47) 'assets/icon/splash_android12.png'
Save-Png (New-FullIcon 512) 'play_store/icon-512.png'

# Imagen destacada 1024x500: ícono a la izquierda, nombre y lema a la derecha.
$fg = New-Object System.Drawing.Bitmap(1024, 500, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = New-Graphics $fg
Fill-Background $g 1024 500
$glyph = New-GlyphBitmap 420 0.80
$g.DrawImage($glyph, 50, 40, 420, 420)
$glyph.Dispose()
$titleFont = New-Object System.Drawing.Font('Segoe UI', 64, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$subFont = New-Object System.Drawing.Font('Segoe UI', 32, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$textBrush = New-Object System.Drawing.SolidBrush($white)
$softBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 255, 255, 255))
# "Perú" con la ú escrita por código: PowerShell 5.1 lee este archivo como ANSI.
$peru = "Per$([char]0x00FA)"
$g.DrawString('Radios', $titleFont, $textBrush, 490, 120)
$g.DrawString("$peru Mix", $titleFont, $textBrush, 490, 195)
$g.DrawString("Las radios del $peru en vivo", $subFont, $softBrush, 494, 300)
$g.Dispose()
Save-Png $fg 'play_store/feature-graphic.png'
