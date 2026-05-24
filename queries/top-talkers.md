# Top Talkers — Highest Traffic Sources

Identifies which source IPs are generating the most traffic. Run this first when investigating bandwidth spikes or unexpectedly high data transfer costs.

## Query

```
fields srcaddr, bytes
| filter action = "ACCEPT"
| stats sum(bytes) as totalBytes by srcaddr
| sort totalBytes desc
| limit 20
```

## Variant: Top Talkers by Destination

```
fields dstaddr, bytes
| filter action = "ACCEPT"
| stats sum(bytes) as totalBytes by dstaddr
| sort totalBytes desc
| limit 20
```

## Variant: Top Talkers for a Specific Time Window

Set the time range in the Logs Insights UI (top right). For incident investigation, use the 1-hour window centered on the incident time.

## How to Interpret

- Internal IPs (10.x.x.x) are usually expected sources — verify they're known instances
- If an EC2 instance shows unexpectedly high outbound bytes, investigate what it's connecting to
- For cross-AZ or cross-region traffic, high byte counts drive up costs
