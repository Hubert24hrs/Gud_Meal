# Makes the Android launcher icons (and the browser-build icons) of the customer and rider apps from the brand logo.
#   powershell -File scripts/make-app-icons.ps1 [-Logo assets/brand/gud-meal-logo.jpg]
# The logo is the wide lock-up (pin symbol + "gud meal"); an app icon is square, so the pin symbol is cropped out
# and centred. Customer app: the pin on the logo's cream. Rider app: the same pin on a cream disc on the logo's
# dark colour, so the two apps are easy to tell apart on one phone.
# Needs Windows PowerShell (System.Drawing). iOS icons are not made here: they need a larger or vector logo.
param(
    [string]$Logo = (Join-Path $PSScriptRoot '..\assets\brand\gud-meal-logo.jpg'),
    [string]$Root = (Join-Path $PSScriptRoot '..')
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$Root = (Resolve-Path $Root).Path
$src = New-Object System.Drawing.Bitmap ((Resolve-Path $Logo).Path)

# --- Find the pin: the orange shape in the left part of the logo.
$minX = [int]::MaxValue; $minY = [int]::MaxValue; $maxX = -1; $maxY = -1
$limitX = [int]($src.Width * 0.30)
for ($y = 0; $y -lt $src.Height; $y++) {
    for ($x = 0; $x -lt $limitX; $x++) {
        $c = $src.GetPixel($x, $y)
        if ($c.R -gt 200 -and $c.G -gt 60 -and $c.G -lt 150 -and $c.B -lt 100) {
            if ($x -lt $minX) { $minX = $x }; if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }; if ($y -gt $maxY) { $maxY = $y }
        }
    }
}
if ($maxX -lt 0) { throw "No orange pin found in $Logo" }
$pinW = $maxX - $minX + 1; $pinH = $maxY - $minY + 1

# --- Brand colours, read from the logo: the cream background and the dark of the bar inside the pin.
function Get-Average([int]$x0, [int]$y0, [int]$n) {
    $r = 0; $g = 0; $b = 0
    for ($y = $y0; $y -lt $y0 + $n; $y++) { for ($x = $x0; $x -lt $x0 + $n; $x++) { $c = $src.GetPixel($x, $y); $r += $c.R; $g += $c.G; $b += $c.B } }
    $k = $n * $n
    return [System.Drawing.Color]::FromArgb(255, [int][Math]::Round($r / $k), [int][Math]::Round($g / $k), [int][Math]::Round($b / $k))
}
$cream = Get-Average 6 6 10
# The dark: the average of the bar's solid pixels (not its soft edge, and not one noisy pixel).
$r = 0; $g = 0; $b = 0; $k = 0
for ($y = $minY; $y -le $maxY; $y++) {
    for ($x = $minX; $x -le $maxX; $x++) {
        $c = $src.GetPixel($x, $y)
        if ($c.R + $c.G + $c.B -lt 130) { $r += $c.R; $g += $c.G; $b += $c.B; $k++ }
    }
}
if ($k -eq 0) { throw "No dark bar found inside the pin" }
$dark = [System.Drawing.Color]::FromArgb(255, [int][Math]::Round($r / $k), [int][Math]::Round($g / $k), [int][Math]::Round($b / $k))
$hex = { param($c) '#{0:X2}{1:X2}{2:X2}' -f $c.R, $c.G, $c.B }
"logo $($src.Width)x$($src.Height); pin at ($minX,$minY) ${pinW}x${pinH}; cream $(& $hex $cream); dark $(& $hex $dark)"

$pad = 5  # keep the pin's soft edge; what surrounds it in the logo is the same cream it is drawn on
$crop = New-Object System.Drawing.Rectangle ($minX - $pad), ($minY - $pad), ($pinW + 2 * $pad), ($pinH + 2 * $pad)

function Add-Mark($g, [double]$cx, [double]$cy, [double]$height) {
    $scale = $height / $pinH
    $w = $crop.Width * $scale; $h = $crop.Height * $scale
    $dest = [System.Drawing.Rectangle]::Round((New-Object System.Drawing.RectangleF ([single]($cx - $w / 2)), ([single]($cy - $h / 2)), ([single]$w), ([single]$h)))
    $attr = New-Object System.Drawing.Imaging.ImageAttributes
    $attr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)  # no dark fringe at the patch's edge
    $g.DrawImage($src, $dest, $crop.X, $crop.Y, $crop.Width, $crop.Height, [System.Drawing.GraphicsUnit]::Pixel, $attr)
    $attr.Dispose()
}

