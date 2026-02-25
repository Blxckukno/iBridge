param(
    [Parameter(Mandatory = $true)]
    [string]$InputImage,
    [string]$OutputDir = "",
    [int]$WhiteThreshold = 245,
    [double]$GutterRatio = 0.92,
    [int]$MinGutter = 4,
    [int]$MinPanel = 80,
    [int]$Rows = 0,
    [int]$Cols = 0
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $InputImage)) {
    throw "Input image not found: $InputImage"
}

Add-Type -AssemblyName System.Drawing

function Get-DefaultOutputDir {
    param([string]$ImagePath)
    $dir = Split-Path -Parent $ImagePath
    $name = [System.IO.Path]::GetFileNameWithoutExtension($ImagePath)
    return (Join-Path $dir ($name + "_split"))
}

function Find-Runs {
    param(
        [bool[]]$Mask,
        [int]$MinLen
    )
    $runs = @()
    $start = -1
    for ($i = 0; $i -lt $Mask.Length; $i++) {
        if ($Mask[$i] -and $start -lt 0) { $start = $i }
        if ((-not $Mask[$i] -or $i -eq $Mask.Length - 1) -and $start -ge 0) {
            $end = if ($Mask[$i] -and $i -eq $Mask.Length - 1) { $i } else { $i - 1 }
            if (($end - $start + 1) -ge $MinLen) {
                $runs += ,@($start, $end)
            }
            $start = -1
        }
    }
    return $runs
}

function Build-BoundsFromGutters {
    param(
        [int]$Size,
        [object[]]$Runs,
        [int]$MinPanel
    )
    $cuts = @()
    foreach ($r in $Runs) {
        $cuts += [int](($r[0] + $r[1]) / 2)
    }
    $cuts = $cuts | Sort-Object -Unique
    $bounds = @(0)
    foreach ($c in $cuts) {
        if (($c - $bounds[-1]) -ge $MinPanel) { $bounds += $c }
    }
    if (($Size - $bounds[-1]) -ge $MinPanel) { $bounds += $Size }
    elseif ($bounds[-1] -ne $Size) { $bounds[-1] = $Size }
    return $bounds
}

function BuildEvenBounds {
    param(
        [int]$Size,
        [int]$Parts
    )
    $b = @()
    for ($i = 0; $i -le $Parts; $i++) {
        $b += [int][Math]::Round(($Size * $i) / $Parts)
    }
    return $b
}

$bitmap = New-Object System.Drawing.Bitmap($InputImage)
$w = $bitmap.Width
$h = $bitmap.Height

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Get-DefaultOutputDir -ImagePath $InputImage
}
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$xMask = New-Object bool[] $w
$yMask = New-Object bool[] $h

if ($Rows -gt 0 -and $Cols -gt 0) {
    $xBounds = BuildEvenBounds -Size $w -Parts $Cols
    $yBounds = BuildEvenBounds -Size $h -Parts $Rows
} else {
    for ($x = 0; $x -lt $w; $x++) {
        $white = 0
        for ($y = 0; $y -lt $h; $y++) {
            $p = $bitmap.GetPixel($x, $y)
            if ($p.R -ge $WhiteThreshold -and $p.G -ge $WhiteThreshold -and $p.B -ge $WhiteThreshold) {
                $white++
            }
        }
        $ratio = $white / [double]$h
        $xMask[$x] = $ratio -ge $GutterRatio
    }

    for ($y = 0; $y -lt $h; $y++) {
        $white = 0
        for ($x = 0; $x -lt $w; $x++) {
            $p = $bitmap.GetPixel($x, $y)
            if ($p.R -ge $WhiteThreshold -and $p.G -ge $WhiteThreshold -and $p.B -ge $WhiteThreshold) {
                $white++
            }
        }
        $ratio = $white / [double]$w
        $yMask[$y] = $ratio -ge $GutterRatio
    }

    $xRuns = Find-Runs -Mask $xMask -MinLen $MinGutter
    $yRuns = Find-Runs -Mask $yMask -MinLen $MinGutter

    $xBounds = Build-BoundsFromGutters -Size $w -Runs $xRuns -MinPanel $MinPanel
    $yBounds = Build-BoundsFromGutters -Size $h -Runs $yRuns -MinPanel $MinPanel

    if ($xBounds.Count -lt 2 -or $yBounds.Count -lt 2) {
        throw "Auto-detect failed. Try manual grid split: -Rows 2 -Cols 2 (or your layout)."
    }
}

$saved = 0
for ($r = 0; $r -lt $yBounds.Count - 1; $r++) {
    for ($c = 0; $c -lt $xBounds.Count - 1; $c++) {
        $x0 = $xBounds[$c]
        $x1 = $xBounds[$c + 1]
        $y0 = $yBounds[$r]
        $y1 = $yBounds[$r + 1]
        $cw = $x1 - $x0
        $ch = $y1 - $y0
        if ($cw -lt $MinPanel -or $ch -lt $MinPanel) { continue }

        $rect = New-Object System.Drawing.Rectangle($x0, $y0, $cw, $ch)
        $crop = $bitmap.Clone($rect, $bitmap.PixelFormat)
        $out = Join-Path $OutputDir ("panel_r{0}_c{1}.png" -f ($r + 1), ($c + 1))
        $crop.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
        $crop.Dispose()
        $saved++
    }
}

$bitmap.Dispose()

Write-Host "Saved $saved panels to: $OutputDir"
Write-Host "Detected grid: $($yBounds.Count - 1) rows x $($xBounds.Count - 1) cols"
