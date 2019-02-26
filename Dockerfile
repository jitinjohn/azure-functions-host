FROM microsoft/dotnet:2.2-sdk AS installer-env

ENV PublishWithAspNetCoreTargetManifest false

COPY . /workingdir

RUN cd workingdir && \
    dotnet build WebJobs.Script.sln && \
    dotnet publish src/WebJobs.Script.WebHost/WebJobs.Script.WebHost.csproj --output /azure-functions-host

# Runtime image
# FROM microsoft/dotnet:2.2-aspnetcore-runtime
FROM mcr.microsoft.com/azure-functions/python:2.0

RUN apt-get update && \
    apt-get install -y gnupg && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get update && \
    apt-get install -y git autoconf libtool make gcc libtool libfuse-dev liblzma-dev nodejs archivemount fuse-zip && \
    git clone https://github.com/vasi/squashfuse && \
    cd squashfuse && \
    ./autogen.sh && \
    ./configure && \
    make && \
    mv /azure-functions-host/workers/python /python

COPY --from=installer-env ["/azure-functions-host", "/azure-functions-host"]
COPY ./content.zip /tmp/content.zip
COPY ./run.sh /run.sh

RUN rm -rf /azure-functions-host/workers && \
    mkdir /azure-functions-host/workers && \
    mv /python /azure-functions-host/workers && \
    chmod +x /run.sh

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    HOME=/home \
    ASPNETCORE_URLS=http://+:80 \
    AZURE_FUNCTIONS_ENVIRONMENT=Development \
    FUNCTIONS_WORKER_RUNTIME=

EXPOSE 80

# CMD [ "dotnet", "/azure-functions-host/Microsoft.Azure.WebJobs.Script.WebHost.dll" ]
CMD /run.sh