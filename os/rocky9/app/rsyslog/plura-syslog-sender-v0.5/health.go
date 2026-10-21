// Readiness is an active, nonce-verified trip through the real TCP listener,
// rsyslog ruleset and the SAME omprog action queue as customer events.
// A distinct daemon avoids the lazy-start deadlock of an HTTP server inside an
// omprog child (which may not be launched until the first accepted message).
package main

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http"
	"net/netip"
	"os"
	"os/signal"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
)

const healthApp = "plura-health"
const healthSDID = "pluraHealth@32473"

type HealthConfig struct {
	NodeID         string   `json:"nodeId"`
	ListenAddress  string   `json:"listenAddress"`
	AllowedPeerIPs []string `json:"allowedPeerIps"`
	ProbeAddress   string   `json:"probeAddress"`
	ProbeSourceIP  string   `json:"probeSourceIp"`
	AckSocket      string   `json:"ackSocket"`
	DrainFile      string   `json:"drainFile"`
	IntervalMS     int      `json:"intervalMs"`
	TimeoutMS      int      `json:"timeoutMs"`
	StaleMS        int      `json:"staleMs"`
}

func loadHealthConfig(path string) (HealthConfig, error) {
	c := HealthConfig{IntervalMS: 2000, TimeoutMS: 1500, StaleMS: 6000}
	b, err := os.ReadFile(path)
	if err != nil {
		return c, err
	}
	if len(b) > 65536 {
		return c, errors.New("health config too large")
	}
	if err := decodeStrict(b, &c); err != nil {
		return c, err
	}
	return c, c.validate()
}
func (c HealthConfig) validate() error {
	if c.NodeID == "" || len(c.NodeID) > 64 || strings.ContainsAny(c.NodeID, " \r\n\t") {
		return errors.New("invalid nodeId")
	}
	for _, a := range []string{c.ListenAddress, c.ProbeAddress} {
		ap, e := netip.ParseAddrPort(a)
		if e != nil || ap.Port() == 0 || ap.Addr().IsUnspecified() || ap.Addr().Zone() != "" {
			return errors.New("use a specific IP:port, not wildcard or hostname")
		}
	}
	src, e := netip.ParseAddr(c.ProbeSourceIP)
	if e != nil || src.Zone() != "" || src.Is4In6() {
		return errors.New("invalid probeSourceIp")
	}
	dst, _ := netip.ParseAddrPort(c.ProbeAddress)
	if dst.Addr() != src {
		return errors.New("probeAddress must use this node's probeSourceIp")
	}
	if len(c.AllowedPeerIPs) == 0 {
		return errors.New("allowedPeerIps required")
	}
	for _, ip := range c.AllowedPeerIPs {
		a, e := netip.ParseAddr(ip)
		if e != nil || a.Zone() != "" || a.Is4In6() {
			return errors.New("invalid allowedPeerIps")
		}
	}
	if !filepath.IsAbs(c.AckSocket) || len(c.AckSocket) > 100 || !filepath.IsAbs(c.DrainFile) {
		return errors.New("invalid runtime socket/drain path")
	}
	if c.IntervalMS < 200 || c.IntervalMS > 60000 || c.TimeoutMS < 100 || c.TimeoutMS > 30000 || c.StaleMS < c.IntervalMS+c.TimeoutMS || c.StaleMS > 120000 {
		return errors.New("invalid health timing")
	}
	return nil
}

