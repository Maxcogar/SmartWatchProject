#!/usr/bin/env pwsh
param()

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildDir = Join-Path $ScriptDir "build"
if (Test-Path $BuildDir) {
    Remove-Item $BuildDir -Recurse -Force
}
cmake -S $ScriptDir -B $BuildDir
cmake --build $BuildDir
ctest --test-dir $BuildDir --output-on-failure
