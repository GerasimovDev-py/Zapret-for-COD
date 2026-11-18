# Call of Duty в России: инструкция для этой сборки zapret


Сборка основана на [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube) версии `1.10.4` и доработана под CoD.

> **Важно.** Обход проверки античита — это вмешательство в работу игры, которое может нарушать её правила. Возможны блокировка аккаунта и другие санкции. Все действия выполняются на ваш страх и риск, гарантий нет.

## 1. В чём проблема

- Call of Duty в РФ не обязана требовать VPN: на проверенной машине домены `callofduty.com`, `activision.com`, `battle.net`, `demonware.net` и TCP-порт 443 доступны без обхода. Блокировки со стороны РКН в этой цепочке нет.
- Основная проблема — античит **Ricochet**. Он реагирует на драйвер **WinDivert**, который использует zapret. Симптомы: игра вылетает при старте, «сетевые службы недоступны», подключение сбрасывается.
- Штатный механизм zapret «Game Filter» и режим `IPSet any` для CoD вредны: они добавляют рассинхронизацию и потери пакетов в игровой трафик.

## 2. Что уже сделано в этой папке

| Файл | Назначение |
|---|---|
| `general (CoD).bat` | Безопасная для CoD стратегия: обход только по доменам, без `ipset` и без Game Filter. |
| `lists/list-exclude-user.txt` | Домены CoD, Activision, Blizzard, Battle.net, Demonware, Steam CDN и Xbox, которые zapret не должен трогать. |
| `lists/ipset-exclude-user.txt` | IP-диапазоны Blizzard (AS57976), Demonware (AS60229) и Akamai-пулы CoD/Battle.net. |
| `bin/monkey_delete.cmd` | Исправлен: раньше ссылался на отсутствующий `tools\elevator`, теперь сам запрашивает права администратора. |
| `bin/WinDivert.dll` | Уже пропатченная версия из `windivert-hide` (bol-van/zapret-win-bundle). |
| `bin/Monkey64.sys` | Копия `WinDivert64.sys` для пропатченного DLL; служба драйвера называется `Monkey`. |

Проверка пропатченного DLL:

```powershell
Get-FileHash .\bin\WinDivert.dll -Algorithm SHA256
```

Ожидаемый хэш:

```text
944368B7A6EB0A97701E152A9171267DB66377CC31BDE415AB5DA22C7A09CC43
```

Если хэш отличается, значит DLL заменён на обычный и маскировку нужно применить заново (см. раздел 9).

Пропатченный DLL не подписан цифровой подписью — это нормально. Драйвер `Monkey64.sys` является подписанной копией оригинального `WinDivert64.sys`.

## 3. Быстрый старт

1. Убедитесь, что путь к папке не содержит кириллицы и спецсимволов. Текущий путь `C:\Users\NORMA\Downloads\lst\zapret-discord-youtube-1.10.4\zapret-discord-youtube-1.10.4` подходит.
2. Закройте старый zapret:
   - если установлена служба — `service.bat` → `Remove Services`;
   - если просто запущен `winws.exe` — закройте его через иконку в трее или командой `taskkill /IM winws.exe /F` от администратора.
3. Очистите старую службу маскировки (если она осталась от предыдущего запуска):
   - запустите `bin\monkey_delete.cmd`, подтвердите `Y`;
   - либо просто перезагрузите ПК — служба `monkey` помечена на удаление и исчезнет после перезагрузки.
4. Запустите **`general (CoD).bat` от имени администратора**.
5. Убедитесь, что в трее появился значок zapret, а в диспетчере задач есть процесс `winws.exe`.
6. Проверьте настройки в `service.bat`:
   - `Game Filter` — **disabled**;
   - `IPSet Filter` — **none**.
   
   В текущей конфигурации так и есть: файла `utils\game_filter.enabled` нет, а `lists\ipset-all.txt` содержит только заглушку `203.0.113.113/32`.
7. Запустите Call of Duty **после** запуска zapret.
8. Discord и YouTube должны работать одновременно с игрой.

Для автозапуска:

```text
service.bat → Install Service → general (CoD)
```

Не запускайте две копии `winws.exe` одновременно.

