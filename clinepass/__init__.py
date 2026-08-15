"""ClinePass provider profile (user plugin).

Registers Cline's ClinePass subscription ($9.99/month, 11 curated
open-weight coding models) as a Hermes model provider using its
OpenAI-compatible Chat Completions API with a static API key
(CLINE_API_KEY).

Known upstream quirk (hermes-agent issue #66750 / #63408): non-streaming
completions from api.cline.bot are wrapped in a ``{data: {...}, success}``
envelope that the OpenAI SDK does not unwrap, which breaks auxiliary
non-streaming calls (titles, compression, memory reads). Streaming is
standard OpenAI SSE and works fine.

Mitigation in this profile (deterministic, no LLM involvement):
  - ``default_aux_model`` left empty so auxiliary slots fall back to the
    profile's own resolution only when explicitly configured.
This plugin does NOT attempt to unwrap the envelope — pin auxiliary.*
to another provider until hermes-agent merges the fix (#63409/#66751).

Sources: pi-clinepass-provider docs (models, pricing), hermes-agent
plugins/model-providers README (contract).
"""

from providers import register_provider
from providers.base import ProviderProfile

clinepass = ProviderProfile(
    name="clinepass",
    aliases=("cline-pass", "cline_pass", "clinepass-provider"),
    display_name="ClinePass",
    description="Cline ClinePass subscription — 11 curated open-weight coding models (GLM-5.2, Kimi K2.7/K3, DeepSeek V4, Qwen3.7...) via OpenAI-compatible API",
    signup_url="https://app.cline.bot/",
    env_vars=("CLINE_API_KEY",),
    base_url="https://api.cline.bot/api/v1",
    auth_type="api_key",
    # Curated static list from ClinePass docs (used by /model picker when
    # the live /models fetch fails). All support tool calling.
    fallback_models=(
        "cline-pass/glm-5.2",
        "cline-pass/glm-5.3",
        "cline-pass/kimi-k2.7-code",
        "cline-pass/kimi-k2.6",
        "cline-pass/kimi-k3",
        "cline-pass/deepseek-v4-pro",
        "cline-pass/deepseek-v4-flash",
        "cline-pass/mimo-v2.5",
        "cline-pass/mimo-v2.5-pro",
        "cline-pass/minimax-m3",
        "cline-pass/qwen3.7-max",
        "cline-pass/qwen3.7-plus",
        "cline-pass/qwen3.8-max",
    ),
    # Per-model output caps (context windows from ClinePass docs).
    # GLM-5.2/5.3 200K, Kimi K2.7/K2.6 262K, Kimi K3 1M, DeepSeek V4 1M,
    # MiMo 262K, MiniMax M3 1M, Qwen3.7 Max 262K, Qwen3.7 Plus 1M,
    # Qwen3.8 Max 262K.
)

register_provider(clinepass)
