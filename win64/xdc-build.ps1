#REQUIRES -Version 2.0
<#
.SYNOPSIS
    XDC build script for Windows
.DESCRIPTION
    A Powershell script to install dependencies for Windows and build binaries.
    Make sure to run `Set-ExecutionPolicy RemoteSigned` in an Adminisrative Powershell window first.
.NOTES
    File Name      : xdc-build.ps1
    Prerequisite   : PowerShell V2
    Copyright 2019 - XinFin
.EXAMPLE
    .\xdc-build.ps1
#>

<##############################################
  Customize options here
###############################################>

# TODO move to CLI args
# Versions
$vergo = "1.11.5"
$vergeth = "master"

# Directories
$basedir = $env:USERPROFILE
$downloaddir = $env:TEMP
$golangroot = "$basedir\golang"
$gosrcroot = "$basedir\go"
$cygwinroot = "$basedir\cygwin"


<##############################################
  Probably nothing needs to be modified below
###############################################>

Function InstallCygwin ()
{
  # TODO make packages 32-bit aware (if possible?)
  $cygwinpackages = "git,unzip,patch"
  $cygwinmirror = "http://mirror-hk.koddos.net/cygwin/"

  if ($ENV:PROCESSOR_ARCHITECTURE -eq "AMD64") {
    $cygarch = "x86_64"
    $cygwinpackages += ",mingw64-x86_64-gcc-g++"
  } else {
    $cygarch = "x86"
    $cygwinpackages += ",mingw64-i686-gcc-g++"
  }
  $cygwindl = -Join("https://cygwin.com/setup-", $cygarch,".exe")

  # Download
  Write-Host "Downloading Cygwin..." -foreground Black -background Green
  (new-object System.Net.WebClient).DownloadFile($cygwindl,"$downloaddir\cygwin-setup.exe")

  # Install Cygwin & dependencies
  Write-Host "Installing dependencies..." -foreground Black -background Green
  cmd /c "$downloaddir\cygwin-setup.exe --root $cygwinroot --site $cygwinmirror --no-admin --quiet-mode --packages=$cygwinpackages"

  $env:PATH = "$env:PATH;$cygwinroot\bin"
  [Environment]::SetEnvironmentVariable("PATH", $env:PATH, "User")
}

Function InstallGolang($vergo) 
{
  # Finalize paths based on processor architecture
  if ($ENV:PROCESSOR_ARCHITECTURE -eq "AMD64") {
    $goarch = "amd64"
  } else {
    $goarch = "386"
  }
  $golangdl = -Join("https://storage.googleapis.com/golang/go", $vergo, ".windows-", $goarch, ".zip")

  # Download
  Write-Host "Downloading Golang..." -foreground Black -background Green
  (new-object System.Net.WebClient).DownloadFile($golangdl,"$downloaddir\golang.zip")

  # Install Golang
  Write-Host "Extracting Golang..." -foreground Black -background Green
  unzip "$downloaddir\golang.zip" -d $golangroot

  # Set environment variables
  $env:GOROOT = "$golangroot\go"
  $env:GOPATH = $gosrcroot
  [Environment]::SetEnvironmentVariable("GOROOT", $env:GOROOT, "User")
  [Environment]::SetEnvironmentVariable("GOPATH", $env:GOPATH, "User")

  $env:PATH = "$env:PATH;$golangroot\go\bin;$gosrcroot\bin"
  [Environment]::SetEnvironmentVariable("PATH", $env:PATH, "User")

}

Function BuildGeth ($vergeth)
{
  Write-Host "Downloading source..." -foreground Black -background Green
  $packagepath = "github.com/XinFinOrg/XDPoS-TestNet-Apothem"

  # Prepare deps if XDC not previously installed
  if (-Not(Test-Path "$env:GOPATH\src\github.com\ethereum\go-ethereum")) {
    go get github.com/tools/godep
    mkdir -p $env:GOPATH\src\github.com\ethereum\go-ethereum
    git clone https://$packagepath $env:GOPATH\src\github.com\ethereum\go-ethereum
  } 

  # Build
  cd $env:GOPATH/src/github.com/ethereum/go-ethereum
  git fetch origin
  git checkout $vergeth
  Write-Host "Building binary..." -foreground Black -background Green
  go install ./...
}

Function Hacks() {
  Write-Host "Patching..." -foreground Black -background Green

  if ($ENV:PROCESSOR_ARCHITECTURE -eq "AMD64") {
    $gcc = "$cygwinroot\bin\x86_64-w64-mingw32-gcc.exe"
    $includePath = "$cygwinroot\usr\x86_64-w64-mingw32\sys-root\mingw\include"
  } else {
    $gcc = "$cygwinroot\bin\i686-w64-mingw32-gcc.exe"
    $includePath = "$cygwinroot\usr\i686-w64-mingw32\sys-root\mingw\include"
  }

  # Make gcc available as gcc.exe
  # Prefer mklink, but that requires elevated privledges
  if (-Not(Test-Path "$cygwinroot\bin\gcc.exe")) {
    copy $gcc "$cygwinroot\bin\gcc.exe"
  }

  # Patch bug http://sourceforge.net/p/mingw-w64/bugs/476/
  $patchFile = "shlobj.patch"
  
  if (-Not (Test-Path (-Join($includePath, "\", $patchFile)))) {
    $patchContent = @"
--- "a/shlobj.h"
+++ "b/shlobj.h"
@@ -34,8 +34,6 @@ typedef enum {
   SHGFP_TYPE_DEFAULT = 1,
 } SHGFP_TYPE;

-  SHFOLDERAPI SHGetFolderPathW (HWND hwnd, int csidl, HANDLE hToken, DWORD dwFlags, LPWSTR pszPath);
-
 #endif

 #if WINAPI_FAMILY_PARTITION (WINAPI_PARTITION_DESKTOP)
@@ -718,6 +716,7 @@ extern "C" {
   SHSTDAPI_(void) SHFlushSFCache (void);

   SHFOLDERAPI SHGetFolderPathA (HWND hwnd, int csidl, HANDLE hToken, DWORD dwFlags, LPSTR pszPath);
+  SHFOLDERAPI SHGetFolderPathW (HWND hwnd, int csidl, HANDLE hToken, DWORD dwFlags, LPWSTR pszPath);
   SHSTDAPI SHGetFolderLocation (HWND hwnd, int csidl, HANDLE hToken, DWORD dwFlags, PIDLIST_ABSOLUTE *ppidl);
   SHSTDAPI SHSetFolderPathA (int csidl, HANDLE hToken, DWORD dwFlags, LPCSTR pszPath);
   SHSTDAPI SHSetFolderPathW (int csidl, HANDLE hToken, DWORD dwFlags, LPCWSTR pszPath);
"@

    # Patch upstream
    cd "$includePath"
    "$patchContent"| Set-Content $patchFile -Encoding ASCII
    Get-Content $patchFile | patch

  }
}

Function CheckDeps() {
  # Install Cygwin if not installed (does not handle upgrades)
  & {
    trap [Management.Automation.CommandNotFoundException] 
    {
      InstallCygwin
      Hacks
      continue
    }
    Write-Host "Checking GCC version" -foreground Black -background Green
    gcc --version
  }

  # Install Golang if not installed (does not handle upgrades)
  & {
    trap [Management.Automation.CommandNotFoundException] 
    {
      InstallGolang($vergo)
      continue
    }
    Write-Host "Checking Golang version" -foreground Black -background Green
    go version
  }
}

CheckDeps
BuildGeth($vergeth)
