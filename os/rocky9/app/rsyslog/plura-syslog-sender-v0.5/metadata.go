package main

import (
	"errors"
	"regexp"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"
)

// Example PEN: replace on BOTH MSA and Sender after assigning a production PEN.
const relaySDID = "pluraRelay@32473"
const relayApp = "plura-relay"

type Destination struct {
	IP       string `json:"ip"`
	Port     int    `json:"port"`
	Protocol string `json:"protocol"`
}
type Route struct {
	Destination Destination
	Framing     string
	Format      string // rfc5424 (default), rfc3164, cef
	Header      string // only for cef: rfc3164 (default), rfc5424
}
type Envelope struct {
	App    string `json:"app"`
	Raw    string `json:"raw"`
	Source string `json:"source"`
}
type ParsedMessage struct {
	Route Route
	Wire  string
}

// Strict profile for trusted MSA-generated RFC5424. A malformed record is never
// forwarded with partially interpreted routing data. Limits bound parser work.
func sdNameOK(s string) bool {
	if len(s) < 1 || len(s) > 32 {
		return false
	}
	for i := 0; i < len(s); i++ {
		if s[i] < 33 || s[i] > 126 || strings.ContainsRune("=]\"[", rune(s[i])) {
			return false
		}
	}
	return true
}
func parseSD(s string, pos int) (int, string, map[string]string, error) {
	fail := func() (int, string, map[string]string, error) {
		return 0, "", nil, errors.New("invalid_structured_data")
	}
	if pos >= len(s) || s[pos] != '[' {
		return fail()
	}
	i := pos + 1
	start := i
	for i < len(s) && s[i] != ']' && s[i] != ' ' {
		i++
	}
	id := s[start:i]
	if !sdNameOK(id) {
		return fail()
	}
	params := make(map[string]string)
	for i < len(s) && s[i] != ']' {
		if s[i] != ' ' {
			return fail()
		}
		i++
		start = i
		for i < len(s) && s[i] != '=' {
			i++
		}
		key := s[start:i]
		if !sdNameOK(key) || i >= len(s) || len(params) >= 64 {
			return fail()
		}
		i++
		if i >= len(s) || s[i] != '"' {
			return fail()
		}
		i++
		var val strings.Builder
		closed := false
		for i < len(s) {
			ch := s[i]
			i++
			if ch == '"' {
				closed = true
				break
			}
			escaped := false
			if ch == '\\' {
				escaped = true
				if i >= len(s) {
					return fail()
				}
				ch = s[i]
				i++
				if ch != '"' && ch != '\\' && ch != ']' {
					return fail()
				}
			}
			if (ch == ']' && !escaped) || ch < 32 || ch == 127 {
				return fail()
			}
			val.WriteByte(ch)
		}
		if !closed || !utf8.ValidString(val.String()) {
			return fail()
		}
		if _, ok := params[key]; ok {
			return fail()
		}
		params[key] = val.String()
	}
	if i >= len(s) || s[i] != ']' {
		return fail()
	}
	return i + 1, id, params, nil
}

var timestampPattern = regexp.MustCompile(`^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?(Z|[+-]\d{2}:\d{2})$`)

func parseTimestamp(s string) (time.Time, error) {
	if !timestampPattern.MatchString(s) {
		return time.Time{}, permanent("invalid_timestamp")
	}
	t, e := time.Parse(time.RFC3339Nano, s)
	if e != nil {
		return time.Time{}, permanent("invalid_timestamp")
	}
	// Go accepts some non-RFC numeric offsets; reject those explicitly.
	if s[len(s)-1] != 'Z' {
		off := s[len(s)-6:]
		h, _ := strconv.Atoi(off[1:3])
		m, _ := strconv.Atoi(off[4:6])
		if h > 23 || m > 59 {
			return time.Time{}, permanent("invalid_timestamp")
		}
	}
	return t, nil
}
func headerTokenOK(s string, max int) bool {
	if s == "" || len(s) > max {
		return false
	}
	for i := 0; i < len(s); i++ {
		if s[i] < 33 || s[i] > 126 {
			return false
		}
	}
	return true
}
func routeFromParams(p map[string]string) (Route, error) {
	var r Route
	for k := range p {
		switch k {
		case "dst", "port", "proto", "framing", "format", "header":
		default:
			return r, permanent("invalid_route_metadata")
		}
	}
	for _, k := range []string{"dst", "port", "proto"} {
		if p[k] == "" {
			return r, permanent("missing_route_parameter")
		}
	}
	for _, k := range []string{"framing", "format", "header"} {
		if v, ok := p[k]; ok && v == "" {
			return r, permanent("empty_route_parameter")
		}
	}
	port, e := strconv.Atoi(p["port"])
	if e != nil || strconv.Itoa(port) != p["port"] {
		return r, permanent("invalid_destination_port")
	}
	r = Route{Destination: Destination{IP: p["dst"], Port: port, Protocol: p["proto"]}, Framing: p["framing"], Format: p["format"], Header: p["header"]}
	if r.Framing == "" {
		if r.Destination.Protocol == "udp" {
			r.Framing = "none"
		} else {
			r.Framing = "octet-counting"
		}
	}
	if r.Format == "" {
		r.Format = "rfc5424"
	}
	switch r.Format {
	case "rfc5424", "rfc3164":
		if r.Header != "" {
			return r, permanent("header_only_valid_for_cef")
		}
	case "cef":
		if r.Header == "" {
			r.Header = "rfc3164"
		}
		if r.Header != "rfc3164" && r.Header != "rfc5424" {
			return r, permanent("unsupported_cef_header")
		}
	default:
		return r, permanent("unsupported_format")
	}
	return r, nil
}

