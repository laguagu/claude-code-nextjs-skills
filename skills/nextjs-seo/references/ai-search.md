# AI search and crawler controls

## Contents

- Eligibility and evidence
- Useful content without filler
- Crawlers and policy
- robots.ts example
- llms.txt
- Measurement and sources

## Eligibility and evidence

Google says AI Overviews and AI Mode need no special schema or AI text file.
The page must be indexed and eligible for a Search snippet. This is eligibility,
not a guarantee of selection or citation. Apply ordinary technical SEO first.

Do not describe FAQPage, a TL;DR, llms.txt, an author bio or a particular word
count as a demonstrated AI ranking factor. Separate vendor-documented behavior
from hypotheses. Keep markup only when it describes real page content and serves
a known consumer; do not add a FAQ solely to produce FAQPage JSON-LD.

## Useful content without filler

Answer the actual question directly. Use descriptive headings and original,
verifiable information. Add a Q&A section only for useful questions that the
page has not already answered. Do not repeat the hero in a summary, FAQ and
keyword paragraph. There is no required opening word count.

A visible update date helps when freshness matters, but must track meaningful
changes. Keep the primary answer available in server-rendered HTML where
practical; crawler JavaScript support varies. Clear HTML is more portable than
relying on client-only fetching.

## Crawlers and policy

Check current vendor docs before changing robots rules. Training, search and
user-initiated fetching are different purposes; a vendor may use separate bots
or a product-control token. Preserve the owner's policy instead of copying a
blanket allow/block list.

| Vendor | Training | Search | User-initiated retrieval |
|--------|----------|--------|--------------------------|
| OpenAI | GPTBot | OAI-SearchBot | ChatGPT-User |
| Anthropic | ClaudeBot | Claude-SearchBot | Claude-User |
| Perplexity | None (PerplexityBot is not used for training) | PerplexityBot | Perplexity-User |

Google Search and its AI features use Googlebot controls. `Google-Extended`
has no separate HTTP user agent: it is a robots product token controlling both
Gemini training and certain Gemini/Vertex AI grounding uses. It does not control
Google Search inclusion or ranking. Do not call it a training-only switch or
promise that blocking it has no effect on all AI referral channels.

Blocking a search crawler can prevent direct content retrieval; it does not
prove that a URL or brand can never be mentioned through other sources.
User-initiated fetchers differ: OpenAI says robots.txt "may not apply" to
ChatGPT-User, Perplexity-User generally ignores it, and Anthropic says all three
of its bots honor it. Each vendor's settings are independent, so allowing
OAI-SearchBot while disallowing GPTBot is a valid policy.

robots.txt is voluntary and is not authorization or access control. Inspect
hosting firewall rules separately when diagnosing denied public crawls. A
User-Agent string can be spoofed; use vendor-documented verification methods
for bot identity, and do not weaken preview protection to make an audit pass.

## robots.ts example

Start with the existing wildcard policy. Add named groups only when a deliberate
exception is needed. Specific groups do not inherit wildcard restrictions.

```typescript
import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  const disallow = ['/api/', '/admin/'];
  return {
    rules: [
      { userAgent: '*', allow: '/', disallow },
      // Only if the owner chooses to opt out of OpenAI training:
      // { userAgent: 'GPTBot', disallow: '/' },
      // If a named search group is needed, repeat the restrictions:
      // { userAgent: 'OAI-SearchBot', allow: '/', disallow },
    ],
    sitemap: 'https://your-site.com/sitemap.xml',
  };
}
```

## llms.txt

Treat llms.txt as an optional documentation-discovery convention, not a Google
SEO requirement or a proven citation boost. It can be useful when developers or
agents explicitly consume documentation through it. Verify the intended consumer
before adding it. Prefer a static `public/llms.txt` for a fixed document; use a
Route Handler only when generation is needed, with caching supported by the
installed Next.js configuration. Do not copy `dynamic = 'force-static'` into a
Cache Components app.

## Measurement and sources

Use referral analytics and concrete citation examples to observe changes.
Missing referrals do not prove missing citations; crawler hits do not prove
citations. Google's Search Console includes AI-feature traffic in overall Web
search reporting, so do not label the whole export as AI traffic.

Sources to re-check for changing policies:
- [Google AI features](https://developers.google.com/search/docs/appearance/ai-features)
- [Google-Extended](https://developers.google.com/crawling/docs/crawlers-fetchers/google-common-crawlers#google-extended)
- [OpenAI crawlers](https://developers.openai.com/api/docs/bots)
- [Anthropic crawlers](https://support.claude.com/en/articles/8896518-does-anthropic-crawl-data-from-the-web-and-how-can-site-owners-block-the-crawler)
- [Perplexity crawlers](https://docs.perplexity.ai/guides/bots)
- [llms.txt proposal](https://llmstxt.org/)
