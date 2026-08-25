/*
===============================================================================
BI-003 — Fase 0: Descoberta Técnica do Zabbix
Rodada 1 — Metadados leves
SGBD: MySQL
Database esperado: zabbix
Ferramenta: Generic SQL Extractor 2.0
===============================================================================

OBJETIVO
- Levantar contexto técnico, versão, catálogo, índices, constraints,
  volumetria estimada, particionamento e tabelas candidatas.
- Não consultar histórico detalhado, eventos, problemas, trends ou history.
- Produzir evidências para planejar as próximas rodadas da Fase 0.

REGRAS DE SEGURANÇA
- Somente SELECT.
- Conta exclusivamente de leitura.
- Nenhuma consulta altera dados ou configuração.
- Nenhuma consulta usa SELECT * em tabelas transacionais.
- As quantidades de linhas são estimativas do INFORMATION_SCHEMA.
- Nomes de tabelas candidatas não comprovam sua semântica funcional.

CLASSIFICAÇÃO DAS EVIDÊNCIAS
- Contexto, catálogo e constraints: observados diretamente no banco.
- Tabelas candidatas por nome: hipóteses para investigação posterior.
===============================================================================
*/

-- @id: 1
-- @output: 01_contexto_versao_mysql.csv
-- @description: Identifica database selecionado, versão e contexto básico do servidor MySQL.
-- @heavy: false
-- @enabled: true
-- @timeout: 60
SELECT
    DATABASE() AS database_selecionado,
    VERSION() AS versao_mysql,
    @@version_comment AS distribuicao_mysql,
    @@hostname AS hostname_mysql,
    CURRENT_TIMESTAMP AS data_hora_servidor,
    @@lower_case_table_names AS lower_case_table_names,
    @@sql_mode AS sql_mode
ORDER BY database_selecionado;

-- @id: 2
-- @output: 02_charset_collation_timezone.csv
-- @description: Levanta charset, collation e timezones globais e da sessão.
-- @heavy: false
-- @enabled: true
-- @timeout: 60
SELECT
    @@character_set_database AS character_set_database,
    @@collation_database AS collation_database,
    @@character_set_server AS character_set_server,
    @@collation_server AS collation_server,
    @@character_set_connection AS character_set_connection,
    @@collation_connection AS collation_connection,
    @@global.time_zone AS global_time_zone,
    @@session.time_zone AS session_time_zone,
    @@system_time_zone AS system_time_zone
ORDER BY character_set_database;

-- @id: 3
-- @output: 03_versao_schema_zabbix.csv
-- @description: Obtém a versão obrigatória e opcional do schema Zabbix registrada em dbversion.
-- @heavy: false
-- @enabled: true
-- @timeout: 60
SELECT
    mandatory AS versao_schema_obrigatoria,
    optional AS versao_schema_opcional
FROM zabbix.dbversion
ORDER BY mandatory, optional
LIMIT 1;

-- @id: 4
-- @output: 04_catalogo_tabelas_views.csv
-- @description: Cataloga tabelas e views do database selecionado com engine, collation e estimativas físicas.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    t.TABLE_SCHEMA AS table_schema,
    t.TABLE_NAME AS table_name,
    t.TABLE_TYPE AS table_type,
    t.ENGINE AS engine,
    t.ROW_FORMAT AS row_format,
    t.TABLE_ROWS AS linhas_estimadas,
    t.AVG_ROW_LENGTH AS tamanho_medio_linha_bytes,
    t.DATA_LENGTH AS data_length_bytes,
    t.INDEX_LENGTH AS index_length_bytes,
    ROUND((COALESCE(t.DATA_LENGTH, 0) + COALESCE(t.INDEX_LENGTH, 0)) / 1024 / 1024, 2) AS tamanho_total_mb,
    t.AUTO_INCREMENT AS proximo_auto_increment,
    t.CREATE_TIME AS create_time,
    t.UPDATE_TIME AS update_time,
    t.TABLE_COLLATION AS table_collation,
    t.TABLE_COMMENT AS table_comment
FROM information_schema.TABLES t
WHERE t.TABLE_SCHEMA = DATABASE()
ORDER BY
    CASE t.TABLE_TYPE WHEN 'BASE TABLE' THEN 1 ELSE 2 END,
    t.TABLE_NAME;

-- @id: 5
-- @output: 05_catalogo_colunas.csv
-- @description: Cataloga colunas, tipos, nulabilidade, defaults e atributos das tabelas e views.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
SELECT
    c.TABLE_SCHEMA AS table_schema,
    c.TABLE_NAME AS table_name,
    c.ORDINAL_POSITION AS ordinal_position,
    c.COLUMN_NAME AS column_name,
    c.DATA_TYPE AS data_type,
    c.COLUMN_TYPE AS column_type,
    c.IS_NULLABLE AS is_nullable,
    c.COLUMN_DEFAULT AS column_default,
    c.CHARACTER_MAXIMUM_LENGTH AS character_maximum_length,
    c.NUMERIC_PRECISION AS numeric_precision,
    c.NUMERIC_SCALE AS numeric_scale,
    c.DATETIME_PRECISION AS datetime_precision,
    c.CHARACTER_SET_NAME AS character_set_name,
    c.COLLATION_NAME AS collation_name,
    c.COLUMN_KEY AS column_key,
    c.EXTRA AS extra,
    c.COLUMN_COMMENT AS column_comment
