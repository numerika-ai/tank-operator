# Heartbeat Rules

## Heartbeat vs Cron
- **Heartbeat**: batch checks, conversational context, timing can drift
- **Cron**: exact timing, isolation, different model, one-shot reminders

## Things to Check (rotate 2-4x/day)
- Emails, Calendar (next 24-48h), Mentions, Weather

## Track in `memory/heartbeat-state.json`

## When to reach out
- Important email, upcoming event (<2h), been >8h since last contact

## When to stay quiet (HEARTBEAT_OK)
- Late night (23:00-08:00), human busy, nothing new, checked <30min ago

## Proactive work (no permission needed)
- Organize memory files, check projects, update docs, commit changes

## Memory Maintenance
Every few days: review daily notes → update MEMORY.md → prune outdated info.
