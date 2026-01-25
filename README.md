# Security Engineering on AWS

**Hands-On Labs to Become a Cloud Security Architect & Engineer on AWS**

[![AWS](https://img.shields.io/badge/AWS-Security-FF9900?logo=amazon-aws)](https://aws.amazon.com/security/)
[![Well-Architected](https://img.shields.io/badge/AWS-Well--Architected-blue)](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## Why This Repository?

**Security Engineering on AWS** is a hands-on learning path for developers, DevOps engineers, and security professionals transitioning into **Cloud Security Architect** and **Cloud Security Engineer** roles.

Each lab implements **real-world AWS security patterns** aligned with the [AWS Well-Architected Framework - Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html).

---

## 🎯 Learning Approach

- ✅ **Deploy real AWS infrastructure** — not simulations
- ✅ **Production-grade patterns** — used in enterprise environments
- ✅ **Cost-transparent** — pricing breakdowns and cleanup scripts included
- ✅ **Well-Architected aligned** — follows AWS security best practices

---

## 📋 Available Labs

| # | Lab | Services | Duration | Level |
|---|-----|----------|----------|-------|
| 1 | [AWS KMS Masterclass - Encryption, Key Rotation & Multi-Region Keys](Hands%20on%20Labs/AWS%20KMS%20Masterclass%20-%20Encryption%2C%20Key%20Rotation%2C%20and%20Multi-Region%20Keys%20(Hands-On%20Lab)/README.md) | KMS, S3, IAM | 45 min | Intermediate |
| 2 | [Zero-Downtime Credential Rotation](Hands%20on%20Labs/Securing%20RDS%20Database%20Credentials%20with%20AWS%20KMS%20and%20Secrets%20Manager%20(Hands-On%2C%20Zero-Downtime%20Rotation)/README.md) | KMS, Secrets Manager, RDS, Lambda | 30 min | Intermediate |

*More labs coming soon: VPC Security, WAF, GuardDuty, Security Hub, IAM Access Analyzer*

---

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/schinchli/Security-Engineering-on-AWS.git

# Navigate to a lab
cd "Hands on Labs/Securing RDS Database Credentials with AWS KMS and Secrets Manager (Hands-On, Zero-Downtime Rotation)"

# Deploy
./scripts/deploy.sh

# Cleanup when done
./scripts/cleanup.sh
```

---

## 🎯 Who This Is For

| Role | What You'll Gain |
|------|------------------|
| **Aspiring Cloud Security Architects** | Design secure AWS architectures |
| **Cloud Security Engineers** | Implement encryption, IAM, secrets management |
| **DevSecOps Professionals** | Automate security in CI/CD pipelines |
| **AWS Certification Candidates** | Hands-on prep for Security Specialty |

---

## 🔒 Security Standards

All labs follow strict security practices:

- ✅ No hardcoded credentials — secrets generated dynamically
- ✅ Least-privilege IAM policies
- ✅ Encryption at rest and in transit
- ✅ [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html) alignment

---

## 📚 AWS References

| Resource | Link |
|----------|------|
| Well-Architected Security Pillar | [Documentation](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html) |
| AWS Security Best Practices | [Whitepaper](https://docs.aws.amazon.com/whitepapers/latest/aws-security-best-practices/welcome.html) |

---

## 📖 Recommended Reading

- **Security:** [How to Use AWS Security Agent for Automated Vulnerability Detection and Remediation?](https://aws.plainenglish.io/how-to-use-aws-security-agent-for-automated-vulnerability-detection-and-remediation-cfdaef9af5b8)

---

## 📄 License

MIT License — free for learning and commercial use.

---

## 👤 Author

If this repo helped you and you'd like deeper guidance or hands-on support, feel free to reach out for [1:1 mentoring on Topmate](https://topmate.io/heyshashank). You can also explore my [Credly badges](https://www.credly.com/users/shashank-chinchli/badges) and connect with me on [LinkedIn](https://www.linkedin.com/in/shashankk/).

**Shashank Chinchli** — ex-AWS Solutions Architect & Golden Jacket Holder

[![GitHub](https://img.shields.io/badge/GitHub-schinchli-black?logo=github)](https://github.com/schinchli)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-shashankk-blue?logo=linkedin)](https://www.linkedin.com/in/shashankk/)
[![Credly](https://img.shields.io/badge/Credly-Badges-orange?logo=credly)](https://www.credly.com/users/shashank-chinchli/badges)
[![Topmate](https://img.shields.io/badge/Topmate-1:1_Mentoring-blueviolet)](https://topmate.io/heyshashank)

---

**Build real AWS security skills. Think like a Cloud Security Architect. Engineer like production.** Star this repository to follow upcoming AWS security labs.