// Accept ONLY the synthetic probe app from the configured local source. The
// callback path is local configuration, NEVER taken from untrusted log data.
func acknowledgeHealthProbe(env Envelope, c Config) error {
	if c.HealthAckSocket == "" || env.Source != c.HealthProbeSourceIP || env.App != healthApp {
		return permanent("health_source_not_allowed")
	}
	if len(env.Raw) > 1024 {
		return permanent("invalid_health_probe")
	}
	parts := strings.SplitN(env.Raw, " ", 7)
	if len(parts) != 7 || parts[0] != "<134>1" || parts[3] != healthApp || parts[4] != "-" || parts[5] != "-" {
		return permanent("invalid_health_probe")
	}
	next, id, params, err := parseSD(parts[6], 0)
	if err != nil || id != healthSDID || next != len(parts[6]) || len(params) != 1 {
		return permanent("invalid_health_probe")
	}
	nonce := params["nonce"]
	decoded, err := hex.DecodeString(nonce)
	if err != nil || len(decoded) != 32 || hex.EncodeToString(decoded) != nonce {
		return permanent("invalid_health_nonce")
	}
	conn, err := net.DialTimeout("unixgram", c.HealthAckSocket, 200*time.Millisecond)
	if err != nil {
		return transient("health_callback_unavailable", err)
	}
	defer conn.Close()
	if err := conn.SetWriteDeadline(time.Now().Add(200 * time.Millisecond)); err != nil {
		return transient("health_callback_deadline", err)
	}
	if n, err := conn.Write([]byte(nonce)); err != nil || n != len(nonce) {
		return transient("health_callback_write", err)
	}
	return nil
}

type readiness struct {
	mu          sync.RWMutex
	lastCheck   time.Time
	lastSuccess time.Time
	ok          bool
	reason      string
}

func (r *readiness) update(err error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.lastCheck = time.Now()
	r.ok = err == nil
	if err == nil {
		r.lastSuccess = r.lastCheck
		r.reason = "ready"
	} else {
		r.reason = "pipeline_probe_failed"
	}
}
func (r *readiness) handler(c HealthConfig) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		host, _, err := net.SplitHostPort(req.RemoteAddr)
		allowed := false
		for _, ip := range c.AllowedPeerIPs {
			if host == ip {
				allowed = true
				break
			}
		}
		if err != nil || !allowed {
			http.Error(w, "forbidden", http.StatusForbidden)
			return
		}
		if req.Method != http.MethodGet {
			http.Error(w, "GET required", http.StatusMethodNotAllowed)
			return
		}
		if req.URL.Path != "/ready" && req.URL.Path != "/live" {
			http.NotFound(w, req)
			return
		}
		r.mu.RLock()
		ok, check, lastSuccess, reason := r.ok, r.lastCheck, r.lastSuccess, r.reason
		r.mu.RUnlock()
		if check.IsZero() {
			ok = false
			reason = "starting"
		} else if time.Since(check) > ms(c.StaleMS) {
			ok = false
			reason = "stale"
		}
		if _, err := os.Stat(c.DrainFile); err == nil {
			ok = false
			reason = "draining"
		} else if !os.IsNotExist(err) {
			ok = false
			reason = "drain_check_failed"
		}
		status := http.StatusServiceUnavailable
		if ok || req.URL.Path == "/live" {
			status = http.StatusOK
		}
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Cache-Control", "no-store")
		w.WriteHeader(status)
		_ = json.NewEncoder(w).Encode(map[string]any{"node": c.NodeID, "ready": ok, "reason": reason, "lastCheck": check, "lastSuccess": lastSuccess, "customerDeliveryChecked": false})
	})
}

// Bounded synchronous probe. Old acknowledgements cannot make a new probe pass.
func pipelineProbe(c HealthConfig, ack *net.UnixConn) error {
	token := make([]byte, 32)
	if _, err := rand.Read(token); err != nil {
		return err
	}
	nonce := hex.EncodeToString(token)
	deadline := time.Now().Add(ms(c.TimeoutMS))
	raw := fmt.Sprintf("<134>1 %s %s %s - - [%s nonce=\"%s\"]", time.Now().UTC().Truncate(time.Microsecond).Format(time.RFC3339Nano), c.NodeID, healthApp, healthSDID, nonce)
	d := net.Dialer{Timeout: ms(c.TimeoutMS), LocalAddr: &net.TCPAddr{IP: net.ParseIP(c.ProbeSourceIP)}}
	conn, err := d.Dial("tcp", c.ProbeAddress)
	if err != nil {
		return err
	}
	if err = conn.SetWriteDeadline(deadline); err == nil {
		_, err = io.WriteString(conn, strconv.Itoa(len(raw))+" "+raw)
	}
	_ = conn.Close()
	if err != nil {
		return err
	}
	if err := ack.SetReadDeadline(deadline); err != nil {
		return err
	}
	for {
		buf := make([]byte, 128)
		n, _, err := ack.ReadFromUnix(buf)
		if err != nil {
			return err
		}
		if string(buf[:n]) == nonce {
			return nil
		}
	}
}

