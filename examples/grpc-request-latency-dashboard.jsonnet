local slo = import '../slo-libsonnet/slo_grpc.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local prometheus = grafana.prometheus;

local latency = slo.latency({
  metric: 'grpc_server_handling_seconds',
  selectors: 'grpc_type="unary",namespace="default",job="fooapp"',
  quantile: 0.99,

  warning: 0.500,  // 500ms
  critical: 1.0,  // 1s
});

dashboard.new(
  'Request Latency',
  time_from='now-1h',
).addTemplate(
  {
    current: {
      text: 'Prometheus',
      value: 'Prometheus',
    },
    hide: 0,
    label: null,
    name: 'datasource',
    options: [],
    query: 'prometheus',
    refresh: 1,
    regex: '',
    type: 'datasource',
  },
).addRow(
  row.new()
  .addPanel(latency.grafana.gauge)
  .addPanel(latency.grafana.graph)
)
