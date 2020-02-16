
// this file has the baseline default parameters
// baseline environment called _ that can be used
// for commands that operate locally and do not affect a cluster.
// These commands include show, as well as the component and param subcommands.
{
  components: {
    generic: {
      name: 'generic',
      replicas: 1,
      serviceType: 'ClusterIP',
    },
  },
}