## 4. Что делает `general (CoD).bat`

Стратегия применяет DPI-обход только к трафику, который совпал с доменными списками:

- Discord и связанные сервисы из `lists/list-general.txt`;
- YouTube и Google из `lists/list-google.txt`;
- домены, которые вы сами добавили в `lists/list-general-user.txt`.

Используются порты:

- TCP: `80, 443, 2053, 2083, 2087, 2096, 8443`;
- UDP: `443, 19294-19344, 50000-50100` (в последнем диапазоне — только Discord/STUN).

Типовые игровые порты CoD (`3074`, `3079`, `3478-3479`, `4379-4380`, `27000-27050` и т.п.) в этот список не входят. Кроме того, в файле нет правил `--ipset`, поэтому даже при включённом IPSet-фильтре эта стратегия не будет трогать игровые IP.

Домены CoD/Blizzard и их IP дополнительно исключены на случай, если вы позже запустите другую стратегию с `ipset`.

## 5. Настройки `service.bat`

- `Game Filter` — держите **disabled**. Эта настройка добавляет обход на порты игр и может ухудшить соединение в CoD.
- `IPSet Filter` — держите **none**. Режим `loaded`/`any` может затронуть игровые IP и вызвать лаги или потери пакетов.
- `Install Service` — установка выбранной стратегии в автозапуск. Выберите `general (CoD)`.
- `Remove Services` — удаляет службу `zapret`, а также службы `WinDivert`/`WinDivert14`. Службу `monkey` он **не удаляет** — для неё используйте `bin\monkey_delete.cmd`.
- `Run Diagnostics` — проверка конфликтующих программ и типовых проблем.
- `Run Tests` — подбор рабочей стратегии, если `general (CoD)` не подходит вашему провайдеру.

Если `general (CoD)` не открывает Discord/YouTube на вашем провайдере, можно использовать другую стратегию `general*`, но тогда обязательно:

1. `Game Filter` = disabled;
2. `IPSet Filter` = none;
3. убедиться, что исключения CoD из этой папки не затёрты.

## 6. Работа со списками

- `lists/list-general-user.txt` — домены, которые нужно обходить дополнительно.
- `lists/list-exclude-user.txt` — домены, которые обходить **не нужно**. Здесь уже перечислены:
  `callofduty.com`, `activision.com`, `activisionblizzard.com`, `demonware.net`, `demonware.com`, `battle.net`, `blizzard.com`, `blizzard.net`, `blizzardcdn.com`, `bnetcdn.com`, `blzstatic.cn`, `steamcontent.com`, `steamstatic.com`, `xboxservices.com`.
- `lists/ipset-exclude-user.txt` — IP-диапазоны, исключённые из обхода. Здесь уже перечислены диапазоны Blizzard, Demonware и Akamai, связанные с CoD/Battle.net.
- `lists/ipset-all.txt` — общий список IP для обхода. Обновляется через `service.bat` → `Update IPSet List`. **Не добавляйте свои адреса в этот файл**: при обновлении они затрутся. Для своих адресов используйте `ipset-exclude-user.txt` или отдельные списки.

Если у вашего провайдера CoD, наоборот, не работает без zapret, удалите соответствующий домен из `list-exclude-user.txt` и добавьте его в `list-general-user.txt`.

## 7. Проверка

Хэш пропатченного DLL:

```powershell
Get-FileHash .\bin\WinDivert.dll -Algorithm SHA256
```

Служба маскировки:

```powershell
sc.exe query monkey
```

Запущенный обход:

```powershell
Get-Process winws -ErrorAction SilentlyContinue
```

Доступность серверов CoD без обхода:

```powershell
Resolve-DnsName callofduty.com, activision.com, battle.net, demonware.net -Type A
Test-NetConnection callofduty.com -Port 443
Test-NetConnection activision.com -Port 443
Test-NetConnection battle.net -Port 443
```

Если DNS и TCP отвечают без zapret, значит блокировка не на уровне РКН, и проблема, скорее всего, в античите.

## 8. Риски и ограничения

