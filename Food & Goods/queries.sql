-- ANÁLISE DOS PEDIDOS E ENTREGAS
-- Total de pedidos e entregas realizados em todo o período de coleta dos dados
SELECT 
	COUNT(DISTINCT o.order_id) AS "Total de Pedidos", 
	COUNT (DISTINCT d.delivery_id) AS "Total de Entregas"
FROM 
	orders o
JOIN 
	deliveries d ON d.delivery_order_id = o.order_id;

-- Contagem de quantos pedidos tiveram mais de uma entrega
SELECT 
	COUNT(*) AS "Quantidade de Pedidos" 
	FROM (
		SELECT 
    		o.order_id, 
    		COUNT(DISTINCT d.delivery_id) AS "Número de Entregas"
FROM 
    orders o
JOIN 
    deliveries d ON d.delivery_order_id = o.order_id
GROUP BY 
    o.order_id
HAVING 
    COUNT(DISTINCT d.delivery_id) > 1
);

-- Preço médio dos pedidos
SELECT ROUND(AVG(order_amount), 2) AS "Preço Médio dos Pedidos" FROM orders;

-- Tendência de pedidos (semana e mês)
SELECT
    TO_CHAR(order_moment_created, 'IYYY-IW') AS "Ano-Semana",
    COUNT(DISTINCT order_id) AS "Pedidos"
FROM 
	orders
GROUP BY 
	"Ano-Semana"
ORDER BY 
	"Ano-Semana";

SELECT
    order_created_month AS "Mês",
    COUNT(DISTINCT order_id) AS "Pedidos"
FROM 
	orders
GROUP BY 
	"Mês"
ORDER BY 
	"Mês";

-- Distância média das entregas
SELECT 
	ROUND(AVG(delivery_distance_meters)/1000, 2) AS "Distância Média (Km)" 
FROM 
	deliveries;

-- Eficiência das entregas
SELECT
	delivery_status AS "Status da Entrega",
	COUNT(delivery_id) AS "Quantidade de Entregas",
	ROUND((COUNT(delivery_id)) * 100.0 / (SELECT COUNT(delivery_id) FROM deliveries), 2) AS "Porcentagem"
FROM
	deliveries
GROUP BY
	delivery_status
ORDER BY
	"Quantidade de Entregas" DESC;

-- Média da Diferença Cobrado - Custo entre todas as entregas
SELECT 
	to_char(ROUND(AVG("Diferença Cobrado - Custo"), 2), 'L999G999G999D99') AS "Média da Diferença Cobrado - Custo" 
FROM (
	SELECT 
		order_id, (order_delivery_fee - order_delivery_cost) AS "Diferença Cobrado - Custo" 
	FROM 
		orders);

-- Diferença Cobrado - Custo por segmento e tipo de canal
SELECT 
	store_segment, 
	to_char(ROUND(AVG(order_delivery_fee - order_delivery_cost), 2), 'L999G999G999D99') AS "Diferença Cobrado - Custo" 
FROM 
	orders o
JOIN 
	stores s ON s.store_id = o.store_id
GROUP BY 
	store_segment;

SELECT 
	channel_type, 
	to_char(ROUND(AVG(order_delivery_fee - order_delivery_cost), 2), 'L999G999G999D99') AS "Diferença Cobrado - Custo" 
FROM 
	orders o
JOIN 
	channels c ON c.channel_id = o.channel_id
GROUP BY 
	channel_type;

-- Comparação com pedidos finalizados	
SELECT
	order_status AS "Status do Pedido",
	to_char(ROUND(AVG(order_amount), 2), 'L999G999G999D99') AS "Preço do Pedido",
	to_char(ROUND(AVG(order_delivery_fee), 2), 'L999G999G999D99') AS "Preço da Entrega",
	to_char(AVG(o.order_moment_ready - o.order_moment_created), 'HH24:MI:SS') AS "Tempo de Preparo nos Hubs",
	to_char(AVG(o.order_moment_delivering - o.order_moment_ready), 'HH24:MI:SS') AS "Tempo para o Pedido ser Coletado na Loja"
FROM 
	orders o
GROUP BY
	"Status do Pedido";


-- ANÁLISE DE PAGAMENTOS
-- Total de Pedidos por Tipo de Pagamento
WITH "Total de Pedidos" AS (
    SELECT COUNT(*) AS Total
    FROM payments
)
SELECT 
    p.payment_method AS "Método de Pagamento",
    COUNT(o.order_id) AS "Quantidade de Pedidos",
    ROUND((COUNT(o.order_id) * 100.0 / (SELECT Total FROM "Total de Pedidos")), 2) AS "Porcentagem"
FROM 
    payments p
JOIN
    orders o ON o.order_id = p.payment_order_id
GROUP BY
    p.payment_method
ORDER BY
    "Quantidade de Pedidos" DESC;

-- Faturamento Total
SELECT 
	to_char(SUM(payment_amount),'L999G999G999D99') AS "Faturamento Total"
FROM 
	payments
