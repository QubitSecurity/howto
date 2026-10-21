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

func withFormat(raw, meta string) string {
	return strings.Replace(raw, ` framing="none"]`, ` framing="none" `+meta+`]`, 1)
}
func cefBody() string {
	return `CEF:0|QubitSecurity|PLURA-XDR|0.5|WAF-SQLI|SQL Injection detected|8|src=203.0.113.10 dst=192.0.2.20 act=blocked msg=a\=b`
}
func TestOutputFormats(t *testing.T) {
	base := makeRaw("172.16.12.212", 514, "udp", "none", "hello")
	cases := []struct{ name, meta, body, want string }{
		{"default", "", "hello", "<134>1 2026-10-21T13:30:00Z msa plura-relay - - - hello"},
		{"explicit_rfc5424", `format="rfc5424"`, "hello", "<134>1 2026-10-21T13:30:00Z msa plura-relay - - - hello"},
		{"rfc3164", `format="rfc3164"`, "hello", "<134>Oct 21 22:30:00 msa plura: hello"},
		{"cef_default_legacy", `format="cef"`, cefBody(), "<134>Oct 21 22:30:00 msa " + cefBody()},
		{"cef_rfc5424", `format="cef" header="rfc5424"`, cefBody(), "<134>1 2026-10-21T13:30:00Z msa plura-relay - - - " + cefBody()},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			raw := strings.TrimSuffix(base, "hello") + tc.body
			if tc.meta != "" {
				raw = withFormat(raw, tc.meta)
			}
			_, p, e := parseEnvelope(envelope(raw, "192.168.1.15"), testCfg())
			if e != nil {
				t.Fatal(e)
			}
			if p.Wire != tc.want {
				t.Fatalf("got %q\nwant %q", p.Wire, tc.want)
			}
		})
	}
}
func TestFormatErrors(t *testing.T) {
	base := makeRaw("172.16.12.212", 514, "udp", "none", "hello")
	cases := map[string]string{
		"unknown_format":        withFormat(base, `format="other"`),
		"tls_as_format":         withFormat(base, `format="rfc5425"`),
		"header_without_cef":    withFormat(base, `header="rfc3164"`),
		"empty_format":          withFormat(base, `format=""`),
		"cef_missing_body":      withFormat(base, `format="cef"`),
		"bad_cef_header_option": withFormat(base, `format="cef" header="raw"`),
		"nil_legacy_time":       strings.Replace(withFormat(base, `format="rfc3164"`), "2026-10-21T13:30:00Z", "-", 1),
		"bad_timestamp":         strings.Replace(base, "2026-10-21T13:30:00Z", "2026-99-21T13:30:00Z", 1),
		"legacy_multiline":      withFormat(base, `format="rfc3164"`) + "\nforged",
		"long_legacy":           withFormat(base, `format="rfc3164"`) + strings.Repeat("x", 1024),
		"duplicate_other_sd":    strings.Replace(base, " hello", `[x@32473 a="1"][x@32473 a="2"] hello`, 1),
	}
	for name, raw := range cases {
		t.Run(name, func(t *testing.T) {
			_, _, e := parseEnvelope(envelope(raw, "192.168.1.15"), testCfg())
			if e == nil || !isPermanent(e) {
				t.Fatalf("expected permanent error, got %v", e)
			}
		})
	}
}
func TestCEFQuotingAndSeverity(t *testing.T) {
	good := []string{cefBody(), `CEF:1|Qubit|Product|1|ID|a\|b\\c|Very-High|msg=one\ntwo key=x\=y`, `CEF:0|Q|P|1|ID|Name|0|`}
	for _, b := range good {
		if e := validateCEF(b); e != nil {
			t.Fatalf("%q: %v", b, e)
		}
	}
	bad := []string{"hello", strings.Replace(cefBody(), "|8|", "|11|", 1), strings.Replace(cefBody(), "CEF:0", "CEF:2", 1), cefBody() + "\nforged", strings.Replace(cefBody(), "detected", "a\\x", 1), cefBody() + ` bad=C:\temp`, `CEF:0||P|1|ID|name|5|`}
	for _, b := range bad {
		if e := validateCEF(b); e == nil {
			t.Fatalf("accepted invalid CEF %q", b)
		}
	}
}
func TestLegacyMetadataPolicy(t *testing.T) {
	raw := withFormat(makeRaw("172.16.12.212", 514, "udp", "none", "hello"), `format="rfc3164"`)
	raw = strings.Replace(raw, " hello", `[other@32473 key="value"] hello`, 1)
	c := testCfg()
	c.LegacyTimezone = "UTC"
	_, p, e := parseEnvelope(envelope(raw, "192.168.1.15"), c)
	if e != nil || p.Wire != "<134>Oct 21 13:30:00 msa plura: hello" {
		t.Fatalf("%q %v", p.Wire, e)
	}
	// Opt-in long legacy mode is a receiver-specific extension, not RFC3164.
	c.LegacyMaxMessageBytes = 2048
	_, _, e = parseEnvelope(envelope(raw+strings.Repeat("x", 1100), "192.168.1.15"), c)
	if e != nil {
		t.Fatal(e)
	}
}
func TestCEFRealUDPSend(t *testing.T) {
	sock, e := net.ListenPacket("udp", "127.0.0.1:0")
	if e != nil {
		t.Fatal(e)
	}
	defer sock.Close()
	c := testCfg()
	c.AllowTestLoopback = true
	c.AllowedSourceIPs = []string{"127.0.0.1"}
	c.AllowedDestinationCIDRs = []string{"127.0.0.1/32"}
	raw := withFormat(makeRaw("127.0.0.1", sock.LocalAddr().(*net.UDPAddr).Port, "udp", "none", cefBody()), `format="cef"`)
	var input, output bytes.Buffer
	input.Write(envelope(raw, "127.0.0.1"))
	input.WriteByte('\n')
	if e := run(c, &input, &output, slog.New(slog.NewJSONHandler(io.Discard, nil))); e != nil {
		t.Fatal(e)
	}
	if output.String() != "OK\nOK\n" {
		t.Fatal(output.String())
	}
	sock.SetReadDeadline(time.Now().Add(time.Second))
	buf := make([]byte, 8192)
	n, _, e := sock.ReadFrom(buf)
	if e != nil || string(buf[:n]) != "<134>Oct 21 22:30:00 msa "+cefBody() {
		t.Fatalf("%q %v", buf[:n], e)
	}
}
func TestLFRejectsEmbeddedNewline(t *testing.T) {
	c := testCfg()
	r := Route{Destination: Destination{IP: "172.16.12.212", Port: 514, Protocol: "tcp"}, Framing: "lf"}
	if _, e := frameMessage(c, r, "line1\nline2"); e == nil {
		t.Fatal("accepted newline")
	}
}
func TestConfigPairAndLegacyValidation(t *testing.T) {
	c := testCfg()
	c.HealthProbeSourceIP = "192.168.200.200"
	c.HealthAckSocket = "/run/plura-syslog/health.sock"
	h := HealthConfig{ListenAddress: "192.168.200.200:18081", ProbeSourceIP: c.HealthProbeSourceIP, AckSocket: c.HealthAckSocket, AllowedPeerIPs: c.AllowedSourceIPs}
	if e := validateConfigPair(c, h); e != nil {
		t.Fatal(e)
	}
	h.ProbeSourceIP = "192.168.200.201"
	if e := validateConfigPair(c, h); e == nil {
		t.Fatal("pair mismatch accepted")
	}
	c.LegacyTimezone = "Local"
	if e := c.validate(); e == nil {
		t.Fatal("Local zone accepted")
	}
}
func TestConfigV041BackwardCompatibility(t *testing.T) {
	c := defaults()
	b := []byte(`{"allowedSourceIps":["192.168.1.15"],"allowedDestinationCidrs":["172.16.12.212/32"],"debug":true}`)
	if e := decodeStrict(b, &c); e != nil {
		t.Fatal(e)
	}
	if e := c.validate(); e != nil {
		t.Fatal(e)
	}
	if c.LegacyTimezone != "Asia/Seoul" || c.LegacyMaxMessageBytes != 1024 {
		t.Fatal("missing compatible defaults")
	}
}
func TestAllSourcesAndDestinationsValidated(t *testing.T) {
	base := testCfg()
	for _, ip := range []string{"127.0.0.1", "0.0.0.0", "169.254.169.254", "224.0.0.1", "255.255.255.255", "::1", "fe80::1", "::ffff:172.16.12.212"} {
		t.Run(ip, func(t *testing.T) {
			c := base
			c.AllowedDestinationCIDRs = []string{"0.0.0.0/0", "::/0"}
			r := Route{Destination: Destination{IP: ip, Port: 514, Protocol: "udp"}, Framing: "none"}
			if e := validateDestination(c, r); e == nil {
				t.Fatal("special address allowed")
			}
		})
	}
	c := base
	c.DenyCIDRs = []string{"172.16.12.212/32"}
	if e := validateDestination(c, Route{Destination: Destination{IP: "172.16.12.212", Port: 514, Protocol: "udp"}, Framing: "none"}); e == nil {
		t.Fatal("deny did not override allow")
	}
}
func FuzzParseEnvelope(f *testing.F) {
	raw := makeRaw("172.16.12.212", 514, "udp", "none", "hello")
	f.Add(envelope(raw, "192.168.1.15"))
	f.Add(envelope(withFormat(raw, `format="rfc3164"`), "192.168.1.15"))
	f.Add([]byte("{}"))
	f.Fuzz(func(t *testing.T, b []byte) {
		if len(b) > 128*1024 {
			t.Skip()
		}
		c := testCfg()
		env, out, e := parseEnvelope(b, c)
		if e == nil {
			if env.App != relayApp || out.Wire == "" || out.Route.Destination.IP != "172.16.12.212" {
				t.Fatal("invalid accepted message")
			}
			if _, e := frameMessage(c, out.Route, out.Wire); e != nil && !isPermanent(e) {
				t.Fatal(e)
			}
		}
	})
}
func TestPermanentDropDoesNotLogPayload(t *testing.T) {
	c := testCfg()
	var logbuf, out bytes.Buffer
	raw := withFormat(makeRaw("172.16.12.212", 514, "udp", "none", "private-secret-value"), `format="cef"`)
	input := append(envelope(raw, "192.168.1.15"), '\n')
	if e := run(c, bytes.NewReader(input), &out, slog.New(slog.NewJSONHandler(&logbuf, nil))); e != nil {
		t.Fatal(e)
	}
	if out.String() != "OK\nOK\n" || !strings.Contains(logbuf.String(), "discarded_not_delivered") || strings.Contains(logbuf.String(), "private-secret-value") {
		t.Fatal(logbuf.String())
	}
}
func TestTimestampAndSDLimits(t *testing.T) {
	for _, s := range []string{"2026-10-21T13:30:00Z", "2026-10-21T13:30:00.123456+09:00"} {
		if _, e := parseTimestamp(s); e != nil {
			t.Fatal(e)
		}
	}
	for _, s := range []string{"2026-10-21T13:30:00.1234567Z", "2026-10-21T13:30:60Z", "2026-10-21T13:30:00+24:00"} {
		if _, e := parseTimestamp(s); e == nil {
			t.Fatal(s)
		}
	}
	if _, _, _, e := parseSD(`[x@32473 `+strings.Repeat("a", 33)+`="v"]`, 0); e == nil {
		t.Fatal("long SD name accepted")
	}
	// Verify envelopes remain ordinary one-line JSON even with escaped content.
	b := envelope(makeRaw("172.16.12.212", 514, "udp", "none", `a"b\c`), "192.168.1.15")
	if !json.Valid(b) {
		t.Fatal(fmt.Sprintf("invalid envelope: %s", b))
	}
}
