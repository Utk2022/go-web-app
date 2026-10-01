package main

import (
	"encoding/json"
	"log"
	"net/http"
)

func homePage(w http.ResponseWriter, r *http.Request) {
	// Render the home HTML page from the static folder.
	http.ServeFile(w, r, "static/home.html")
}

func coursePage(w http.ResponseWriter, r *http.Request) {
	// Render the courses HTML page.
	http.ServeFile(w, r, "static/courses.html")
}

func aboutPage(w http.ResponseWriter, r *http.Request) {
	// Render the about HTML page.
	http.ServeFile(w, r, "static/about.html")
}

func contactPage(w http.ResponseWriter, r *http.Request) {
	// Render the contact HTML page.
	http.ServeFile(w, r, "static/contact.html")
}

// healthzHandler reports whether the application process is alive.
//
// This endpoint is intentionally lightweight and does not check
// external dependencies.
func healthzHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	_ = json.NewEncoder(w).Encode(map[string]string{
		"status": "ok",
	})
}

// readyzHandler reports whether the application is ready to receive traffic.
//
// At this stage the application has no external dependencies,
// so readiness is always successful.
func readyzHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	_ = json.NewEncoder(w).Encode(map[string]string{
		"status": "ready",
	})
}

func main() {
	// Create the application metrics registry.
	metrics := NewAppMetrics()

	// Create an application-specific HTTP mux.
	mux := http.NewServeMux()

	// Application endpoints.
	mux.Handle(
		"/home",
		metrics.Instrument(
			"/home",
			http.HandlerFunc(homePage),
		),
	)

	mux.Handle(
		"/courses",
		metrics.Instrument(
			"/courses",
			http.HandlerFunc(coursePage),
		),
	)

	mux.Handle(
		"/about",
		metrics.Instrument(
			"/about",
			http.HandlerFunc(aboutPage),
		),
	)

	mux.Handle(
		"/contact",
		metrics.Instrument(
			"/contact",
			http.HandlerFunc(contactPage),
		),
	)

	// Health/readiness endpoints are also application endpoints,
	// so we instrument them as well.
	mux.Handle(
		"/healthz",
		metrics.Instrument(
			"/healthz",
			http.HandlerFunc(healthzHandler),
		),
	)

	mux.Handle(
		"/readyz",
		metrics.Instrument(
			"/readyz",
			http.HandlerFunc(readyzHandler),
		),
	)

	// Prometheus scrape endpoint.
	//
	// IMPORTANT:
	// We intentionally do not instrument /metrics with the application
	// request metrics. Otherwise Prometheus scraping itself would
	// continuously generate application request measurements.
	mux.Handle("/metrics", metrics.Handler())

	server := &http.Server{
		Addr:    "0.0.0.0:8080",
		Handler: mux,
	}

	log.Println("server listening on :8080")

	if err := server.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}
