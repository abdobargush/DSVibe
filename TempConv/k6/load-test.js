import grpc from "k6/net/grpc";
import { check, sleep } from "k6";

const client = new grpc.Client();
client.load(["../backend/proto"], "temperature.proto");

export const options = {
  stages: [
    { duration: "30s", target: 20 }, // Ramp up to 20 users
    { duration: "1m", target: 20 }, // Stay at 20 users
    { duration: "30s", target: 50 }, // Ramp up to 50 users
    { duration: "1m", target: 50 }, // Stay at 50 users
    { duration: "30s", target: 0 }, // Ramp down to 0 users
  ],
  thresholds: {
    "grpc_req_duration": ["p(95)<500"], // 95% of requests must complete below 500ms
    "grpc_req_failed": ["rate<0.01"], // Error rate must be below 1%
  },
};

export default function () {
  // Get the external IP from environment or use default
  const host = __ENV.ENVOY_HOST || "localhost:8080";

  client.connect(host, {
    plaintext: true,
  });

  // Test Celsius to Fahrenheit conversion
  const celsiusRequest = {
    value: Math.random() * 100,
  };

  const celsiusResponse = client.invoke(
    "temperature.TemperatureConverter/ConvertToFahrenheit",
    celsiusRequest,
  );

  check(celsiusResponse, {
    "celsius conversion status is OK": (r) => r && r.status === grpc.StatusOK,
  });

  // Test Fahrenheit to Celsius conversion
  const fahrenheitRequest = {
    value: Math.random() * 200,
  };

  const fahrenheitResponse = client.invoke(
    "temperature.TemperatureConverter/ConvertToCelsius",
    fahrenheitRequest,
  );

  check(fahrenheitResponse, {
    "fahrenheit conversion status is OK": (r) =>
      r && r.status === grpc.StatusOK,
  });

  client.close();
  sleep(1);
}
