package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/netip"
	"os"
	"path/filepath"
	"strings"
	"time"
	"unicode/utf8"
)

// A single global config, not a per-customer route database.
// The explicit destination allowlist is required to prevent arbitrary relaying.
type Config struct {
	LegacyTimezone          string   `json:"legacyTimezone"`
	LegacyMaxMessageBytes   int      `json:"legacyMaxMessageBytes"`
	AllowedSourceIPs        []string `json:"allowedSourceIps"`
	AllowedDestinationCIDRs []string `json:"allowedDestinationCidrs"`
	DenyCIDRs               []string `json:"denyCidrs"`
	AllowTestLoopback       bool     `json:"allowTestLoopback"`
	DialTimeoutMS           int      `json:"dialTimeoutMs"`
	WriteTimeoutMS          int      `json:"writeTimeoutMs"`
	MaxConnections          int      `json:"maxConnections"`
	ConnectionIdleSeconds   int      `json:"connectionIdleSeconds"`
	MaxMessageBytes         int      `json:"maxMessageBytes"`
	MaxUDPBytes             int      `json:"maxUdpBytes"`
	Debug                   bool     `json:"debug"`
	HealthProbeSourceIP     string   `json:"healthProbeSourceIp,omitempty"`
	HealthAckSocket         string   `json:"healthAckSocket,omitempty"`
}

