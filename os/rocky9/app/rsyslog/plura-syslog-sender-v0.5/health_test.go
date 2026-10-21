package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"
)

func shortSocket(t *testing.T) string {
	t.Helper()
	d, e := os.MkdirTemp("", "plura-h-")
	if e != nil {
		t.Fatal(e)
	}
	t.Cleanup(func() { os.RemoveAll(d) })
	return filepath.Join(d, "ack.sock")
}
func rawHealth(n string) string {
	return `<134>1 2026-10-21T00:00:00Z gw1 plura-health - - [pluraHealth@32473 nonce="` + n + `"]`
}
func TestHealthProbeCallbackAndIsolation(t *testing.T) {
	path := shortSocket(t)
	ack, err := net.ListenUnixgram("unixgram", &net.UnixAddr{Name: path, Net: "unixgram"})
	if err != nil {
		t.Fatal(err)
	}
	defer ack.Close()
	c := testCfg()
	c.HealthProbeSourceIP = "127.0.0.1"
	c.HealthAckSocket = path
	nonce := strings.Repeat("ab", 32)
	env := Envelope{App: healthApp, Source: "127.0.0.1", Raw: rawHealth(nonce)}
	if err := acknowledgeHealthProbe(env, c); err != nil {
		t.Fatal(err)
	}
	ack.SetReadDeadline(time.Now().Add(time.Second))
	b := make([]byte, 128)
	n, _, err := ack.ReadFromUnix(b)
	if err != nil || string(b[:n]) != nonce {
		t.Fatalf("%s %v", b[:n], err)
	}
	env.Source = "192.168.1.15" // a valid business source is NOT a health source
	if err := acknowledgeHealthProbe(env, c); err == nil {
		t.Fatal("foreign probe accepted")
	}
	env.Source = "127.0.0.1"
	env.Raw = rawHealth("bad")
	if err := acknowledgeHealthProbe(env, c); err == nil {
		t.Fatal("bad nonce accepted")
	}
}
func TestHealthProbeFailureNeverBlocksBusinessQueue(t *testing.T) {
	c := testCfg()
	c.HealthProbeSourceIP = "127.0.0.1"
	c.HealthAckSocket = shortSocket(t)
	p := &Processor{cfg: c, log: slog.New(slog.NewJSONHandler(io.Discard, nil))}
	b, _ := json.Marshal(Envelope{App: healthApp, Source: "127.0.0.1", Raw: rawHealth(strings.Repeat("ab", 32))})
	if p.process(b) != "OK" {
		t.Fatal("health failure must not cause permanent queue retry")
	}
	if p.sent != 0 || p.received != 0 {
		t.Fatal("probe counted as a customer delivery")
	}
}
func TestReadinessStates(t *testing.T) {
	c := HealthConfig{NodeID: "gw1", AllowedPeerIPs: []string{"127.0.0.1"}, DrainFile: filepath.Join(t.TempDir(), "drain"), StaleMS: 1000}
	r := &readiness{}
	status := func(path, remote string) int {
		q := httptest.NewRequest("GET", path, nil)
		q.RemoteAddr = remote
		w := httptest.NewRecorder()
		r.handler(c).ServeHTTP(w, q)
		return w.Code
	}
	if status("/ready", "127.0.0.1:1234") != 503 {
		t.Fatal("not fail-closed on startup")
	}
	r.update(nil)
	if status("/ready", "127.0.0.1:1234") != 200 {
		t.Fatal("ready not 200")
	}
	if status("/ready", "192.0.2.1:1234") != 403 {
		t.Fatal("peer ACL bypass")
	}
	if status("/anything", "127.0.0.1:1234") != 404 {
		t.Fatal("unknown path accepted")
	}
	os.WriteFile(c.DrainFile, []byte{}, 0600)
	if status("/ready", "127.0.0.1:1234") != 503 {
		t.Fatal("drain ignored")
	}
	os.Remove(c.DrainFile)
	r.mu.Lock()
	r.lastCheck = time.Now().Add(-time.Minute)
	r.mu.Unlock()
	if status("/ready", "127.0.0.1:1234") != 503 {
		t.Fatal("stale readiness accepted")
	}
	if status("/live", "127.0.0.1:1234") != 200 {
		t.Fatal("live not 200")
	}
}
func TestPipelineProbeThroughTCPAndProcessor(t *testing.T) {
	path := shortSocket(t)
	ack, err := net.ListenUnixgram("unixgram", &net.UnixAddr{Name: path, Net: "unixgram"})
	if err != nil {
		t.Fatal(err)
	}
	defer ack.Close()
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer ln.Close()
	cfg := testCfg()
	cfg.HealthProbeSourceIP = "127.0.0.1"
	cfg.HealthAckSocket = path
	done := make(chan error, 1)
	go func() {
		conn, e := ln.Accept()
		if e != nil {
			done <- e
			return
		}
		defer conn.Close()
		conn.SetReadDeadline(time.Now().Add(2 * time.Second))
		rd := bufio.NewReader(conn)
		prefix, e := rd.ReadString(' ')
		if e != nil {
			done <- e
			return
		}
		n, e := strconv.Atoi(strings.TrimSpace(prefix))
		if e != nil || n > 1024 {
			done <- fmt.Errorf("bad prefix")
			return
		}
		raw := make([]byte, n)
		_, e = io.ReadFull(rd, raw)
		if e != nil {
			done <- e
			return
		}
		source, _, _ := net.SplitHostPort(conn.RemoteAddr().String())
		b, _ := json.Marshal(Envelope{App: healthApp, Source: source, Raw: string(raw)})
		p := &Processor{cfg: cfg, log: slog.New(slog.NewJSONHandler(io.Discard, nil))}
		if p.process(b) != "OK" {
			done <- fmt.Errorf("bad ack")
			return
		}
		done <- nil
	}()
	hc := HealthConfig{NodeID: "gw1", ProbeAddress: ln.Addr().String(), ProbeSourceIP: "127.0.0.1", TimeoutMS: 1000}
	if err := pipelineProbe(hc, ack); err != nil {
		t.Fatal(err)
	}
	if err := <-done; err != nil {
		t.Fatal(err)
	}
}
func TestHealthConfigValidation(t *testing.T) {
	c := HealthConfig{NodeID: "gw1", ListenAddress: "192.168.200.200:18081", AllowedPeerIPs: []string{"192.168.200.199"}, ProbeAddress: "192.168.200.200:514", ProbeSourceIP: "192.168.200.200", AckSocket: "/run/plura-syslog/health.sock", DrainFile: "/run/plura-syslog/drain", IntervalMS: 2000, TimeoutMS: 1500, StaleMS: 6000}
	if e := c.validate(); e != nil {
		t.Fatal(e)
	}
	c.ProbeAddress = "172.16.12.212:514"
	if e := c.validate(); e == nil {
		t.Fatal("probe may not target arbitrary customer")
	}
}
