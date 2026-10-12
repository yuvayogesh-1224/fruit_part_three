Add-Type -AssemblyName System.Drawing

function Convert-ToTransparentOutline {
    param(
        [string]$inputPath,
        [string]$outputPath
    )
    if (-not (Test-Path $inputPath)) {
        Write-Warning "File not found: $inputPath"
        return
    }
    
    $src = [System.Drawing.Bitmap]::FromFile($inputPath)
    $w = $src.Width
    $h = $src.Height
    $dest = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $srcData = $src.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $destData = $dest.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    
    $bytes = [Math]::Abs($srcData.Stride) * $h
    $rgbValues = New-Object byte[] $bytes
    [System.Runtime.InteropServices.Marshal]::Copy($srcData.Scan0, $rgbValues, 0, $bytes)
    
    $outValues = New-Object byte[] $bytes
    for ($i = 0; $i -lt $bytes; $i += 4) {
        $b = $rgbValues[$i]
        $g = $rgbValues[$i + 1]
        $r = $rgbValues[$i + 2]
        
        $lum = [int](0.299 * $r + 0.587 * $g + 0.114 * $b)
        if ($lum -ge 242) {
            $outValues[$i] = 0
            $outValues[$i + 1] = 0
            $outValues[$i + 2] = 0
            $outValues[$i + 3] = 0
        } else {
            $alpha = [Math]::Min(255, [int]((255 - $lum) * 1.5))
            # Deep navy outline #1E1F3B
            $outValues[$i] = 59
            $outValues[$i + 1] = 31
            $outValues[$i + 2] = 30
            $outValues[$i + 3] = [byte]$alpha
        }
    }
    
    [System.Runtime.InteropServices.Marshal]::Copy($outValues, 0, $destData.Scan0, $bytes)
    $src.UnlockBits($srcData)
    $dest.UnlockBits($destData)
    $src.Dispose()
    
    $dest.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $dest.Dispose()
    Write-Output "Successfully converted $inputPath -> $outputPath"
}

$images = Get-ChildItem -Path "e:\fruit_colouring\assets\images" -Filter "*.jpg"
foreach ($img in $images) {
    $outName = [System.IO.Path]::ChangeExtension($img.FullName, ".png")
    Convert-ToTransparentOutline -inputPath $img.FullName -outputPath $outName
}
