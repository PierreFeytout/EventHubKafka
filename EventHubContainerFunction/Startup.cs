using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using System.IO;
using Confluent.Kafka;
using Microsoft.Extensions.DependencyInjection;
using System.Collections.Generic;

[assembly: FunctionsStartup(typeof(EventHubContainerFunction.Startup))]
namespace EventHubContainerFunction
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            builder.Services.AddSingleton<IProducer<Null,string>>((sp) =>
            {
                var configuration = sp.GetRequiredService<IConfiguration>();
#if DEBUG_KAFKA
                var section = configuration.GetSection("Kafka");
#else
                var section = configuration.GetSection("EventHub");
#endif
                var conf = new ProducerConfig {
                    BootstrapServers = section.GetValue<string>("BrokerList"),
                    SaslUsername = section.GetValue<string>("Username"),
                    SaslPassword = section.GetValue<string>("Password"),
                    SecurityProtocol = SecurityProtocol.SaslSsl,
                    SaslMechanism = SaslMechanism.Plain
                };
                var producerBuilder = new ProducerBuilder<Null, string>(conf);

                return producerBuilder.Build();
            });
        }

        public override void ConfigureAppConfiguration(IFunctionsConfigurationBuilder builder)
        {
            var context = builder.GetContext();

#if DEBUG_KAFKA
            builder.ConfigurationBuilder.AddJsonFile(Path.Combine(context.ApplicationRootPath, "appsettings.kafka.json"));
#endif
        }
    }
}
