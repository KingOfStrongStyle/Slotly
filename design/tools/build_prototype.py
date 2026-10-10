#!/usr/bin/env python3
"""Builds the Slotly design prototype from one set of tokens.

Outputs:
  design/figma-import/frames/*.svg      11 mobile frames (360 x 800), importable into Figma
  design/figma-import/components/*.svg  UI kit components in their states
  design/prototype/index.html           clickable prototype with the same frames
  design/prototype/ui-kit.html          tokens, icons, components and usage rules

Colors, radii and spacing are copied from lib/app/theme.dart (values of
ColorScheme.fromSeed(0xFF0B6E69)), so the prototype matches the Flutter app.
Icons are simplified line icons drawn here; the app uses the corresponding
Material icons listed in design/prototype/ui-kit.html.

Run from the repository root:  python3 design/tools/build_prototype.py
"""
import html
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DESIGN = os.path.join(ROOT, 'design')

C = {
    'primary': '#006A65', 'onPrimary': '#FFFFFF',
    'primaryContainer': '#9DF2EA', 'onPrimaryContainer': '#00504C',
    'secondaryContainer': '#CCE8E5', 'onSecondaryContainer': '#324B49',
    'tertiaryContainer': '#D0E4FF', 'onTertiaryContainer': '#304962',
    'error': '#BA1A1A', 'errorContainer': '#FFDAD6', 'onErrorContainer': '#93000A',
    'surface': '#F4FBF9', 'onSurface': '#161D1C', 'onSurfaceVariant': '#3F4947',
    'surfaceContainerLow': '#EFF5F3', 'surfaceContainer': '#E9EFED',
    'surfaceContainerHigh': '#E3E9E8', 'surfaceContainerHighest': '#DDE4E2',
    'outline': '#6F7978', 'outlineVariant': '#BEC9C7', 'inverseSurface': '#2B3231',
    'onInverseSurface': '#ECF2F0', 'scrim': '#000000',
}
FONT = "Roboto, 'Segoe UI', Arial, sans-serif"
W, H = 360, 800


ICONS = {
    'search': '<circle cx="10.5" cy="10.5" r="6"/><path d="M15 15l5 5"/>',
    'close': '<path d="M6 6l12 12M18 6L6 18"/>',
    'back': '<path d="M20 12H5M11 6l-6 6 6 6"/>',
    'forward': '<path d="M4 12h15M13 6l6 6-6 6"/>',
    'chevron': '<path d="M9 6l6 6-6 6"/>',
    'calendar': '<rect x="4" y="5" width="16" height="15" rx="2"/><path d="M4 10h16M8 3v4M16 3v4"/>',
    'clock': '<circle cx="12" cy="12" r="8"/><path d="M12 8v4l3 2"/>',
    'person': '<circle cx="12" cy="8" r="4"/><path d="M4 20c1.5-4 4.5-6 8-6s6.5 2 8 6"/>',
    'store': '<path d="M4 9l2-5h12l2 5M4 9h16v11H4zM9 20v-6h6v6"/>',
    'list': '<rect x="4" y="4" width="16" height="16" rx="2"/><path d="M8 9h8M8 13h8M8 17h5"/>',
    'check': '<path d="M5 12l5 5 9-10"/>',
    'check-circle': '<circle cx="12" cy="12" r="9"/><path d="M8 12l3 3 5-6"/>',
    'radio': '<circle cx="12" cy="12" r="9"/>',
    'scissors': '<circle cx="6" cy="7" r="3"/><circle cx="6" cy="17" r="3"/><path d="M8.5 8.5L20 18M8.5 15.5L20 6"/>',
    'spa': '<path d="M12 20c-4 0-8-3-8-8 4 0 8 3 8 8zM12 20c4 0 8-3 8-8-4 0-8 3-8 8zM12 20c-2-3-2-9 0-13 2 4 2 10 0 13z"/>',
    'smile': '<circle cx="12" cy="12" r="9"/><path d="M8 14c1 2 7 2 8 0"/><circle cx="9" cy="10" r=".6"/><circle cx="15" cy="10" r=".6"/>',
    'hospital': '<rect x="4" y="4" width="16" height="16" rx="2"/><path d="M12 8v8M8 12h8"/>',
    'car': '<path d="M4 15l2-6h12l2 6v3H4z"/><circle cx="8" cy="18" r="1.5"/><circle cx="16" cy="18" r="1.5"/>',
    'school': '<path d="M2 9l10-5 10 5-10 5zM6 11v5c3 3 9 3 12 0v-5"/>',
    'payments': '<rect x="3" y="6" width="18" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/>',
    'info': '<circle cx="12" cy="12" r="9"/><path d="M12 11v6M12 7.5v.5"/>',
    'moon': '<path d="M19 15A8 8 0 019 5a8 8 0 1010 10z"/>',
    'bell': '<path d="M6 17V11a6 6 0 0112 0v6l2 2H4zM10 21h4"/>',
    'pulse': '<path d="M3 12h4l2-5 4 10 2-5h6"/>',
    'gesture': '<path d="M4 15c3-8 5-8 6 0s4 6 6-2 4-3 4-3"/>',
    'draw': '<path d="M4 20l4-1 11-11-3-3L5 16zM14 7l3 3"/>',
    'event-busy': '<rect x="4" y="5" width="16" height="15" rx="2"/><path d="M4 10h16M9 13l6 5M15 13l-6 5"/>',
    'event-ok': '<rect x="4" y="5" width="16" height="15" rx="2"/><path d="M4 10h16M8.5 15l2.5 2.5 4.5-5"/>',
    'search-off': '<circle cx="10.5" cy="10.5" r="6"/><path d="M15 15l5 5M7.5 7.5l6 6"/>',
    'heart': '<path d="M12 20s-7-4.5-7-10a4 4 0 017-2.5A4 4 0 0119 10c0 5.5-7 10-7 10z"/>',
    'star': '<path d="M12 3l2.6 5.6 6 .7-4.5 4.1 1.2 6L12 16.4 6.7 19.4l1.2-6L3.4 9.3l6-.7z"/>',
    'insights': '<path d="M4 18l5-6 4 3 7-9"/><circle cx="20" cy="6" r="1.2"/>',
    'review': '<rect x="3" y="4" width="18" height="13" rx="2"/><path d="M7 21l4-4M8 11h8"/>',
    'lock': '<rect x="5" y="10" width="14" height="10" rx="2"/><path d="M8 10V7a4 4 0 018 0v3"/>',
    'logout': '<path d="M10 4H5v16h5M14 8l4 4-4 4M18 12H9"/>',
    'table': '<rect x="4" y="4" width="16" height="16" rx="2"/><path d="M4 10h16M4 15h16"/>',
}


def icon(name, x, y, size=24, color=None, width=2):
    color = color or C['onSurfaceVariant']
    s = size / 24
    return (f'<g transform="translate({x},{y}) scale({s})" fill="none" stroke="{color}" '
            f'stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round">{ICONS[name]}</g>')



def esc(t):
    return html.escape(t, quote=True)


def text(x, y, value, size=14, weight=400, color=None, anchor='start', spacing=0):
    color = color or C['onSurface']
    ls = f' letter-spacing="{spacing}"' if spacing else ''
    return (f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}" font-weight="{weight}" '
            f'fill="{color}" text-anchor="{anchor}"{ls}>{esc(value)}</text>')


def rect(x, y, w, h, fill, r=0, stroke=None, sw=1, opacity=None):
    s = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ''
    o = f' fill-opacity="{opacity}"' if opacity is not None else ''
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}"{s}{o}/>'


def text_width(value, size):
    return len(value) * size * 0.6


def hotspot(x, y, w, h, target, label):
    """Clickable area. Ignored by Figma, used by the HTML prototype."""
    return (f'<rect class="hotspot" data-go="{target}" x="{x}" y="{y}" width="{w}" height="{h}" '
            f'rx="12" fill="#000" fill-opacity="0"><title>{esc(label)}</title></rect>')



