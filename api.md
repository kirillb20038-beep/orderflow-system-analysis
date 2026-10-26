# REST API — контракт MVP

Base URL: `/api/v1`

## Общие соглашения
- Формат данных: JSON, UTF-8.
- Все даты — ISO 8601 в UTC.
- Денежные суммы передаются десятичным числом; в реальной платёжной системе нужно отдельно определить валюту и правила округления.
- Серверные ошибки имеют форму `{ "error": { "code": "...", "message": "...", "details": [] } }`.

## GET /products
Возвращает список активных товаров.

**200 OK**
```json
{
  "items": [
    {
      "id": 101,
      "name": "Механическая клавиатура",
      "description": "Компактная клавиатура",
      "price": 79.90,
      "stock_quantity": 12
    }
  ]
}
```

## POST /orders
Создаёт заказ. Заголовок `Idempotency-Key` обязателен.

**Request**
```http
POST /api/v1/orders
Content-Type: application/json
Idempotency-Key: 2d4d2ac0-8bd8-4d92-bf23-42f2d0c0f101
```
```json
{
  "items": [
    { "product_id": 101, "quantity": 1 },
    { "product_id": 202, "quantity": 2 }
  ]
}
```

**201 Created**
```json
{
  "id": 5001,
  "status": "NEW",
  "total_amount": 119.80,
  "items": [
    {
      "product_id": 101,
      "quantity": 1,
      "unit_price": 79.90,
      "line_total": 79.90
    },
    {
      "product_id": 202,
      "quantity": 2,
      "unit_price": 19.95,
      "line_total": 39.90
    }
  ],
  "created_at": "2026-10-25T08:00:00Z"
}
```

**Ошибки**
- `400 VALIDATION_ERROR` — некорректное тело, пустой список или quantity не положительное целое.
- `404 PRODUCT_NOT_FOUND` — товар не найден.
- `409 INSUFFICIENT_STOCK` — не хватает остатка.
- `409 IDEMPOTENCY_KEY_REUSED` — ключ использован с другим содержимым.
- `500 INTERNAL_ERROR` — непредвиденная ошибка; клиенту не раскрываются внутренние детали.

## GET /orders/{orderId}
Возвращает заказ и позиции.

- `200 OK` — заказ найден.
- `404 ORDER_NOT_FOUND` — заказа нет.

## POST /orders/{orderId}/cancel
Отменяет заказ в статусе `NEW`.

**200 OK**
```json
{
  "id": 5001,
  "status": "CANCELLED",
  "updated_at": "2026-10-25T08:05:00Z"
}
```

**Ошибки**
- `404 ORDER_NOT_FOUND` — заказ не найден.
- `409 ORDER_NOT_CANCELLABLE` — заказ нельзя отменить в текущем статусе.

## Почему отмена использует POST
Отмена — бизнес-команда, запускающая несколько согласованных действий: изменение статуса и восстановление остатков. `POST /orders/{id}/cancel` явно выражает команду. Альтернативой мог бы быть `PATCH /orders/{id}` со сменой статуса, но контракт должен выбрать один согласованный подход.
