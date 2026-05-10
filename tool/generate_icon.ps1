# Generates a 1024x1024 app icon (gradient + "F") and writes Android launcher PNGs.

Add-Type -AssemblyName System.Drawing

function New-FigusIcon {
  param([int]$Size, [string]$Path, [bool]$Round = $false)

  $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.TextRenderingHint = 'AntiAliasGridFit'

  # Background gradient: brand blue → violet
  $rect = New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)
  $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $rect,
    [System.Drawing.Color]::FromArgb(255, 31, 102, 255),
    [System.Drawing.Color]::FromArgb(255, 122, 91, 255),
    45.0
  )

  if ($Round) {
    $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
    $gp.AddEllipse(0, 0, $Size, $Size)
    $g.FillPath($brush, $gp)
    $gp.Dispose()
  } else {
    # Rounded square (foreground style)
    $radius = [int]($Size * 0.22)
    $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
    $gp.AddArc(0, 0, $radius * 2, $radius * 2, 180, 90)
    $gp.AddArc($Size - $radius * 2, 0, $radius * 2, $radius * 2, 270, 90)
    $gp.AddArc($Size - $radius * 2, $Size - $radius * 2, $radius * 2, $radius * 2, 0, 90)
    $gp.AddArc(0, $Size - $radius * 2, $radius * 2, $radius * 2, 90, 90)
    $gp.CloseFigure()
    $g.FillPath($brush, $gp)
    $gp.Dispose()
  }

  # White "F"
  $fontSize = [int]($Size * 0.62)
  $font = New-Object System.Drawing.Font('Arial Black', $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
  $sf = New-Object System.Drawing.StringFormat
  $sf.Alignment = 'Center'
  $sf.LineAlignment = 'Center'
  $textRect = New-Object System.Drawing.RectangleF(0, [single]($Size * -0.04), [single]$Size, [single]$Size)
  $g.DrawString('F', $font, $textBrush, $textRect, $sf)

  $g.Dispose()
  $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  $brush.Dispose()
  $textBrush.Dispose()
  $font.Dispose()
  Write-Host "Wrote $Path ($Size x $Size)"
}

$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'assets\icon'
New-Item -ItemType Directory -Path $out -Force | Out-Null

# Master icon (used by flutter_launcher_icons later)
New-FigusIcon -Size 1024 -Path (Join-Path $out 'app_icon.png') -Round $false
New-FigusIcon -Size 1024 -Path (Join-Path $out 'app_icon_round.png') -Round $true

# Android mipmap launcher icons
$sizes = @{
  'mdpi'    = 48
  'hdpi'    = 72
  'xhdpi'   = 96
  'xxhdpi'  = 144
  'xxxhdpi' = 192
}
foreach ($k in $sizes.Keys) {
  $dir = Join-Path $root "android\app\src\main\res\mipmap-$k"
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  New-FigusIcon -Size $sizes[$k] -Path (Join-Path $dir 'ic_launcher.png') -Round $false
  New-FigusIcon -Size $sizes[$k] -Path (Join-Path $dir 'ic_launcher_round.png') -Round $true
}

# Web favicons
$webIcons = Join-Path $root 'web\icons'
if (Test-Path $webIcons) {
  New-FigusIcon -Size 192 -Path (Join-Path $webIcons 'Icon-192.png') -Round $false
  New-FigusIcon -Size 512 -Path (Join-Path $webIcons 'Icon-512.png') -Round $false
  New-FigusIcon -Size 192 -Path (Join-Path $webIcons 'Icon-maskable-192.png') -Round $false
  New-FigusIcon -Size 512 -Path (Join-Path $webIcons 'Icon-maskable-512.png') -Round $false
}
$favicon = Join-Path $root 'web\favicon.png'
New-FigusIcon -Size 64 -Path $favicon -Round $false

Write-Host "`nDone. Icons generated."