- Маскировка меняет только имя службы и файла драйвера. Если Ricochet проверяет имя устройства, создаваемого драйвером, а не службу, способ может не сработать.
- Возможны блокировки аккаунта за обход античита. Не используйте этот способ, если не готовы к такому риску.
- `zapret` не снижает пинг. Высокий пинг — это маршрутизация до серверов, а не DPI. Для низкого пинга нужен другой маршрут/VPN, а не этот проект.
- Не используйте `IPSet any` и Game Filter во время игры в CoD.
- Антивирус может реагировать на WinDivert. Добавьте папку проекта в исключения, если это происходит.

## 9. Обновление и переустановка

- Обновление zapret/переустановка затирает `bin\WinDivert.dll` и `bin\Monkey64.sys` обычными файлами. После обновления повторите маскировку:
  1. остановите zapret и службу `WinDivert` (если есть);
  2. скачайте `WinDivert.dll` и `Monkey64.sys` из [bol-van/zapret-win-bundle/windivert-hide](https://github.com/bol-van/zapret-win-bundle/tree/master/windivert-hide);
  3. замените файлы в `bin`;
  4. проверьте хэш `WinDivert.dll` — он должен быть `944368B7A6EB0A97701E152A9171267DB66377CC31BDE415AB5DA22C7A09CC43`;
  5. запустите `general (CoD).bat` от администратора.
- Файлы `lists/*-user.txt` при обновлении обычно сохраняются. Сделайте их резервную копию.
- `lists/ipset-all.txt` обновляется отдельно через `service.bat` и может быть перезаписан — это нормально.

## 10. Если что-то не работает

**CoD вылетает на старте или пишет про сетевые службы:**
- проверьте, что `WinDivert.dll` пропатчен (хэш выше);
- запустите `bin\monkey_delete.cmd`, перезагрузите ПК и попробуйте снова;
- попробуйте запустить zapret, дождаться значка в трее и только потом запускать игру;
- если не помогло — маскировка вам не подходит: играйте без zapret либо используйте отдельное устройство/роутер для обхода.

**Лаги и потери пакетов в игре:**
- `Game Filter` = disabled;
- `IPSet Filter` = none;
- не используйте `IPSet any`;
- попробуйте другую стратегию `general*` с теми же настройками фильтров.

**Не работает Discord:**
- включите Secure DNS (DoH) в браузере/Windows;
- `service.bat` → `Update Hosts File`;
- `service.bat` → `Run Diagnostics` и очистите кэш Discord;
- попробуйте другую стратегию.

**Не работает YouTube:**
- включите Secure DNS;
- попробуйте другую стратегию;
- проверьте, что домены YouTube не попали в `list-exclude-user.txt`.

**После настроек пропал интернет:**
- `service.bat` → `IPSet Filter` = none;
- `service.bat` → `Game Filter` = disabled;
- перезапустите zapret.

**Антивирус удаляет WinDivert:**
- добавьте папку проекта в исключения;
- WinDivert — легальный инструмент перехвата трафика, но антивирусы часто относят его к RiskTool.

## 11. Ссылки

- [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube)
- [bol-van/zapret](https://github.com/bol-van/zapret)
- [bol-van/zapret-win-bundle: windivert-hide](https://github.com/bol-van/zapret-win-bundle/tree/master/windivert-hide)

---

# English version

This README covers **Call of Duty only** for this customized copy of [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube) `1.10.4`.

> **Warning.** Hiding WinDivert from the game's anti-cheat may violate the game's rules. Account bans and other penalties are possible. Use at your own risk; no guarantees.

## The problem

- Call of Duty is reachable from Russia without a VPN on the tested machine (`callofduty.com`, `activision.com`, `battle.net`, `demonware.net`, TCP 443).
- The blocker is **Ricochet**, which detects the **WinDivert** driver used by zapret. The game may crash on startup or report unavailable network services.
- zapret's Game Filter and `IPSet any` mode make CoD worse: they can add packet loss and connection instability.

## What is already done

- `general (CoD).bat` — domain-only bypass strategy (no `ipset`, no Game Filter).
- `lists/list-exclude-user.txt` — CoD/Activision/Blizzard/Battle.net/Demonware/Steam/Xbox domains excluded from bypass.
- `lists/ipset-exclude-user.txt` — Blizzard (AS57976), Demonware (AS60229) and CoD/Battle.net Akamai ranges excluded from bypass.
- `bin/WinDivert.dll` — patched `windivert-hide` build, SHA-256 `944368B7A6EB0A97701E152A9171267DB66377CC31BDE415AB5DA22C7A09CC43`.
- `bin/Monkey64.sys` — copy of `WinDivert64.sys` used by the patched DLL.
- `bin/monkey_delete.cmd` — fixed to self-elevate (the original referenced a missing `tools\elevator`).

## Quick start

1. Close any previous zapret instance: `service.bat` → `Remove Services`, or terminate `winws.exe`.
2. Remove a stale `monkey` service: run `bin\monkey_delete.cmd` and confirm, or reboot.
3. Run **`general (CoD).bat` as Administrator**.
4. Make sure `Game Filter` is **disabled** and `IPSet Filter` is **none** in `service.bat` (this is the current state).
5. Start Call of Duty after zapret is running.
6. Discord and YouTube keep working.

For autostart: `service.bat` → `Install Service` → `general (CoD)`.

## What `general (CoD).bat` does

It applies DPI desync only to hostnames from the domain lists (Discord, YouTube/Google, Cloudflare and user-added domains). It uses TCP `80,443,2053,2083,2087,2096,8443` and UDP `443,19294-19344,50000-50100`. Typical CoD game ports (`3074`, `3079`, `3478-3479`, `4379-4380`, `27000-27050`, etc.) are not in these ranges, and there are no `--ipset` rules at all. Therefore game traffic is not processed.

## Important settings

- Keep `Game Filter` disabled.
- Keep `IPSet Filter` set to `none`.
- Do not use `IPSet any`.
- Do not run two `winws.exe` instances.
- If you use another `general*` strategy because your ISP needs it, keep the same filter settings and keep the CoD exclusions.

## Validation

```powershell
Get-FileHash .\bin\WinDivert.dll -Algorithm SHA256
sc.exe query monkey
Get-Process winws -ErrorAction SilentlyContinue
Resolve-DnsName callofduty.com, activision.com, battle.net, demonware.net -Type A
Test-NetConnection callofduty.com -Port 443
```

The patched DLL hash must be:

```text
944368B7A6EB0A97701E152A9171267DB66377CC31BDE415AB5DA22C7A09CC43
```

## Updates

Updating or reinstalling zapret replaces `bin\WinDivert.dll` and `bin\Monkey64.sys` with stock files. Re-apply the hide workaround:

1. Stop zapret and any WinDivert service.
2. Download `WinDivert.dll` and `Monkey64.sys` from [windivert-hide](https://github.com/bol-van/zapret-win-bundle/tree/master/windivert-hide).
3. Replace the files in `bin`.
4. Verify the DLL hash.
5. Start `general (CoD).bat` as Administrator.

Back up `lists/*-user.txt`; `lists/ipset-all.txt` is managed by `service.bat` and can be overwritten.

## Risks and limits

- The hide changes only the service name and driver filename. If Ricochet checks the driver's device name, this may not work.
- Using anti-cheat evasion can lead to account bans.
- zapret does not reduce ping; high ping is a routing issue.
- Antivirus software may flag WinDivert; add the project folder to exclusions if needed.

## Troubleshooting

- **CoD crashes or reports network services unavailable:** verify the DLL hash, run `bin\monkey_delete.cmd`, reboot, start zapret first, then the game. If it still fails, the method may not work for your setup; play without zapret or use a separate device/router.
- **Packet loss/lag:** disable Game Filter, set IPSet Filter to `none`, avoid `IPSet any`, try another strategy.
- **Discord issues:** enable Secure DNS, update hosts, clear Discord cache via diagnostics, try another strategy.
- **YouTube issues:** enable Secure DNS, try another strategy, ensure the domains are not in `list-exclude-user.txt`.
- **No internet after changes:** set IPSet Filter to `none` and Game Filter to disabled, restart zapret.

## Links

- [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube)
- [bol-van/zapret](https://github.com/bol-van/zapret)
- [bol-van/zapret-win-bundle: windivert-hide](https://github.com/bol-van/zapret-win-bundle/tree/master/windivert-hide)