WHERE 
	payment_status = 'PAID';

-- Faturamento por mês
SELECT 
	to_char(SUM(payment_amount),'L999G999G999D99') AS "Faturamento Total",
	order_created_month AS "Mês"
FROM 
	payments p
JOIN
	orders o ON o.order_id = p.payment_order_id
WHERE
	payment_status = 'PAID'
GROUP BY
	"Mês";

-- Faturamento por segmento
SELECT 
	store_segment AS "Segmento",
	to_char(SUM(payment_amount),'L999G999G999D99') AS "Faturamento Total"
FROM 
	payments p
JOIN
	orders o ON o.order_id = p.payment_order_id
JOIN
	stores s on s.store_id = o.store_id
WHERE
	payment_status = 'PAID'
GROUP BY
	"Segmento";

-- Faturamento por canal
SELECT 
	channel_type AS "Canal",
	to_char(SUM(payment_amount),'L999G999G999D99') AS "Faturamento Total"
FROM 
	payments p
JOIN
	orders o ON o.order_id = p.payment_order_id
JOIN
	channels c on c.channel_id = o.channel_id
WHERE
	payment_status = 'PAID'
GROUP BY
	"Canal";

-- Faturamento por cidade e hub
SELECT 
	hub_name AS "Hub",
	hub_city AS "Cidade",
	to_char(SUM(payment_amount),'L999G999G999D99') AS "Faturamento"
FROM 
	payments p
JOIN
	orders o ON o.order_id = p.payment_order_id
JOIN
	stores s ON s.store_id = o.store_id
JOIN
	hubs h ON h.hub_id = s.hub_id
WHERE
	payment_status = 'PAID'
GROUP BY
	"Cidade", "Hub"
ORDER BY 
	"Faturamento" DESC;

-- Faturamento por loja e segmento
SELECT 
	store_name AS "Loja",
	store_segment AS "Segmento",
	to_char(SUM(payment_amount),'L999G999G999D99') AS "Faturamento"
FROM 
	payments p
JOIN
	orders o ON o.order_id = p.payment_order_id
JOIN
	stores s ON s.store_id = o.store_id
WHERE
	payment_status = 'PAID'
GROUP BY
	"Loja", "Segmento"
ORDER BY 
	"Faturamento" DESC;


-- ANÁLISE DE HUBS
-- Quantidade de lojas por hub
SELECT 
	hub_name AS "Nome do Hub",
	COUNT(store_id) AS "Número de Lojas"
FROM 
	stores s
JOIN
	hubs h ON h.hub_id = s.hub_id
GROUP BY 
	"Nome do Hub"
ORDER BY
	"Número de Lojas" DESC;

-- Entregas por cidade do Hub
SELECT
	h.hub_city AS "Cidade",
	COUNT(delivery_id) AS "Entregas"
FROM
	hubs h
JOIN 
	stores s ON s.hub_id = h.hub_id
JOIN
	orders o ON o.store_id = s.store_id
JOIN
	deliveries dl ON dl.delivery_order_id = o.order_id
GROUP BY
	"Cidade"
ORDER BY
	"Entregas" DESC;

-- Tempo de preparo dos pedidos nos hubs x quantidade de pedidos preparados (Eficiência dos hubs)
SELECT 
	h.hub_name AS "Nome do Hub",
	h.hub_city AS "Cidade",
	COUNT(o.order_id) AS "Pedidos Recebidos",
	to_char(AVG(o.order_moment_ready - o.order_moment_created), 'HH24:MI:SS') AS "Tempo de Preparo"
FROM
	hubs h
JOIN
	stores s ON s.hub_id = h.hub_id
JOIN
 	orders o ON o.store_id = s.store_id
GROUP BY
	"Nome do Hub",
	"Cidade"
ORDER BY
	"Pedidos Recebidos" DESC, "Tempo de Preparo";


-- ANÁLISE DOS ENTREGADORES
-- Entregas por Motorista
SELECT 
	COUNT("Motoristas") "Quantidade de Motoristas", 
	ROUND(AVG("Entregas"),0) "Média de Entregas por Motorista" 
FROM(
	SELECT
	  d.driver_id AS "Motoristas",
	  COUNT(dl.delivery_id) AS "Entregas"
	FROM
	  drivers d
	JOIN
	  deliveries dl ON dl.driver_id = d.driver_id
	GROUP BY
	  d.driver_id);

-- Eficiência dos Motoristas (Número de Entregas x Tempo de Entrega)
SELECT
	d.driver_id AS "Motorista",
	COUNT(dl.delivery_id) AS "Número de Entregas",
	to_char(AVG(o.order_moment_delivered - o.order_moment_delivering), 'HH24:MI:SS') AS "Tempo de Entrega"
FROM
	drivers d
JOIN 
	deliveries dl ON dl.driver_id = d.driver_id
JOIN
	orders o ON o.order_id = dl.delivery_order_id
GROUP BY
	"Motorista"
ORDER BY
	"Número de Entregas" DESC, "Tempo de Entrega";