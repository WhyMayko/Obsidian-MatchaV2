# Obsidian Matcha Community

Welcome to the community folder! This folder hosts custom themes and configs created for Obsidian Matcha.

## Loading from Matcha

If you are running a script that uses Obsidian Matcha, you can load any of these community files instantly through the executor's console.

### Load a Theme

To load a theme from the `themes/` folder, run:
```lua
community.loadTheme("ThemeName")
```
*Example: `community.loadTheme("Matcha-Waifu")`*

### Load a Config

To load a config from the `configs/` folder, run:
```lua
community.loadConfig("ConfigName")
```

The files will be automatically downloaded to your local `Galax/Obsidian/Settings/` folder and applied to your running script immediately.

### Load a Webhook

To load a webhook URL from the executor console:
```lua
webhook.load("Name", "https://discord.com/api/webhooks/...")
```
*The webhook is saved locally and can be managed through the UI section built by `WebhookManager:BuildWebhookSection(tab)`.*
