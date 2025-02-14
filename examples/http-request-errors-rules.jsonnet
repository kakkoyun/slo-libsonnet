local slo = import '../slo-libsonnet/slo.libsonnet';

{
local errors = slo.errors({
  metric: 'promhttp_metric_handler_requests_total',
  selectors: 'namespace="default",job="fooapp"',

  warning: 5,  // 5% of total requests
  critical: 10,  // 10% of total requests
}),

// Output these as example
recordingrule: errors.recordingrule,
alerts: [
  errors.alertWarning,
  errors.alertCritical,
],
}
