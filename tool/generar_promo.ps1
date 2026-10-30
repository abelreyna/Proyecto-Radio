# Genera las capturas promocionales de la ficha de Google Play y la imagen
# destacada a partir de las capturas reales de la app.
# Uso (desde la raiz del proyecto):
#   powershell -ExecutionPolicy Bypass -File tool\generar_promo.ps1
#
# Entradas:
#   play_store/capturas_app/*.png   capturas reales de la app (1080x2160, sin barra de estado)
#   play_store/icon-512.png         icono (lo genera tool/generar_graficos.ps1)
#   tool/promo_textos.json          titulos y textos (UTF-8)
# Salidas:
#   play_store/screenshots/*.png    1080x1920 (9:16, lo que exige Play)
#   play_store/feature-graphic.png  1024x500
#
# Los textos van en el JSON porque PowerShell 5.1 lee este archivo como ANSI y
# romperia las tildes.

Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$cfg = [IO.File]::ReadAllText((Join-Path $root 'tool\promo_textos.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json

function Argb([int]$a, [int]$r, [int]$g, [int]$b) { return [System.Drawing.Color]::FromArgb($a, $r, $g, $b) }
$red = Argb 255 0xE0 0x12 0x2A
$deep = Argb 255 0x6A 0x05 0x12
$white = [System.Drawing.Color]::White
$typo = [System.Drawing.StringFormat]::GenericTypographic

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
    $g.TextRenderingHint = 'AntiAlias'
    return $g
}

function New-Font([string]$family, [float]$size) {
    return New-Object System.Drawing.Font($family, $size, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
}

function Text-Width($g, [string]$text, $font) { return $g.MeasureString($text, $font, 10000, $typo).Width }

# Fondo: degradado rojo a granate con ondas de radio translucidas.
function Fill-Backdrop($g, [int]$w, [int]$h) {
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Point(0, 0)), (New-Object System.Drawing.Point($w, $h)), $red, $deep)
    $g.FillRectangle($grad, 0, 0, $w, $h)
    $grad.Dispose()
}

function Draw-Rings($g, [float]$cx, [float]$cy, [float[]]$radii, [float]$width, [int]$alpha) {
    $pen = New-Object System.Drawing.Pen((Argb $alpha 255 255 255), $width)
    foreach ($r in $radii) { $g.DrawEllipse($pen, $cx - $r, $cy - $r, 2 * $r, 2 * $r) }
    $pen.Dispose()
}

function Draw-Glow($g, [float]$cx, [float]$cy, [float]$rx, [float]$ry, [int]$alpha) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddEllipse($cx - $rx, $cy - $ry, 2 * $rx, 2 * $ry)
    $brush = New-Object System.Drawing.Drawing2D.PathGradientBrush($path)
    $brush.CenterColor = Argb $alpha 255 255 255
    $brush.SurroundColors = @((Argb 0 255 255 255))
    $g.FillPath($brush, $path)
    $brush.Dispose(); $path.Dispose()
}