def status_bar():
    return (text(20, 26, '12:00', 13, 500) +
            rect(300, 16, 14, 10, C['onSurface'], 2) + rect(320, 16, 22, 10, C['onSurface'], 2))


def app_bar(title, back=None, action=None):
    out = []
    x = 16
    if back:
        out.append(icon('back', 16, 52))
        out.append(hotspot(4, 40, 48, 48, back, 'Назад'))
        x = 64
    out.append(text(x, 72, title, 22, 400))
    if action:
        out.append(icon(action, 320, 52))
    return ''.join(out)


def search_field(y, value=None, focused=False):
    out = [rect(16, y, 328, 48, C['surfaceContainerHighest'], 12)]
    if focused:
        out.append(rect(16, y + 46, 328, 2, C['primary']))
    out.append(icon('search', 28, y + 12))
    if value:
        out.append(text(64, y + 30, value, 16))
        out.append(icon('close', 312, y + 12, 22))
    else:
        out.append(text(64, y + 30, 'Найти место или услугу', 16, color=C['onSurfaceVariant']))
    return ''.join(out)


def chip(x, y, label, selected=False, icon_name=None, disabled=False, strike=False, h=32):
    w = text_width(label, 14) + (40 if icon_name else 24)
    fill = C['secondaryContainer'] if selected else C['surface']
    stroke = None if selected else C['outlineVariant']
    color = C['onSurface'] if not disabled else C['outlineVariant']
    out = [rect(x, y, w, h, fill, 8, stroke)]
    tx = x + 12
    if icon_name:
        out.append(icon(icon_name, x + 8, y + 7, 18, C['primary'] if not disabled else color))
        tx = x + 32
    out.append(text(tx, y + h / 2 + 5, label, 14, 500, color))
    if strike:
        out.append(f'<line x1="{tx}" y1="{y + h / 2}" x2="{tx + text_width(label, 14)}" y2="{y + h / 2}" stroke="{color}" stroke-width="1.2"/>')
    return ''.join(out), w


def chips_row(y, items, x=16, gap=8):
    out = []
    for label, selected, icon_name in items:
        svg, w = chip(x, y, label, selected, icon_name)
        out.append(svg)
        x += w + gap
    return ''.join(out)


ART = [('primaryContainer', 'onPrimaryContainer'), ('secondaryContainer', 'onSecondaryContainer'),
       ('tertiaryContainer', 'onTertiaryContainer')]
CIRCLES = [[(0.15, 0.2, 0.35), (0.95, 0.9, 0.45)], [(0.9, 0.15, 0.4), (0.1, 0.95, 0.3)],
           [(0.5, -0.05, 0.4), (0.85, 0.95, 0.3), (0.05, 0.6, 0.2)]]


def artwork(x, y, w, h, variant, icon_name, r=12, icon_size=32, uid='a'):
    bg, fg = ART[variant % 3]
    clip = f'clip-{uid}'
    out = [f'<clipPath id="{clip}"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}"/></clipPath>',
           f'<g clip-path="url(#{clip})">', rect(x, y, w, h, C[bg])]
    side = min(w, h)
    for cx, cy, cr in CIRCLES[variant % 3]:
        out.append(f'<circle cx="{x + cx * w}" cy="{y + cy * h}" r="{cr * side}" fill="{C[fg]}" fill-opacity="0.12"/>')
    out.append('</g>')
    out.append(icon(icon_name, x + w / 2 - icon_size / 2, y + h / 2 - icon_size / 2, icon_size, C[fg]))
    return ''.join(out)


def service_card(y, title, meta, price, variant, icon_name, target=None, uid='c', pressed=False):
    fill = C['surfaceContainerHigh'] if pressed else C['surfaceContainerLow']
    out = [rect(16, y, 328, 96, fill, 16, C['outlineVariant']),
           artwork(28, y + 12, 72, 72, variant, icon_name, uid=uid),
           text(112, y + 34, title, 16, 500), text(112, y + 54, meta, 12, color=C['onSurfaceVariant']),
           text(112, y + 78, price, 14, 500, C['primary']), icon('chevron', 316, y + 36)]
    if target:
        out.append(hotspot(16, y, 328, 96, target, title))
    return ''.join(out)


CLIENT_TABS = [('Каталог', 'store'), ('Избранное', 'heart'), ('Записи', 'list'), ('Профиль', 'person')]
OWNER_TABS = [('Обзор', 'insights'), ('Записи', 'list'), ('Услуги', 'store'), ('Отзывы', 'review'),
              ('Организация', 'person')]


def nav_bar(active, targets, top=H - 80, items=None):
    items = items or CLIENT_TABS
    n = len(items)
    out = [rect(0, top, W, 80, C['surfaceContainer'])]
    for i, (label, icon_name) in enumerate(items):
        cx = W / (2 * n) * (2 * i + 1)
        if i == active:
            out.append(rect(cx - 28, top + 12, 56, 32, C['secondaryContainer'], 16))
        color = C['onSecondaryContainer'] if i == active else C['onSurfaceVariant']
        out.append(icon(icon_name, cx - 12, top + 16, 24, color))
        out.append(text(cx, top + 58, label, 11 if n > 4 else 12, 600 if i == active else 500, C['onSurface'], 'middle'))
        if targets and i < len(targets) and targets[i]:
            out.append(hotspot(cx - W / (2 * n), top + 4, W / n, 72, targets[i], label))
    return ''.join(out)


def segmented(y, labels, selected, targets=None, x=16, w=328):
    out = [rect(x, y, w, 44, C['surface'], 22, C['outline'])]
    seg = w / len(labels)
    for i, label in enumerate(labels):
        sx = x + i * seg
        if i == selected:
            r = 22 if i in (0, len(labels) - 1) else 0
            out.append(rect(sx + 1, y + 1, seg - 2, 42, C['secondaryContainer'], r))
        if i > 0:
            out.append(rect(sx, y, 1, 44, C['outline']))
        out.append(text(sx + seg / 2, y + 27, label, 14, 500, C['onSurface'], 'middle'))
        if targets and targets[i] and i != selected:
            out.append(hotspot(sx, y, seg, 44, targets[i], label))
    return ''.join(out)


def rating(x, y, value, count):
    return (icon('star', x, y - 14, 18, '#B7791F') + text(x + 22, y, value, 14, 700) +
            text(x + 22 + text_width(value, 14) + 6, y, f'· {count}', 13, color=C['onSurfaceVariant']))


def org_card(y, name, category, value, count, variant, icon_name, favorite=False, target=None, uid='o'):
    out = [rect(16, y, 328, 224, C['surfaceContainerLow'], 16, C['outlineVariant']),
           artwork(16, y, 328, 137, variant, icon_name, r=16, icon_size=40, uid=uid),
           rect(16, y + 120, 328, 17, C[ART[variant % 3][0]]),
           f'<circle cx="316" cy="{y + 28}" r="20" fill="{C["surface"]}" fill-opacity=".9"/>',
           icon('heart', 304, y + 16, 24, C['error'] if favorite else C['onSurface']),
           text(32, y + 166, name, 16, 500), text(32, y + 186, category, 12, color=C['onSurfaceVariant']),
           rating(32, y + 210, value, count)]
    if target:
        out.append(hotspot(16, y, 280, 224, target, name))
    return ''.join(out)


def filled_button(x, y, w, label, target=None, disabled=False, icon_name=None, h=52):
    fill = C['onSurface'] if disabled else C['primary']
    opacity = 0.12 if disabled else None
    color = C['onSurface'] if disabled else C['onPrimary']
    out = [rect(x, y, w, h, fill, 12, opacity=opacity)]
    label_w = text_width(label, 16) + (28 if icon_name else 0)
    tx = x + w / 2 - label_w / 2
    out.append('<g opacity=".38">' if disabled else '<g>')
    out.append(text(tx, y + h / 2 + 6, label, 16, 600, color))
    if icon_name:
        out.append(icon(icon_name, tx + text_width(label, 16) + 6, y + h / 2 - 10, 20, color))
    out.append('</g>')
    if target and not disabled:
        out.append(hotspot(x, y, w, h, target, label))
    return ''.join(out)


