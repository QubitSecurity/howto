package main

import (
	"errors"
	"io"
	"net"
	"net/netip"
	"strconv"
	"strings"
	"time"
)

type pooledConn struct {
	conn     net.Conn
	lastUsed time.Time
}
type Sender struct {
	cfg  Config
	pool map[string]*pooledConn
}

func newSender(c Config) *Sender { return &Sender{cfg: c, pool: make(map[string]*pooledConn)} }
func (s *Sender) Close() {
	for k, v := range s.pool {
		_ = v.conn.Close()
		delete(s.pool, k)
	}
}

func frameMessage(c Config, r Route, raw string) ([]byte, error) {
	if raw == "" || len(raw) > c.MaxMessageBytes || strings.ContainsRune(raw, '\x00') {
		return nil, permanent("message_invalid_size_or_nul")
	}
	if r.Destination.Protocol == "udp" {
		if len(raw) > c.MaxUDPBytes {
			return nil, permanent("udp_message_too_large")
		}
		return []byte(raw), nil
	}
	if r.Framing == "lf" {
		// Never split one event into multiple forged events. Use octet counting for multiline payloads.
		if strings.ContainsAny(raw, "\r\n") {
			return nil, permanent("lf_message_contains_newline")
		}
		return []byte(raw + "\n"), nil
	}
	if r.Framing != "octet-counting" {
		return nil, permanent("unsupported_framing")
	}
	return []byte(strconv.Itoa(len([]byte(raw))) + " " + raw), nil
}

func (s *Sender) Send(r Route, raw string) (int, error) {
	frame, err := frameMessage(s.cfg, r, raw)
	if err != nil {
		return 0, err
	}
	a, err := netip.ParseAddr(r.Destination.IP)
	if err != nil {
		return 0, permanent("destination_requires_literal_ip")
	}
	addr := net.JoinHostPort(a.Unmap().String(), strconv.Itoa(r.Destination.Port))
	key := r.Destination.Protocol + "|" + addr + "|" + r.Framing
	now := time.Now()
	for k, v := range s.pool {
		if now.Sub(v.lastUsed) > time.Duration(s.cfg.ConnectionIdleSeconds)*time.Second {
			_ = v.conn.Close()
			delete(s.pool, k)
		}
	}
	pc, ok := s.pool[key]
	if !ok {
		if len(s.pool) >= s.cfg.MaxConnections {
			var oldest string
			var t time.Time
			for k, v := range s.pool {
				if oldest == "" || v.lastUsed.Before(t) {
					oldest = k
					t = v.lastUsed
				}
			}
			_ = s.pool[oldest].conn.Close()
			delete(s.pool, oldest)
		}
		d := net.Dialer{Timeout: ms(s.cfg.DialTimeoutMS), KeepAlive: 30 * time.Second}
		conn, e := d.Dial(r.Destination.Protocol, addr)
		if e != nil {
			return 0, transient("connect_failed", e)
		}
		pc = &pooledConn{conn: conn}
		s.pool[key] = pc
	}
	discard := func() { _ = pc.conn.Close(); delete(s.pool, key) }
	if err = pc.conn.SetWriteDeadline(time.Now().Add(ms(s.cfg.WriteTimeoutMS))); err != nil {
		discard()
		return 0, transient("deadline_failed", err)
	}
	total := 0
	if r.Destination.Protocol == "udp" {
		n, e := pc.conn.Write(frame)
		total = n
		err = e
		if err == nil && n != len(frame) {
			err = io.ErrShortWrite
		}
	} else {
		for total < len(frame) {
			n, e := pc.conn.Write(frame[total:])
			total += n
			if e != nil {
				err = e
				break
			}
			if n == 0 {
				err = io.ErrNoProgress
				break
			}
		}
	}
	if err != nil {
		discard()
		return total, transient("write_failed", err)
	}
	if total != len(frame) {
		discard()
		return total, transient("write_failed", errors.New("incomplete write"))
	}
	pc.lastUsed = time.Now()
	return total, nil
}
