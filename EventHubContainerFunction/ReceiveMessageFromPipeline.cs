using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Kafka;
using Microsoft.Extensions.Logging;

namespace EventHubContainerFunction
{
    public class ReceiveMessageFromPipeline
    {
        [FunctionName("ReceiveMessageFromPipeline")]
        public void Run(
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
            }
        }
    }
}