def outlined_button(x, y, w, label, color=None, h=44):
    color = color or C['primary']
    return rect(x, y, w, h, C['surface'], 12, C['outline']) + text(x + w / 2, y + h / 2 + 5, label, 14, 500, color, 'middle')


def frame(name, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" '
            f'data-frame="{name}"><title>Slotly — {esc(name)}</title>{rect(0, 0, W, H, C["surface"])}'
            f'{status_bar()}{body}</svg>')



CATEGORIES = [('Барбершоп', 'scissors'), ('Салон красоты', 'spa'), ('Стоматология', 'smile'),
              ('Клиника', 'hospital'), ('Автосервис', 'car'), ('Репетиторы', 'school')]
NAV = ['catalog', 'bookings', 'profile']


def logo(x, y, size):
    s = size / 100
    cells = ''.join(rect(x + cx * s, y + cy * s, 28 * s, 28 * s, '#FFFFFF', 7 * s, opacity=0.38)
                    for cx, cy in [(19, 19), (53, 19), (19, 53)])
    return (rect(x, y, size, size, C['primary'], 26 * s) + cells +
            rect(x + 53 * s, y + 53 * s, 28 * s, 28 * s, C['primaryContainer'], 7 * s) +
            f'<path d="M{x + 60 * s} {y + 67 * s} L{x + 65 * s} {y + 72 * s} L{x + 74 * s} {y + 62 * s}" fill="none" '
            f'stroke="{C["onPrimaryContainer"]}" stroke-width="{4 * s}" stroke-linecap="round" stroke-linejoin="round"/>')


def welcome():
    out = [logo(24, 56, 72), text(24, 180, 'Slotly', 36, 700, C['primary']),
           text(24, 220, 'Запись на услуги', 24), text(24, 250, 'без звонков', 24),
           text(24, 288, 'Выберите услугу, специалиста и удобное', 15, color=C['onSurfaceVariant']),
           text(24, 310, 'время. Запись подтверждается сразу.', 15, color=C['onSurfaceVariant']),
           text(24, 358, 'Что вас интересует?', 16, 500)]
    x, y = 24, 374
    for i, (label, icon_name) in enumerate(CATEGORIES):
        svg, w = chip(x, y, label, i == 0, icon_name)
        if x + w > W - 16:
            x, y = 24, y + 44
            svg, w = chip(x, y, label, i == 0, icon_name)
        out.append(svg)
        x += w + 8
    out.append(text(24, y + 64, 'Выбрано: Барбершоп — каталог откроется с фильтром', 12,
                    color=C['onSurfaceVariant']))
    out.append(filled_button(24, y + 96, 312, 'Продолжить', 'login', icon_name='forward'))
    return frame('01 Welcome', ''.join(out))


SERVICES = [('Мужская стрижка', 'Барбершоп · 45 мин', '6 000 ₸', 0, 'scissors'),
            ('Оформление бороды', 'Барбершоп · 30 мин', '4 000 ₸', 1, 'scissors'),
            ('Маникюр с покрытием', 'Салон красоты · 1 ч 30 мин', '9 000 ₸', 2, 'spa'),
            ('Окрашивание волос', 'Салон красоты · 2 ч', '25 000 ₸', 0, 'spa'),
            ('Чистка зубов', 'Стоматология · 1 ч', '18 000 ₸', 1, 'smile')]


def login():
    out = [app_bar('Вход', back='welcome'), logo(16, 104, 48),
           text(16, 186, 'Войдите как клиент, чтобы записываться, или', 14, color=C['onSurfaceVariant']),
           text(16, 206, 'как владелец, чтобы управлять организацией.', 14, color=C['onSurfaceVariant']),
           rect(16, 228, 328, 52, C['surfaceContainerHighest'], 12), icon('person', 30, 242),
           text(64, 260, 'aliya', 16), rect(16, 292, 328, 52, C['surfaceContainerHighest'], 12),
           icon('lock', 30, 306), text(64, 324, '••••••••••', 16),
           filled_button(16, 360, 328, 'Войти', 'catalog'),
           rect(16, 432, 328, 280, C['surfaceContainerLow'], 16, C['outlineVariant']),
           text(32, 462, 'Демо-аккаунты', 14, 500),
           text(32, 484, 'Публичные пароли, данные только на этом', 12, color=C['onSurfaceVariant']),
           text(32, 500, 'устройстве. Это не защищённая авторизация.', 12, color=C['onSurfaceVariant'])]
    for i, (who, cred, target) in enumerate([('Алия Н. · Клиент', 'aliya / aliya-demo', 'catalog'),
                                              ('Дамир К. · Клиент', 'damir / damir-demo', 'catalog'),
                                              ('Ержан Б. · Владелец', 'north / north-demo', 'dashboard')]):
        y = 524 + i * 60
        out.append(icon('store' if 'Владелец' in who else 'person', 32, y + 2))
        out.append(text(68, y + 14, who, 15))
        out.append(text(68, y + 34, cred, 13, color=C['onSurfaceVariant']))
        out.append(hotspot(16, y - 6, 328, 56, target, who))
    return frame('02 Вход', ''.join(out))


def catalog():
    out = [app_bar('Каталог'), search_field(96), hotspot(16, 96, 328, 48, 'search', 'Поиск'),
           segmented(156, ['Места', 'Услуги'], 0, [None, 'search']),
           chips_row(212, [('Все', True, None), ('Барбершоп', False, 'scissors'), ('Салон красоты', False, 'spa')]),
           text(16, 268, 'Найдено: 6', 12, 500),
           org_card(280, 'Барбершоп «Северный»', 'Барбершоп', '4,6', '17 отзывов', 0, 'scissors', True,
                    'organization', 'org0'),
           org_card(516, 'Автосервис «Гараж 24»', 'Автосервис', '3,3', '6 отзывов', 1, 'car', False, None, 'org1'),
           nav_bar(0, [None, None, 'bookings', 'profile'])]
    return frame('03 Каталог мест', ''.join(out))


def search_results():
    out = [app_bar('Каталог'), search_field(96, 'стриж', focused=True),
           segmented(156, ['Места', 'Услуги'], 1, ['catalog', None]),
           chips_row(212, [('Все', True, None), ('Барбершоп', False, 'scissors'), ('Салон красоты', False, 'spa')]),
           text(16, 268, 'Найдено: 3', 12, 500),
           service_card(280, *SERVICES[0], target='details', uid='s0'),
           text(16, 400, 'Пустой результат:', 12, 500, C['onSurfaceVariant']),
           f'<circle cx="180" cy="430" r="34" fill="{C["secondaryContainer"]}"/>',
           icon('search-off', 162, 412, 36, C['onSecondaryContainer']),
           text(180, 494, 'Ничего не найдено', 16, 500, anchor='middle'),
           text(180, 518, 'Попробуйте изменить запрос', 14, color=C['onSurfaceVariant'], anchor='middle'),
           text(180, 538, 'или выбрать другую категорию.', 14, color=C['onSurfaceVariant'], anchor='middle'),
           outlined_button(110, 556, 140, 'Сбросить фильтры'),
           nav_bar(0, ['catalog', None, 'bookings', 'profile'])]
    return frame('04 Поиск услуг', ''.join(out))


