FROM microsoft/dotnet:2.2-sdk AS installer-env

ENV PublishWithAspNetCoreTargetManifest false

COPY . /workingdir

RUN cd workingdir && \
    dotnet publish src/WebJobs.Script.WebHost/WebJobs.Script.WebHost.csproj --output /azure-functions-host

# Runtime image
# FROM microsoft/dotnet:2.2-aspnetcore-runtime
FROM mcr.microsoft.com/azure-functions/mesh:2.0.12410

RUN mv /azure-functions-host/workers /workers && \
    rm -rf /azure-functions-host && \
    apt-get update && \
    apt-get install -y fuse-zip git build-essential pkg-config autoconf automake \
    libtool liblzma-dev zlib1g-dev liblzo2-dev liblz4-dev libfuse-dev libattr1-dev && \
    git clone --depth 1 https://github.com/vasi/squashfuse && \
    cd squashfuse && \
    ./autogen.sh && \
    ./configure && \
    make

COPY --from=installer-env ["/azure-functions-host", "/azure-functions-host"]

COPY ./run.sh /run.sh

RUN rm -rf /azure-functions-host/workers && \
    mv /workers /azure-functions-host/ && \
    chmod +x /run.sh && \
    wget https://raw.githubusercontent.com/maiqbal11/azure-functions-docker/5437beb94d749c8ae69689e1f80ca8158817382e/host/2.0/stretch/amd64/python-context/start.sh && \
    mv start.sh /azure-functions-host/workers/python && \
    chmod +x /azure-functions-host/workers/python/start.sh && \
    pip uninstall -y azure-functions-worker && \
    pip install git+https://github.com/Azure/azure-functions-python-worker@reload-env-vars

CMD /run.sh