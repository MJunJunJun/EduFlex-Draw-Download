param(
    [string]$PackagePath,
    [Security.SecureString]$Password,
    [switch]$VerifyOnly,
    [switch]$LibraryOnly
)
$ErrorActionPreference = 'Stop'

function Get-PackageKeys([Security.SecureString]$Secret, [byte[]]$Salt) {
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret)
    try {
        $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
        $derive = New-Object Security.Cryptography.Rfc2898DeriveBytes($plain, $Salt, 200000)
        try { return ,$derive.GetBytes(64) } finally { $derive.Dispose(); $plain = $null }
    } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
}

function Protect-Package([byte[]]$Data, [Security.SecureString]$Secret) {
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    $salt = New-Object byte[] 16
    $iv = New-Object byte[] 16
    $rng.GetBytes($salt); $rng.GetBytes($iv); $rng.Dispose()
    $keys = Get-PackageKeys $Secret $salt
    $aes = [Security.Cryptography.Aes]::Create()
    $aes.Key = [byte[]]$keys[0..31]; $aes.IV = $iv
    try {
        $transform = $aes.CreateEncryptor()
        try { $cipher = $transform.TransformFinalBlock($Data, 0, $Data.Length) }
        finally { $transform.Dispose() }
    } finally { $aes.Dispose() }
    $body = [byte[]]([Text.Encoding]::ASCII.GetBytes('EDUFLEX1') + $salt + $iv + $cipher)
    $mac = New-Object Security.Cryptography.HMACSHA256
    $mac.Key = [byte[]]$keys[32..63]
    try { return ,([byte[]]($body + $mac.ComputeHash($body))) }
    finally { $mac.Dispose(); [Array]::Clear($keys, 0, $keys.Length) }
}

function Unprotect-Package([byte[]]$Data, [Security.SecureString]$Secret) {
    if ($Data.Length -lt 88 -or [Text.Encoding]::ASCII.GetString($Data, 0, 8) -ne 'EDUFLEX1' -or (($Data.Length - 72) % 16) -ne 0) {
        throw 'Format paket tidak valid.'
    }
    $keys = Get-PackageKeys $Secret ([byte[]]$Data[8..23])
    try {
        $mac = New-Object Security.Cryptography.HMACSHA256
        $mac.Key = [byte[]]$keys[32..63]
        try { $expected = $mac.ComputeHash($Data, 0, $Data.Length - 32) }
        finally { $mac.Dispose() }
        $difference = 0
        for ($i = 0; $i -lt 32; $i++) { $difference = $difference -bor ($expected[$i] -bxor $Data[$Data.Length - 32 + $i]) }
        if ($difference -ne 0) { throw 'Password salah atau paket telah berubah.' }
        $aes = [Security.Cryptography.Aes]::Create()
        $aes.Key = [byte[]]$keys[0..31]; $aes.IV = [byte[]]$Data[24..39]
        try {
            $transform = $aes.CreateDecryptor()
            try { return ,$transform.TransformFinalBlock($Data, 40, $Data.Length - 72) }
            finally { $transform.Dispose() }
        } finally { $aes.Dispose() }
    } finally { [Array]::Clear($keys, 0, $keys.Length) }
}

if ($LibraryOnly) { return }
$folder = Join-Path $env:TEMP ('EduFlex-' + [guid]::NewGuid().ToString('N'))
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if (!$Password) { $Password = Read-Host 'Masukkan password instal EduFlex Draw' -AsSecureString }
    if ($Password.Length -eq 0) { throw 'Password tidak boleh kosong.' }
    New-Item -ItemType Directory -Path $folder | Out-Null
    if (!$PackagePath) {
        $PackagePath = Join-Path $folder 'installer.eduflex'
        Write-Host 'Mengunduh paket installer...'
        Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/MJunJunJun/EduFlex-Draw-Download/releases/download/v1.0.0.2/installer.eduflex' -OutFile $PackagePath
    }
    $installer = Join-Path $folder 'EduFlex-Draw-Setup.exe'
    $decoded = Unprotect-Package ([IO.File]::ReadAllBytes($PackagePath)) $Password
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $actual = [BitConverter]::ToString($sha.ComputeHash($decoded)).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
    if ($actual -ne '482790b75eb34230dbc4963a64acab3caf34aa506ba02d61e4dd1a011d4fb540') { throw 'Checksum installer tidak cocok.' }
    if ($VerifyOnly) { Write-Host 'PASS: password, integritas paket, dan checksum installer.'; return }
    [IO.File]::WriteAllBytes($installer, $decoded)
    [Array]::Clear($decoded, 0, $decoded.Length)
    Write-Host 'Password benar. Membuka installer...'
    $process = Start-Process -FilePath $installer -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw ('Installer selesai dengan kode ' + $process.ExitCode) }
} catch {
    Write-Host ('Gagal: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    if (Test-Path -LiteralPath $folder) { Remove-Item -LiteralPath $folder -Recurse -Force }
}
