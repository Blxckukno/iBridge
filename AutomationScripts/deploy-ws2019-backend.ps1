param(
    [string]$VmName = "iBridge-WS2019-Backend",
    [string]$VmPath = "D:\HyperV\iBridge-WS2019-Backend",
    [string]$VhdPath = "D:\HyperV\iBridge-WS2019-Backend\osdisk.vhdx",
    [string]$IsoPath = "D:\ISO\Windows_Server_2019.iso",
    [string]$SwitchName = "Default Switch",
    [int]$MemoryStartupGB = 8,
    [int]$VhdSizeGB = 160,
    [int]$CpuCount = 4
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
        IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        throw "Run this script as Administrator."
    }
}

function Assert-HyperV {
    if (-not (Get-Command Get-VM -ErrorAction SilentlyContinue)) {
        throw "Hyper-V PowerShell module is not available. Enable Hyper-V first."
    }
}

Assert-Admin
Assert-HyperV

if (-not (Test-Path $IsoPath)) {
    throw "Windows Server 2019 ISO not found: $IsoPath"
}

if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
    throw "Hyper-V switch '$SwitchName' not found. Create it first."
}

if (-not (Test-Path $VmPath)) {
    New-Item -Path $VmPath -ItemType Directory -Force | Out-Null
}

if (Get-VM -Name $VmName -ErrorAction SilentlyContinue) {
    throw "VM '$VmName' already exists. Choose a different -VmName or remove existing VM."
}

Write-Host "Creating VM: $VmName"
New-VM `
    -Name $VmName `
    -Generation 2 `
    -MemoryStartupBytes (${MemoryStartupGB}GB) `
    -NewVHDPath $VhdPath `
    -NewVHDSizeBytes (${VhdSizeGB}GB) `
    -Path $VmPath `
    -SwitchName $SwitchName | Out-Null

Set-VMProcessor -VMName $VmName -Count $CpuCount
Set-VMMemory -VMName $VmName -DynamicMemoryEnabled $true -MinimumBytes 4GB -MaximumBytes 16GB
Set-VMFirmware -VMName $VmName -EnableSecureBoot On -SecureBootTemplate "MicrosoftWindows"

Add-VMDvdDrive -VMName $VmName -Path $IsoPath | Out-Null

Write-Host "VM created and ISO attached."
Write-Host "Next steps:"
Write-Host "1) Start-VM -Name '$VmName'"
Write-Host "2) Install Windows Server 2019 in the VM."
Write-Host "3) After login inside VM, run: AutomationScripts\configure-ws2019-backend.ps1"
