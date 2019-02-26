#! /bin/sh
set -e

mknod /dev/fuse c 10 229 || true
mkdir -p /home/site/wwwroot || true
export PATH=$PATH:/squashfuse

dotnet /azure-functions-host/Microsoft.Azure.WebJobs.Script.WebHost.dll
