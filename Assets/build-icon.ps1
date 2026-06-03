# Build app.ico from the design defined in Assets/app.svg using GDI+.
# Renders sizes 16/24/32/48/64/128/256 as PNGs and packs them into a
# multi-size PNG-embedded ICO. Windows PowerShell 5.1 compatible.
#
# Design: BreezeFlow single bold leaf filling the frame (stem + midrib + veins).

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outIco    = Join-Path $scriptDir 'app.ico'
$sizes     = 16, 24, 32, 48, 64, 128, 256

function Add-QuadCurve {
    # Append a quadratic Bezier (P0 -> Q -> P1) to a GraphicsPath
    # by converting it to its cubic equivalent.
    param(
        [System.Drawing.Drawing2D.GraphicsPath]$Path,
        [single]$X0, [single]$Y0,
        [single]$Qx, [single]$Qy,
        [single]$X1, [single]$Y1
    )
    $c1x = $X0 + (2.0 / 3.0) * ($Qx - $X0)
    $c1y = $Y0 + (2.0 / 3.0) * ($Qy - $Y0)
    $c2x = $X1 + (2.0 / 3.0) * ($Qx - $X1)
    $c2y = $Y1 + (2.0 / 3.0) * ($Qy - $Y1)
    $Path.AddBezier($X0, $Y0, $c1x, $c1y, $c2x, $c2y, $X1, $Y1)
}

function Add-Dot {
    param(
        [System.Drawing.Graphics]$G,
        [System.Drawing.Color]$Color,
        [single]$Cx, [single]$Cy, [single]$R
    )
    $brush = New-Object System.Drawing.SolidBrush $Color
    $G.FillEllipse($brush, $Cx - $R, $Cy - $R, $R * 2, $R * 2)
    $brush.Dispose()
}

