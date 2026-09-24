---
name: claude-model-selection
description: Claude-Model-Selection. At the start of a new chat (the user's first message), briefly assess the requested task and recommend which Claude model to use (Haiku, Sonnet or Opus) and which effort level (low to xhigh), along with the current 5-hour limit usage, weekly usage percentage and context size. Also use it when the user asks which model or effort fits, how much usage they have left, or when the task clearly changes in complexity mid-chat.
---

# Claude-Model-Selection

Goal: save tokens by picking the cheapest model and effort that will still do the task well. This skill must itself be cheap: do not explore files or research; judge only from the user's message.

**Language:** always reply in the user's language, including the labels of the output block.

**Model names:** refer to models only by family (Haiku, Sonnet, Opus), never by version number, so the skill stays current as new versions ship.

## Steps

1. **Usage and context**: if the `mcp__ccd_session_mgmt__get_usage` tool is available (load it with ToolSearch `select:mcp__ccd_session_mgmt__get_usage` if deferred), call it.
   - From `plan.windows`: 5-hour limit % and weekly %, with `resetsIn`.
   - From `context`: `tokensUsed` and the tokens of the "MCP tools" category.
   - **Fallback**: if the tool does not exist (e.g. terminal CLI, IDE, web) or its status is not `ok`, do not fail and do not guess numbers. Write one line telling the user to run `/usage` (plan limits) and `/context` (context size) themselves, and skip steps 3, 5 and 6 unless the user shares those numbers.

2. **Classify the task** from the request alone:

| Task | Model | Effort |
|---|---|---|
| Quick questions, one-off doubts, translating, renaming, formatting, summarizing short text, simple commands | Haiku | low |
| Editing 1–2 files, small scripts, obvious bugs, templated documents/proposals, explanations | Sonnet | low – medium |
| Multi-file features, moderate refactors, debugging with an unclear cause, data analysis | Sonnet | medium – high |
| Architecture, system design, hard or intermittent bugs, real-money strategies, security review, high-impact decisions | Opus | high – xhigh |

   - The table gives ranges for guidance, but always recommend **exactly one** effort level, never a range.
   - Normal effort levels: **low, medium, high, xhigh**. Only suggest **max** in very special cases (e.g. a bug risking real money that has already failed several times) and explain why.
   - **Borderline tasks**: if the task sits between two tiers and the current model already belongs to one of them, keep the current model and do not suggest a switch; switching on weak evidence wastes cache (see step 4). Only recommend a switch when the evidence is clear.
   - If still unsure and nothing favors the current model, pick the cheaper tier and say so: "if it falls short, move up to X".

3. **Adjust for plan usage**:
   - 5-hour ≥ 80 % or weekly ≥ 85 %: drop one tier (Opus→Sonnet, Sonnet→Haiku) unless the task is critical; say when the limit resets.
   - Weekly ahead of pace (e.g. > 60 % with more than half the week left): prefer Sonnet/Haiku.

4. **Cost of switching models (cache)**: each model has its own prompt cache, so after a switch the new model re-reads the whole conversation at full price.
   - Start of chat (little history): switching is cheap, recommend it freely.
   - Mid-chat with a long history (> ~50k tokens beyond the fixed baseline): do not recommend switching in the same chat; offer to write a short summary so the user can open a new chat on the right model.

5. **Context size**: the whole history is reprocessed on every message.
   - `tokensUsed` > ~150k: suggest `/compact` or a new chat with a summary.

6. **Unused connectors**: if "MCP tools" weighs > ~10k tokens and `mcp__ccd_connectors__session_connectors_status` is available, call it and find connectors the task clearly does not need (e.g. email or browser for a coding task). Suggest turning them off in one line, with the tokens it would save. Only after an explicit "yes", call `mcp__ccd_connectors__set_session_connector_enabled` (`enabled: false`), noting it also stays off by default in new chats. If there are no clear candidates or the tools are unavailable, skip this step.

7. **Cheap subagents**: if the task is large and has separable, mechanical parts (broad searches across many files, repetitive edits, gathering data), propose delegating them to a subagent with `model: "haiku"` or `"sonnet"` (Agent tool) while the main conversation stays on the current model. Only propose it; delegate only if the user agrees. Do not suggest it for small tasks: the subagent starts without context and costs more than it saves.

8. **Reply with this short block** (translated to the user's language) before any other work or question, then continue with the task. The block is mandatory every time this skill runs, even if the task first needs clarification or files are missing. Always fill in `current:` with the family (Haiku, Sonnet or Opus) of the model you are running on, without version. Omit only the optional lines (marked *) when they do not apply:

```
🧭 Claude-Model-Selection
Task: <summary in ≤10 words>
Recommended: <Model> · effort <level>  (current: <current model>)
Reason: <one line>
Usage: 5h <x>% (resets in <t>) · week <y>% (resets in <t>) · context <n>k tokens   (fallback: run /usage and /context)
*Savings: <connectors to turn off / compact / subagent>
*Tip: open chats on Sonnet (or Haiku) and move up to Opus only when this skill recommends it.
```

   - Show the *Tip* only when the current model is Opus and the task does not need it.
   - If the recommended model or effort differs from the current one, tell the user in one line to change it in the app's model picker (or with `/model` in the terminal). Claude cannot change the model or effort of its own session.

## Mid-chat

If the task clearly changes in complexity (becomes much simpler or much harder), give a single recommendation line applying steps 2 (borderline rule) and 4. Do not repeat the full block, and do not do it on every message.
