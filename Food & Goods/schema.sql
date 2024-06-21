-- CRIANDO AS TABELAS E INSERINDO DADOS
CREATE TABLE hubs (
	hub_id INT PRIMARY KEY,
	hub_name VARCHAR(50) NOT NULL,
	hub_city VARCHAR(50) NOT NULL,
	hub_state VARCHAR(2) NOT NULL,
	hub_latitude DECIMAL NOT NULL,
	hub_longitude DECIMAL NOT NULL
);

CREATE TABLE channels (
	channel_id INT PRIMARY KEY,
	channel_name VARCHAR(50) NOT NULL,
	channel_type VARCHAR(20) NOT NULL
);

CREATE TABLE stores (
	store_id INT PRIMARY KEY,
	hub_id INT NOT NULL,
	store_name VARCHAR(100) NOT NULL,
	store_segment VARCHAR(20) NOT NULL,
	store_plan_price DECIMAL,
	store_latitude DECIMAL,
	store_longitude DECIMAL,
	FOREIGN KEY (hub_id) REFERENCES hubs(hub_id)
);

CREATE TABLE drivers (
	driver_id INT PRIMARY KEY,
	driver_modal VARCHAR(20) NOT NULL,
	driver_type VARCHAR(20) NOT NULL
);

CREATE TABLE orders (
	order_id BIGINT PRIMARY KEY,
	store_id INT NOT NULL,
	channel_id INT NOT NULL,
	payment_order_id BIGINT NOT NULL,
	delivery_order_id BIGINT NOT NULL,
	order_status VARCHAR(20) NOT NULL,
	order_amount DECIMAL NOT NULL,
	order_delivery_fee DECIMAL,
	order_delivery_cost DECIMAL,
	order_created_hour INT NOT NULL,
	order_created_minute INT NOT NULL,
	order_created_day INT NOT NULL,
	order_created_month INT NOT NULL,
	order_created_year INT NOT NULL,
	order_moment_created VARCHAR(30),
	order_moment_accepted VARCHAR(30),
	order_moment_ready VARCHAR(30),
	order_moment_collected VARCHAR(30),
	order_moment_in_expedition VARCHAR(30),
	order_moment_delivering VARCHAR(30),
	order_moment_delivered VARCHAR(30),
	order_moment_finished VARCHAR(30),
	order_metric_collected_time DECIMAL,
	order_metric_paused_time DECIMAL,
	order_metric_production_time DECIMAL,
	order_metric_walking_time DECIMAL,
	order_metric_expediton_speed_time DECIMAL,
	order_metric_transit_time DECIMAL,
	order_metric_cycle_time DECIMAL,
	FOREIGN KEY (store_id) REFERENCES stores(store_id),
	FOREIGN KEY (channel_id) REFERENCES channels(channel_id)
);

CREATE TABLE payments (
	payment_id BIGINT PRIMARY KEY,
	payment_order_id BIGINT NOT NULL,
	payment_amount DECIMAL NOT NULL,
	payment_fee DECIMAL,
	payment_method VARCHAR(50) NOT NULL,
	payment_status VARCHAR(50) NOT NULL,
	FOREIGN KEY (payment_order_id) REFERENCES orders(order_id)
);

CREATE TABLE deliveries (
	delivery_id BIGINT PRIMARY KEY,
	delivery_order_id BIGINT NOT NULL,
	driver_id INT,
	delivery_distance_meters INT,
	delivery_status VARCHAR(20) NOT NULL,
	FOREIGN KEY (delivery_order_id) REFERENCES orders(order_id),
	FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
);

-- Alterando o formato das colunas order_moment_* com a função to_timestamp
ALTER TABLE orders
	ALTER COLUMN order_moment_created TYPE timestamp USING to_timestamp(order_moment_created, 'MM/DD/YYYY HH:MI:SS AM'),
	ALTER COLUMN order_moment_accepted TYPE timestamp USING to_timestamp(order_moment_accepted, 'MM/DD/YYYY HH:MI:SS AM'),
	ALTER COLUMN order_moment_ready TYPE timestamp USING to_timestamp(order_moment_ready, 'MM/DD/YYYY HH:MI:SS AM'),
	ALTER COLUMN order_moment_collected TYPE timestamp USING to_timestamp(order_moment_collected, 'MM/DD/YYYY HH:MI:SS AM'),
	ALTER COLUMN order_moment_in_expedition TYPE timestamp USING to_timestamp(order_moment_in_expedition, 'MM/DD/YYYY HH:MI:SS AM'),
	ALTER COLUMN order_moment_delivering TYPE timestamp USING to_timestamp(order_moment_delivering, 'MM/DD/YYYY HH:MI:SS AM'),
	ALTER COLUMN order_moment_delivered TYPE timestamp USING to_timestamp(order_moment_delivered, 'MM/DD/YYYY HH:MI:SS AM'),
	ALTER COLUMN order_moment_finished TYPE timestamp USING to_timestamp(order_moment_finished, 'MM/DD/YYYY HH:MI:SS AM');


-- CRIANDO VIEWS
-- View para pesquisa rápida e simples dos pedidos de pedidos 
CREATE VIEW "Pedido Simples" AS
	SELECT 
		order_id AS "ID do Pedido", 
		store_name AS "Nome da Loja", 
		channel_name AS "Nome do Canal", 
		order_status AS "Status do Pedido",
		order_amount AS "Preço do Pedido", 
		order_moment_created AS "Horário do pedido", 
		order_moment_delivered AS "Horário da entrega"
FROM 
	orders o
JOIN 
	stores s ON o.store_id = s.store_id
JOIN 
	channels c ON o.channel_id = c.channel_id;

-- View para acompanhar as entregas feitas pelo entregador
CREATE VIEW "Entregas por entregador" AS
SELECT 
	dl.delivery_id, d.driver_id, d.driver_modal, d.driver_type, dl.delivery_status, dl.delivery_distance_meters
FROM 
	deliveries dl
JOIN 
	drivers d ON dl.driver_id = d.driver_id;

-- ÍNDICES
CREATE INDEX idx_orders_store_id ON orders (store_id); 
CREATE INDEX idx_orders_channel_id ON orders (channel_id);
CREATE INDEX idx_deliveries_driver_id ON deliveries (driver_id);


-- TRIGGERS
CREATE TRIGGER atualiza_status_pedido
AFTER INSERT OR UPDATE ON payments
FOR EACH ROW
EXECUTE FUNCTION atualizar_status_pedido();