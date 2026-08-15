# hermes-clinepass-provider

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Model-provider plugin for [Hermes Agent](https://github.com/NousResearch/hermes-agent) that adds
[ClinePass](https://docs.cline.bot/getting-started/clinepass) (Cline's $9.99/month subscription)
as an LLM provider — 11 curated open-weight coding models via an OpenAI-compatible API:

| Model | ID | Context |
|---|---|---|
| GLM-5.2 | `cline-pass/glm-5.2` | 200K |
| Kimi K2.7 Code | `cline-pass/kimi-k2.7-code` | 262K |
| Kimi K2.6 | `cline-pass/kimi-k2.6` | 262K |
| Kimi K3 | `cline-pass/kimi-k3` | 1M |
| DeepSeek V4 Pro | `cline-pass/deepseek-v4-pro` | 1M |
| DeepSeek V4 Flash | `cline-pass/deepseek-v4-flash` | 1M |
| MiMo-V2.5 | `cline-pass/mimo-v2.5` | 262K |
| MiMo-V2.5-Pro | `cline-pass/mimo-v2.5-pro` | 262K |
| MiniMax M3 | `cline-pass/minimax-m3` | 1M |
| Qwen3.7 Max | `cline-pass/qwen3.7-max` | 262K |
| Qwen3.7 Plus | `cline-pass/qwen3.7-plus` | 1M |

## Install

```sh
git clone https://github.com/LorenzCard/hermes-clinepass-provider.git
cd hermes-clinepass-provider
./install.sh
```

`install.sh` copies the plugin to `$HERMES_HOME/plugins/model-providers/clinepass/`
(default `~/.hermes/`) and to every `~/.hermes/profiles/*/` that exists.

Then set your API key (from [app.cline.bot](https://app.cline.bot/) → Settings → API Keys):

```sh
echo 'CLINE_API_KEY=sk_...' >> ~/.hermes/.env
```

## Usage

```sh
# one-shot
hermes chat -q "Reply with exactly: OK" --provider clinepass -m cline-pass/glm-5.2 -Q

# interactive
hermes chat --provider clinepass -m cline-pass/kimi-k3
```

Or in-session: `/model clinepass/cline-pass/glm-5.2`

Aliases: `clinepass`, `cline-pass`, `cline_pass`, `clinepass-provider`.

## Known limitation — non-streaming envelope (IMPORTANT)

`api.cline.bot` wraps **non-streaming** Chat Completions in a gateway envelope:

```json
{"data": { "...openai chat.completion..." }, "success": true}
```

The OpenAI SDK then sees `choices=None`, which breaks every Hermes path that
uses non-streaming completions: session titles, summaries, context compaction,
memory reads. **Streaming is standard OpenAI SSE and works fine** — normal chat
is unaffected.

Tracked upstream: [NousResearch/hermes-agent#66750](https://github.com/NousResearch/hermes-agent/issues/66750)
(dup of #63408); fix PRs #63409 / #66751 open at time of writing.

**Mitigation:** keep all `auxiliary.*` slots in `config.yaml` pinned to another
provider (e.g. `zai` / `glm-4.7-flash`) instead of `auto`. As long as
auxiliary slots don't inherit clinepass, everything works.

Also note `api.cline.bot` has no `/models` endpoint — Hermes falls back to the
curated `fallback_models` list in this plugin, which is fine.

## Smoke test

```sh
./test_smoke.sh   # registry discovery + live streaming round-trip
```

## Uninstall

```sh
rm -rf ~/.hermes/plugins/model-providers/clinepass
rm -rf ~/.hermes/profiles/*/plugins/model-providers/clinepass   # if installed per-profile
# remove CLINE_API_KEY from your .env files
```

## License

MIT
