# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`fixably` is a Ruby gem wrapping the [Fixably API](https://docs.fixably.com) v3.
It is built on top of Active Resource and monkey patches it heavily so that the
Fixably API's non-standard conventions (camelCase keys, a single `q` query
parameter, link expansion, hash-wrapped collections) look like an ordinary
Rails-style model layer to callers.

Ruby >= 3.0. The gem has one runtime dependency: `activeresource` (>= 5, < 7).

## Commands

```sh
bundle exec rake          # default task: rspec + rubocop
bundle exec rspec         # full test suite
bundle exec rspec spec/fixably/resources/order_spec.rb          # single file
bundle exec rspec spec/fixably/resources/order_spec.rb:42       # single example
bundle exec rspec --only-failures                               # uses .rspec_status
bundle exec rubocop -a    # lint with safe autocorrect
bin/console               # IRB with the gem loaded
```

Mutation testing runs via `bin/mutant` (`bin/mutant run`), which requires the
`mutant-license` gem from a private source declared in the `Gemfile`. Subjects
and exclusions live in `.mutant.yml`.

Tests never hit the network — specs stub `described_class.connection` and assert
on the exact path/body that *would* have been sent. `spec/helpers/config.rb`
sets a dummy api_key/subdomain globally in `spec_helper`, so no `.env` file is
needed (the README's dotenv instructions are stale).

## Architecture

### Layering

`ApplicationResource < ActiveResource::Base` ([lib/fixably/application_resource.rb](lib/fixably/application_resource.rb))
is the base class every resource inherits from. It composes four mixins, each
solving one impedance mismatch with the Fixably API:

- **`Actions`** ([lib/fixably/actions.rb](lib/fixably/actions.rb)) — overrides
  every Active Resource entry point (`all`, `create`, `find`, `first`, `last`,
  `where`, `save`, `destroy`…) to gate on `ActionPolicy` and to run arguments
  through `ArgumentParameterisation` before delegating to `super`.
- **`Encoding`** ([lib/fixably/encoding.rb](lib/fixably/encoding.rb)) — on
  write, converts underscored keys back to camelCase, strips read-only
  attributes (`remove_on_encode`) and has_many associations, and nests the
  payload under the parent association name when creating a nested record.
- **`LoadFromResponse`** ([lib/fixably/load_from_response.rb](lib/fixably/load_from_response.rb))
  — on read, underscores keys, unwraps single-element array responses, turns
  nested collection hashes into `PaginatedCollection`s, and deletes
  href-only "empty" associations so Active Resource doesn't mistake them for
  real records.
- **`Authorization`** ([lib/fixably/authorization.rb](lib/fixably/authorization.rb))
  — injects the API key into request headers.

### The Active Resource monkey patch

[lib/fixably/active_resource/base.rb](lib/fixably/active_resource/base.rb)
patches `ActiveResource::Base` itself (aliasing the originals):

- `instantiate_record` deep-underscores every incoming key.
- `query_string` collapses all non-pagination filters into Fixably's single
  `q=attribute:value,attribute:value` parameter; `expand`, `limit`, `offset`
  and `page` pass through untouched (`non_query_parameters`).

It also installs `Fixably::ActiveResource::PaginatedCollection` as the global
`collection_parser`. Changing behaviour here affects *all* resources, so this
file is the first place to look when request/response shapes are wrong.

### URLs are derived from class nesting

`ApplicationResource.site_url` builds the endpoint from the class name:

- `Fixably::Customer` → `https://<subdomain>.fixably.com/api/v3`
- `Fixably::Order::Note` → `.../api/v3/orders/:order_id` (the middle name part
  is pluralised and becomes a prefix option)

So nesting a class under another resource is what makes it a nested endpoint.
`CreateHasManyRecord` relies on the same convention: appending to a has_many
collection (`order.notes << note`) sets `parent_association`, fills in the
`:<parent>_id` prefix option, and saves — and it refuses records nested more
than one level deep.

### Permissions are declarative

Each resource declares `actions %i[create delete list show update]` — only the
subset Fixably actually supports. `ActionPolicy`
([lib/fixably/action_policy.rb](lib/fixably/action_policy.rb)) raises
`Fixably::UnsupportedError` for anything not declared. When adding a resource,
the `actions` list is the contract; the specs' shared examples take it as an
argument and generate the matching request expectations.

### Link expansion and pagination

Fixably returns collections as bare `href` stubs unless asked to expand, so
`ArgumentParameterisation` always adds `expand=items` for list scopes and
`ResourceLazyLoader` (behind `Model.includes(:assoc)`) merges extra
associations into that parameter — `has_one` expands as `assocName`,
`has_many` as `assocName(items)`.

`PaginatedCollection` wraps the `{limit, offset, totalItems, items}` envelope
and adds `next_page`/`previous_page`/`paginated_each`/`paginated_map`.
`Actions.last` is non-trivial: it fetches a page, then re-requests with
`offset: total_items - 1` when the last record isn't in the current page.

Array values in `where` become Fixably ranged searches (`[from,to]`), with
`Date`/`Time` values formatted as `%F` — see
`ArgumentParameterisation#stringify_array_values`.

## Adding a resource

1. Create `lib/fixably/resources/<name>.rb` subclassing `ApplicationResource`
   (or nest the class inside its parent resource for nested endpoints).
2. Declare `actions`, a `schema` block (only attributes Fixably accepts on
   create/update), associations, and any validations.
3. Require it from [lib/fixably.rb](lib/fixably.rb).
4. Add a spec using the `"a resource"` / `"a nested resource"` shared examples
   in [spec/support/shared_examples/](spec/support/shared_examples/).
5. Document it in `docs/<name>.md` and link it from the README's supported
   resources list.

## Conventions

- Style is enforced by [.rubocop.yml](.rubocop.yml): double quotes, trailing
  dot for multiline chains, trailing commas in multiline literals, endless
  methods (`def api_version = "v3"`) and numbered block params (`_1`) are
  used liberally, and `# frozen_string_literal: true` heads every file.
- Bump `Fixably::VERSION` in [lib/fixably/version.rb](lib/fixably/version.rb)
  for releases; built gems are committed under `pkg/`.
- `webhook_events/` holds captured sample webhook payloads (untracked
  reference data, not used by code or tests).
