-- Create a stream corresponding to old products
CREATE STREAM products_old (ID INT KEY, product VARCHAR)
    WITH (KAFKA_TOPIC='products_old',
          VALUE_FORMAT='AVRO',
          PARTITIONS=6);

-- Create a stream corresponding to old products
CREATE STREAM products (ID INT KEY, product VARCHAR)
    WITH (KAFKA_TOPIC='products',
          VALUE_FORMAT='AVRO',
          PARTITIONS=6);

-- Combine the two product streams together into one stream
CREATE STREAM joined_products WITH (KAFKA_TOPIC='joined_products',
          VALUE_FORMAT='AVRO',
          PARTITIONS=6) AS SELECT * FROM products_old;

INSERT INTO joined_products SELECT * FROM products;