# Metadata boundaries

Use the installed Metadata API/file conventions. Static metadata and
`generateMetadata` belong to server route modules and cannot both be exported
in the same segment. Interactive children can remain client components.

Metadata merges shallowly: replacing a nested object can drop inherited images,
descriptions or robot fields. Homepage canonical/social URLs should not
misidentify child pages. File-based metadata has priority over matching config.

Viewport settings have a separate export. In 16, `params` and the
`generateImageMetadata` `id` passed to `opengraph-image`/`icon` functions are
Promises, and `sitemap` receives `id` as `Promise<string>`. With Cache
Components, `generateMetadata` reading runtime or uncached data is a
prerender error; see the `cache-components` skill.

Use `ImageResponse` only when generated images are useful. Its CSS/fonts/bundle
constraints differ from browser rendering. A static social image is often enough.

For crawlability, structured data, bots and production metadata verification,
use `nextjs-seo`. Start from `03-api-reference/04-functions/generate-metadata.md`
and `03-api-reference/03-file-conventions/01-metadata/`.