func defaults() Config {
	return Config{
		LegacyTimezone: "Asia/Seoul", LegacyMaxMessageBytes: 1024,
		DialTimeoutMS: 2000, WriteTimeoutMS: 2000, MaxConnections: 128,
		ConnectionIdleSeconds: 30, MaxMessageBytes: 8192, MaxUDPBytes: 8192,
	}
}
func decodeStrict(data []byte, v any) error {
	if !utf8.Valid(data) {
		return errors.New("JSON must be UTF-8")
	}
	d := json.NewDecoder(strings.NewReader(string(data)))
	d.DisallowUnknownFields()
	if err := d.Decode(v); err != nil {
		return err
	}
	if err := d.Decode(new(any)); err != io.EOF {
		return errors.New("expected exactly one JSON value")
	}
	return nil
}
func loadConfig(path string) (Config, error) {
	c := defaults()
	f, err := os.Open(path)
	if err != nil {
		return c, err
	}
	defer f.Close()
	b, err := io.ReadAll(io.LimitReader(f, 65537))
	if err != nil {
		return c, err
	}
	if len(b) > 65536 {
		return c, errors.New("config too large")
	}
	if err = decodeStrict(b, &c); err != nil {
		return c, err
	}
	return c, c.validate()
}
func (c Config) validate() error {
	if c.LegacyTimezone == "" || c.LegacyTimezone == "Local" {
		return errors.New("use an explicit legacyTimezone, e.g. Asia/Seoul or UTC")
	}
	if _, err := legacyLocation(c.LegacyTimezone); err != nil {
		return errors.New("invalid legacyTimezone")
	}
	if c.LegacyMaxMessageBytes < 256 || c.LegacyMaxMessageBytes > c.MaxMessageBytes {
		return errors.New("invalid legacyMaxMessageBytes")
	}
	if (c.HealthProbeSourceIP == "") != (c.HealthAckSocket == "") {
		return errors.New("healthProbeSourceIp and healthAckSocket must be set together")
	}
	if c.HealthProbeSourceIP != "" {
		a, e := netip.ParseAddr(c.HealthProbeSourceIP)
		if e != nil || a.Zone() != "" || a.Is4In6() {
			return errors.New("invalid healthProbeSourceIp")
		}
		if !filepath.IsAbs(c.HealthAckSocket) || len(c.HealthAckSocket) > 100 {
			return errors.New("healthAckSocket must be an absolute path <= 100 bytes")
		}
	}

	if len(c.AllowedSourceIPs) == 0 || len(c.AllowedDestinationCIDRs) == 0 {
		return errors.New("allowedSourceIps and allowedDestinationCidrs must be nonempty")
	}
	for _, ip := range c.AllowedSourceIPs {
		a, e := netip.ParseAddr(ip)
		if e != nil || a.Zone() != "" || a.Is4In6() {
			return fmt.Errorf("invalid allowedSourceIps entry %q", ip)
		}
	}
	for _, s := range append(append([]string{}, c.AllowedDestinationCIDRs...), c.DenyCIDRs...) {
		p, e := netip.ParsePrefix(s)
		if e != nil || p.Addr().Is4In6() {
			return fmt.Errorf("invalid CIDR %q", s)
		}
	}
	for n, v := range map[string]int{"dialTimeoutMs": c.DialTimeoutMS, "writeTimeoutMs": c.WriteTimeoutMS} {
		if v < 1 || v > 30000 {
			return fmt.Errorf("%s must be 1..30000", n)
		}
	}
	if c.MaxConnections < 1 || c.MaxConnections > 4096 {
		return errors.New("invalid maxConnections")
	}
	if c.ConnectionIdleSeconds < 1 || c.ConnectionIdleSeconds > 3600 {
		return errors.New("invalid connectionIdleSeconds")
	}
	if c.MaxMessageBytes < 256 || c.MaxMessageBytes > 1048576 {
		return errors.New("invalid maxMessageBytes")
	}
	if c.MaxUDPBytes < 256 || c.MaxUDPBytes > 65507 || c.MaxUDPBytes > c.MaxMessageBytes {
		return errors.New("invalid maxUdpBytes")
	}
	return nil
}
func (c Config) allowsSource(ip string) bool {
	a, e := netip.ParseAddr(ip)
	if e != nil || a.Zone() != "" || a.Is4In6() {
		return false
	}
	for _, s := range c.AllowedSourceIPs {
		if a.String() == s {
			return true
		}
	}
	return false
}
func prefixContains(list []string, addr netip.Addr) bool {
	for _, s := range list {
		p, e := netip.ParsePrefix(s)
		if e == nil && p.Contains(addr) {
			return true
		}
	}
	return false
}
func validateDestination(c Config, r Route) error {
	a, e := netip.ParseAddr(r.Destination.IP)
	if e != nil || a.Zone() != "" || a.Is4In6() {
		return permanent("invalid_destination_ip")
	}
	if a.IsUnspecified() || a.IsMulticast() || a.IsLinkLocalUnicast() || a.IsLinkLocalMulticast() ||
		a.String() == "255.255.255.255" || netip.MustParsePrefix("0.0.0.0/8").Contains(a) ||
		netip.MustParsePrefix("240.0.0.0/4").Contains(a) || (a.IsLoopback() && !c.AllowTestLoopback) {
		return permanent("special_destination_blocked")
	}
	if prefixContains(c.DenyCIDRs, a) {
		return permanent("destination_denied")
	}
	if !prefixContains(c.AllowedDestinationCIDRs, a) {
		return permanent("destination_not_allowlisted")
	}
	if r.Destination.Port < 1 || r.Destination.Port > 65535 {
		return permanent("invalid_destination_port")
	}
	switch r.Destination.Protocol {
	case "udp":
		if r.Framing != "none" {
			return permanent("udp_framing_invalid")
		}
	case "tcp":
		if r.Framing != "lf" && r.Framing != "octet-counting" {
			return permanent("tcp_framing_invalid")
		}
	default:
		return permanent("unsupported_protocol")
	}
	return nil
}
func ms(n int) time.Duration { return time.Duration(n) * time.Millisecond }

type jobError struct {
	code      string
	permanent bool
	cause     error
}

func (e *jobError) Error() string {
	if e.cause != nil {
		return e.code + ": " + e.cause.Error()
	}
	return e.code
}
func permanent(code string) error            { return &jobError{code: code, permanent: true} }
func transient(code string, err error) error { return &jobError{code: code, cause: err} }
func isPermanent(err error) bool             { var e *jobError; return errors.As(err, &e) && e.permanent }
func errorCode(err error) string {
	var e *jobError
	if errors.As(err, &e) {
		return e.code
	}
	return "internal_error"
}
