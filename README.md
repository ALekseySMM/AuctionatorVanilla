# AuctionatorVanilla — v1.10

**English** | [Русский](#русский)

A fork of [nimeral/AuctionatorVanilla](https://github.com/nimeral/AuctionatorVanilla) (Auctionator backported to WoW 1.12.1; original addon by Zirco, Vanilla adaptation by Nimeral).

## What's new in 1.10

### 1. Post several stacks at once

The Auctionator tab has **Stack size**, **Stacks** and a **Post** button, so one big stack can be sold as several smaller ones in a single click.

1. Put the item into the *Auction Item* slot.
2. Enter **Stack size** (items per stack) and **Stacks** (how many). Leave *Stacks* empty to post as many as possible.
3. Set *Starting Price* and *Buyout Price* — they are the prices for **one stack of `Stack size` items**.
4. Press **Post**.

Example: 20 items → Stack size 5, Stacks 4 gives four auctions of 5.

The addon splits the stack in your bags and posts the pieces one after another, then prints a summary in chat. It needs at least one free bag slot. Each stack is taken from a single bag slot (leftovers in different slots are not merged).

![Auctionator 1.10](screenshots/Pic%20for%20v%201.10.png)

> **IMPORTANT!** Remember the rule: if the **Stack Size** field is empty, it is a regular auction. If it contains a number X, the **Buyout Price** is the price for X items!

### 2. Buyout on the Auctionator tab

Click a line in the price list (the highlight the addon sets by itself does not count), then press **Buyout**. The standard "Buyout auction for:" confirmation appears; after **Accept** the addon looks the auction up again (same name, stack size and buyout price, not yours) and buys it. If someone was faster, you get a message instead.

### 3. Reset and Setup in the title bar

**Setup** (addon options) and **Reset** sit next to the window's close button. On the Browse tab **Reset** collapses the category tree, clears the level range and rarity, and empties the result list (until the next search).

### Other changes

The bottom row of the Auctionator tab is `[Post] [Buyout] [Close]` and uses the Bid tab art, so no empty "Cancel Auction" slot shows. The chat message on load is now "Auctionator Sherai loaded."

## Installation

Copy the folder into `Interface\AddOns\` and name it `Auctionator`. Interface 11200 (1.12.1).

---

## Русский

Форк [nimeral/AuctionatorVanilla](https://github.com/nimeral/AuctionatorVanilla) (Auctionator для WoW 1.12.1; оригинальный аддон — Zirco, адаптация под Vanilla — Nimeral).

### Что нового в 1.10

#### 1. Выставление нескольких стаков за раз

На вкладке Auctionator появились поля **Stack size**, **Stacks** и кнопка **Post**: один большой стак можно продать несколькими маленькими одним нажатием.

1. Положите предмет в слот *Auction Item*.
2. Введите **Stack size** (штук в стаке) и **Stacks** (сколько стаков). Если *Stacks* пусто, выставится максимально возможное количество.
3. Задайте *Starting Price* и *Buyout Price* — это цены за **один стак из `Stack size` штук**.
4. Нажмите **Post**.

Пример: 20 штук → Stack size 5, Stacks 4 даст четыре лота по 5 штук.

Аддон сам делит стак в сумке и выставляет части по очереди, в конце пишет итог в чат. Нужна минимум одна свободная ячейка в сумке. Каждый стак берётся из одной ячейки (остатки в разных ячейках не объединяются).

![Auctionator 1.10](screenshots/Pic%20for%20v%201.10.png)

> **ВАЖНО!** Запомните правило: если поле **Stack Size** пустое, то это обычный аукцион. Если в нём стоит число Х шт., то цена **Buyout Price** — это цена за Х штук!

#### 2. Покупка (Buyout) на вкладке Auctionator

Кликните строку в списке цен (подсветка, которую аддон ставит сам, не считается), затем нажмите **Buyout**. Появится стандартное окно подтверждения «Buyout auction for:»; после **Accept** аддон заново находит лот (то же название, размер стака и цена выкупа, не ваш) и покупает его. Если кто-то успел раньше, придёт сообщение.

#### 3. Reset и Setup в заголовке окна

Кнопки **Setup** (настройки аддона) и **Reset** стоят рядом с крестиком закрытия окна. На вкладке Browse **Reset** сворачивает дерево категорий, очищает диапазон уровней и редкость и очищает список результатов (до следующего поиска).

#### Прочее

Основная суть изменений - удобство пользования аддоном. 
Если будут просьбы - пишите. В игре или тут.

### Установка

Скопируйте папку в `Interface\AddOns\` и назовите её `Auctionator`. Interface 11200 (1.12.1).