# Layout in Android's adaptive-icon units: a 108dp layer of which launchers show the middle 72dp.
#   customer: pin 54dp tall on cream.   rider: pin 40dp tall on a cream disc (radius 29dp) on dark.
function Save-Icon([string]$path, [int]$size, [string]$app, [string]$kind) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'
    $g.PixelOffsetMode = 'HighQuality'; $g.CompositingQuality = 'HighQuality'
    $dp = if ($kind -eq 'foreground') { $size / 108.0 } else { $size / 72.0 }
    $mid = $size / 2.0
    $ground = if ($app -eq 'rider') { $dark } else { $cream }
    $brush = New-Object System.Drawing.SolidBrush $ground
    if ($kind -eq 'legacy') {
        # Launchers older than Android 8 draw this as it is: a rounded square on a transparent corner.
        $r = [single](16 * $dp); $d = 2 * $r; $s = [single]$size
        $shape = New-Object System.Drawing.Drawing2D.GraphicsPath
        $shape.AddArc(0, 0, $d, $d, 180, 90); $shape.AddArc($s - $d, 0, $d, $d, 270, 90)
        $shape.AddArc($s - $d, $s - $d, $d, $d, 0, 90); $shape.AddArc(0, $s - $d, $d, $d, 90, 90); $shape.CloseFigure()
        $g.FillPath($brush, $shape); $shape.Dispose()
    } else {
        $g.FillRectangle($brush, 0, 0, $size, $size)
    }
    if ($app -eq 'rider') {
        $disc = New-Object System.Drawing.SolidBrush $cream
        $radius = 29 * $dp
        $g.FillEllipse($disc, [single]($mid - $radius), [single]($mid - $radius), [single](2 * $radius), [single](2 * $radius))
        $disc.Dispose()
        Add-Mark $g $mid $mid (40 * $dp)
    } else {
        Add-Mark $g $mid $mid (54 * $dp)
    }
    $brush.Dispose(); $g.Dispose()
    New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
}

$densities = [ordered]@{ mdpi = 1.0; hdpi = 1.5; xhdpi = 2.0; xxhdpi = 3.0; xxxhdpi = 4.0 }
foreach ($app in 'customer', 'rider') {
    $res = Join-Path $Root "mobile\$app\android\app\src\main\res"
    foreach ($density in $densities.Keys) {
        $k = $densities[$density]
        Save-Icon (Join-Path $res "mipmap-$density\ic_launcher.png") ([int](48 * $k)) $app 'legacy'
        Save-Icon (Join-Path $res "mipmap-$density\ic_launcher_foreground.png") ([int](108 * $k)) $app 'foreground'
    }
    $ground = if ($app -eq 'rider') { $dark } else { $cream }
    $utf8 = New-Object System.Text.UTF8Encoding $false
    New-Item -ItemType Directory -Force (Join-Path $res 'mipmap-anydpi-v26') | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $res 'mipmap-anydpi-v26\ic_launcher.xml'), @"
<?xml version="1.0" encoding="utf-8"?>
<!-- Made by scripts/make-app-icons.ps1 from assets/brand/gud-meal-logo.jpg. -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"@.Replace("`r`n", "`n") + "`n", $utf8)
    [System.IO.File]::WriteAllText((Join-Path $res 'values\ic_launcher_background.xml'), @"
<?xml version="1.0" encoding="utf-8"?>
<!-- Made by scripts/make-app-icons.ps1: the launcher icon's background, read from the brand logo. -->
<resources>
    <color name="ic_launcher_background">$(& $hex $ground)</color>
</resources>
"@.Replace("`r`n", "`n") + "`n", $utf8)

    # Browser builds (flutter build web): the same picture, full bleed.
    $web = Join-Path $Root "mobile\$app\web"
    if (Test-Path $web) {
        Save-Icon (Join-Path $web 'favicon.png') 32 $app 'legacy'
        foreach ($n in 192, 512) {
            Save-Icon (Join-Path $web "icons\Icon-$n.png") $n $app 'square'
            Save-Icon (Join-Path $web "icons\Icon-maskable-$n.png") $n $app 'square'
        }
    }
    "made the $app app's icons"
}
$src.Dispose()
