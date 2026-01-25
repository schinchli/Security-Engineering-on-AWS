# Claude Context for Lab Management

## New Lab Addition Workflow

When adding a new lab to this repository:

### 1. Update Security-Engineering-on-AWS README
- Add lab to Available Labs table in `/README.md`
- Format: `| # | [Lab Name](Hands%20on%20Labs/Lab-Folder-Name/README.md) | Services | Duration | Level |`
- URL-encode spaces as `%20` and special characters

### 2. Update How-to-Become-an-AWS-Solutions-Architect README
- Add lab to Available Labs table with Domain column
- Link to external GitHub URL: `https://github.com/schinchli/Security-Engineering-on-AWS/tree/main/Hands%20on%20Labs/...`
- Security labs should have Domain = "Security"

### 3. Housekeeping - Validate Hyperlinks
After each update, validate:
- Local README links exist in repo
- External GitHub links return HTTP 200
- Recommended Reading links are accessible

### Repository Links
- **Architecting**: https://github.com/schinchli/How-to-Become-an-AWS-Solutions-Architect
- **Security Engineering**: https://github.com/schinchli/Security-Engineering-on-AWS

### Current Labs Structure

**Security-Engineering-on-AWS:**
| # | Lab | Services |
|---|-----|----------|
| 1 | AWS KMS Masterclass | KMS, S3, IAM |
| 2 | Zero-Downtime Credential Rotation | KMS, Secrets Manager, RDS, Lambda |

**How-to-Become-an-AWS-Solutions-Architect (Security Domain):**
| # | Lab | Domain |
|---|-----|--------|
| 4 | Securing RDS Credentials (Zero-Downtime Rotation) | Security |
| 5 | RDS Secrets with KMS | Security |
