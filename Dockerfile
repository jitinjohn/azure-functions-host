FROM microsoft/dotnet:2.2-sdk AS installer-env

ENV PublishWithAspNetCoreTargetManifest false

COPY . /workingdir

RUN cd workingdir && \
    dotnet build WebJobs.Script.sln && \
    dotnet publish src/WebJobs.Script.WebHost/WebJobs.Script.WebHost.csproj --output /azure-functions-host

# Runtime image
# FROM microsoft/dotnet:2.2-aspnetcore-runtime
FROM mcr.microsoft.com/azure-functions/mesh:2.0.12410

RUN mv /azure-functions-host/workers /workers

COPY --from=installer-env ["/azure-functions-host", "/azure-functions-host"]

COPY ./run.sh /run.sh

RUN rm -rf /azure-functions-host/workers && \
    mv /workers /azure-functions-host/ && \
    chmod +x /run.sh

CMD /run.sh
