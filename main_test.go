package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestMain(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/home", nil)
	rr := httptest.NewRecorder()

	handler := http.HandlerFunc(homePage)
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Fatalf(
			"home handler returned status %d, want %d",
			status,
			http.StatusOK,
		)
	}

	expectedContentType := "text/html; charset=utf-8"

	if contentType := rr.Header().Get("Content-Type"); contentType != expectedContentType {
		t.Fatalf(
			"home handler returned Content-Type %q, want %q",
			contentType,
			expectedContentType,
		)
	}
}

func TestHealthzHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rr := httptest.NewRecorder()

	healthzHandler(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Fatalf(
			"healthz handler returned status %d, want %d",
			status,
			http.StatusOK,
		)
	}

	contentType := rr.Header().Get("Content-Type")

	if !strings.HasPrefix(contentType, "application/json") {
		t.Fatalf(
			"healthz handler returned Content-Type %q, want application/json",
			contentType,
		)
	}

	expectedBody := `{"status":"ok"}`

	actualBody := strings.TrimSpace(rr.Body.String())

	if actualBody != expectedBody {
		t.Fatalf(
			"healthz handler returned body %q, want %q",
			actualBody,
			expectedBody,
		)
	}
}

func TestHealthzHandlerMethodNotAllowed(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/healthz", nil)
	rr := httptest.NewRecorder()

	healthzHandler(rr, req)

	if status := rr.Code; status != http.StatusMethodNotAllowed {
		t.Fatalf(
			"healthz handler returned status %d for POST, want %d",
			status,
			http.StatusMethodNotAllowed,
		)
	}
}

func TestReadyzHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/readyz", nil)
	rr := httptest.NewRecorder()

	readyzHandler(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Fatalf(
			"readyz handler returned status %d, want %d",
			status,
			http.StatusOK,
		)
	}

	contentType := rr.Header().Get("Content-Type")

	if !strings.HasPrefix(contentType, "application/json") {
		t.Fatalf(
			"readyz handler returned Content-Type %q, want application/json",
			contentType,
		)
	}

	expectedBody := `{"status":"ready"}`

	actualBody := strings.TrimSpace(rr.Body.String())

	if actualBody != expectedBody {
		t.Fatalf(
			"readyz handler returned body %q, want %q",
			actualBody,
			expectedBody,
		)
	}
}

func TestReadyzHandlerMethodNotAllowed(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/readyz", nil)
	rr := httptest.NewRecorder()

	readyzHandler(rr, req)

	if status := rr.Code; status != http.StatusMethodNotAllowed {
		t.Fatalf(
			"readyz handler returned status %d for POST, want %d",
			status,
			http.StatusMethodNotAllowed,
		)
	}
}

func TestApplicationMetrics(t *testing.T) {
	metrics := NewAppMetrics()

	// Wrap the existing home handler with application metrics.
	instrumentedHandler := metrics.Instrument(
		"/home",
		http.HandlerFunc(homePage),
	)

	req := httptest.NewRequest(http.MethodGet, "/home", nil)
	rr := httptest.NewRecorder()

	instrumentedHandler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Fatalf(
			"instrumented home handler returned status %d, want %d",
			status,
			http.StatusOK,
		)
	}

	// Gather all metrics from our custom registry.
	metricFamilies, err := metrics.Registry.Gather()

	if err != nil {
		t.Fatalf("failed to gather application metrics: %v", err)
	}

	var (
		foundRequestCounter   bool
		foundRequestHistogram bool
		foundInFlightGauge    bool
	)

	for _, family := range metricFamilies {
		switch family.GetName() {
		case "go_web_app_http_requests_total":
			foundRequestCounter = true

		case "go_web_app_http_request_duration_seconds":
			foundRequestHistogram = true

		case "go_web_app_http_requests_in_flight":
			foundInFlightGauge = true
		}
	}

	if !foundRequestCounter {
		t.Error("HTTP request counter metric was not registered")
	}

	if !foundRequestHistogram {
		t.Error("HTTP request duration metric was not registered")
	}

	if !foundInFlightGauge {
		t.Error("HTTP in-flight gauge metric was not registered")
	}
}

func TestMetricsEndpoint(t *testing.T) {
	metrics := NewAppMetrics()

	instrumentedHandler := metrics.Instrument(
		"/home",
		http.HandlerFunc(homePage),
	)

	// Generate at least one application request so that the metrics
	// contain actual samples.
	req := httptest.NewRequest(http.MethodGet, "/home", nil)
	rr := httptest.NewRecorder()

	instrumentedHandler.ServeHTTP(rr, req)

	// Expose the metrics through the /metrics handler.
	metricsHandler := metrics.Handler()

	metricsReq := httptest.NewRequest(http.MethodGet, "/metrics", nil)
	metricsRR := httptest.NewRecorder()

	metricsHandler.ServeHTTP(metricsRR, metricsReq)

	if status := metricsRR.Code; status != http.StatusOK {
		t.Fatalf(
			"metrics endpoint returned status %d, want %d",
			status,
			http.StatusOK,
		)
	}

	body := metricsRR.Body.String()

	expectedMetrics := []string{
		"go_web_app_http_requests_total",
		"go_web_app_http_request_duration_seconds",
		"go_web_app_http_requests_in_flight",
	}

	for _, metricName := range expectedMetrics {
		if !strings.Contains(body, metricName) {
			t.Errorf(
				"metrics endpoint response does not contain %q",
				metricName,
			)
		}
	}
}