func serveHealth(c HealthConfig, logger *slog.Logger) error {
	// Systemd RuntimeDirectory or installer creates this root-owned directory.
	// Hold an advisory lock: a second monitor must not unlink a live socket.
	lock, err := os.OpenFile(c.AckSocket+".lock", os.O_CREATE|os.O_RDWR, 0600)
	if err != nil {
		return err
	}
	defer lock.Close()
	if err := syscall.Flock(int(lock.Fd()), syscall.LOCK_EX|syscall.LOCK_NB); err != nil {
		return errors.New("health monitor already running")
	}
	defer syscall.Flock(int(lock.Fd()), syscall.LOCK_UN)
	if st, err := os.Lstat(c.AckSocket); err == nil {
		if st.Mode()&os.ModeSocket == 0 {
			return errors.New("ackSocket exists and is not a socket")
		}
		if err := os.Remove(c.AckSocket); err != nil {
			return err
		}
	} else if !os.IsNotExist(err) {
		return err
	}
	ack, err := net.ListenUnixgram("unixgram", &net.UnixAddr{Name: c.AckSocket, Net: "unixgram"})
	if err != nil {
		return err
	}
	defer func() { ack.Close(); os.Remove(c.AckSocket) }()
	if err := os.Chmod(c.AckSocket, 0600); err != nil {
		return err
	}
	listener, err := net.Listen("tcp", c.ListenAddress)
	if err != nil {
		return err
	}
	defer listener.Close()
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()
	state := &readiness{reason: "starting"}
	done := make(chan struct{})
	go func() {
		defer close(done)
		lastReady := false
		first := true
		for {
			err := pipelineProbe(c, ack)
			state.update(err)
			ready := err == nil
			if first || ready != lastReady {
				if err != nil {
					logger.Warn("readiness_changed", "node", c.NodeID, "ready", ready, "error", err.Error())
				} else {
					logger.Info("readiness_changed", "node", c.NodeID, "ready", ready)
				}
				lastReady = ready
				first = false
			}
			timer := time.NewTimer(ms(c.IntervalMS))
			select {
			case <-ctx.Done():
				timer.Stop()
				return
			case <-timer.C:
			}
		}
	}()
	srv := &http.Server{Handler: state.handler(c), ReadHeaderTimeout: 2 * time.Second, ReadTimeout: 3 * time.Second, WriteTimeout: 3 * time.Second, IdleTimeout: 5 * time.Second, MaxHeaderBytes: 4096}
	go func() {
		<-ctx.Done()
		shutdownCtx, stop := context.WithTimeout(context.Background(), 2*time.Second)
		defer stop()
		_ = srv.Shutdown(shutdownCtx)
	}()
	logger.Info("health_started", "node", c.NodeID, "listen", c.ListenAddress, "probe", c.ProbeAddress, "customerDeliveryChecked", false)
	err = srv.Serve(listener)
	cancel()
	_ = ack.Close()
	<-done
	if errors.Is(err, http.ErrServerClosed) {
		return nil
	}
	return err
}

// Upgrade/install validation. Never probes the network or mutates configs.
func validateConfigPair(c Config, h HealthConfig) error {
	if c.HealthProbeSourceIP != h.ProbeSourceIP || c.HealthAckSocket != h.AckSocket {
		return errors.New("sender and health probe source / socket do not match")
	}
	listen, _ := netip.ParseAddrPort(h.ListenAddress)
	if listen.Addr().String() != h.ProbeSourceIP {
		return errors.New("health listen IP must be this Gateway IP")
	}
	for _, ip := range c.AllowedSourceIPs {
		found := false
		for _, peer := range h.AllowedPeerIPs {
			if ip == peer {
				found = true
			}
		}
		if !found {
			return errors.New("each HAProxy allowedSourceIps entry must be in health allowedPeerIps")
		}
	}
	return nil
}
