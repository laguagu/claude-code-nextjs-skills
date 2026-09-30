# Metadata boundaries

Use the installed Metadata API/file conventions. Static metadata and
`generateMetadata` belong to server route modules and cannot both be exported
in the same segment. Interactive children can remain client components.

Metadata merges shallowly: replacing a nested object can drop inherited images,
descriptions or robot fields. Homepage canonical/social URLs should not
misidentify child pages. File-based metadata has priority over matching config.

Viewport settings have a separate export. Async route params, image IDs and
sitemap IDs need the installed signature. In 16, the image-generating function
receives `params` and `id` as promises, but `generateImageMetadata` itself
continues to receive synchronous `params`. The sitemap generator receives
`id: Promise<string>`. Cache Components also imposes
serialization/freshness requirements on cached metadata output.

Use `ImageResponse` only when generated images are useful. Its CSS/fonts/bundle
constraints differ from browser rendering. A static social image is often enough.

For crawlability, structured data, bots and production metadata verification,
use `nextjs-seo`. Start from
[generateMetadata](https://nextjs.org/docs/app/api-reference/functions/generate-metadata).
