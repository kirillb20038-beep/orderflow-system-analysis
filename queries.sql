-- 1. Каталог активных товаров
SELECT id, name, price, stock_quantity
FROM products
WHERE is_active = TRUE
ORDER BY name;

-- 2. Заказы со статусом и общей суммой
SELECT id, status, total_amount, created_at
FROM orders
ORDER BY created_at DESC;

-- 3. Состав заказа
SELECT oi.order_id, p.name, oi.quantity, oi.unit_price, oi.line_total
FROM order_items oi
JOIN products p ON p.id = oi.product_id
WHERE oi.order_id = 5001;

-- 4. Количество заказов по статусам
SELECT status, COUNT(*) AS orders_count
FROM orders
GROUP BY status;

-- 5. Самые часто заказываемые товары
SELECT p.id, p.name, SUM(oi.quantity) AS units_ordered
FROM order_items oi
JOIN products p ON p.id = oi.product_id
JOIN orders o ON o.id = oi.order_id
WHERE o.status = 'NEW'
GROUP BY p.id, p.name
ORDER BY units_ordered DESC;

-- 6. Условное уменьшение остатка для одной позиции.
-- В приложении результат нужно проверить: если обновлено 0 строк,
-- остатка недостаточно. Все позиции и создание заказа должны быть
-- частью одной транзакции.
UPDATE products
SET stock_quantity = stock_quantity - 2,
    updated_at = NOW()
WHERE id = 101
  AND is_active = TRUE
  AND stock_quantity >= 2
RETURNING id, stock_quantity;
