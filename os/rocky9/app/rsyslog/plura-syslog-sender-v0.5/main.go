// Go Sender v0.5: rsyslog omprog child reading JSON envelopes on stdin.
// The RFC5424 relay Structured Data contains an IP/port/protocol; no route DB.
package main

import (
	"bufio"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"os"
	"time"
)

var version = "0.5.0"

func eventHash(raw string) string { h := sha256.Sum256([]byte(raw)); return hex.EncodeToString(h[:8]) }

type Processor struct {
	cfg                             Config
	sender                          *Sender
	log                             *slog.Logger
	received, sent, failed, dropped uint64
	lastStats                       time.Time
}

func (p *Processor) process(b []byte) string {
	// Health probes use the SAME omprog action queue as business messages.
	// They never become a network relay job and must never block that queue.
	var probeEnv Envelope
	if decodeStrict(b, &probeEnv) == nil && probeEnv.App == healthApp {
		if err := acknowledgeHealthProbe(probeEnv, p.cfg); err != nil {
			p.log.Warn("health_probe_rejected", "reason", errorCode(err), "error", err.Error())
		}
		return "OK"
	}
	p.received++
	env, parsed, err := parseEnvelope(b, p.cfg)
	var n int
	if err == nil {
		n, err = p.sender.Send(parsed.Route, parsed.Wire)
	}
	if err != nil {
		if isPermanent(err) {
			p.dropped++
			p.log.Warn("dropped", "reason", errorCode(err), "eventHash", eventHash(env.Raw), "ackMeaning", "discarded_not_delivered")
			return "OK"
		}
		p.failed++
		p.log.Error("retry_requested", "reason", errorCode(err), "error", err.Error(), "eventHash", eventHash(env.Raw))
		return "ERR"
	}
	p.sent++
	if p.cfg.Debug {
		p.log.Info("socket_write_ok", "destination", parsed.Route.Destination, "format", parsed.Route.Format, "header", parsed.Route.Header, "wireBytes", n, "eventHash", eventHash(env.Raw), "deliveryConfirmed", false)
	}
	return "OK"
}
func (p *Processor) stats(force bool) {
	if force || time.Since(p.lastStats) >= 30*time.Second {
		p.log.Info("stats", "processedAttempts", p.received, "socketWriteOK", p.sent, "retryRequested", p.failed, "dropped", p.dropped)
		p.lastStats = time.Now()
	}
}
func boundedLine(r *bufio.Reader, max int) ([]byte, bool, error) {
	var line []byte
	long := false
	for {
		part, err := r.ReadSlice('\n')
		if !long {
			if len(line)+len(part) > max {
				long = true
				line = nil
			} else {
				line = append(line, part...)
			}
		}
		if err == bufio.ErrBufferFull {
			continue
		}
		if err == nil {
			if !long && len(line) > 0 {
				line = line[:len(line)-1]
			}
			return line, long, nil
		}
		if err == io.EOF && (len(line) > 0 || long) {
			return line, long, nil
		}
		return line, long, err
	}
}
func run(c Config, in io.Reader, out io.Writer, logger *slog.Logger) error {
	sender := newSender(c)
	defer sender.Close()
	p := &Processor{cfg: c, sender: sender, log: logger, lastStats: time.Now()}
	defer p.stats(true)
	if _, err := io.WriteString(out, "OK\n"); err != nil {
		return err
	}
	logger.Info("started", "version", version, "routeSource", "rfc5424-structured-data", "persistentQueue", false, "debug", c.Debug)
	reader := bufio.NewReaderSize(in, 64*1024)
	for {
		b, long, err := boundedLine(reader, c.MaxMessageBytes*6+4096)
		if errors.Is(err, io.EOF) {
			return nil
		}
		if err != nil {
			return err
		}
		ack := "OK"
		if long {
			p.received++
			p.dropped++
			logger.Warn("dropped", "reason", "envelope_too_large")
		} else {
			ack = p.process(b)
		}
		if _, err = fmt.Fprintln(out, ack); err != nil {
			return err
		}
		p.stats(false)
	}
}
func main() {
	path := flag.String("config", "/etc/plura-syslog/sender.json", "sender config JSON")
	check := flag.Bool("check-config", false, "validate configuration without sending")
	ver := flag.Bool("version", false, "print version")
	health := flag.Bool("health", false, "run readiness HTTP daemon; -config points to health.json")
	pair := flag.String("check-pair", "", "validate sender -config with this health.json path; no network IO")
	flag.Parse()
	if *ver {
		fmt.Println(version)
		return
	}
	log := slog.New(slog.NewJSONHandler(os.Stderr, nil))
	if *health {
		cfg, err := loadHealthConfig(*path)
		if err != nil {
			log.Error("health_configuration_error", "error", err.Error())
			os.Exit(2)
		}
		if *check {
			log.Info("health_config_check_ok", "node", cfg.NodeID)
			return
		}
		if err := serveHealth(cfg, log); err != nil {
			log.Error("health_exit", "error", err.Error())
			os.Exit(1)
		}
		return
	}
	cfg, err := loadConfig(*path)
	if err != nil {
		log.Error("configuration_error", "error", err.Error())
		os.Exit(2)
	}
	if *pair != "" {
		hc, err := loadHealthConfig(*pair)
		if err == nil {
			err = validateConfigPair(cfg, hc)
		}
		if err != nil {
			log.Error("config_pair_error", "error", err.Error())
			os.Exit(2)
		}
		log.Info("config_pair_ok", "node", hc.NodeID)
		return
	}
	if *check {
		log.Info("config_check_ok", "allowedSources", len(cfg.AllowedSourceIPs), "allowedDestinationCidrs", len(cfg.AllowedDestinationCIDRs))
		return
	}
	if err = run(cfg, os.Stdin, os.Stdout, log); err != nil {
		log.Error("sender_exit", "error", err.Error())
		os.Exit(1)
	}
}
