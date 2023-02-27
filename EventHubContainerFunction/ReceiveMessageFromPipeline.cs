using EventHubContainerFunction.Models;
using EventHubContainerFunction.Sql;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Kafka;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using System.Threading.Tasks;

namespace EventHubContainerFunction
{
    public class ReceiveMessageFromPipeline
    {
        private readonly UserDbContext _userDbContext;

        public ReceiveMessageFromPipeline(UserDbContext userDbContext)
        {
            _userDbContext = userDbContext;
        }

        [FunctionName("ReceiveMessageFromPipeline")]
        public async Task Run(
#if DEBUG_KAFKA
            [KafkaTrigger(
                brokerList: "%Kafka:BrokerList%",
                topic: "%Kafka:TopicName%",
                Username = "%Kafka:Username%",
                Password = "%Kafka:Password%",
                Protocol = BrokerProtocol.Plaintext,
                AuthenticationMode = BrokerAuthenticationMode.NotSet,
                ConsumerGroup ="$Default")]
#else
            [KafkaTrigger(
                brokerList: "%EventHub:BrokerList%",
                topic: "%EventHub:TopicName%",
                Username = "%EventHub:Username%",
                Password = "%EventHub:Password%",
                Protocol = BrokerProtocol.SaslSsl,
                AuthenticationMode = BrokerAuthenticationMode.Plain,
                ConsumerGroup ="$Default")]
#endif
            KafkaEventData<string>[] events,
            ILogger log)
        {
            foreach (KafkaEventData<string> kevent in events)
            {
                log.LogInformation($"C# Kafka trigger function processed a message: {kevent.Value}");
                var json = JsonSerializer.Deserialize<User>(kevent.Value);
                await _userDbContext.AddAsync(new UserEntity
                {
                    UserName = json.UserName
                });
            }

            await _userDbContext.SaveChangesAsync();
        }
    }
}
