package main

import (
	"bufio"
	"bytes"
	"io"
	"log/slog"
	"net"
	"strconv"
	"strings"
	"testing"
	"time"
)

func TestTCPConnectionReuseAndByteCount(t *testing.T) {
	ln, e := net.Listen("tcp", "127.0.0.1:0")
	if e != nil {
		t.Fatal(e)
	}
	defer ln.Close()
	c := testCfg()
	c.AllowTestLoopback = true
	c.AllowedDestinationCIDRs = []string{"127.0.0.1/32"}
	s := newSender(c)
	defer s.Close()
	r := Route{Destination: Destination{IP: "127.0.0.1", Port: ln.Addr().(*net.TCPAddr).Port, Protocol: "tcp"}, Framing: "octet-counting"}
	if _, e = s.Send(r, "one 한글"); e != nil {
		t.Fatal(e)
	}
	conn, e := ln.Accept()
	if e != nil {
		t.Fatal(e)
	}
	defer conn.Close()
	conn.SetReadDeadline(time.Now().Add(time.Second))
	rd := bufio.NewReader(conn)
	read := func(want string) {
		t.Helper()
		prefix, e := rd.ReadString(' ')
		if e != nil {
			t.Fatal(e)
		}
		n, e := strconv.Atoi(strings.TrimSpace(prefix))
		if e != nil {
			t.Fatal(e)
		}
		b := make([]byte, n)
		if _, e = io.ReadFull(rd, b); e != nil {
			t.Fatal(e)
		}
		if string(b) != want {
			t.Fatal(string(b))
		}
	}
	read("one 한글")
	if _, e = s.Send(r, "two 한글"); e != nil {
		t.Fatal(e)
	}
	read("two 한글")
	if len(s.pool) != 1 {
		t.Fatal("connection not reused")
	}
}
func TestTransientFailureRequestsRetry(t *testing.T) {
	// Reserving an ephemeral port, then closing, produces a local refusal.
	ln, e := net.Listen("tcp", "127.0.0.1:0")
	if e != nil {
		t.Fatal(e)
	}
	port := ln.Addr().(*net.TCPAddr).Port
	ln.Close()
	c := testCfg()
	c.AllowTestLoopback = true
	c.AllowedSourceIPs = []string{"127.0.0.1"}
	c.AllowedDestinationCIDRs = []string{"127.0.0.1/32"}
	var out, logs bytes.Buffer
	b := append(envelope(makeRaw("127.0.0.1", port, "tcp", "octet-counting", "do-not-log-me"), "127.0.0.1"), '\n')
	if e := run(c, bytes.NewReader(b), &out, slog.New(slog.NewJSONHandler(&logs, nil))); e != nil {
		t.Fatal(e)
	}
	if out.String() != "OK\nERR\n" {
		t.Fatal(out.String())
	}
	if strings.Contains(logs.String(), "do-not-log-me") || !strings.Contains(logs.String(), "retry_requested") {
		t.Fatal(logs.String())
	}
}
func TestLFFrameAndUDPSize(t *testing.T) {
	c := testCfg()
	r := Route{Destination: Destination{Protocol: "tcp"}, Framing: "lf"}
	b, e := frameMessage(c, r, "hello")
	if e != nil || string(b) != "hello\n" {
		t.Fatalf("%q %v", b, e)
	}
	r.Destination.Protocol = "udp"
	r.Framing = "none"
	c.MaxUDPBytes = 256
	if _, e := frameMessage(c, r, strings.Repeat("x", 257)); e == nil {
		t.Fatal("oversized UDP accepted")
	}
}
func TestBoundedInputResynchronizes(t *testing.T) {
	rd := bufio.NewReaderSize(strings.NewReader(strings.Repeat("x", 300)+"\nok\n"), 16)
	_, long, e := boundedLine(rd, 100)
	if e != nil || !long {
		t.Fatal("long line not detected")
	}
	b, long, e := boundedLine(rd, 100)
	if e != nil || long || string(b) != "ok" {
		t.Fatalf("%q %v %v", b, long, e)
	}
}
