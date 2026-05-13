# Configuring Network Gear to Send Syslog to Logstash

These devices can't run Elastic Agent, so they send raw syslog to
`logstash.lan:5514` (UDP or TCP). The Logstash pipeline parses both
RFC5424 and RFC3164 formats and indexes into `syslog-network-*`.

## pfSense / OPNsense

Status → System Logs → Settings → Remote Logging Options
- Enable Remote Logging
- Source Address: LAN
- IP/Hostname: `logstash.lan:5514`
- Remote Syslog Contents: check everything you want shipped
  (filter, DHCP, system events, firewall events, etc.)

## UniFi (Dream Machine / CloudKey)

Settings → System → Application Configuration → Remote Syslog Server
- Host: `logstash.lan`
- Port: `5514`
- Enable "Include debug messages" if you want verbose output

On individual UniFi switches/APs in site-wide logging:
Settings → System → Controller Configuration → Remote Logging

## MikroTik RouterOS

```
/system logging action add name=elk target=remote remote=logstash.lan remote-port=5514
/system logging add topics=info action=elk
/system logging add topics=warning action=elk
/system logging add topics=error action=elk
/system logging add topics=critical action=elk
```

## Cisco IOS / IOS-XE

```
logging host logstash.lan transport udp port 5514
logging trap informational
logging source-interface Vlan1
service timestamps log datetime msec
```

## Cisco NX-OS

```
logging server logstash.lan 6 use-vrf default
logging timestamp milliseconds
```

## Juniper (Junos)

```
set system syslog host logstash.lan any info
set system syslog host logstash.lan port 5514
```

## Generic Linux host syslog (if you'd rather not install Elastic Agent)

`/etc/rsyslog.d/50-elk.conf`:
```
*.* @logstash.lan:5514
```
Then `systemctl restart rsyslog`.

## Verifying logs are arriving

From the Logstash VM:
```bash
sudo tcpdump -i any -n port 5514
```

In Kibana → Discover → select data view `syslog-network-*`. If the
data view doesn't exist yet, create it in Stack Management → Data Views.
