# AuctionatorVanilla — multi-stack posting

**English** | [Русский](#русский)

A fork of [nimeral/AuctionatorVanilla](https://github.com/nimeral/AuctionatorVanilla) (Auctionator backported to WoW 1.12.1; original addon by Zirco, Vanilla adaptation by Nimeral).

## What's added

The Auctionator tab now has **Stack size**, **Stacks** and a **Post** button, so one big stack can be sold as several smaller ones in a single click.

1. Put the item into the *Auction Item* slot.
2. Enter **Stack size** (items per stack) and **Stacks** (how many). Leave *Stacks* empty to post as many as possible.
3. Set *Starting Price* and *Buyout Price* — they are the prices for **one stack of `Stack size` items**.
4. Press **Post**.

Example: 20 items → Stack size 5, Stacks 4 gives four auctions of 5.

The addon splits the stack in your bags and posts the pieces one after another, then prints a summary in chat. It needs at least one free bag slot. Stacks are taken from a single bag slot each (leftovers in different slots are not merged).

Also changed: the *Auctionator* button is now **Setup**, and the Post / Setup buttons sit in the slots of the Bid tab art.

## Installation

Copy the folder into `Interface\AddOns\` and name it `Auctionator`. Interface 11200 (1.12.1).

---

## Русский

Форк [nimeral/AuctionatorVanilla](https://github.com/nimeral/AuctionatorVanilla) (Auctionator для WoW 1.12.1; оригинальный аддон — Zirco, адаптация под Vanilla — Nimeral).

### Что добавлено

На вкладке Auctionator появились поля **Stack size**, **Stacks** и кнопка **Post**: один большой стак можно продать несколькими маленькими одним нажатием.

1. Положите предмет в слот *Auction Item*.
2. Введите **Stack size** (штук в стаке) и **Stacks** (сколько стаков). Если *Stacks* пусто, выставится максимально возможное количество.
3. Задайте *Starting Price* и *Buyout Price* — это цены за **один стак из `Stack size` штук**.
4. Нажмите **Post**.

Пример: 20 штук → Stack size 5, Stacks 4 даст четыре лота по 5 штук.

Аддон сам делит стак в сумке и выставляет части по очереди, в конце пишет итог в чат. Нужна минимум одна свободная ячейка в сумке. Каждый стак берётся из одной ячейки (остатки в разных ячейках не объединяются).

Также: кнопка *Auctionator* переименована в **Setup**, а кнопки Post и Setup стоят в пазах рисунка вкладки Bid.

### Установка

Скопируйте папку в `Interface\AddOns\` и назовите её `Auctionator`. Interface 11200 (1.12.1).
