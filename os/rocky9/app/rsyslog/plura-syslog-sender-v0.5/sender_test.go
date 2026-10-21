package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net"
	"strings"
	"testing"
	"time"
)

func testCfg() Config {
	c := defaults()
	c.AllowedSourceIPs = []string{"192.168.1.15"}
	c.AllowedDestinationCIDRs = []string{"172.16.12.212/32"}
	return c
}
func makeRaw(dest string, port int, proto, frame, msg string) string {
	return fmt.Sprintf("<134>1 2026-10-21T13:30:00Z msa plura-relay - - [pluraRelay@32473 dst=\"%s\" port=\"%d\" proto=\"%s\" framing=\"%s\"] %s", dest, port, proto, frame, msg)
}
func envelope(raw, source string) []byte {
	b, _ := json.Marshal(Envelope{App: relayApp, Raw: raw, Source: source})
	return b
}
func TestMetadataAndStrip(t *testing.T) {
	c := testCfg()
	raw := makeRaw("172.16.12.212", 514, "udp", "none", "한글 hello")
	_, parsed, err := parseEnvelope(envelope(raw, "192.168.1.15"), c)
	if err != nil {
		t.Fatal(err)
	}
	if parsed.Route.Destination.IP != "172.16.12.212" || parsed.Route.Destination.Port != 514 || parsed.Route.Destination.Protocol != "udp" {
		t.Fatal(parsed.Route)
	}
	if strings.Contains(parsed.Wire, "pluraRelay@32473") || !strings.HasSuffix(parsed.Wire, " - 한글 hello") {
		t.Fatal(parsed.Wire)
	}
}
func TestOtherStructuredDataRetained(t *testing.T) {
	raw := "<134>1 2026-10-21T13:30:00Z msa plura-relay - - [other@32473 name=\"A\\\"B\"][pluraRelay@32473 dst=\"172.16.12.212\" port=\"514\" proto=\"udp\"] hello"
	_, out, err := parseEnvelope(envelope(raw, "192.168.1.15"), testCfg())
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out.Wire, "[other@32473 name=\"A\\\"B\"]") || strings.Contains(out.Wire, "pluraRelay") {
		t.Fatal(out.Wire)
	}
}
func TestRejectInvalidMessages(t *testing.T) {
	good := makeRaw("172.16.12.212", 514, "udp", "none", "hello")
	cases := map[string]struct{ raw, source string }{
		"source_disallowed":      {good, "192.168.1.16"},
		"destination_disallowed": {makeRaw("192.168.200.200", 514, "udp", "none", "hello"), "192.168.1.15"},
		"special_destination":    {makeRaw("169.254.169.254", 514, "udp", "none", "hello"), "192.168.1.15"},
		"port_invalid":           {makeRaw("172.16.12.212", 0, "udp", "none", "hello"), "192.168.1.15"},
		"proto_invalid":          {makeRaw("172.16.12.212", 514, "http", "none", "hello"), "192.168.1.15"},
		"missing_sd":             {strings.Replace(good, `[pluraRelay@32473 dst="172.16.12.212" port="514" proto="udp" framing="none"]`, `-`, 1), "192.168.1.15"},
		"duplicate_sd":           {strings.Replace(good, ` [pluraRelay@32473`, ` [pluraRelay@32473 dst="172.16.12.212" port="514" proto="udp"][pluraRelay@32473`, 1), "192.168.1.15"},
		"duplicate_param":        {strings.Replace(good, ` proto="udp"`, ` proto="udp" proto="tcp"`, 1), "192.168.1.15"},
		"bad_escape":             {strings.Replace(good, `proto="udp"`, `proto="u\np"`, 1), "192.168.1.15"},
		"wrong_app":              {strings.Replace(good, " plura-relay ", " plura-rx ", 1), "192.168.1.15"},
	}
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			_, _, err := parseEnvelope(envelope(tc.raw, tc.source), testCfg())
			if err == nil {
				t.Fatal("unexpected accept")
			}
		})
	}
}
func TestValidateConfig(t *testing.T) {
	c := testCfg()
	if err := c.validate(); err != nil {
		t.Fatal(err)
	}
	c.AllowedDestinationCIDRs = nil
	if err := c.validate(); err == nil {
		t.Fatal("allowlist must be required")
	}
}
func TestOmprogUDPEndToEnd(t *testing.T) {
	pc, err := net.ListenPacket("udp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer pc.Close()
	c := testCfg()
	c.AllowedSourceIPs = []string{"127.0.0.1"}
	c.AllowedDestinationCIDRs = []string{"127.0.0.1/32"}
	c.AllowTestLoopback = true
	port := pc.LocalAddr().(*net.UDPAddr).Port
	good := makeRaw("127.0.0.1", port, "udp", "none", "hello 한글")
	var input bytes.Buffer
	input.Write(envelope(good, "127.0.0.1"))
	input.WriteByte('\n')
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	var output bytes.Buffer
	if err := run(c, &input, &output, logger); err != nil {
		t.Fatal(err)
	}
	if output.String() != "OK\nOK\n" {
		t.Fatal(output.String())
	}
	if err := pc.SetReadDeadline(time.Now().Add(time.Second)); err != nil {
		t.Fatal(err)
	}
	buf := make([]byte, 8192)
	n, _, err := pc.ReadFrom(buf)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(buf[:n]), "pluraRelay") || !strings.Contains(string(buf[:n]), "hello 한글") {
		t.Fatalf("bad packet %s", buf[:n])
	}
}
func TestTCPFraming(t *testing.T) {
	c := testCfg()
	r := Route{Destination: Destination{IP: "172.16.12.212", Port: 514, Protocol: "tcp"}, Framing: "octet-counting"}
	framed, err := frameMessage(c, r, "<134>1 x x x x x - hello\nsecond")
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.HasPrefix(framed, []byte(fmt.Sprintf("%d ", len("<134>1 x x x x x - hello\nsecond")))) {
		t.Fatal(string(framed))
	}
}

// HA adds no CEF conversion: a caller-built CEF body is retained byte-for-byte.
func TestCEFBodyPassThrough(t *testing.T) {
	body := `CEF:0|QubitSecurity|PLURA-XDR|1|TEST|CEF event|5|src=203.0.113.10 dst=192.0.2.20 msg=a\=b`
	raw := makeRaw("172.16.12.212", 514, "udp", "none", body)
	_, parsed, err := parseEnvelope(envelope(raw, "192.168.1.15"), testCfg())
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasSuffix(parsed.Wire, " - "+body) || strings.Contains(parsed.Wire, relaySDID) {
		t.Fatal(parsed.Wire)
	}
}
