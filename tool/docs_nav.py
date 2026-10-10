#!/usr/bin/env python3
"""Rewrites the sidebar of every page in docs/ from one list.

Pages that do not exist yet are skipped, so links in the sidebar never
point to missing files. Run from the repository root:

    python3 tool/docs_nav.py
"""
import pathlib
import re

DOCS = pathlib.Path(__file__).resolve().parent.parent / "docs"

NAV = [
    ("Начало", [
        ("index.html", "Главная"),
        ("project-overview.html", "Обзор проекта"),
        ("environment.html", "Окружение"),
        ("product-evolution-plan.html", "План эволюции продукта"),
    ]),
    ("Архитектура", [
        ("architecture.html", "Архитектура"),
        ("architecture-decisions.html", "Архитектурные решения"),
        ("requirements-matrix.html", "Матрица требований"),
        ("seed-data.html", "Демо-данные"),
    ]),
    ("Продукт", [
        ("auth-and-roles.html", "Вход и роли"),
        ("permission-matrix.html", "Матрица прав"),
        ("reviews-and-ratings.html", "Отзывы и рейтинги"),
        ("owner-dashboard.html", "Кабинет владельца"),
        ("analytics.html", "Аналитика"),
        ("notifications.html", "Напоминания"),
    ]),
    ("Лабораторные", [
        ("lab-1.html", "Лабораторная №1"),
        ("lab-2.html", "Лабораторная №2"),
        ("independent-work.html", "Самостоятельная работа"),
        ("lab-3.html", "Лабораторная №3"),
    ]),
    ("Качество и защита", [
        ("testing.html", "Тестирование"),
        ("demo-scenario.html", "Сценарий демонстрации"),
        ("defense.html", "Защита"),
        ("future-roadmap.html", "План развития"),
    ]),
    ("Команда", [
        ("team/kirill.html", "Кирилл"),
        ("team/vlad.html", "Влад"),
        ("team/yan.html", "Ян"),
    ]),
]

SIDEBAR = re.compile(r'<aside class="sidebar">.*?</aside>', re.S)


def sidebar_for(page: pathlib.Path) -> str:
    prefix = "../" * (len(page.relative_to(DOCS).parts) - 1)
    current = page.relative_to(DOCS).as_posix()
    lines = [
        '<aside class="sidebar">',
        f'<a class="brand" href="{prefix}index.html">'
        f'<img src="{prefix}assets/slotly-logo.svg" alt="">Slotly</a>',
        '<nav aria-label="Разделы документации">',
    ]
    for group, links in NAV:
        items = []
        for href, title in links:
            if not (DOCS / href).exists():
                continue
            mark = ' aria-current="page"' if href == current else ""
            items.append(f'<li><a href="{prefix}{href}"{mark}>{title}</a></li>')
        if items:
            lines.append(f'<div class="nav-group">{group}</div><ul>')
            lines.extend(items)
            lines.append("</ul>")
    lines += ["</nav>", "</aside>"]
    return "\n".join(lines)


def main() -> None:
    for page in sorted(DOCS.rglob("*.html")):
        text = page.read_text(encoding="utf-8")
        if not SIDEBAR.search(text):
            continue
        updated = SIDEBAR.sub(lambda _: sidebar_for(page), text, count=1)
        if updated != text:
            page.write_text(updated, encoding="utf-8")
            print(f"updated {page.relative_to(DOCS)}")


if __name__ == "__main__":
    main()
