
// this file has the param overrides for the default environment
local base = import './base.libsonnet';

base {
  components +: {
    generic +: {
      name: 'adservice',
      image: 'gcr.io/google-samples/microservices-demo/adservice:v0.1.3',
      containerPort: 9555,
      readinessProbe: ["/bin/grpc_health_probe", "-addr=:9555"],
      livenessProbe: ["/bin/grpc_health_probe", "-addr=:9555"],
      serviceName: 'grpc',
      servicePort: 9555
    },
  }
}
