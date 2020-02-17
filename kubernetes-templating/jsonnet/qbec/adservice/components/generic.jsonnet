local env = {
  name: std.extVar('qbec.io/env'),
  namespace: std.extVar('qbec.io/defaultNs'),
};
local p = import '../params.libsonnet';
local params = p.components.generic;

[
  {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      name: params.name,
      labels: { app: params.name },
    },
    spec: {
      replicas: params.replicas,
      selector: {
        matchLabels: { app: params.name },
      },
      template: {
        metadata: {
          labels: { app: params.name },
        },
        spec: {
          containers: [
            {
              name: 'server',
              image: params.image,
              ports: [
                {
                  containerPort: params.containerPort,
                },
              ],
              env: [
                {
                  name: 'PORT',
                  value: std.format("%d", params.containerPort),
                },
              ],
              readinessProbe: {
                initialDelaySeconds: 20,
                periodSeconds: 15,
                exec: {
                  command: params.readinessProbe,
                },
              },
              livenessProbe: {
                initialDelaySeconds: 20,
                periodSeconds: 15,
                exec: {
                  command: params.readinessProbe,
                },
              },
            },
          ],
        },
      },
    },
  },
  {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: params.name,
    },
    spec: {
      type: params.serviceType,
      selector: { app: params.name },
      ports: [
        {
          name: params.serviceName,
          port: params.servicePort,
          targetPort: params.containerPort,
        },
      ],
    },
  },
]
