package main

import (
	"fmt"
	"strconv"
	"strings"
	"sync"
	"time"
	_ "time/tzdata" // Embed zone data so minimal runtime images work too.
	"unicode/utf8"
)

// Only operator-configured zone names are cached, not customer input.
var timezoneCache sync.Map

func legacyLocation(name string) (*time.Location, error) {
	if cached, ok := timezoneCache.Load(name); ok {
		return cached.(*time.Location), nil
	}
	loc, err := time.LoadLocation(name)
	if err != nil {
		return nil, err
	}
	actual, _ := timezoneCache.LoadOrStore(name, loc)
	return actual.(*time.Location), nil
}

// CEF events are created by the MSA, which owns the event schema. The relay only
// validates the header's shape and quoting, then preserves the body. This is NOT
// a full CEF extension dictionary/type validator or a SIEM certification.
func validateCEF(body string) error {
	if !utf8.ValidString(body) || strings.ContainsAny(body, "\r\n\x00") {
		return permanent("invalid_cef_body")
	}
	fields := make([]string, 0, 7)
	var field strings.Builder
	end := 0
	for i := 0; i < len(body); i++ {
		ch := body[i]
		if ch == '\\' {
			i++
			if i >= len(body) || (body[i] != '\\' && body[i] != '|') {
				return permanent("invalid_cef_header_escape")
			}
			field.WriteByte(body[i])
			continue
		}
		if ch == '|' {
			fields = append(fields, field.String())
			field.Reset()
			if len(fields) == 7 {
				end = i + 1
				break
			}
		} else {
			if ch < 32 || ch == 127 {
				return permanent("invalid_cef_header")
			}
			field.WriteByte(ch)
		}
	}
	if len(fields) != 7 || (fields[0] != "CEF:0" && fields[0] != "CEF:1") {
		return permanent("invalid_cef_header")
	}
	limits := []int{0, 63, 63, 31, 1023, 512}
	for i := 1; i <= 5; i++ {
		if fields[i] == "" || utf8.RuneCountInString(fields[i]) > limits[i] {
			return permanent("invalid_cef_header_field")
		}
	}
	severity := fields[6]
	switch severity {
	case "Unknown", "Low", "Medium", "High", "Very-High":
	default:
		n, e := strconv.Atoi(severity)
		if e != nil || n < 0 || n > 10 || strconv.Itoa(n) != severity {
			return permanent("invalid_cef_severity")
		}
	}
	// Validate escape spelling in extension values, but leave key semantics and
	// event mapping to MSA. Unescaped '=' may be a key/value delimiter.
	extension := body[end:]
	for i := 0; i < len(extension); i++ {
		if extension[i] == '\\' {
			i++
			if i >= len(extension) || !strings.ContainsRune("\\=nr", rune(extension[i])) {
				return permanent("invalid_cef_extension_escape")
			}
		}
	}
	return nil
}

func renderOutput(c Config, r Route, pri int, toks []string, suffix, stripped string) (string, error) {
	body := ""
	if suffix != "" {
		body = suffix[1:]
	}
	if r.Format == "cef" {
		// A UTF-8 BOM is not part of the CEF signature; remove only that prefix.
		body = strings.TrimPrefix(body, "\ufeff")
		if e := validateCEF(body); e != nil {
			return "", e
		}
		if r.Header == "rfc5424" {
			if suffix != "" {
				stripped = stripped[:len(stripped)-len(suffix)] + " " + body
			}
			return stripped, nil
		}
	} else if r.Format == "rfc5424" {
		return stripped, nil
	}

	// Legacy output cannot express NIL timestamp/host; don't invent event data.
	if toks[1] == "-" || toks[2] == "-" {
		return "", permanent("legacy_requires_timestamp_and_host")
	}
	ts, e := parseTimestamp(toks[1])
	if e != nil {
		return "", e
	}
	loc, e := legacyLocation(c.LegacyTimezone)
	if e != nil {
		return "", permanent("invalid_legacy_timezone")
	}
	if strings.ContainsAny(body, "\r\n\x00") {
		return "", permanent("legacy_message_contains_newline")
	}
	// Convert to one documented timezone. RFC3164 has no year/zone/SD fields.
	prefix := fmt.Sprintf("<%d>%s %s ", pri, ts.In(loc).Format("Jan _2 15:04:05"), toks[2])
	if r.Format == "rfc3164" {
		prefix += "plura: "
	}
	wire := prefix + body // CEF has no extra 'plura:' prefix before CEF:0|...
	if len(wire) > c.LegacyMaxMessageBytes {
		return "", permanent("legacy_message_too_large")
	}
	return wire, nil
}
