{
  port: 8125,
  mgmt_port: 8126,

  graphitePort: 2003,
  graphiteHost: "127.0.0.1",
  flushInterval: 1000,
  deleteIdleStats: true,

  backends: ['./backends/graphite'],
  graphite: {
    legacyNamespace: false,
    globalPrefix: "",
    prefixCounter: "",
    prefixTimer: "",
    prefixGauge: "",
    prefixSet: ""
  }
}
