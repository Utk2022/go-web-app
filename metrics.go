package main

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// AppMetrics contains the application-level Prometheus metrics
// used by the Go web application.
type AppMetrics struct {
	Registry *prometheus.Registry

	HTTPRequestsTotal    *prometheus.CounterVec
	HTTPRequestDuration  *prometheus.HistogramVec
	HTTPRequestsInFlight *prometheus.GaugeVec
}

// NewAppMetrics creates and registers all application-specific metrics.
//
// A custom registry is used intentionally so that Step 2 exposes only
// application metrics. Go runtime and process metrics can be added
// later when we build the complete observability stack.
func NewAppMetrics() *AppMetrics {
	registry := prometheus.NewRegistry()

	httpRequestsTotal := prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "go_web_app_http_requests_total",
			Help: "Total number of HTTP requests processed by the Go web application.",
		},
		[]string{"route", "method", "code"},
	)

	httpRequestDuration := prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name: "go_web_app_http_request_duration_seconds",
			Help: "HTTP request duration in seconds for the Go web application.",
			Buckets: []float64{
				0.005,
				0.01,
				0.025,
				0.05,
				0.1,
				0.25,
				0.5,
				1,
				2.5,
				5,
				10,
			},
		},
		[]string{"route", "method", "code"},
	)

	httpRequestsInFlight := prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "go_web_app_http_requests_in_flight",
			Help: "Current number of HTTP requests being processed by the Go web application.",
		},
		[]string{"route"},
	)

	registry.MustRegister(httpRequestsTotal)
	registry.MustRegister(httpRequestDuration)
	registry.MustRegister(httpRequestsInFlight)

	return &AppMetrics{
		Registry:             registry,
		HTTPRequestsTotal:    httpRequestsTotal,
		HTTPRequestDuration:  httpRequestDuration,
		HTTPRequestsInFlight: httpRequestsInFlight,
	}
}

// Instrument wraps an HTTP handler with Prometheus metrics.
//
// The route is supplied explicitly rather than using r.URL.Path.
// This is important because using arbitrary URL paths as labels can
// create extremely high metric cardinality in production.
func (m *AppMetrics) Instrument(route string, handler http.Handler) http.Handler {
	// Fix the route label at instrumentation time.
	//
	// The remaining labels are "method" and "code", which are supported
	// by the promhttp HTTP instrumentation helpers.
	counter := m.HTTPRequestsTotal.MustCurryWith(
		prometheus.Labels{
			"route": route,
		},
	)

	duration := m.HTTPRequestDuration.MustCurryWith(
		prometheus.Labels{
			"route": route,
		},
	)

	inFlight := m.HTTPRequestsInFlight.WithLabelValues(route)

	// Middleware is applied from inside to outside:
	//
	// Handler
	//   ↓
	// Request counter
	//   ↓
	// Request duration
	//   ↓
	// In-flight requests
	//
	// Each layer records a different operational signal.
	return promhttp.InstrumentHandlerInFlight(
		inFlight,
		promhttp.InstrumentHandlerDuration(
			duration,
			promhttp.InstrumentHandlerCounter(
				counter,
				handler,
			),
		),
	)
}

// Handler returns an HTTP handler that exposes the registered
// application metrics in Prometheus text format.
func (m *AppMetrics) Handler() http.Handler {
	return promhttp.HandlerFor(
		m.Registry,
		promhttp.HandlerOpts{},
	)
}
