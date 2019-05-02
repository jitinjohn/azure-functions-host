// Copyright (c) .NET Foundation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

using System;
using System.Globalization;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;
using static Microsoft.Azure.WebJobs.Script.Rpc.LanguageWorkerConstants;

namespace Microsoft.Azure.WebJobs.Script.Configuration
{
    internal class ScriptHostOptionsSetup : IConfigureOptions<ScriptJobHostOptions>
    {
        private readonly IConfiguration _configuration;
        private readonly IEnvironment _environment;
        private readonly IOptions<ScriptApplicationHostOptions> _applicationHostOptions;

        internal static readonly TimeSpan MinFunctionTimeout = TimeSpan.FromSeconds(1);
        internal static readonly TimeSpan DefaultFunctionTimeoutDynamic = TimeSpan.FromMinutes(5);
        internal static readonly TimeSpan MaxFunctionTimeoutDynamic = TimeSpan.FromMinutes(10);
        internal static readonly TimeSpan DefaultFunctionTimeout = TimeSpan.FromMinutes(30);

        public ScriptHostOptionsSetup(IConfiguration configuration, IEnvironment environment, IOptions<ScriptApplicationHostOptions> applicationHostOptions)
        {
            _configuration = configuration;
            _environment = environment;
            _applicationHostOptions = applicationHostOptions;
        }

        public void Configure(ScriptJobHostOptions options)
        {
            // Add the standard built in watched directories set to any the user may have specified
            options.WatchDirectories.Add("node_modules");

            // Set default logging mode
            options.FileLoggingMode = FileLoggingMode.DebugOnly;

            // Bind to all configuration properties
            IConfigurationSection jobHostSection = _configuration.GetSection(ConfigurationSectionNames.JobHost);

            if (jobHostSection != null)
            {
                jobHostSection.Bind(options);

                var fileLoggingMode = jobHostSection.GetSection(ConfigurationSectionNames.Logging)
                    ?.GetValue<FileLoggingMode?>("fileLoggingMode");
                if (fileLoggingMode != null)
                {
                    options.FileLoggingMode = fileLoggingMode.Value;
                }
            }

            // FunctionTimeout
            ConfigureFunctionTimeout(options);

            // If we have a read only file system, override any configuration and
            // disable file watching
            if (_environment.FileSystemIsReadOnly())
            {
                options.FileWatchingEnabled = false;
            }

            // Set the root script path to the value the runtime was initialized with:
            ScriptApplicationHostOptions webHostOptions = _applicationHostOptions.Value;
            options.RootScriptPath = webHostOptions.ScriptPath;
            options.RootLogPath = webHostOptions.LogPath;
            options.IsSelfHost = webHostOptions.IsSelfHost;
            options.TestDataPath = webHostOptions.TestDataPath;
        }

        private void ConfigureFunctionTimeout(ScriptJobHostOptions options)
        {
            if (options.FunctionTimeout != null)
            {
                ValidateTimeoutValue(options, options.FunctionTimeout);
            }
            else
            {
                options.FunctionTimeout = _environment.IsDynamic() ? DefaultFunctionTimeoutDynamic : DefaultFunctionTimeout;
            }
        }

        private void ValidateTimeoutValue(ScriptJobHostOptions options, TimeSpan? timeoutValue)
        {
            if (timeoutValue != null)
            {
                var maxTimeout = TimeSpan.MaxValue;
                if (_environment.IsDynamic())
                {
                    maxTimeout = MaxFunctionTimeoutDynamic;
                }
                if (timeoutValue < MinFunctionTimeout || timeoutValue > maxTimeout)
                {
                    string message = $"{nameof(options.FunctionTimeout)} must be greater than {MinFunctionTimeout} and less than {maxTimeout}.";
                    throw new ArgumentException(message);
                }
            }
        }
    }
}