FROM information_schema.COLUMNS c
WHERE c.TABLE_SCHEMA = DATABASE()
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

-- @id: 6
-- @output: 06_catalogo_indices.csv
-- @description: Cataloga índices, colunas, unicidade, cardinalidade estimada e método de acesso.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
SELECT
    s.TABLE_SCHEMA AS table_schema,
    s.TABLE_NAME AS table_name,
    s.INDEX_NAME AS index_name,
    s.NON_UNIQUE AS non_unique,
    s.SEQ_IN_INDEX AS seq_in_index,
    s.COLUMN_NAME AS column_name,
    s.COLLATION AS index_collation,
    s.CARDINALITY AS cardinalidade_estimada,
    s.SUB_PART AS sub_part,
    s.NULLABLE AS nullable,
    s.INDEX_TYPE AS index_type,
    s.INDEX_COMMENT AS index_comment
FROM information_schema.STATISTICS s
WHERE s.TABLE_SCHEMA = DATABASE()
ORDER BY s.TABLE_NAME, s.INDEX_NAME, s.SEQ_IN_INDEX;

-- @id: 7
-- @output: 07_constraints_relacionamentos_declarados.csv
-- @description: Cataloga PKs, uniques e FKs declaradas, incluindo colunas referenciadas e regras de atualização/exclusão.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
SELECT
    tc.CONSTRAINT_SCHEMA AS constraint_schema,
    tc.TABLE_NAME AS table_name,
    tc.CONSTRAINT_NAME AS constraint_name,
    tc.CONSTRAINT_TYPE AS constraint_type,
    kcu.ORDINAL_POSITION AS ordinal_position,
    kcu.COLUMN_NAME AS column_name,
    kcu.REFERENCED_TABLE_SCHEMA AS referenced_table_schema,
    kcu.REFERENCED_TABLE_NAME AS referenced_table_name,
    kcu.REFERENCED_COLUMN_NAME AS referenced_column_name,
    rc.UPDATE_RULE AS update_rule,
    rc.DELETE_RULE AS delete_rule
FROM information_schema.TABLE_CONSTRAINTS tc
LEFT JOIN information_schema.KEY_COLUMN_USAGE kcu
    ON kcu.CONSTRAINT_SCHEMA = tc.CONSTRAINT_SCHEMA
   AND kcu.TABLE_NAME = tc.TABLE_NAME
   AND kcu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
LEFT JOIN information_schema.REFERENTIAL_CONSTRAINTS rc
    ON rc.CONSTRAINT_SCHEMA = tc.CONSTRAINT_SCHEMA
   AND rc.TABLE_NAME = tc.TABLE_NAME
   AND rc.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
WHERE tc.CONSTRAINT_SCHEMA = DATABASE()
ORDER BY
    tc.TABLE_NAME,
    tc.CONSTRAINT_TYPE,
    tc.CONSTRAINT_NAME,
    kcu.ORDINAL_POSITION;

-- @id: 8
-- @output: 08_volumetria_estimada_tabelas.csv
-- @description: Resume linhas estimadas e tamanho de dados/índices das tabelas base sem realizar COUNT(*) exato.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    t.TABLE_NAME AS table_name,
    t.ENGINE AS engine,
    t.TABLE_ROWS AS linhas_estimadas,
    ROUND(COALESCE(t.DATA_LENGTH, 0) / 1024 / 1024, 2) AS dados_mb,
    ROUND(COALESCE(t.INDEX_LENGTH, 0) / 1024 / 1024, 2) AS indices_mb,
    ROUND((COALESCE(t.DATA_LENGTH, 0) + COALESCE(t.INDEX_LENGTH, 0)) / 1024 / 1024, 2) AS total_mb,
    t.DATA_FREE AS data_free_bytes,
    t.UPDATE_TIME AS update_time
FROM information_schema.TABLES t
WHERE t.TABLE_SCHEMA = DATABASE()
  AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY t.TABLE_NAME;

-- @id: 9
-- @output: 09_ranking_tabelas_por_tamanho.csv
-- @description: Lista as maiores tabelas do database por tamanho estimado total.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    t.TABLE_NAME AS table_name,
    t.ENGINE AS engine,
    t.TABLE_ROWS AS linhas_estimadas,
    ROUND(COALESCE(t.DATA_LENGTH, 0) / 1024 / 1024, 2) AS dados_mb,
    ROUND(COALESCE(t.INDEX_LENGTH, 0) / 1024 / 1024, 2) AS indices_mb,
    ROUND((COALESCE(t.DATA_LENGTH, 0) + COALESCE(t.INDEX_LENGTH, 0)) / 1024 / 1024, 2) AS total_mb