def organization():
    out = [artwork(0, 0, W, 240, 0, 'scissors', r=0, icon_size=72, uid='org'),
           icon('back', 16, 52, 24, C['onSurface']), hotspot(4, 40, 48, 48, 'catalog', 'Назад'),
           icon('heart', 320, 52, 24, C['error']),
           rect(272, 200, 72, 28, '#000000', 8, opacity=0.55), text(308, 219, '1 из 4', 13, 500, '#FFFFFF', 'middle'),
           text(16, 276, 'Барбершоп «Северный»', 22), text(16, 298, 'Барбершоп', 13, color=C['onSurfaceVariant']),
           rating(16, 328, '4,6', '17 отзывов'),
           text(16, 364, 'Мужские стрижки и уход за бородой.', 15),
           text(16, 410, 'Услуги и цены', 14, 500, C['primary']),
           rect(16, 422, 328, 112, C['surfaceContainerLow'], 16, C['outlineVariant']),
           text(32, 450, 'Мужская стрижка', 15, 500), text(300, 450, 'от 6 000 ₸', 14, 500, C['primary'], 'end'),
           icon('chevron', 308, 434), text(32, 470, '45 мин', 12, color=C['onSurfaceVariant']),
           text(32, 494, 'Короткая', 12, color=C['onSurfaceVariant']), text(300, 494, '6 000 ₸', 12, color=C['onSurfaceVariant'], anchor='end'),
           text(32, 514, 'Удлинённая', 12, color=C['onSurfaceVariant']), text(300, 514, '7 500 ₸', 12, color=C['onSurfaceVariant'], anchor='end'),
           hotspot(16, 422, 328, 112, 'details', 'Мужская стрижка'),
           rect(16, 546, 328, 64, C['surfaceContainerLow'], 16, C['outlineVariant']),
           text(32, 574, 'Оформление бороды', 15, 500), text(300, 574, '4 000 ₸', 14, 500, C['primary'], 'end'),
           text(32, 594, '30 мин', 12, color=C['onSurfaceVariant']),
           text(16, 642, 'Отзывы', 14, 500, C['primary']),
           text(16, 690, '4,6', 40, 700)]
    for i, (stars, share, n) in enumerate([(5, .7, 12), (4, .24, 4), (3, .06, 1), (2, 0, 0), (1, 0, 0)]):
        y = 660 + i * 16
        out.append(text(116, y + 9, str(stars), 11, 500))
        out.append(rect(132, y, 180, 8, C['surfaceContainerHighest'], 4))
        if share:
            out.append(rect(132, y, 180 * share, 8, '#B7791F', 4))
        out.append(text(336, y + 9, str(n), 11, 500, anchor='end'))
    return frame('05 Организация', ''.join(out))


def info_row(y, icon_name, label, value, x=16):
    return icon(icon_name, x, y + 4, 20) + text(x + 32, y + 10, label, 12, color=C['onSurfaceVariant']) + text(x + 32, y + 32, value, 16)


def specialist_tile(y, initials, name, role, selected, x=16, w=328):
    out = [rect(x, y, w, 64, C['primaryContainer'] if selected else C['surfaceContainerLow'], 16,
                C['primary'] if selected else C['outlineVariant'], 2 if selected else 1),
           f'<circle cx="{x + 36}" cy="{y + 32}" r="20" fill="{C["secondaryContainer"]}"/>',
           text(x + 36, y + 37, initials, 14, 500, C['onSecondaryContainer'], 'middle'),
           text(x + 68, y + 28, name, 16), text(x + 68, y + 48, role, 14, color=C['onSurfaceVariant'])]
    out.append(icon('check-circle' if selected else 'radio', x + w - 40, y + 20, 24,
                    C['primary'] if selected else C['onSurfaceVariant']))
    return ''.join(out)


def details():
    out = [artwork(0, 0, W, 220, 0, 'scissors', r=0, icon_size=72, uid='d'), icon('back', 16, 52, 24, C['onSurface']),
           hotspot(4, 40, 48, 48, 'organization', 'Назад'),
           text(16, 260, 'Мужская стрижка', 24),
           info_row(276, 'scissors', 'Категория', 'Барбершоп'), info_row(322, 'payments', 'Стоимость', 'Короткая — 6 000 ₸ · Удлинённая — 7 500 ₸'),
           info_row(368, 'clock', 'Длительность', '45 мин'),
           text(16, 436, 'Об услуге', 14, 500, C['primary']),
           text(16, 462, 'Консультация, мытьё головы, стрижка', 16),
           text(16, 484, 'машинкой и ножницами, укладка.', 16),
           text(16, 528, 'Специалисты', 14, 500, C['primary']),
           f'<circle cx="36" cy="568" r="20" fill="{C["secondaryContainer"]}"/>', text(36, 573, 'АС', 14, 500, C['onSecondaryContainer'], 'middle'),
           text(68, 564, 'Арман С.', 16), text(68, 584, 'Барбер', 14, color=C['onSurfaceVariant']),
           f'<circle cx="36" cy="624" r="20" fill="{C["secondaryContainer"]}"/>', text(36, 629, 'ДА', 14, 500, C['onSecondaryContainer'], 'middle'),
           text(68, 620, 'Данияр А.', 16), text(68, 640, 'Старший барбер', 14, color=C['onSurfaceVariant']),
           filled_button(16, 724, 328, 'Записаться', 'booking')]
    return frame('06 Детали услуги', ''.join(out))


def date_chip(x, y, caption, day, selected):
    fill = C['primary'] if selected else C['surfaceContainerLow']
    color = C['onPrimary'] if selected else C['onSurface']
    return (rect(x, y, 56, 64, fill, 12, None if selected else C['outlineVariant']) +
            text(x + 28, y + 18, caption, 11, 500, color, 'middle') + text(x + 28, y + 42, day, 22, 400, color, 'middle') +
            text(x + 28, y + 57, 'окт', 11, 500, color, 'middle'))


def slot(x, y, label, state):
    if state == 'selected':
        return rect(x, y, 70, 32, C['secondaryContainer'], 8) + text(x + 35, y + 21, label, 14, 500, anchor='middle')
    disabled = state == 'busy'
    color = C['outlineVariant'] if disabled else C['onSurface']
    out = rect(x, y, 70, 32, C['surface'], 8, C['outlineVariant'] if not disabled else C['surfaceContainerHigh']) + \
        text(x + 35, y + 21, label, 14, 500, color, 'middle')
    if disabled:
        out += f'<line x1="{x + 17}" y1="{y + 16}" x2="{x + 53}" y2="{y + 16}" stroke="{color}" stroke-width="1.2"/>'
    return out