func parseEnvelope(b []byte, c Config) (Envelope, ParsedMessage, error) {
	var env Envelope
	var result ParsedMessage
	if !utf8.Valid(b) || decodeStrict(b, &env) != nil {
		return env, result, permanent("invalid_envelope")
	}
	if !c.allowsSource(env.Source) {
		return env, result, permanent("source_not_allowed")
	}
	if env.App != relayApp {
		return env, result, permanent("invalid_app")
	}
	raw := env.Raw
	if raw == "" || len(raw) > c.MaxMessageBytes || strings.ContainsRune(raw, 0) || !utf8.ValidString(raw) {
		return env, result, permanent("message_invalid_size_or_nul")
	}
	end := strings.IndexByte(raw, '>')
	if raw[0] != '<' || end < 2 || end > 4 {
		return env, result, permanent("invalid_pri")
	}
	pri, e := strconv.Atoi(raw[1:end])
	if e != nil || pri < 0 || pri > 191 || strconv.Itoa(pri) != raw[1:end] {
		return env, result, permanent("invalid_pri")
	}
	toks := strings.SplitN(raw[end+1:], " ", 7)
	if len(toks) != 7 || toks[0] != "1" || toks[3] != relayApp {
		return env, result, permanent("invalid_rfc5424_header")
	}
	for idx, max := range map[int]int{1: 32, 2: 255, 3: 48, 4: 128, 5: 32} {
		if !headerTokenOK(toks[idx], max) {
			return env, result, permanent("invalid_rfc5424_header")
		}
	}
	if toks[1] != "-" {
		if _, e := parseTimestamp(toks[1]); e != nil {
			return env, result, e
		}
	}
	sdmsg := toks[6]
	if sdmsg == "" || sdmsg[0] != '[' {
		return env, result, permanent("missing_route_sd")
	}
	pos := 0
	found := false
	var others strings.Builder
	ids := map[string]bool{}
	for pos < len(sdmsg) && sdmsg[pos] == '[' {
		next, id, p, err := parseSD(sdmsg, pos)
		if err != nil || len(ids) >= 64 {
			return env, result, permanent("invalid_structured_data")
		}
		if ids[id] {
			return env, result, permanent("duplicate_sd_id")
		}
		ids[id] = true
		if id == relaySDID {
			found = true
			result.Route, e = routeFromParams(p)
			if e != nil {
				return env, result, e
			}
		} else {
			others.WriteString(sdmsg[pos:next])
		}
		pos = next
	}
	if !found {
		return env, result, permanent("missing_route_sd")
	}
	if pos < len(sdmsg) && sdmsg[pos] != ' ' {
		return env, result, permanent("malformed_sd_suffix")
	}
	suffix := sdmsg[pos:]
	sd := others.String()
	if sd == "" {
		sd = "-"
	}
	stripped := raw[:end+1] + strings.Join(toks[:6], " ") + " " + sd + suffix
	if e := validateDestination(c, result.Route); e != nil {
		return env, result, e
	}
	result.Wire, e = renderOutput(c, result.Route, pri, toks, suffix, stripped)
	if e != nil {
		return env, result, e
	}
	if len(result.Wire) > c.MaxMessageBytes {
		return env, result, permanent("outgoing_message_too_large")
	}
	return env, result, nil
}
