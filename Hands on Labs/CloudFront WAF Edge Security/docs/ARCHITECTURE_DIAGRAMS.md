# Architecture Diagrams: AWS WAF CloudFront Edge Security

## Request Flow (With WAF Protection)

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Internet Users                               │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    CloudFront Edge Location                          │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS WAF Web ACL                              │
│  • SQL Injection Detection                                          │
│  • XSS Pattern Matching                                             │
│  • Rate Limit Enforcement                                           │
│  • Geo-Location Check                                               │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
           ┌──────────────┐          ┌──────────────┐
           │   BLOCKED    │          │   ALLOWED    │
           │   (403)      │          │              │
           └──────────────┘          └──────┬───────┘
                                            │
                                            ▼
                               ┌─────────────────────────┐
                               │   Amazon S3 (Private)   │
                               │   via OAI               │
                               └─────────────────────────┘
```

## Security Stack

```
Layer 1: Edge Protection (CloudFront + WAF)
  • HTTPS/TLS termination
  • DDoS protection (AWS Shield Standard)
  • WAF rule enforcement

Layer 2: Web Application Firewall
  • OWASP Top 10 protection
  • Rate limiting
  • Bot detection
  • Geo-blocking

Layer 3: Origin Access Control
  • Origin Access Identity (OAI)
  • S3 bucket policy (CloudFront only)

Layer 4: Data Protection
  • S3 Server-Side Encryption
  • TLS 1.2+ minimum
```

---

*Author: Shashank Chinchli, AWS Solutions Architect*
