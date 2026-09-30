# Structured data

Start from the page's real content and intended consumer. Schema.org validity
and Google rich-result eligibility are different checks. Consult the current
[Google search gallery](https://developers.google.com/search/docs/appearance/structured-data/search-gallery)
and the selected feature's documentation before choosing a type; supported
features and restrictions change.

Mark up only facts users can verify on the page or through its legitimate
associated content. Do not invent reviews, ratings, prices, stock, authors,
credentials or organization details. An optional FAQ section does not justify
schema solely for search visibility.

Use stable absolute URLs and identifiers for the relevant entities. Share
organization/page data where useful; `@graph` is an organizational option,
not a requirement. Avoid conflicting duplicates from manual markup and a
library. In App Router, a plain `application/ld+json` script is appropriate;
it does not require executable-script loading strategies.

Serialize data safely. JSON text inside an HTML script can contain
`</script>`; escape `<` after JSON serialization or use an established safe
serializer. Do not concatenate untrusted strings into markup. See the
[Next.js JSON-LD guide](https://nextjs.org/docs/app/guides/json-ld).

Validate the served production markup with the relevant consumer's validator.
Google's Rich Results Test assesses supported features; a Schema.org
validator answers a broader vocabulary question. Fix invalid or misleading
markup, then inspect Search Console reporting where available. Valid markup
does not guarantee a rich result or ranking improvement.
