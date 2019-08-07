{
  errors(slo):: {
    local recordingrule = {
      expr: 'sum(rate(%s{%s}[10m])) by (grpc_code)' % [slo.metric, slo.selectors],
      record: 'grpc_code:%s:rate:sum' % slo.metric,
    },
    recordingrule: recordingrule,

    alertWarning: {
      expr: '%s{grpc_code!="OK"} * 100 / %s > %s' % [recordingrule.record, recordingrule.record, slo.warning],
      'for': '5m',
      labels: {
        severity: 'warning',
      },
    },

    alertCritical: {
      expr: '%s{grpc_code!="OK"} * 100 / %s > %s' % [recordingrule.record, recordingrule.record, slo.critical],
      'for': '5m',
      labels: {
        severity: 'critical',
      },
    },

    grafana: {
      graph: {
        span: 12,
        aliasColors: {
          Aborted: '#EAB839',
          AlreadyExists: '#7EB26D',
          FailedPrecondition: '#6ED0E0',
          Unimplemented: '#6ED0E0',
          InvalidArgument: '#EF843C',
          NotFound: '#EF843C',
          PermissionDenied: '#EF843C',
          Unauthenticated: '#EF843C',
          Canceled: '#E24D42',
          DataLoss: '#E24D42',
          DeadlineExceeded: '#E24D42',
          Internal: '#E24D42',
          OutOfRange: '#E24D42',
          ResourceExhausted: '#E24D42',
          Unavailable: '#E24D42',
          Unknown: '#E24D42',
          OK: '#7EB26D',
          'error': '#E24D42',
        },
        datasource: '$datasource',
        legend: {
          avg: false,
          current: false,
          max: false,
          min: false,
          show: true,
          total: false,
          values: false,
        },
        targets: [
          {
            expr: '%s' % recordingrule.record,
            format: 'time_series',
            intervalFactor: 2,
            legendFormat: '{{grpc_type}} {{grpc_code}}',
            refId: 'A',
            step: 10,
          },
        ],
        title: 'gRPC Response Codes',
        tooltip: {
          shared: true,
          sort: 0,
          value_type: 'individual',
        },
        type: 'graph',
      },
    },
  },

  latency(slo):: {
    recordingrule(quantile=slo.quantile):: {
      expr: |||
        histogram_quantile(%.2f, sum(rate(%s_bucket{%s}[5m])) by (le))
      ||| % [
        quantile,
        slo.metric,
        slo.selectors,
      ],
      record: '%s:histogram_quantile' % slo.metric,
      labels: {
        quantile: '%.2f' % quantile,
      },
    },

    local _recordingrule = self.recordingrule(),

    alertWarning: {
      expr: '%s > %.3f' % [_recordingrule.record, slo.warning],
      'for': '5m',
      labels: {
        severity: 'warning',
      },
    },

    alertCritical: {
      expr: '%s > %.3f' % [_recordingrule.record, slo.critical],
      'for': '5m',
      labels: {
        severity: 'critical',
      },
    },

    grafana: {
      gauge: {
        type: 'gauge',
        title: 'P99 Latency',
        datasource: '$datasource',
        options: {
          maxValue: '1.5',  // TODO might need to be configurable
          minValue: 0,
          thresholds: [
            {
              color: 'green',
              index: 0,
              value: null,
            },
            {
              color: '#EAB839',
              index: 1,
              value: slo.warning,
            },
            {
              color: 'red',
              index: 2,
              value: slo.critical,
            },
          ],
          valueOptions: {
            decimals: null,
            stat: 'last',
            unit: 'dtdurations',
          },
        },
        targets: [
          {
            expr: '%s{quantile="%.2f"}' % [
              _recordingrule.record,
              slo.quantile,
            ],
            format: 'time_series',
          },
        ],
      },
      graph: {
        type: 'graph',
        title: 'Request Latency',
        datasource: '$datasource',
        targets: [
          {
            expr: 'max(%s) by (quantile)' % _recordingrule.record,
            legendFormat: '{{ quantile }}',
          },
        ],
        yaxes: [
          {
            show: true,
            min: '0',
            max: null,
            format: 's',
            decimals: 1,
          },
          {
            show: false,
          },
        ],
        xaxis: {
          show: true,
          mode: 'time',
          name: null,
          values: [],
          buckets: null,
        },
        yaxis: {
          align: false,
          alignLevel: null,
        },
        lines: true,
        fill: 2,
        span: 12,
        linewidth: 1,
        dashes: false,
        dashLength: 10,
        paceLength: 10,
        points: false,
        pointradius: 2,
        thresholds: [
          {
            value: slo.warning,
            colorMode: 'warning',
            op: 'gt',
            fill: true,
            line: true,
            yaxis: 'left',
          },
          {
            value: slo.critical,
            colorMode: 'critical',
            op: 'gt',
            fill: true,
            line: true,
            yaxis: 'left',
          },
        ],
      },
    },
  },
}
