# Rejected Connections — Security Group and NACL Blocks

Shows which connections are being blocked by security groups or NACLs. High reject counts usually mean a misconfigured security group, a brute-force attempt, or a port scan.

## Query: All Rejects by Source

```
fields srcaddr, dstaddr, dstport, protocol
| filter action = "REJECT"
| stats count(*) as rejectCount by srcaddr, dstaddr, dstport
| sort rejectCount desc
| limit 20
```

## Query: SSH Brute Force Detection

```
fields srcaddr, dstaddr, dstport, action
| filter dstport = 22 and action = "REJECT"
| stats count(*) as attempts by srcaddr
| sort attempts desc
| limit 10
```

A single IP with >50 rejected SSH attempts in a short window is a brute-force indicator.

## Query: Database Connection Rejections (MySQL/PostgreSQL)

```
fields srcaddr, dstaddr, dstport, action
| filter (dstport = 3306 or dstport = 5432) and action = "REJECT"
| stats count(*) as rejectCount by srcaddr, dstaddr, dstport
| sort rejectCount desc
```

If the app server is being rejected by the DB: the security group on the DB instance likely doesn't allow the app server's security group or CIDR.

## Query: All Rejects in the Last Hour (for incident triage)

```
fields @timestamp, srcaddr, dstaddr, srcport, dstport, protocol, action
| filter action = "REJECT"
| sort @timestamp desc
| limit 100
```

## How to Interpret

- REJECT + srcaddr is an external IP → blocked inbound from internet (usually expected)
- REJECT + srcaddr is an internal IP → security group misconfiguration (investigate rule)
- High reject rate from one source → potential scan or brute force (consider security group block or WAF)