# Telefono con marco, esquinas redondeadas y sombra. Devuelve el bitmap y el
# margen reservado para la sombra.
function New-PhoneBitmap($img, [int]$w) {
    $b = [int]($w * 0.028)
    $sw = $w - 2 * $b
    $sh = [int]($sw * $img.Height / $img.Width)
    $h = $sh + 2 * $b
    $m = [int]($w * 0.09)
    $r = $w * 0.115

    $bmp = New-Object System.Drawing.Bitmap(($w + 2 * $m), ($h + 2 * $m), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = New-Graphics $bmp
    $g.Clear([System.Drawing.Color]::Transparent)

    $shadowBrush = New-Object System.Drawing.SolidBrush((Argb 5 20 0 4))
    for ($i = $m; $i -ge 1; $i -= 2) {
        $p = New-RoundedRect ($m - $i * 0.7) ($m - $i * 0.7 + $m * 0.35) ($w + $i * 1.4) ($h + $i * 1.4) ($r + $i * 0.7)
        $g.FillPath($shadowBrush, $p); $p.Dispose()
    }
    $shadowBrush.Dispose()

    $body = New-RoundedRect $m $m $w $h $r
    $bodyBrush = New-Object System.Drawing.SolidBrush((Argb 255 0x10 0x10 0x13))
    $g.FillPath($bodyBrush, $body)
    $edge = New-Object System.Drawing.Pen((Argb 255 0x45 0x45 0x4D), [Math]::Max(2, $w * 0.004))
    $g.DrawPath($edge, $body)

    # Pantalla: textura escalada para que las esquinas queden suavizadas.
    $screenImg = New-Object System.Drawing.Bitmap($sw, $sh)
    $sg = New-Graphics $screenImg
    $sg.DrawImage($img, 0, 0, $sw, $sh)
    $sg.Dispose()
    $tex = New-Object System.Drawing.TextureBrush($screenImg, [System.Drawing.Drawing2D.WrapMode]::Clamp)
    $tex.TranslateTransform($m + $b, $m + $b)
    $screen = New-RoundedRect ($m + $b) ($m + $b) $sw $sh ($r - $b)
    $g.FillPath($tex, $screen)

    $tex.Dispose(); $screenImg.Dispose(); $screen.Dispose(); $body.Dispose()
    $bodyBrush.Dispose(); $edge.Dispose(); $g.Dispose()
    return @{ Bitmap = $bmp; Margin = $m; Height = $h }
}

# Pastillas de texto (por ejemplo "Gratis"); pasan a otra fila si no caben.
function Draw-Chips($g, [string[]]$chips, $font, [float]$x, [float]$y, [float]$maxW, [bool]$center) {
    $padX = $font.Size * 0.9; $gap = $font.Size * 0.5; $ch = $font.Size * 1.9
    $rows = @(); $row = @(); $rowW = 0
    foreach ($c in $chips) {
        $cw = (Text-Width $g $c $font) + 2 * $padX
        if ($row.Count -gt 0 -and $rowW + $gap + $cw -gt $maxW) { $rows += , @($row); $row = @(); $rowW = 0 }
        if ($row.Count -gt 0) { $rowW += $gap }
        $row += , @($c, $cw); $rowW += $cw
    }
    if ($row.Count -gt 0) { $rows += , @($row) }

    $fill = New-Object System.Drawing.SolidBrush((Argb 46 255 255 255))
    $line = New-Object System.Drawing.Pen((Argb 120 255 255 255), 2)
    $text = New-Object System.Drawing.SolidBrush($white)
    foreach ($r in $rows) {
        $total = 0; foreach ($c in $r) { $total += $c[1] }; $total += $gap * ($r.Count - 1)
        $cx = if ($center) { $x + ($maxW - $total) / 2 } else { $x }
        foreach ($c in $r) {
            $p = New-RoundedRect $cx $y $c[1] $ch ($ch / 2)
            $g.FillPath($fill, $p); $g.DrawPath($line, $p); $p.Dispose()
            $g.DrawString($c[0], $font, $text, $cx + $padX, $y + ($ch - $font.Size * 1.33) / 2, $typo)
            $cx += $c[1] + $gap
        }
        $y += $ch + $gap
    }
    $fill.Dispose(); $line.Dispose(); $text.Dispose()
    return $y
}

function Wrap-Text($g, [string]$text, $font, [float]$maxW) {
    $lines = @(); $current = ''
    foreach ($word in $text -split ' ') {
        $try = if ($current) { "$current $word" } else { $word }
        if ($current -and (Text-Width $g $try $font) -gt $maxW) { $lines += $current; $current = $word } else { $current = $try }
    }
    if ($current) { $lines += $current }
    return $lines
}

# Igual que Wrap-Text, pero reparte las palabras para que las lineas midan
# parecido y no quede una palabra sola al final.
function Wrap-Balanced($g, [string]$text, $font, [float]$maxW) {
    $lines = @(Wrap-Text $g $text $font $maxW)
    if ($lines.Count -le 1) { return $lines }
    $limit = (Text-Width $g $text $font) / $lines.Count
    do { $try = @(Wrap-Text $g $text $font $limit); $limit += 10 } while ($try.Count -gt $lines.Count)
    return $try
}

function Draw-CenteredLine($g, [string]$text, $font, $brush, [float]$cx, [float]$y, $shadow) {
    $x = $cx - (Text-Width $g $text $font) / 2
    if ($shadow) { $g.DrawString($text, $font, $shadow, $x, $y + $font.Size * 0.05, $typo) }
    $g.DrawString($text, $font, $brush, $x, $y, $typo)
}

function Load-Capture([string]$name) {
    return [System.Drawing.Image]::FromFile((Join-Path $root "play_store\capturas_app\$name.png"))
}

function Save-Png($bmp, [string]$relative) {
    $path = Join-Path $root $relative
    New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    "  $relative"
}

$white90 = New-Object System.Drawing.SolidBrush((Argb 235 255 255 255))
$whiteBrush = New-Object System.Drawing.SolidBrush($white)
$shadowText = New-Object System.Drawing.SolidBrush((Argb 70 40 0 8))

"Generando capturas promocionales:"
foreach ($s in $cfg.capturas) {
    $W = 1080; $H = 1920
    $bmp = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = New-Graphics $bmp
    Fill-Backdrop $g $W $H
    Draw-Rings $g 1015 150 @(110, 190, 270, 350) 7 28
    Draw-Rings $g 40 1790 @(120, 210, 300) 7 20

    # Titulo: se reduce hasta que cada linea quepa en 960 px.
    $lines = $s.titulo -split "`n"
    $size = 94
    do {
        $title = New-Font 'Segoe UI Black' $size
        $widest = ($lines | ForEach-Object { Text-Width $g $_ $title } | Measure-Object -Maximum).Maximum
        if ($widest -gt 960) { $title.Dispose(); $size -= 2 }
    } while ($widest -gt 960)
    $y = 92
    foreach ($l in $lines) { Draw-CenteredLine $g $l $title $whiteBrush ($W / 2) $y $shadowText; $y += $size * 1.12 }
    $title.Dispose()

    $y += 20
    $sub = New-Font 'Segoe UI Semibold' 40
    foreach ($l in (Wrap-Balanced $g $s.subtitulo $sub 900)) { Draw-CenteredLine $g $l $sub $white90 ($W / 2) $y $null; $y += 52 }
    $sub.Dispose()

    if ($s.chips) {
        $chipFont = New-Font 'Segoe UI Semibold' 32
        [void](Draw-Chips $g $s.chips $chipFont 90 ($y + 24) 900 $true)
        $chipFont.Dispose()
    }

    # Telefono centrado en la parte inferior, siempre del mismo tamano.
    $img = Load-Capture $s.captura
    $phone = New-PhoneBitmap $img 660
    $img.Dispose()
    $top = 600
    Draw-Glow $g ($W / 2) ($top + $phone.Height / 2) 560 760 70
    $g.DrawImage($phone.Bitmap, ($W - 660) / 2 - $phone.Margin, $top - $phone.Margin)
    $phone.Bitmap.Dispose()
    $g.Dispose()
    Save-Png $bmp "play_store\screenshots\$($s.captura).png"
}

"Generando imagen destacada:"
$fgc = $cfg.imagenDestacada
$W = 1024; $H = 500
$bmp = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = New-Graphics $bmp
Fill-Backdrop $g $W $H
Draw-Rings $g 70 60 @(70, 125, 180, 235) 5 26
Draw-Glow $g 800 260 300 300 80

# Dos telefonos inclinados a la derecha, cortados por el borde inferior.
foreach ($p in @(@{ Name = $fgc.capturaAtras; Cx = 905; Cy = 300; Angle = 12; W = 205 },
                 @{ Name = $fgc.capturaFrente; Cx = 735; Cy = 320; Angle = -7; W = 225 })) {
    $img = Load-Capture $p.Name
    $phone = New-PhoneBitmap $img $p.W
    $img.Dispose()
    $state = $g.Save()
    $g.TranslateTransform($p.Cx, $p.Cy)
    $g.RotateTransform($p.Angle)
    $g.DrawImage($phone.Bitmap, -$phone.Bitmap.Width / 2, -$phone.Bitmap.Height / 2)
    $g.Restore($state)
    $phone.Bitmap.Dispose()
}

# Icono con esquinas redondeadas y sombra suave.
$icon = [System.Drawing.Image]::FromFile((Join-Path $root 'play_store\icon-512.png'))
$iconSize = 92; $ix = 56; $iy = 58
$shadowBrush = New-Object System.Drawing.SolidBrush((Argb 10 30 0 6))
for ($i = 14; $i -ge 1; $i -= 2) {
    $p = New-RoundedRect ($ix - $i * 0.6) ($iy - $i * 0.6 + 6) ($iconSize + $i * 1.2) ($iconSize + $i * 1.2) (22 + $i * 0.6)
    $g.FillPath($shadowBrush, $p); $p.Dispose()
}
$scaled = New-Object System.Drawing.Bitmap($iconSize, $iconSize)
$sg = New-Graphics $scaled; $sg.DrawImage($icon, 0, 0, $iconSize, $iconSize); $sg.Dispose(); $icon.Dispose()
$tex = New-Object System.Drawing.TextureBrush($scaled, [System.Drawing.Drawing2D.WrapMode]::Clamp)
$tex.TranslateTransform($ix, $iy)
$p = New-RoundedRect $ix $iy $iconSize $iconSize 22
$g.FillPath($tex, $p)
$ring = New-Object System.Drawing.Pen((Argb 150 255 255 255), 3)
$g.DrawPath($ring, $p)
$p.Dispose(); $tex.Dispose(); $scaled.Dispose(); $ring.Dispose(); $shadowBrush.Dispose()

$title = New-Font 'Segoe UI Black' 60
$g.DrawString($fgc.titulo, $title, $shadowText, 54, 178, $typo)
$g.DrawString($fgc.titulo, $title, $whiteBrush, 54, 175, $typo)
$title.Dispose()
$lema = New-Font 'Segoe UI Semibold' 27
$y = 262
foreach ($l in (Wrap-Balanced $g $fgc.lema $lema 520)) { $g.DrawString($l, $lema, $white90, 56, $y, $typo); $y += 36 }
$lema.Dispose()
$chipFont = New-Font 'Segoe UI Semibold' 21
[void](Draw-Chips $g $fgc.chips $chipFont 56 ($y + 20) 540 $false)
$chipFont.Dispose()
$g.Dispose()
Save-Png $bmp 'play_store\feature-graphic.png'

$white90.Dispose(); $whiteBrush.Dispose(); $shadowText.Dispose()