def booking_form(dialog=False):
    out = [app_bar('Новая запись', back='details'),
           rect(16, 96, 328, 64, C['surfaceContainerLow'], 16, C['outlineVariant']),
           text(32, 124, 'Мужская стрижка · Удлинённая', 16, 500), text(32, 146, '45 мин · 7 500 ₸', 14, color=C['onSurfaceVariant']),
           text(16, 188, 'Специалист', 14, 500, C['primary']),
           specialist_tile(200, 'АС', 'Арман С.', 'Барбер', True),
           specialist_tile(272, 'ДА', 'Данияр А.', 'Старший барбер', False),
           text(16, 368, 'Дата', 14, 500, C['primary'])]
    for i, (caption, day) in enumerate([('Сегодня', '5'), ('Завтра', '6'), ('ср', '7'), ('чт', '8'), ('пт', '9')]):
        out.append(date_chip(16 + i * 64, 380, caption, day, i == 1))
    out.append(text(16, 476, 'Время', 14, 500, C['primary']))
    times = [('10:00', 'free'), ('11:00', 'busy'), ('12:00', 'selected'), ('13:00', 'free'),
             ('14:00', 'free'), ('15:00', 'busy'), ('16:00', 'free'), ('17:00', 'free')]
    for i, (label, state) in enumerate(times):
        out.append(slot(16 + (i % 4) * 80, 488 + (i // 4) * 44, label, state))
    out.append(text(16, 600, 'Комментарий', 14, 500, C['primary']))
    out.append(rect(16, 612, 328, 56, C['surfaceContainerHighest'], 12))
    out.append(text(32, 645, 'Например: нужна парковка рядом', 16, color=C['onSurfaceVariant']))
    out.append(rect(0, 692, W, 108, C['surfaceContainer']))
    out.append(filled_button(16, 724, 328, 'Продолжить', None if dialog else 'confirm'))
    if dialog:
        out.append(rect(0, 0, W, H, C['scrim'], opacity=0.32))
        out.append(rect(32, 190, 296, 400, C['surfaceContainerHigh'], 28))
        out.append(icon('event-ok', 168, 214, 24, C['primary']))
        out.append(text(180, 270, 'Подтвердите запись', 22, anchor='middle'))
        for i, (icon_name, label, value) in enumerate([('store', 'Услуга', 'Мужская стрижка'), ('person', 'Специалист', 'Арман С.'),
                                                     ('calendar', 'Дата', 'вт, 6 октября'), ('clock', 'Время', '12:00–12:45'),
                                                     ('payments', 'Стоимость', 'Удлинённая, 7 500 ₸')]):
            out.append(info_row(290 + i * 46, icon_name, label, value, x=56))
        out.append(text(108, 560, 'Изменить', 14, 500, C['primary'], 'middle'))
        out.append(hotspot(64, 536, 92, 40, 'booking', 'Изменить'))
        out.append(filled_button(172, 532, 140, 'Подтвердить', 'bookings', h=44))
        return frame('08 Подтверждение', ''.join(out))
    return frame('07 Вариант, специалист, время', ''.join(out))


def booking_tile(y, day, title, details_text, uid):
    return (rect(16, y, 328, 76, C['surfaceContainerLow'], 16, C['outlineVariant']) +
            rect(28, y + 12, 52, 52, C['primaryContainer'], 12) +
            text(54, y + 38, day, 22, 400, C['onPrimaryContainer'], 'middle') + text(54, y + 56, 'окт', 11, 500, C['onPrimaryContainer'], 'middle') +
            text(96, y + 34, title, 16, 500) + text(96, y + 56, details_text, 14, color=C['onSurfaceVariant']))


def bookings():
    out = [app_bar('Мои записи'),
           text(60, 120, 'Активные (2)', 13, 500, C['primary'], 'middle'),
           text(180, 120, 'Прошедшие (29)', 13, 500, C['onSurfaceVariant'], 'middle'),
           text(300, 120, 'Отменённые (5)', 13, 500, C['onSurfaceVariant'], 'middle'),
           rect(12, 134, 96, 3, C['primary'], 2), rect(0, 137, W, 1, C['outlineVariant']),
           text(16, 166, 'Нажмите для подробностей, удерживайте для действий.', 12, color=C['onSurfaceVariant']),
           text(16, 182, 'Влево — отменить, вправо — перенести.', 12, color=C['onSurfaceVariant']),
           booking_tile(196, '6', 'Мужская стрижка', '12:00–12:45 · Талон 143', 'b1')]
    out.append(rect(16, 284, 328, 76, C['secondaryContainer'], 16))
    out.append(icon('calendar', 34, 310, 24, C['onSecondaryContainer']))
    out.append(text(66, 327, 'Перенести', 14, 600, C['onSecondaryContainer']))
    out.append('<g transform="translate(150,0)">' + booking_tile(284, '7', 'Оформление бороды', '11:00–11:30 · Талон 144', 'b2') + '</g>')
    out.append(rect(16, 632, 328, 48, C['inverseSurface'], 12))
    out.append(text(32, 661, 'Вы записаны: Мужская стрижка. Талон 143', 13, color=C['onInverseSurface']))
    out.append(nav_bar(2, ['catalog', None, None, 'profile']))
    return frame('09 Мои записи', ''.join(out))


def switch(x, y, on):
    if on:
        return rect(x, y, 52, 32, C['primary'], 16) + f'<circle cx="{x + 36}" cy="{y + 16}" r="12" fill="{C["onPrimary"]}"/>'
    return rect(x, y, 52, 32, C['surfaceContainerHighest'], 16, C['outline'], 2) + f'<circle cx="{x + 16}" cy="{y + 16}" r="8" fill="{C["outline"]}"/>'


def list_tile(y, icon_name, title, subtitle, trailing='chevron', on=None):
    out = [icon(icon_name, 16, y + 8), text(56, y + 16, title, 16), text(56, y + 36, subtitle, 13, color=C['onSurfaceVariant'])]
    if trailing == 'switch':
        out.append(switch(292, y + 4, on))
    elif trailing == 'chevron':
        out.append(icon('chevron', 320, y + 8))
    return ''.join(out)


def profile():
    out = [app_bar('Профиль'), rect(16, 96, 328, 88, C['surfaceContainerLow'], 16, C['outlineVariant']),
           f'<circle cx="60" cy="140" r="28" fill="{C["primaryContainer"]}"/>', text(60, 146, 'АН', 16, 500, C['onPrimaryContainer'], 'middle'),
           text(104, 134, 'Алия Н.', 16, 500), text(104, 156, 'Клиент · Логин aliya', 12, color=C['onSurfaceVariant']),
           text(16, 220, 'Настройки', 14, 500, C['primary']),
           list_tile(232, 'moon', 'Тёмная тема', 'Светлая и тёмная схема', 'switch', False),
           list_tile(288, 'bell', 'Напоминания о записях', 'Накануне, утром и за час'),
           text(16, 372, 'Для разработчиков', 14, 500, C['primary']),
           list_tile(384, 'pulse', 'Диагностика', 'Жизненный цикл приложения'),
           list_tile(440, 'gesture', 'Gesture Lab', 'Песочница жестов для ЛР №3'),
           text(16, 524, 'О приложении', 14, 500, C['primary']),
           list_tile(536, 'info', 'О Slotly', 'Версия 0.2.0 · учебный MVP', None),
           icon('logout', 16, 604, 24, C['error']), text(56, 622, 'Выйти', 16, color=C['error']),
           hotspot(0, 592, W, 48, 'welcome', 'Выйти'),
           nav_bar(3, ['catalog', None, 'bookings', None])]
    return frame('10 Профиль', ''.join(out))


def kpi(x, y, label, value, note=''):
    return (rect(x, y, 160, 84, C['surfaceContainerLow'], 16, C['outlineVariant']) +
            text(x + 14, y + 24, label, 12, color=C['onSurfaceVariant']) + text(x + 14, y + 56, value, 24, 700) +
            text(x + 14, y + 74, note, 11, color=C['onSurfaceVariant']))


def dashboard():
    out = [text(16, 64, 'Обзор', 22), text(16, 84, 'Барбершоп «Северный»', 12),
           segmented(100, ['7 дней', '30 дней', '90 дней'], 1),
           kpi(16, 156, 'Записи', '10'), kpi(184, 156, 'Состоялись', '6'),
           kpi(16, 252, 'Отмены', '4', '40 % от всех'), kpi(184, 252, 'Рейтинг за период', '4,8', 'за всё время 4,6'),
           rect(16, 352, 328, 236, C['surfaceContainerLow'], 16, C['outlineVariant']),
           text(32, 382, 'Записи по дням', 14, 500), icon('table', 308, 364, 22),
           text(32, 404, 'Коснитесь столбца, чтобы увидеть значение', 11, color=C['onSurfaceVariant'])]
    values = [1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0]
    for i, v in enumerate(values):
        x = 32 + i * 9.4
        h = 110 if v else 2
        out.append(rect(x, 530 - h, 7.4, h, C['primary'] if v else C['outlineVariant'], 2))
    out.append(rect(32, 530, 282, 1, C['outlineVariant']))
    out.append(text(32, 552, 'пт, 11 сен', 11, color=C['onSurfaceVariant']))
    out.append(text(314, 552, 'сб, 10 окт', 11, color=C['onSurfaceVariant'], anchor='end'))
    out.append(rect(16, 600, 328, 104, C['surfaceContainerLow'], 16, C['outlineVariant']))
    out.append(text(32, 628, 'Статусы записей', 14, 500))
    out.append(rect(32, 642, 168, 14, '#2A78D6', 4))
    out.append(rect(202, 642, 110, 14, '#1BAF7A', 4))
    out.append(text(32, 680, 'Состоялись: 6 (60 %)   Отменены: 4 (40 %)', 12))
    out.append(nav_bar(0, [None, None, None, None, 'welcome'], items=OWNER_TABS))
    return frame('11 Обзор владельца', ''.join(out))


FRAMES = [('welcome', welcome), ('login', login), ('catalog', catalog), ('search', search_results),
          ('organization', organization), ('details', details),
          ('booking', lambda: booking_form(False)), ('confirm', lambda: booking_form(True)),
          ('bookings', bookings), ('profile', profile), ('dashboard', dashboard)]



def component(name, w, h, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            f'<title>Slotly UI kit — {esc(name)}</title>{rect(0, 0, w, h, C["surface"])}{body}</svg>')


def components():
    def label(x, y, value):
        return text(x, y, value, 11, 500, C['onSurfaceVariant'])

    buttons = component('Button', 360, 260, ''.join([
        label(16, 20, 'default'), filled_button(16, 28, 328, 'Продолжить'),
        label(16, 100, 'pressed'), rect(16, 108, 328, 52, C['primary'], 12),
        rect(16, 108, 328, 52, C['onPrimary'], 12, opacity=0.12), text(180, 140, 'Продолжить', 16, 600, C['onPrimary'], 'middle'),
        label(16, 180, 'disabled'), filled_button(16, 188, 328, 'Продолжить', disabled=True)]))
    slots = component('Time slot', 360, 120, ''.join([
        label(16, 20, 'available'), slot(16, 28, '10:00', 'free'),
        label(104, 20, 'selected'), slot(104, 28, '12:00', 'selected'),
        label(192, 20, 'unavailable'), slot(192, 28, '11:00', 'busy'),
        label(16, 90, 'Занятый слот зачёркнут, отключён и озвучивается как «Занято».')]))
    card = component('Service card', 360, 240, ''.join([
        label(16, 20, 'default'), service_card(28, *SERVICES[0], uid='k1'),
        label(16, 144, 'pressed'), service_card(152, *SERVICES[1], uid='k2', pressed=True)]))
    chips = component('Chip', 360, 100, ''.join([
        label(16, 20, 'default'), chip(16, 28, 'Барбершоп', False, 'scissors')[0],
        label(150, 20, 'selected'), chip(150, 28, 'Барбершоп', True, 'scissors')[0],
        label(16, 80, 'Фильтр категорий: один выбранный чип, «Все» снимает фильтр.')]))
    field = component('Text field', 360, 230, ''.join([
        label(16, 20, 'default'), search_field(28),
        label(16, 100, 'focused'), search_field(108, 'стриж', focused=True),
        label(16, 176, 'error'), rect(16, 184, 328, 40, C['surfaceContainerHighest'], 12),
        rect(16, 222, 328, 2, C['error']), text(32, 209, 'Комментарий длиннее 200 символов', 14, color=C['error'])]))
    nav = component('Navigation bar', 360, 80, nav_bar(0, None, top=0))
    return {'button': buttons, 'time-slot': slots, 'service-card': card, 'chip': chips,
            'text-field': field, 'navigation-bar': nav}



PROTOTYPE_TEMPLATE = '''<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Slotly — интерактивный прототип</title>
<style>
:root {{ --primary: #006A65; --surface: #F4FBF9; --text: #161D1C; --muted: #3F4947; --outline: #BEC9C7; }}
* {{ box-sizing: border-box; }}
body {{ margin: 0; font: 15px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
  color: var(--text); background: #E3E9E8; }}
header {{ padding: 16px 24px; background: var(--surface); border-bottom: 1px solid var(--outline);
  display: flex; flex-wrap: wrap; gap: 12px 24px; align-items: center; }}
header h1 {{ font-size: 20px; margin: 0; color: var(--primary); }}
header a {{ color: var(--primary); }}
.controls {{ display: flex; gap: 8px; flex-wrap: wrap; }}
button {{ font: inherit; padding: 6px 14px; border-radius: 10px; border: 1px solid var(--outline);
  background: #fff; cursor: pointer; }}
button[aria-pressed="true"] {{ background: #CCE8E5; border-color: var(--primary); }}
main {{ padding: 24px; }}
.flow {{ display: flex; gap: 32px; align-items: flex-start; flex-wrap: wrap; justify-content: center; }}
.device {{ width: 360px; max-width: 100%; border-radius: 28px; overflow: hidden;
  box-shadow: 0 8px 32px rgba(0,0,0,.18); background: var(--surface); }}
.device svg {{ display: block; width: 100%; height: auto; }}
.steps {{ max-width: 360px; }}
.steps ol {{ padding-left: 20px; }}
.steps li.current {{ font-weight: 700; color: var(--primary); }}
.gallery {{ display: none; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 24px; }}
.gallery figure {{ margin: 0; }}
.gallery figcaption {{ margin-top: 6px; color: var(--muted); font-size: 13px; }}
.gallery .device {{ width: 100%; }}
body.show-all .flow {{ display: none; }}
body.show-all .gallery {{ display: grid; }}
.hotspot {{ cursor: pointer; }}
.hotspot:active {{ fill-opacity: .08; }}
body.show-hotspots .hotspot {{ fill: #006A65; fill-opacity: .18; stroke: #006A65; stroke-width: 1.5; }}
</style>
</head>
<body>
<header>
  <h1>Slotly · прототип</h1>
  <div class="controls">
    <button id="restart" type="button">С начала</button>
    <button id="hotspots" type="button" aria-pressed="false">Показать кликабельные зоны</button>
    <button id="all" type="button" aria-pressed="false">Все 11 фреймов</button>
  </div>
  <a href="ui-kit.html">UI kit</a>
</header>
<main>
  <div class="flow">
    <div class="device" id="device" aria-live="polite"></div>
    <div class="steps">
      <h2>Основной сценарий</h2>
      <ol id="steps">{steps}</ol>
      <p>Нажимайте на кнопки и карточки внутри телефона. Нижняя навигация переключает «Услуги», «Записи» и «Профиль», стрелка «назад» возвращает на предыдущий экран.</p>
    </div>
  </div>
  <div class="gallery">{gallery}</div>
</main>
<script>
const frames = {frames_json};
const order = {order_json};
const device = document.getElementById('device');
const steps = document.querySelectorAll('#steps li');
let current = 'welcome';
function show(name) {{
  current = name;
  device.innerHTML = frames[name];
  steps.forEach((li) => li.classList.toggle('current', li.dataset.frame === name));
  history.replaceState(null, '', '#' + name);
}}
device.addEventListener('click', (event) => {{
  const target = event.target.closest('.hotspot');
  if (target) show(target.dataset.go);
}});
document.getElementById('restart').onclick = () => show('welcome');
for (const id of ['hotspots', 'all']) {{
  const button = document.getElementById(id);
  button.onclick = () => {{
    const on = button.getAttribute('aria-pressed') !== 'true';
    button.setAttribute('aria-pressed', String(on));
    document.body.classList.toggle(id === 'all' ? 'show-all' : 'show-hotspots', on);
  }};
}}
const start = location.hash.slice(1);
show(order.includes(start) ? start : 'welcome');
</script>
</body>
</html>
'''



DARK = {
    'primary': '#81D5CE', 'onPrimary': '#003734', 'primaryContainer': '#00504C',
    'onPrimaryContainer': '#9DF2EA', 'secondaryContainer': '#324B49', 'tertiaryContainer': '#304962',
    'error': '#FFB4AB', 'errorContainer': '#93000A', 'surface': '#0E1514', 'onSurface': '#DDE4E2',
    'onSurfaceVariant': '#BEC9C7', 'surfaceContainerLow': '#161D1C', 'surfaceContainerHighest': '#2F3635',
    'outlineVariant': '#3F4947',
}
ROLES = {
    'primary': 'основные кнопки, выбранная дата, цена',
    'onPrimary': 'текст и иконки на primary',
    'primaryContainer': 'выбранный специалист, бейдж даты, иллюстрация',
    'onPrimaryContainer': 'текст на primaryContainer',
    'secondaryContainer': 'выбранный чип, индикатор NavigationBar, аватар',
    'tertiaryContainer': 'третий вариант иллюстрации услуги',
    'error': 'ошибки, отмена записи',
    'errorContainer': 'фон ошибки, фон свайпа отмены',
    'surface': 'фон экранов',
    'onSurface': 'основной текст',
    'onSurfaceVariant': 'вторичный текст, неактивные иконки',
    'surfaceContainerLow': 'фон карточек',
    'surfaceContainerHighest': 'поля ввода',
    'outlineVariant': 'границы карточек и чипов',
}
TYPE_SCALE = [('displaySmall', 36, 44, 400, 'Slotly на welcome (жирный 700)'),
              ('headlineSmall', 24, 32, 400, 'название услуги, слоган'),
              ('titleLarge', 22, 28, 400, 'заголовки экранов'),
              ('titleMedium', 16, 24, 500, 'названия услуг и записей'),
              ('bodyLarge', 16, 24, 400, 'основной текст'),
              ('bodyMedium', 14, 20, 400, 'описания'),
              ('labelLarge', 14, 20, 500, 'кнопки, чипы, цена'),
              ('bodySmall', 12, 16, 400, 'метаданные, подсказки')]
ICON_MAP = [('search', 'Icons.search', 'поиск'), ('close', 'Icons.close', 'очистка поиска'),
            ('back', 'стрелка AppBar', 'назад'), ('forward', 'Icons.arrow_forward', 'кнопка welcome'),
            ('chevron', 'Icons.chevron_right', 'переход к деталям'), ('store', 'Icons.storefront', 'вкладка «Услуги»'),
            ('list', 'Icons.event_note', 'вкладка «Записи»'), ('person', 'Icons.person', 'вкладка «Профиль»'),
            ('scissors', 'Icons.content_cut', 'барбершоп'), ('spa', 'Icons.spa_outlined', 'салон красоты'),
            ('smile', 'Icons.sentiment_satisfied_alt_outlined', 'стоматология'), ('hospital', 'Icons.local_hospital_outlined', 'клиника'),
            ('car', 'Icons.car_repair', 'автосервис'), ('school', 'Icons.school_outlined', 'репетиторы'),
            ('calendar', 'Icons.calendar_today_outlined', 'дата'), ('clock', 'Icons.schedule', 'время, длительность'),
            ('payments', 'Icons.payments_outlined', 'стоимость'), ('event-busy', 'Icons.event_busy', 'отмена записи'),
            ('moon', 'Icons.dark_mode_outlined', 'тёмная тема'), ('bell', 'Icons.notifications_outlined', 'уведомления'),
            ('pulse', 'Icons.monitor_heart_outlined', 'диагностика'), ('gesture', 'Icons.gesture', 'Gesture Lab'),
            ('draw', 'Icons.draw_outlined', 'ввод талона'), ('info', 'Icons.info_outline', 'о приложении')]

UI_KIT_TEMPLATE = """<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Slotly — UI kit</title>
<style>
* {{ box-sizing: border-box; }}
body {{ margin: 0; font: 15px/1.55 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
  color: #161D1C; background: #F4FBF9; }}
main {{ max-width: 1040px; margin: 0 auto; padding: 24px 16px 64px; }}
h1 {{ color: #006A65; margin: 0 0 4px; }}
h2 {{ margin: 40px 0 12px; padding-top: 8px; border-top: 1px solid #BEC9C7; }}
a {{ color: #006A65; }}
.muted {{ color: #3F4947; }}
.grid {{ display: grid; gap: 12px; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); }}
.swatch {{ border: 1px solid #BEC9C7; border-radius: 12px; overflow: hidden; background: #fff; }}
.swatch div {{ height: 56px; }}
.swatch p {{ margin: 0; padding: 8px 10px; font-size: 13px; }}
.swatch code {{ font-size: 12px; }}
.table-wrap {{ overflow-x: auto; border: 1px solid #BEC9C7; border-radius: 12px; background: #fff; }}
table {{ border-collapse: collapse; width: 100%; font-size: 14px; }}
th, td {{ text-align: left; padding: 8px 12px; border-bottom: 1px solid #DDE4E2; vertical-align: middle; }}
th {{ background: #E3E9E8; }}
.space {{ display: flex; align-items: center; gap: 12px; margin: 6px 0; }}
.space span {{ display: inline-block; height: 16px; background: #9DF2EA; border: 1px solid #006A65; }}
.radii {{ display: flex; flex-wrap: wrap; gap: 16px; }}
.radii div {{ width: 96px; height: 72px; background: #CCE8E5; border: 1px solid #006A65; display: flex;
  align-items: center; justify-content: center; font-size: 13px; }}
.components {{ display: grid; gap: 20px; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); }}
.component {{ background: #fff; border: 1px solid #BEC9C7; border-radius: 16px; padding: 12px; }}
.component svg {{ width: 100%; height: auto; display: block; }}
.component h3 {{ margin: 0 0 8px; font-size: 16px; }}
.component p {{ margin: 8px 0 0; font-size: 14px; color: #3F4947; }}
.icons {{ display: grid; gap: 8px; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); }}
.icon {{ display: flex; gap: 10px; align-items: center; background: #fff; border: 1px solid #DDE4E2;
  border-radius: 10px; padding: 8px; font-size: 13px; }}
.icon svg {{ flex: none; }}
.live {{ display: flex; flex-wrap: wrap; gap: 12px; align-items: center; }}
.btn {{ font: 600 16px/1 inherit; font-family: inherit; min-height: 52px; padding: 0 24px; border: 0;
  border-radius: 12px; background: #006A65; color: #fff; cursor: pointer; }}
.btn:hover {{ box-shadow: 0 1px 3px rgba(0,0,0,.25); }}
.btn:active {{ background: #1A7A75; }}
.btn:disabled {{ background: rgba(22,29,28,.12); color: rgba(22,29,28,.38); cursor: not-allowed; box-shadow: none; }}
.btn:focus-visible {{ outline: 3px solid #9DF2EA; outline-offset: 2px; }}
.field {{ display: grid; gap: 4px; min-width: 260px; }}
.field input {{ font: inherit; padding: 14px 16px; border: 0; border-bottom: 2px solid transparent; border-radius: 12px;
  background: #DDE4E2; }}
.field input:focus {{ outline: none; border-bottom-color: #006A65; }}
.field.error input {{ border-bottom-color: #BA1A1A; }}
.field.error small {{ color: #BA1A1A; }}
ul.rules li {{ margin: 6px 0; }}
</style>
</head>
<body>
<main>
<h1>Slotly · UI kit</h1>
<p class="muted">Токены сняты с <code>ColorScheme.fromSeed(seedColor: Color(0xFF0B6E69))</code> в <code>lib/app/theme.dart</code>. Те же значения использованы во фреймах <a href="index.html">прототипа</a> и в SVG для Figma (<code>design/figma-import/</code>).</p>

<h2>Цвета — светлая схема</h2>
<div class="grid">{light}</div>
<h2>Цвета — тёмная схема</h2>
<div class="grid">{dark}</div>

<h2>Типографика</h2>
<p class="muted">Системный шрифт Android (Roboto), шкала Material 3.</p>
<div class="table-wrap"><table><thead><tr><th>Роль</th><th>Пример</th><th>Размер / строка</th><th>Применение</th></tr></thead><tbody>{type_rows}</tbody></table></div>

<h2>Отступы</h2>
<p class="muted"><code>AppSpacing</code>: кратно 4 dp. Боковой отступ экрана — 16, между карточками — 12, между секциями — 24.</p>
{spaces}

<h2>Радиусы</h2>
<div class="radii">{radii}</div>

<h2>Иконки</h2>
<p class="muted">В прототипе — упрощённые линейные иконки, в приложении — соответствующие Material icons из Flutter SDK.</p>
<div class="icons">{icons}</div>

<h2>Компоненты и состояния</h2>
<div class="components">{components}</div>

<h3>Интерактивные состояния</h3>
<p class="muted">Наведите курсор, нажмите и переключитесь клавишей Tab, чтобы увидеть hover, pressed и focus.</p>
<div class="live">
  <button class="btn" type="button">Продолжить</button>
  <button class="btn" type="button" disabled>Продолжить</button>
  <label class="field">Поиск<input placeholder="Найти услугу"></label>
  <label class="field error">Комментарий<input value="Слишком длинный комментарий…"><small>Комментарий должен быть не длиннее 200 символов</small></label>
</div>

<h2>Правила использования</h2>
<ul class="rules">
<li><strong>Одна главная кнопка на экран.</strong> <code>FilledButton</code> закреплена внизу (детали услуги, форма записи). Второстепенные действия — <code>TextButton</code> или <code>OutlinedButton</code>.</li>
<li><strong>Disabled — с объяснением.</strong> Если кнопка отключена, рядом написано, чего не хватает: «Чтобы продолжить, выберите: специалиста, время».</li>
<li><strong>Error — текстом и цветом.</strong> Ошибка поля показывается под полем красным текстом; ошибка операции — в SnackBar или карточке <code>errorContainer</code>. Цвет никогда не единственный признак.</li>
<li><strong>Карточка услуги</strong> всегда содержит иллюстрацию категории, название, категорию с длительностью и цену. Вся карточка — одна зона нажатия.</li>
<li><strong>Временной слот:</strong> доступный — с рамкой, выбранный — <code>secondaryContainer</code>, занятый — зачёркнут и отключён.</li>
<li><strong>Нижняя навигация</strong> — только три раздела верхнего уровня. Вложенные экраны открываются поверх и не показывают NavigationBar.</li>
<li><strong>Опасные действия</strong> (отмена записи) всегда подтверждаются диалогом, кнопка подтверждения — цвета <code>error</code>.</li>
<li><strong>Зоны касания</strong> — не меньше 48 × 48 dp; текст не обрезается при увеличенном шрифте.</li>
</ul>
</main>
</body>
</html>
"""


def ui_kit_page(component_svgs):
    def swatches(colors):
        return ''.join(f'<div class="swatch"><div style="background:{v}"></div><p><strong>{k}</strong><br>'
                       f'<code>{v}</code><br>{ROLES.get(k, "")}</p></div>' for k, v in colors.items() if k in ROLES)
    type_rows = ''.join(f'<tr><td><code>{name}</code></td><td style="font-size:{size}px;line-height:{lh}px;'
                        f'font-weight:{weight}">Запись без звонков</td><td>{size} / {lh}</td><td>{use}</td></tr>'
                        for name, size, lh, weight, use in TYPE_SCALE)
    spaces = ''.join(f'<div class="space"><span style="width:{v * 4}px"></span>{v} dp — <code>AppSpacing.{n}</code></div>'
                     for n, v in [('xs', 4), ('s', 8), ('m', 12), ('l', 16), ('xl', 24), ('xxl', 32)])
    radii = ''.join(f'<div style="border-radius:{v}px">{v} dp<br>{use}</div>'
                    for v, use in [(8, 'чипы'), (12, 'кнопки, поля'), (16, 'карточки'), (28, 'диалоги')])
    icons = ''.join(f'<div class="icon"><svg width="28" height="28" viewBox="0 0 28 28">{icon(name, 2, 2, 24, C["primary"])}</svg>'
                    f'<span><code>{flutter}</code><br>{use}</span></div>' for name, flutter, use in ICON_MAP)
    descriptions = {
        'button': ('Кнопка', 'Состояния default, pressed и disabled. Высота 52 dp, радиус 12.'),
        'time-slot': ('Временной слот', 'available, selected, unavailable.'),
        'service-card': ('Карточка услуги', 'default и pressed (ripple затемняет фон).'),
        'chip': ('Чип категории', 'default и selected.'),
        'text-field': ('Поле ввода', 'default, focused и error.'),
        'navigation-bar': ('Нижняя навигация', 'Три раздела, активный выделен индикатором.'),
    }
    components_html = ''.join(f'<div class="component"><h3>{descriptions[k][0]}</h3>{svg}<p>{descriptions[k][1]}</p></div>'
                              for k, svg in component_svgs.items())
    return UI_KIT_TEMPLATE.format(light=swatches(C), dark=swatches(DARK), type_rows=type_rows, spaces=spaces,
                                  radii=radii, icons=icons, components=components_html)


TITLES = {'welcome': 'Welcome', 'login': 'Вход', 'catalog': 'Каталог мест', 'search': 'Поиск услуг',
          'organization': 'Организация', 'details': 'Детали услуги',
          'booking': 'Вариант, специалист и время', 'confirm': 'Подтверждение', 'bookings': 'Мои записи',
          'profile': 'Профиль', 'dashboard': 'Обзор владельца'}


def main():
    import json
    frames_dir = os.path.join(DESIGN, 'figma-import', 'frames')
    comp_dir = os.path.join(DESIGN, 'figma-import', 'components')
    os.makedirs(frames_dir, exist_ok=True)
    for name in os.listdir(frames_dir):
        if name.endswith('.svg'):
            os.remove(os.path.join(frames_dir, name))
    os.makedirs(comp_dir, exist_ok=True)
    built = {}
    for i, (key, builder) in enumerate(FRAMES, start=1):
        svg = builder()
        built[key] = svg
        clean = svg.replace(' class="hotspot"', ' data-hotspot="true"')
        with open(os.path.join(frames_dir, f'{i:02d}-{key}.svg'), 'w', encoding='utf-8') as f:
            f.write('<?xml version="1.0" encoding="UTF-8"?>\n' + clean + '\n')
    component_svgs = components()
    for name, svg in component_svgs.items():
        with open(os.path.join(comp_dir, f'{name}.svg'), 'w', encoding='utf-8') as f:
            f.write('<?xml version="1.0" encoding="UTF-8"?>\n' + svg + '\n')
    inline = {k: v.replace('clip-', f'ui-{k}-clip-') for k, v in component_svgs.items()}
    with open(os.path.join(DESIGN, 'prototype', 'ui-kit.html'), 'w', encoding='utf-8') as f:
        f.write(ui_kit_page(inline))

    steps = ''.join(f'<li data-frame="{k}">{TITLES[k]}</li>' for k, _ in FRAMES)
    gallery = ''.join(f'<figure><div class="device">{built[k].replace("clip-", "g-clip-")}</div>'
                      f'<figcaption>{i:02d} · {TITLES[k]}</figcaption></figure>'
                      for i, (k, _) in enumerate(FRAMES, start=1))
    page = PROTOTYPE_TEMPLATE.format(steps=steps, gallery=gallery,
                                     frames_json=json.dumps(built, ensure_ascii=False),
                                     order_json=json.dumps([k for k, _ in FRAMES]))
    with open(os.path.join(DESIGN, 'prototype', 'index.html'), 'w', encoding='utf-8') as f:
        f.write(page)
    print('frames:', len(built), 'components:', len(component_svgs))


if __name__ == '__main__':
    main()
