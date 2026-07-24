# islands-ai

Static host for **AI Visibility Audit** pages, served at `islands-ai.com/audit/<company>`.

Each audit is one self-contained HTML file produced by the `/ai-visibility-audit` skill.
The folder path is the URL: drop the file, push, and it's live.

## Publish a new audit

1. Generate the audit HTML with the `/ai-visibility-audit` skill.
2. Save it as `audit/<company-slug>/index.html`
   (slug = lowercase, hyphenated company name, e.g. `hippo-insurance`).
3. Commit and push to `main`:

   ```bash
   git add audit/<company-slug>/index.html
   git commit -m "audit: <Company Name>"
   git push
   ```

4. GitHub Pages redeploys in ~1 minute. The page is live at
   `https://islands-ai.com/audit/<company-slug>`.

## Notes

- `CNAME` binds the custom domain `islands-ai.com` (do not delete).
- `.nojekyll` tells GitHub Pages to serve files as-is.
- Root `/` redirects to islandshq.xyz. There is no public index of audits,
  so a page is only reachable by its exact slug (share the link with the prospect).
- Repo is public because GitHub Pages custom domains require it on the free tier.
  Audit pages are prospect-facing marketing, not confidential.