function New-IconPng {
    param([int]$Size)

    $bmp = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $scale = $Size / 256.0
    $g.ScaleTransform($scale, $scale)

    # ---- background: rounded square with cyan gradient ----
    $rectF  = New-Object System.Drawing.RectangleF 8, 8, 240, 240
    $bgPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $r      = 40.0
    $bgPath.AddArc($rectF.X,                       $rectF.Y,                       $r, $r, 180, 90)
    $bgPath.AddArc($rectF.X + $rectF.Width - $r,   $rectF.Y,                       $r, $r, 270, 90)
    $bgPath.AddArc($rectF.X + $rectF.Width - $r,   $rectF.Y + $rectF.Height - $r,  $r, $r,   0, 90)
    $bgPath.AddArc($rectF.X,                       $rectF.Y + $rectF.Height - $r,  $r, $r,  90, 90)
    $bgPath.CloseFigure()

    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF 8, 8),
        (New-Object System.Drawing.PointF 248, 248),
        ([System.Drawing.Color]::FromArgb(255, 128, 222, 234)),
        ([System.Drawing.Color]::FromArgb(255,   0, 131, 143)))
    $g.FillPath($bgBrush, $bgPath)
    $bgBrush.Dispose()
    $bgPath.Dispose()

    # ---- stem ----
    $stemPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 46, 125, 50)), 9
    $stemPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $stemPen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $stemPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    Add-QuadCurve -Path $stemPath -X0 60 -Y0 224 -Qx 52 -Qy 235 -X1 46 -Y1 244
    $g.DrawPath($stemPen, $stemPath)
    $stemPath.Dispose()
    $stemPen.Dispose()

    # ---- leaf body: base (60,224), tip (196,40) — large, fills the frame ----
    $leafPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $leafPath.AddBezier( 60, 224, 171, 212, 216, 152, 196,  40)
    $leafPath.AddBezier(196,  40,  85,  52,  40, 112,  60, 224)
    $leafPath.CloseFigure()

    $leafBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF 0, 256),
        (New-Object System.Drawing.PointF 256, 0),
        ([System.Drawing.Color]::FromArgb(255,  46, 125,  50)),
        ([System.Drawing.Color]::FromArgb(255, 156, 204, 101)))
    $g.FillPath($leafBrush, $leafPath)
    $leafBrush.Dispose()
    $leafPath.Dispose()

    # ---- midrib (white, alpha ~0.6) ----
    $midPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(153, 255, 255, 255)), ([single]4)
    $midPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $midPen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $midPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    Add-QuadCurve -Path $midPath -X0 60 -Y0 224 -Qx 115 -Qy 120 -X1 196 -Y1 40
    $g.DrawPath($midPen, $midPath)
    $midPath.Dispose()
    $midPen.Dispose()

    # ---- side veins (white, alpha ~0.5) ----
    $veinPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(128, 255, 255, 255)), ([single]2.5)
    $veinPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $veinPen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $vp = New-Object System.Drawing.Drawing2D.GraphicsPath
    Add-QuadCurve -Path $vp -X0 102 -Y0 154 -Qx 115 -Qy 156 -X1 121 -Y1 168
    $g.DrawPath($veinPen, $vp); $vp.Reset()
    Add-QuadCurve -Path $vp -X0 102 -Y0 154 -Qx 96  -Qy 142 -X1 83  -Y1 140
    $g.DrawPath($veinPen, $vp); $vp.Reset()
    Add-QuadCurve -Path $vp -X0 128 -Y0 117 -Qx 141 -Qy 119 -X1 147 -Y1 131
    $g.DrawPath($veinPen, $vp); $vp.Reset()
    Add-QuadCurve -Path $vp -X0 128 -Y0 117 -Qx 122 -Qy 105 -X1 109 -Y1 103
    $g.DrawPath($veinPen, $vp); $vp.Reset()
    Add-QuadCurve -Path $vp -X0 153 -Y0 87  -Qx 165 -Qy 90  -X1 171 -Y1 100
    $g.DrawPath($veinPen, $vp); $vp.Reset()
    Add-QuadCurve -Path $vp -X0 153 -Y0 87  -Qx 147 -Qy 77  -X1 135 -Y1 74
    $g.DrawPath($veinPen, $vp)
    $vp.Dispose()
    $veinPen.Dispose()

    # ---- "BreezeFlow" wordmark at the top, stretched to span the icon width ----
    $titleFont  = New-Object System.Drawing.Font("Segoe UI", 28, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $titleBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(235, 0, 71, 77))
    $titleFmt   = New-Object System.Drawing.StringFormat ([System.Drawing.StringFormat]::GenericTypographic)
    $titleFmt.Alignment     = [System.Drawing.StringAlignment]::Center
    $titleFmt.LineAlignment = [System.Drawing.StringAlignment]::Center
    # measure natural width, then scale x so the wordmark spans ~206px (center x=128)
    $titleW = $g.MeasureString("BreezeFlow", $titleFont, [int]1000, $titleFmt).Width
    $titleScale = 206.0 / $titleW
    $tState = $g.Save()
    $g.TranslateTransform([single]128, [single]0)
    $g.ScaleTransform([single]$titleScale, [single]1)
    $g.TranslateTransform([single]-128, [single]0)
    $g.DrawString("BreezeFlow", $titleFont, $titleBrush, (New-Object System.Drawing.PointF 128, 26), $titleFmt)
    $g.Restore($tState)
    $titleFmt.Dispose()
    $titleBrush.Dispose()
    $titleFont.Dispose()

    # ---- small "ELT" wordmark at the bottom, stretched horizontally (x scaled 1.7 around center x=140) ----
    $eltFont  = New-Object System.Drawing.Font("Segoe UI", 28, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $eltBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(230, 255, 255, 255))
    $eltFmt   = New-Object System.Drawing.StringFormat
    $eltFmt.Alignment     = [System.Drawing.StringAlignment]::Center
    $eltFmt.LineAlignment = [System.Drawing.StringAlignment]::Center
    $eltState = $g.Save()
    $g.TranslateTransform([single]140, [single]0)
    $g.ScaleTransform([single]1.7, [single]1)
    $g.TranslateTransform([single]-140, [single]0)
    $g.DrawString("ELT", $eltFont, $eltBrush, (New-Object System.Drawing.PointF 140, 230), $eltFmt)
    $g.Restore($eltState)
    $eltFmt.Dispose()
    $eltBrush.Dispose()
    $eltFont.Dispose()

    $g.Dispose()

    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    return ,$ms.ToArray()
}

$pngs = @{}
foreach ($s in $sizes) {
    $pngs[$s] = New-IconPng -Size $s
    Write-Host ("  {0,3}x{1,-3}: {2,7:N0} bytes" -f $s, $s, $pngs[$s].Length)
}

$fs = [System.IO.File]::Open($outIco, [System.IO.FileMode]::Create)
$bw = New-Object System.IO.BinaryWriter $fs
try {
    $bw.Write([UInt16]0)
    $bw.Write([UInt16]1)
    $bw.Write([UInt16]$sizes.Count)

    $headerSize = 6 + 16 * $sizes.Count
    $offset     = $headerSize

    foreach ($s in $sizes) {
        $data = $pngs[$s]
        if ($s -ge 256) { $dim = [Byte]0 } else { $dim = [Byte]$s }
        $bw.Write($dim)
        $bw.Write($dim)
        $bw.Write([Byte]0)
        $bw.Write([Byte]0)
        $bw.Write([UInt16]1)
        $bw.Write([UInt16]32)
        $bw.Write([UInt32]$data.Length)
        $bw.Write([UInt32]$offset)
        $offset += $data.Length
    }

    foreach ($s in $sizes) {
        $bw.Write($pngs[$s])
    }
}
finally {
    $bw.Dispose()
    $fs.Dispose()
}

Write-Host ""
Write-Host ("Generated: {0} ({1:N0} bytes)" -f $outIco, (Get-Item $outIco).Length)
