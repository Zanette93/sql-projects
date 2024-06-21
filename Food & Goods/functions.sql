-- ANÁLISE DOS PEDIDOS E ENTREGAS
-- Função para averiguar a quantidade de pedidos por categoria (Tipo de Canal, Segmento da Loja, Status do Pedido, etc.)
CREATE OR REPLACE FUNCTION estatisticas_pedido(grupo_por_campo TEXT, nome_tabela TEXT, condicao_join TEXT)
RETURNS TABLE (
    "Categoria" TEXT,
    "Quantidade de Pedidos" BIGINT,
    "Porcentagem" DECIMAL
) AS $$
BEGIN
	IF condicao_join = 'TRUE' THEN
		 RETURN QUERY EXECUTE format(
	        'SELECT 
				%s::text AS "Categoria",
	            COUNT(orders.order_id) AS "Quantidade de Pedidos",
	            ROUND((COUNT(orders.order_id) * 100.0 / (SELECT COUNT(*) FROM orders)), 2) AS "Porcentagem"
	        FROM
	            %I
	        GROUP BY 
	            %s', grupo_por_campo, nome_tabela, grupo_por_campo
	    );
	ELSE
	    RETURN QUERY EXECUTE format(
	        'SELECT 
				%s::text AS "Categoria",
	            COUNT(orders.order_id) AS "Quantidade de Pedidos",
	            ROUND((COUNT(orders.order_id) * 100.0 / (SELECT COUNT(*) FROM orders)), 2) AS "Porcentagem"
	        FROM
	            %I 
	        JOIN
	            orders ON %s
	        GROUP BY 
	            %s', grupo_por_campo, nome_tabela, condicao_join, grupo_por_campo
	    );
	END IF;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM estatisticas_pedido('channels.channel_type', 'channels', 'orders.channel_id = channels.channel_id');

SELECT * FROM estatisticas_pedido('stores.store_segment', 'stores', 'orders.store_id = stores.store_id');

SELECT * FROM estatisticas_pedido('orders.order_status', 'orders', 'TRUE');


-- Função que avalia tempo total das entregas independente da categoria
DROP FUNCTION tempo_medio_entrega
CREATE OR REPLACE FUNCTION tempo_medio_entrega(categoria_entrega TEXT, nome_tabela TEXT DEFAULT NULL, condicao_join TEXT DEFAULT NULL)
RETURNS TABLE (
    "Categoria" TEXT,
    "Tempo de Entrega" TEXT
) AS $$
BEGIN
    IF categoria_entrega IN ('driver_modal', 'driver_type') THEN
        RETURN QUERY EXECUTE format(
            'SELECT 
                %s::text AS "Categoria",
                to_char(AVG(orders.order_moment_finished - orders.order_moment_created), ''HH24:MI:SS'') AS "Tempo de Entrega"
            FROM 
                drivers
            JOIN 
                deliveries ON deliveries.driver_id = drivers.driver_id
            JOIN
                orders ON orders.order_id = deliveries.delivery_order_id
            GROUP BY 
                %I', categoria_entrega, categoria_entrega
        );
    ELSE
        RETURN QUERY EXECUTE format(
            'SELECT 
                %s::text AS "Categoria",
                to_char(AVG(orders.order_moment_finished - orders.order_moment_created), ''HH24:MI:SS'') AS "Tempo de Entrega"
            FROM 
                %I
            JOIN 
                orders ON %s
            GROUP BY 
                %I', categoria_entrega, nome_tabela, condicao_join, categoria_entrega
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM tempo_medio_entrega('driver_modal');
SELECT * FROM tempo_medio_entrega('store_segment', 'stores', 'orders.store_id = stores.store_id');


-- Função que retorna Trigger para atualizar status do pedido
CREATE OR REPLACE FUNCTION atualizar_status_pedido() 
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.payment_status = 'PAID' THEN
        UPDATE orders
        SET order_status = 'FINISHED'
        WHERE order_id = NEW.payment_order_id;
    ELSIF NEW.payment_status = 'AWAITING' THEN
        UPDATE orders
        SET order_status = 'PENDING'
        WHERE order_id = NEW.payment_order_id;
    ELSIF NEW.payment_status = 'CHARGEBACK' THEN
        UPDATE orders
        SET order_status = 'CANCELED'
        WHERE order_id = NEW.payment_order_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
