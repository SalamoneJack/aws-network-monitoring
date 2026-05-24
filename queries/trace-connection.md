# Trace a Specific Connection

Follow all flow log records for a specific source IP, destination IP, or both. Use this during an incident when you know the IPs involved and need to reconstruct the full conversation.

## Query: All Traffic From a Specific Source IP

```
fields @timestamp, srcaddr, dstaddr, srcport, dstport, protocol, action, bytes
| filter srcaddr = "1.2.3.4"
| sort @timestamp asc
```

## Query: All Traffic Between Two Specific IPs

```
fields @timestamp, srcaddr, dstaddr, srcport, dstport, protocol, action, bytes
| filter (srcaddr = "10.0.1.5" and dstaddr = "10.0.2.10")
    or (srcaddr = "10.0.2.10" and dstaddr = "10.0.1.5")
| sort @timestamp asc
```

## Query: Did a Specific Connection Succeed?

```
fields @timestamp, srcaddr, dstaddr, dstport, action, bytes
| filter srcaddr = "10.0.1.5" and dstaddr = "10.0.2.10" and dstport = 443
| sort @timestamp desc
| limit 20
```

- action = "ACCEPT" → the connection reached the destination (network allowed it)
- action = "REJECT" → blocked by SG or NACL (network problem)
- ACCEPT with no response bytes → application not responding (not a network problem)

## Query: Port Scan Detection (many ports from one source)

```
fields srcaddr, dstport
| filter srcaddr = "1.2.3.4"
| stats count_distinct(dstport) as uniquePorts by srcaddr
| sort uniquePorts desc
```

A single source hitting many unique destination ports in a short time = port scan.

## Troubleshooting Workflow

1. Get the source and destination IPs from the application error log or user report
2. Run "All traffic between two IPs" for the time window of the reported failure
3. Check `action`: ACCEPT = network worked, REJECT = network blocked it
4. If ACCEPT: look at `bytes` — if bytes > 0 on the request but 0 on the response, the app received it but didn't respond
5. If REJECT: check the security group rules on the destination instance
