using Confluent.Kafka;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Extensions.Kafka;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.IO;

namespace EventHubContainerFunction
{
    public class SendMessageToPipeline
    {
        private readonly IProducer<Null, string> _kafkaProducer;

        public SendMessageToPipeline(IProducer<Null, string> kafkaProducer)
        {
            _kafkaProducer = kafkaProducer;
        }

        [FunctionName("SendMessageToPipeline")]
        public IActionResult Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = null)] HttpRequest req,
#if DEBUG_KAFKA
            [Kafka(
                brokerList: "%Kafka:BrokerList%",
                topic: "%Kafka:TopicName%",
                Username = "%Kafka:Username%",
                Password = "%Kafka:Password%",
                Protocol = BrokerProtocol.Plaintext,
                AuthenticationMode = BrokerAuthenticationMode.NotSet)]
#else
            [Kafka(
                brokerList: "%EventHub:BrokerList%",
                topic: "%EventHub:TopicName%",
                Username = "%EventHub:Username%",
                Password = "%EventHub:Password%",
                Protocol = BrokerProtocol.SaslSsl,
                AuthenticationMode = BrokerAuthenticationMode.Plain)]
#endif
                out KafkaEventData<string> eventData,
                ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            string name = req.Query["name"];

            string requestBody = new StreamReader(req.Body).ReadToEnd();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            name = name ?? data?.name;

            string responseMessage = string.IsNullOrEmpty(name)
                ? "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."
                : $"Hello, {name}. This HTTP triggered function executed successfully.";

            eventData = new KafkaEventData<string>(requestBody);
            eventData.Headers.Add("test", System.Text.Encoding.UTF8.GetBytes("dotnet"));

            //_kafkaProducer.ProduceAsync("topic", new Message<Null, string>
            //{
            //    Value = "toto"
            //});

            //_kafkaProducer.Flush();

            return new OkObjectResult(responseMessage);
        }
    }
}
