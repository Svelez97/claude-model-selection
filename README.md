# Claude-Model-Selection

A Claude Code plugin that helps you spend fewer tokens. At the start of every chat it looks at what you asked for and recommends the cheapest Claude model (**Haiku**, **Sonnet**, **Opus** or **Fable**) and **effort level** that will still do the job well. It also shows how much of your plan you have used.

```
🧭 Claude-Model-Selection
Task: design architecture for a live-money trading bot
Recommended: Opus · effort high  (current: Sonnet)
Reason: system design with real-money risk
Usage: 5h 12% (resets in 3h 40m) · week 49% (resets in 3d 4h) · context 58k tokens
```

It replies in your language.

## Install

In Claude Code, run:

```
/plugin marketplace add Svelez97/claude-model-selection
/plugin install claude-model-selection@claude-model-selection
```

Or just ask Claude: *"Install the plugin claude-model-selection from GitHub: Svelez97/claude-model-selection"*.

Start a new chat afterwards so it loads.

## What it does

When the first real message of a chat arrives (a bare "hi" is ignored), it:

1. **Reads your usage**: the 5-hour limit, weekly limit and context size.
2. **Classifies the task** from your message alone. It does not read files, so the check stays cheap.

   | Task | Model | Effort |
   |---|---|---|
   | Quick questions, formatting, simple commands | Haiku | n/a (Haiku has no effort setting) |
   | Small edits, scripts, clear bugs, explanations | Sonnet | low / medium |
   | Multi-file features, refactors, unclear bugs, data analysis | Sonnet | medium / high |
   | Architecture, hard bugs, security, real-money or high-impact decisions | Opus | high / xhigh |
   | Very large, long-running projects Claude runs mostly on its own, where mistakes are very costly | Fable | high / xhigh |

   It always picks one effort level. Two more levels are kept for rare cases, and it explains why when it suggests them:
   - **max**: deepest reasoning, for extremely hard problems that already failed at xhigh.
   - **ultracode**: a Claude Code setting that plans a whole multi-step workflow per task; for large builds only.

   Fable uses the most of your limit and needs a paid plan, so it is recommended only for the last row. If you do not have it, you get Opus instead.

3. **Adjusts to your plan**: if you are close to your 5-hour or weekly limit, it recommends one tier lower (Fable → Opus → Sonnet → Haiku), avoids max and ultracode, and tells you when the limit resets.
4. **Avoids pointless switches**: switching models mid-chat throws away the prompt cache, and the new model re-reads the whole conversation. On borderline tasks it keeps your current model. In a long chat it offers a summary so you can open a new chat on the right model.
5. **Suggests savings** only when they apply:
   - compact the chat or start a new one when the context gets large;
   - turn off connectors the task does not need (only with your OK);
   - hand large mechanical sub-tasks to a cheaper Haiku or Sonnet subagent (only with your OK).

6. **Waits for you when a switch is needed.** If the recommended model differs from your current one, Claude stops after the recommendation and does not start the task. Switch models in the picker (or with `/model`), then send any message such as "done", and it carries out your original request on the new model. Reply "continue" to keep your current model instead. If the model already matches, it goes straight to the task.

If the task changes a lot mid-chat, it gives a one-line recommendation instead of the full block.

### Subagent cost guard

When Claude hands part of the work to a subagent:

- **Same model as your session, or a cheaper one**: it runs without asking.
- **A more expensive model** (Haiku < Sonnet < Opus < Fable): you are asked to approve it first.

A `PreToolUse` hook enforces this, so it holds even if Claude forgets the rule. It also catches custom agents whose definition sets a more expensive model. If the session model cannot be determined, only Haiku subagents run without asking.

To skip it for a chat, say "skip selection" in your first message.

## Notes and limits

- **Claude cannot switch its own model.** You change it in the model picker, or with `/model` in the terminal. The plugin only recommends.
- **Live usage numbers need the Claude desktop app.** It reads them with a tool that only the desktop app (Code tab) provides. Elsewhere (terminal, IDE, web) it asks you to run `/usage` and `/context` and still recommends a model and effort.
- **The subagent guard and the per-message reminder need bash.** macOS and Linux have it, and on Windows it comes with Git for Windows (Git Bash), which Claude Code normally uses. Without bash they do not run; the start-of-chat reminder still works. It also cannot ask you in bypass-permissions mode or in non-interactive runs (`claude -p`); there, an approval request blocks the subagent instead.
- The thresholds (80 % of the 5-hour limit, 85 % of the week, 150k context tokens) are rules of thumb. To change them, edit `skills/claude-model-selection/SKILL.md`.

## How it works

- `skills/claude-model-selection/SKILL.md`: the skill with the selection rules.
- `hooks/hooks.json`:
  - a `SessionStart` hook that tells Claude to run the skill once at the start of each new chat;
  - a `UserPromptSubmit` hook (`hooks/remind-until-run.sh`) that repeats that reminder with each of your messages until the skill has run in the chat, so it triggers reliably;
  - a `PreToolUse` hook on subagent launches that runs `hooks/check-subagent-model.sh`, the cost guard.

## Uninstall

```
/plugin uninstall claude-model-selection@claude-model-selection
```

## License

[MIT](LICENSE)

---

### En español

Plugin para Claude Code que, al iniciar cada chat, recomienda el modelo más barato (Haiku, Sonnet, Opus o Fable) y el nivel de esfuerzo adecuados para tu tarea. También muestra tu uso del límite de 5 horas, el semanal y el tamaño del contexto. Si el modelo recomendado es distinto del que usas, se detiene y espera a que lo cambies; luego escribe cualquier mensaje (por ejemplo "listo") y hace tu pedido original. Si Claude quiere lanzar un subagente con un modelo más caro que el de tu sesión, primero te pide autorización; con el mismo modelo o uno más barato lo hace sin preguntar. Se instala con los dos comandos de arriba, o pidiéndoselo a Claude, y responde en tu idioma.
