# MCP-серверы для 1С

Управление Docker-контейнерами [MCP-серверов](https://docs.onerpa.ru/mcp-servery-1c) для разработки на 1С в Cursor IDE.

## Структура

```
├── global/                 Глобальные серверы (всегда запущены)
│   ├── docker-compose.yml  syntax_check, help_search, code_checker, ssl_search, forms_server, template_search
│   └── volumes/            Векторные БД и кэш моделей
│
├── projects/               Серверы по конфигурациям 1С
│   ├── _template/          Шаблон для новых проектов
│   ├── buh/                Бухгалтерия предприятия
│   ├── zupreg/             ЗУП Рег
│   ├── wms/                WMS (склад)
│   ├── testzup/            ЗУП Упр
│   ├── roznica/            Розница
│   └── unf/                УНФ
│
├── config/                 mcp.json для Cursor
└── scripts/                PowerShell-скрипты управления
```

## Быстрый старт

### 1. Настройте окружение

```powershell
Copy-Item .env.example .env
# Заполните .env: лицензионные ключи, GLOBAL_OPENAI_API_KEY и OPENAI_API_KEY (часто OpenRouter), путь к платформе
```

### 2. Запустите глобальные серверы

```powershell
# Все глобальные серверы
.\scripts\start-global.ps1

# Только отдельные серверы
.\scripts\start-global.ps1 -Services syntax_check,help_search

# Один сервер
.\scripts\start-global.ps1 -Services ssl_search
```

### 3. Подготовьте данные конфигурации

Для каждой конфигурации выгрузите из Конфигуратора:

1. **Конфигурация → Отчёт из конфигурации** → `projects\<имя>\data\report\`
2. **Конфигурация → Выгрузить конфигурацию в файлы** → `projects\<имя>\data\src\`

### 4. Запустите серверы конфигурации

```powershell
# Проект: по умолчанию профиль metadata (шаблоны — смотри start-global.ps1)
.\scripts\start-project.ps1 -Name buh

# Только метаданные
.\scripts\start-project.ps1 -Name buh -Services metadata

# Только граф
.\scripts\start-project.ps1 -Name buh -Services graph
```

### 5. Установите mcp.json в Cursor

```powershell
.\config\install-mcp-config.ps1
```

## Скрипты

| Скрипт | Назначение |
|---|---|
| `start-global.ps1 [-Services ...]` | Запуск глобальных серверов (все или выборочно) |
| `stop-global.ps1 [-Services ...]` | Остановка глобальных серверов (все или выборочно) |
| `start-project.ps1 -Name X [-Services ...]` | Запуск серверов конфигурации |
| `stop-project.ps1 -Name X [-Services ...]` | Остановка серверов конфигурации |
| `new-project.ps1 -Name X -PortBase N` | Создание нового проекта |
| `status.ps1` | Статус всех контейнеров |
| `generate-mcp-json.ps1` | Пересборка mcp.json |
| `backup.ps1` | Бэкап векторных БД |

## Порты

### Глобальные

| Сервер | Порт |
|---|---|
| SyntaxCheck | 8002 |
| HelpSearch | 8003 |
| CodeChecker | 8007 |
| SSLSearch | 8008 |
| FormsServer | 8011 |
| TemplateSearch | 8004 |

### По конфигурациям (PORT_BASE + смещение)

| Конфигурация | CodeMetadata | Graph | Neo4j Browser | Neo4j Bolt |
|---|---|---|---|---|
| buh | 8100 | 8106 | 8174 | 8187 |
| zupreg | 8200 | 8206 | 8274 | 8287 |
| wms | 8300 | 8306 | 8374 | 8387 |
| testzup | 8400 | 8406 | 8474 | 8487 |
| roznica | 8500 | 8506 | 8574 | 8587 |
| unf | 8600 | 8606 | 8674 | 8687 |

## Добавление новой конфигурации

```powershell
.\scripts\new-project.ps1 -Name erp -PortBase 8700
# Выгрузите данные из Конфигуратора в projects\erp\data\
.\scripts\start-project.ps1 -Name erp
.\scripts\generate-mcp-json.ps1
.\config\install-mcp-config.ps1
```

## Выборочный запуск

### Глобальные серверы

Параметр `-Services` принимает имена сервисов из `global/docker-compose.yml`:

| Имя сервиса | Описание |
|---|---|
| `syntax_check` | Проверка синтаксиса |
| `help_search` | Поиск по справке платформы |
| `code_checker` | Проверка кода |
| `ssl_search` | Поиск по БСП |
| `forms_server` | Работа с формами |
| `template_search` | Поиск шаблонов кода |

```powershell
.\scripts\start-global.ps1 -Services syntax_check,help_search
.\scripts\stop-global.ps1 -Services ssl_search
```

Без `-Services` запускаются/останавливаются все глобальные серверы.

### Профили проектов

В каждом проекте — профили `metadata`, `cloud` и `graph`.

| Профиль | Сервисы | Назначение |
|---|---|---|
| `metadata` | code_metadata | Поиск по метаданным и коду конфигурации |
| `cloud` | cloud_embeddings | Альтернатива CodeMetadata (облачные эмбеддинги) |
| `graph` | neo4j + graph_metadata | Графовый поиск связей объектов |

Без параметра `-Services` для проекта поднимается профиль `metadata`.

## Настройки индексации

Переопределяются в `projects\<имя>\.env` (раскомментируйте нужное):

**CodeMetadata:**
- `INDEX_CODE` — индексация BSL-кода (по умолчанию `true`)
- `INDEX_METADATA` — индексация метаданных (по умолчанию `true`)
- `INDEX_HELP` — индексация HTML-справки конфигурации (по умолчанию `true`)
- `INDEX_BATCH_SIZE` — размер пакета записей в ChromaDB (по умолчанию `25`)
- `CHUNK_SIZE` — размер фрагмента текста при разбивке (по умолчанию `1000`)

**Graph:**
- `ENABLE_CODE_SEARCH` — поиск по BSL-коду (по умолчанию `true`)
- `ENABLE_BUSINESS_SEARCH` — семантический поиск по бизнес-описаниям (по умолчанию `true`)
- `GRAPH_INDEX_BATCH_SIZE` — размер пакета при индексации (по умолчанию `50`)

## Embedding

Глобальные MCP (`help_search`, `ssl_search`, `template_search`) читают из корневого `.env` переменные `GLOBAL_OPENAI_API_BASE`, `GLOBAL_OPENAI_API_KEY`, `GLOBAL_OPENAI_MODEL` (по умолчанию тот же OpenRouter и модель `qwen/qwen3-embedding-8b`). CodeMetadata в проектах использует `OPENAI_API_BASE`, `OPENAI_API_KEY`, `OPENAI_MODEL`.

**Graph Metadata Search** в контейнере ожидает `OPENAI_API_BASE` и `OPENAI_API_KEY` ([документация](https://docs.onerpa.ru/mcp-servery-1c/servery/graph-metadata-search/konfiguraciya)). В корневом `.env` задайте `GRAPH_OPENAI_API_BASE` и `GRAPH_OPENAI_API_KEY` — compose подставляет их в эти переменные для графа (LM Studio, прямой OpenAI и т.д.), не меняя endpoint для остальных сервисов.

## Документация

- [MCP-серверы для 1С](https://docs.onerpa.ru/mcp-servery-1c)
- [Cursor Rules для 1С](https://github.com/comol/cursor_rules_1c)
