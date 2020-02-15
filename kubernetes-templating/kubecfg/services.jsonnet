
local kube = import "https://github.com/bitnami-labs/kube-libsonnet/raw/52ba963ca44f7a4960aeae9ee0fbee44726e481f/kube.libsonnet";
local common(name) = {

  service: kube.Service(name) {
    target_pod:: $.deployment.spec.template,
  },

  deployment: kube.Deployment(name) {
    spec+: {
      template+: {
        spec+: {
          containers_: {
            common: kube.Container("common") {
              env: [{name: "PORT", value: "50051"}],
              ports: [{containerPort: 50051}],
              securityContext: {
                readOnlyRootFilesystem: true,
                runAsNonRoot: true,
                runAsUser: 10001,
              },
              readinessProbe: {
                  initialDelaySeconds: 20,
                  periodSeconds: 15,
                  exec: {
                      command: [
                          "/bin/grpc_health_probe",
                          "-addr=:50051",
                      ],
                  },
              },
              livenessProbe: {
                  initialDelaySeconds: 20,
                  periodSeconds: 15,
                  exec: {
                      command: [
                          "/bin/grpc_health_probe",
                          "-addr=:50051",
                      ],
}}}}}}}}};

{
    shippingservice: common("shippingservice") {
        deployment+: {
            spec+: {
                template+: {
                    spec+: {
                        containers_+: {
                            common+: {
                                name: "server",
                                image: "gcr.io/google-samples/microservices-demo/shippingservice:v0.1.3",
                                resources: {
                                    requests: { cpu: "100m", memory: "64Mi"},
                                    limits: { cpu: "200m", memory: "128Mi"},
    }}}}}}}},
    paymentservice: common("paymentservice") {
        deployment+: {
            spec+: {
                template+: {
                    spec+: {
                        containers_+: {
                            common+: {
                                name: "server",
                                image: "gcr.io/google-samples/microservices-demo/paymentservice:v0.1.3",
                                resources: {
                                    requests: { cpu: "100m", memory: "64Mi"},
                                    limits: { cpu: "200m", memory: "128Mi"},
    }}}}}}}},
}