FROM information_schema.TABLES t
WHERE t.TABLE_SCHEMA = DATABASE()
  AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY
    (COALESCE(t.DATA_LENGTH, 0) + COALESCE(t.INDEX_LENGTH, 0)) DESC,
    t.TABLE_NAME
LIMIT 100;

-- @id: 10
-- @output: 10_tabelas_sem_chave_primaria.csv
-- @description: Identifica tabelas base sem constraint PRIMARY KEY declarada.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    t.TABLE_NAME AS table_name,
    t.ENGINE AS engine,
    t.TABLE_ROWS AS linhas_estimadas,
    ROUND((COALESCE(t.DATA_LENGTH, 0) + COALESCE(t.INDEX_LENGTH, 0)) / 1024 / 1024, 2) AS total_mb
FROM information_schema.TABLES t
LEFT JOIN information_schema.TABLE_CONSTRAINTS tc
    ON tc.CONSTRAINT_SCHEMA = t.TABLE_SCHEMA
   AND tc.TABLE_NAME = t.TABLE_NAME
   AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
WHERE t.TABLE_SCHEMA = DATABASE()
  AND t.TABLE_TYPE = 'BASE TABLE'
  AND tc.CONSTRAINT_NAME IS NULL
ORDER BY total_mb DESC, t.TABLE_NAME;

-- @id: 11
-- @output: 11_particionamento_tabelas.csv
-- @description: Identifica tabelas particionadas, métodos, expressões e limites das partições.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
SELECT
    p.TABLE_SCHEMA AS table_schema,
    p.TABLE_NAME AS table_name,
    p.PARTITION_NAME AS partition_name,
    p.SUBPARTITION_NAME AS subpartition_name,
    p.PARTITION_ORDINAL_POSITION AS partition_ordinal_position,
    p.PARTITION_METHOD AS partition_method,
    p.PARTITION_EXPRESSION AS partition_expression,
    p.PARTITION_DESCRIPTION AS partition_description,
    p.TABLE_ROWS AS linhas_estimadas,
    ROUND((COALESCE(p.DATA_LENGTH, 0) + COALESCE(p.INDEX_LENGTH, 0)) / 1024 / 1024, 2) AS total_mb
FROM information_schema.PARTITIONS p
WHERE p.TABLE_SCHEMA = DATABASE()
  AND p.PARTITION_NAME IS NOT NULL
ORDER BY p.TABLE_NAME, p.PARTITION_ORDINAL_POSITION, p.SUBPARTITION_ORDINAL_POSITION;

-- @id: 12
-- @output: 12_tabelas_candidatas_zabbix.csv
-- @description: Identifica por nomenclatura tabelas candidatas para inventário, monitoramento, eventos, histórico e manutenção; resultado é hipótese.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    t.TABLE_NAME AS table_name,
    t.TABLE_TYPE AS table_type,
    t.ENGINE AS engine,
    t.TABLE_ROWS AS linhas_estimadas,
    ROUND((COALESCE(t.DATA_LENGTH, 0) + COALESCE(t.INDEX_LENGTH, 0)) / 1024 / 1024, 2) AS total_mb,
    CASE
        WHEN LOWER(t.TABLE_NAME) REGEXP '(^|_)host|hosts|interface|proxy|template|hstgrp|group' THEN 'inventario_e_classificacao'
        WHEN LOWER(t.TABLE_NAME) REGEXP 'item|trigger|function|expression|macro|graph' THEN 'itens_triggers_e_semantica'
        WHEN LOWER(t.TABLE_NAME) REGEXP 'event|problem|acknowledge|correlation|suppression' THEN 'eventos_e_recuperacao'
        WHEN LOWER(t.TABLE_NAME) REGEXP 'maintenance|maintenances' THEN 'manutencao'
        WHEN LOWER(t.TABLE_NAME) REGEXP 'history|trend' THEN 'historico_e_tendencias'
        WHEN LOWER(t.TABLE_NAME) REGEXP 'service|sla' THEN 'servicos_e_sla'
        WHEN LOWER(t.TABLE_NAME) REGEXP 'audit|task|alert|action' THEN 'operacao_e_auditoria'
        ELSE 'outra_candidata'
    END AS categoria_hipotetica
FROM information_schema.TABLES t
WHERE t.TABLE_SCHEMA = DATABASE()
  AND LOWER(t.TABLE_NAME) REGEXP
      'host|interface|proxy|template|hstgrp|group|item|trigger|function|expression|macro|graph|event|problem|acknowledge|correlation|suppression|maintenance|history|trend|service|sla|audit|task|alert|action'
ORDER BY categoria_hipotetica, t.TABLE_NAME;
