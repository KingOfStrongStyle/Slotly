# Как работать с репозиторием

## Ветки

| Ветка | Для чего |
|---|---|
| `main` | Рабочая версия. Всегда собирается и проходит тесты. Прямые коммиты — только для служебных правок владельца. |
| `feature/lifecycle` | Каркас, навигация, lifecycle, «Мои записи» (Кирилл) |
| `feature/booking` | Данные, репозиторий, форма записи (Влад) |
| `feature/gestures` | Распознавание и ввод талона (Влад), Gesture Lab (Ян) |
| `feature/ui-kit` | UI kit, экраны каталога и профиля, прототип (Ян) |
| `fix/<short-name>` | Исправление ошибки, например `fix/slot-overlap` |
| `docs/<short-name>` | Документация, например `docs/defense-questions` |

Каждый участник коммитит от своего имени (настройте `git config user.name` и `user.email` в своём клоне) и открывает pull request в `main`. Чужие коммиты не переписываются, `git push --force` в `main` не используется.

## Коммиты

Формат [Conventional Commits](https://www.conventionalcommits.org/ru/v1.0.0/), описание на английском в повелительном наклонении:

```
feat: add booking reschedule action
fix: keep selected slot after rotation
test: cover ticket entry limits
docs: describe gesture arena in lab 3
ci: cache gradle in workflow
chore: bump flutter to 3.48
refactor: extract date badge widget
```

## Перед коммитом

```bash
dart format .
flutter analyze
flutter test                    # или тесты изменённого модуля
git diff                        # нет ли лишнего: секретов, путей, отладочного кода
```

- Пользовательские тексты добавляйте в `lib/core/app_strings.dart`.
- Новая логика — в `domain/` с unit-тестами; экраны — с widget-тестами ключевых сценариев.
- `print` в коде приложения не используется; для отладки lifecycle есть `debugPrint` в debug-сборке.
- Golden-эталоны обновляются только намеренно (`flutter test --update-goldens test/goldens`), изменения в PNG нужно просмотреть.
- Не добавляйте пакеты без необходимости; если добавили — обновите таблицу зависимостей в `docs/architecture.html`.
- Не коммитьте `local.properties`, keystore, `key.properties`, `.env`, сборки и кэши IDE (они в `.gitignore`).

## Pull request

1. Заполните шаблон: что изменено и как проверить.
2. Дождитесь зелёного CI (формат, анализ, тесты, debug APK).
3. Попросите ревью у участника, отвечающего за затронутый модуль (см. `PROJECT_TASKS.md`).
4. Обновите `CHANGELOG.md` и при необходимости `docs/requirements-matrix.html`.

## Владельцы модулей

Файл `CODEOWNERS` не добавлен: GitHub-логины Влада и Яна станут известны после того, как владелец репозитория пригласит их. После этого можно добавить `.github/CODEOWNERS`, например:

```
/lib/app/                       @<логин Кирилла>
/lib/features/booking/domain/   @<логин Влада>
/lib/features/gesture_lab/      @<логин Яна>
```

## Дизайн-прототип

Прототип и SVG генерируются скриптом: `python3 design/tools/build_prototype.py`. Правьте генератор, а не готовые файлы, и коммитьте результат вместе с изменением скрипта.
