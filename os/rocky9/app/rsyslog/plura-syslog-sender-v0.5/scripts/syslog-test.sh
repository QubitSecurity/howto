#!/usr/bin/env bash
# Bash + coreutils only. TCP ingress uses RFC6587 octet counting.
# Positional args remain compatible with v0.4.1. Optional args 7/8 select output.
# tcp 'message' LB_IP CUSTOMER_IP PORT udp|tcp [rfc5424|rfc3164|cef] [cef_header]
set -euo pipefail
transport=${1:-tcp}
message=${2:-'PLURA-XDR TEST'}
gateway=${3:?Argument 3 must be the actual HAProxy listen IP}
dest=${4:-172.16.12.212}
dport=${5:-514}
protocol=${6:-udp}
format=${7:-rfc5424}
header=${8:-rfc3164}
gport=${GATEWAY_PORT:-514}
framing=${FRAMING:-octet-counting}
for ip in "$gateway" "$dest"; do
  [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || { echo "IPv4 required: $ip" >&2; exit 2; }
  IFS=. read -r a b c d <<<"$ip"
  for n in "$a" "$b" "$c" "$d"; do
    [[ $n == 0 || $n != 0* ]] && ((10#$n<=255)) || { echo "invalid/canonical IPv4: $ip" >&2; exit 2; }
  done
done
for p in "$dport" "$gport"; do [[ $p =~ ^[1-9][0-9]{0,4}$ ]] && ((p<=65535)) || { echo "invalid port: $p" >&2; exit 2; }; done
[[ $transport == tcp ]] || { echo 'HA ingress is TCP only; customer output can still use UDP.' >&2; exit 2; }
[[ $protocol == udp || $protocol == tcp ]] || { echo 'customer protocol must be udp or tcp' >&2; exit 2; }
case $format in rfc5424|rfc3164|cef) ;; *) echo 'format must be rfc5424, rfc3164 or cef' >&2;exit 2;; esac
if [[ $protocol == udp ]];then framing=none;else [[ $framing == lf || $framing == octet-counting ]] || exit 2;fi
[[ $message != *$'\r'* && $message != *$'\n'* ]] || { echo 'Use literal escaped \\n in CEF values, not a physical newline.' >&2;exit 2; }
extra=" format=\"${format}\""
if [[ $format == cef ]];then
  [[ $header == rfc3164 || $header == rfc5424 ]] || { echo 'CEF header must be rfc3164 or rfc5424' >&2;exit 2; }
  [[ $message == CEF:0\|* || $message == CEF:1\|* ]] || { echo 'Supply a complete MSA-built CEF body.' >&2;exit 2; }
  extra+=" header=\"${header}\""
elif (($#>=8));then echo 'Argument 8 is only for CEF.' >&2;exit 2
fi
timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
host=${HOSTNAME:-test-msa};host=${host//[^A-Za-z0-9._-]/_};host=${host:0:100}
sd="[pluraRelay@32473 dst=\"${dest}\" port=\"${dport}\" proto=\"${protocol}\" framing=\"${framing}\"${extra}]"
raw="<134>1 ${timestamp} ${host} plura-relay - - ${sd} ${message}"
export LC_ALL=C
bytes=${#raw}
((bytes<=8192)) || { echo 'Full internal RFC5424 message exceeds 8192 bytes.' >&2;exit 2; }
# Bash TCP connect timeouts depend on the OS; this is a one-shot test, not a queue.
exec 3>"/dev/tcp/${gateway}/${gport}"
printf '%s %s' "$bytes" "$raw" >&3
exec 3>&-
printf 'Written to %s:%s TCP; requested customer %s:%s %s, format=%s\n' "$gateway" "$gport" "$dest" "$dport" "$protocol" "$format"
printf 'This is local socket-write completion, NOT customer delivery confirmation.\n'
