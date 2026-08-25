/*
===============================================================================
BI-003 — Fase 0 — Rodada 3: Itens, Triggers e Semântica do Monitoramento
Rodadas 3A e 3B — Estrutura, vocabulário, semântica e cobertura
SGBD: MySQL
Database esperado: zabbix
Ferramenta: Generic SQL Extractor 2.0
===============================================================================

REGRAS DE SEGURANÇA
- Somente SELECT/CTE em metadados e estruturas de configuração.
- Nenhuma estrutura histórica, de eventos ou de manutenção é consultada.
- Itens e triggers são restritos aos hosts regulares comprovados na Rodada 2.
- IP, DNS, hostname, valores de item e valores de macro não são retornados.
- As Consultas 12–22 foram habilitadas somente após a remessa 3A limpa.
- Códigos e vocabulário são preservados sem promover candidatos a regra oficial.
===============================================================================
*/

-- @id: 1
-- @output: 01_estrutura_objetos_monitoramento.csv
-- @description: Cataloga colunas dos objetos de itens, triggers, dependências, tags e macros sem consultar valores sensíveis.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    c.TABLE_SCHEMA AS table_schema,
    c.TABLE_NAME AS table_name,
    c.ORDINAL_POSITION AS ordinal_position,
    c.COLUMN_NAME AS column_name,
    c.DATA_TYPE AS data_type,
    c.COLUMN_TYPE AS column_type,
    c.IS_NULLABLE AS is_nullable,
    c.COLUMN_DEFAULT AS column_default,
    c.COLUMN_KEY AS column_key,
    c.EXTRA AS extra
FROM information_schema.COLUMNS c
WHERE c.TABLE_SCHEMA = DATABASE()
  AND c.TABLE_NAME IN (
      'items',
      'functions',
      'triggers',
      'trigger_depends',
      'trigger_tag',
      'hostmacro',
      'globalmacro',
      'hosts',
      'hosts_templates',
      'hosts_groups',
      'hstgrp'
  )
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

-- @id: 2
-- @output: 02_indices_constraints_monitoramento.csv
-- @description: Cataloga PKs, FKs, uniques e índices dos objetos de configuração utilizados na Rodada 3.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    'CONSTRAINT' AS registro_tipo,
    tc.TABLE_SCHEMA AS table_schema,
    tc.TABLE_NAME AS table_name,
    tc.CONSTRAINT_NAME AS objeto_nome,
    tc.CONSTRAINT_TYPE AS objeto_tipo,
    kcu.ORDINAL_POSITION AS ordinal_position,
    kcu.COLUMN_NAME AS column_name,
    kcu.REFERENCED_TABLE_NAME AS referenced_table_name,
    kcu.REFERENCED_COLUMN_NAME AS referenced_column_name,
    rc.UPDATE_RULE AS update_rule,
    rc.DELETE_RULE AS delete_rule,
    NULL AS non_unique,
    NULL AS cardinalidade_estimada,
    NULL AS index_type
FROM information_schema.TABLE_CONSTRAINTS tc
LEFT JOIN information_schema.KEY_COLUMN_USAGE kcu
    ON kcu.CONSTRAINT_SCHEMA = tc.CONSTRAINT_SCHEMA
   AND kcu.TABLE_NAME = tc.TABLE_NAME
   AND kcu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
LEFT JOIN information_schema.REFERENTIAL_CONSTRAINTS rc
    ON rc.CONSTRAINT_SCHEMA = tc.CONSTRAINT_SCHEMA
   AND rc.TABLE_NAME = tc.TABLE_NAME
   AND rc.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
WHERE tc.TABLE_SCHEMA = DATABASE()
  AND tc.TABLE_NAME IN (
      'items', 'functions', 'triggers', 'trigger_depends', 'trigger_tag',
      'hostmacro', 'globalmacro', 'hosts', 'hosts_templates',
      'hosts_groups', 'hstgrp'
  )
UNION ALL
SELECT
    'INDEX' AS registro_tipo,
    s.TABLE_SCHEMA AS table_schema,
    s.TABLE_NAME AS table_name,
    s.INDEX_NAME AS objeto_nome,
    'INDEX' AS objeto_tipo,
    s.SEQ_IN_INDEX AS ordinal_position,
    s.COLUMN_NAME AS column_name,
    NULL AS referenced_table_name,
    NULL AS referenced_column_name,
    NULL AS update_rule,
    NULL AS delete_rule,
    s.NON_UNIQUE AS non_unique,
    s.CARDINALITY AS cardinalidade_estimada,
    s.INDEX_TYPE AS index_type
FROM information_schema.STATISTICS s
WHERE s.TABLE_SCHEMA = DATABASE()
  AND s.TABLE_NAME IN (
      'items', 'functions', 'triggers', 'trigger_depends', 'trigger_tag',
      'hostmacro', 'globalmacro', 'hosts', 'hosts_templates',
      'hosts_groups', 'hstgrp'
  )
ORDER BY table_name, registro_tipo, objeto_nome, ordinal_position;

-- @id: 3
-- @output: 03_volumetria_configuracao_monitoramento.csv
-- @description: Mede por metadados o volume estimado dos objetos de configuração sem executar contagens exatas amplas.
-- @heavy: false
-- @enabled: true
-- @timeout: 90
SELECT
    t.TABLE_SCHEMA AS table_schema,
    t.TABLE_NAME AS table_name,
    t.ENGINE AS engine,
    t.TABLE_ROWS AS linhas_estimadas,
    ROUND(COALESCE(t.DATA_LENGTH, 0) / 1024 / 1024, 2) AS dados_mb,
    ROUND(COALESCE(t.INDEX_LENGTH, 0) / 1024 / 1024, 2) AS indices_mb,
    ROUND((COALESCE(t.DATA_LENGTH, 0) + COALESCE(t.INDEX_LENGTH, 0)) / 1024 / 1024, 2) AS total_mb
FROM information_schema.TABLES t
WHERE t.TABLE_SCHEMA = DATABASE()
  AND t.TABLE_NAME IN (
      'items', 'functions', 'triggers', 'trigger_depends', 'trigger_tag',
      'hostmacro', 'globalmacro'
  )
ORDER BY t.TABLE_NAME;

-- @id: 4
-- @output: 04_itens_distribuicao_bruta.csv
-- @description: Distribui itens dos hosts regulares pelos códigos brutos de configuração e presença de vínculos técnicos.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    i.status AS item_status_bruto,
    i.type AS item_type_bruto,
    i.value_type AS value_type_bruto,
    i.flags AS item_flags_bruto,
    CASE WHEN i.interfaceid IS NULL THEN 0 ELSE 1 END AS possui_interfaceid,
    CASE WHEN i.templateid IS NULL THEN 0 ELSE 1 END AS possui_templateid,
    COUNT(*) AS itens,
    COUNT(DISTINCT i.hostid) AS hosts_regulares_distintos
FROM items i
JOIN hosts h
    ON h.hostid = i.hostid
WHERE h.flags = 0
  AND h.status IN (0, 1)
GROUP BY
    i.status,
    i.type,
    i.value_type,
    i.flags,
    CASE WHEN i.interfaceid IS NULL THEN 0 ELSE 1 END,
    CASE WHEN i.templateid IS NULL THEN 0 ELSE 1 END
ORDER BY
    i.status,
    i.type,
    i.value_type,
    i.flags,
    possui_interfaceid,
    possui_templateid;

-- @id: 5
-- @output: 05_itens_catalogo_chaves.csv
-- @description: Cataloga chaves e nomes de itens observados nos hosts regulares com frequência e códigos brutos.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
SELECT
    i.key_ AS item_key,
    i.name AS item_name,
    i.status AS item_status_bruto,
    i.type AS item_type_bruto,
    i.value_type AS value_type_bruto,
    i.flags AS item_flags_bruto,
    COUNT(*) AS itens,
    COUNT(DISTINCT i.hostid) AS hosts_regulares_distintos,
    COUNT(DISTINCT i.templateid) AS origens_template_distintas
FROM items i
JOIN hosts h
    ON h.hostid = i.hostid
WHERE h.flags = 0
  AND h.status IN (0, 1)
GROUP BY
    i.key_,
    i.name,
    i.status,
    i.type,
    i.value_type,
    i.flags
ORDER BY
    hosts_regulares_distintos DESC,
    itens DESC,
    i.key_,
    i.name,
    i.status,
    i.type,
    i.value_type,
    i.flags
LIMIT 5000;

-- @id: 6
-- @output: 06_itens_origem_templates.csv
-- @description: Mapeia itens herdados dos hosts regulares para o item e template de origem comprovados por chaves técnicas.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
SELECT
    t.hostid AS template_hostid,
    t.host AS template_nome_tecnico,
    t.name AS template_nome_visivel,
    origem.itemid AS item_origem_id,
    origem.key_ AS item_origem_key,
    origem.name AS item_origem_nome,
    origem.status AS item_origem_status_bruto,
    origem.type AS item_origem_type_bruto,
    origem.value_type AS item_origem_value_type_bruto,
    COUNT(*) AS itens_herdados,
    COUNT(DISTINCT destino.hostid) AS hosts_regulares_distintos
FROM items destino
JOIN hosts h
    ON h.hostid = destino.hostid
JOIN items origem
    ON origem.itemid = destino.templateid
JOIN hosts t
    ON t.hostid = origem.hostid
WHERE h.flags = 0
  AND h.status IN (0, 1)
GROUP BY
    t.hostid,
    t.host,
    t.name,
    origem.itemid,
    origem.key_,
    origem.name,
    origem.status,
    origem.type,
    origem.value_type
ORDER BY
    hosts_regulares_distintos DESC,
    itens_herdados DESC,
    t.name,
    origem.key_,
    origem.itemid
LIMIT 5000;

-- @id: 7
-- @output: 07_triggers_distribuicao_bruta.csv
-- @description: Distribui triggers relacionadas aos hosts regulares pelos códigos brutos de configuração sem consultar eventos.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH triggers_escopo AS (
    SELECT DISTINCT f.triggerid
    FROM items i
    JOIN hosts h
        ON h.hostid = i.hostid
    JOIN functions f
        ON f.itemid = i.itemid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
)
SELECT
    t.status AS trigger_status_bruto,
    t.priority AS priority_bruto,
    t.recovery_mode AS recovery_mode_bruto,
    t.correlation_mode AS correlation_mode_bruto,
    t.manual_close AS manual_close_bruto,
    t.flags AS trigger_flags_bruto,
    COUNT(*) AS triggers
FROM triggers_escopo te
JOIN triggers t
    ON t.triggerid = te.triggerid
GROUP BY
    t.status,
    t.priority,
    t.recovery_mode,
    t.correlation_mode,
    t.manual_close,
    t.flags
ORDER BY
    t.status,
    t.priority,
    t.recovery_mode,
    t.correlation_mode,
    t.manual_close,
    t.flags;

-- @id: 8
-- @output: 08_triggers_catalogo_descricoes.csv
-- @description: Cataloga descrições de triggers do escopo com frequência, prioridade e estado bruto, sem expressões completas.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
SELECT
    t.description AS trigger_description,
    t.priority AS priority_bruto,
    t.status AS trigger_status_bruto,
    t.flags AS trigger_flags_bruto,
    COUNT(DISTINCT t.triggerid) AS triggers,
    COUNT(DISTINCT i.hostid) AS hosts_regulares_distintos
FROM items i
JOIN hosts h
    ON h.hostid = i.hostid
JOIN functions f
    ON f.itemid = i.itemid
JOIN triggers t
    ON t.triggerid = f.triggerid
WHERE h.flags = 0
  AND h.status IN (0, 1)
GROUP BY
    t.description,
    t.priority,
    t.status,
    t.flags
ORDER BY
    hosts_regulares_distintos DESC,
    triggers DESC,
    t.priority DESC,
    t.description,
    t.status,
    t.flags
LIMIT 5000;

-- @id: 9
-- @output: 09_funcoes_relacao_item_trigger.csv
-- @description: Comprova e resume a relação estrutural item, função e trigger no escopo dos hosts regulares.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
SELECT
    t.triggerid,
    t.status AS trigger_status_bruto,
    t.priority AS priority_bruto,
    COUNT(DISTINCT f.functionid) AS funcoes,
    COUNT(DISTINCT f.itemid) AS itens_distintos,
    COUNT(DISTINCT i.hostid) AS hosts_regulares_distintos,
    COUNT(DISTINCT f.name) AS nomes_funcao_distintos
FROM items i
JOIN hosts h
    ON h.hostid = i.hostid
JOIN functions f
    ON f.itemid = i.itemid
JOIN triggers t
    ON t.triggerid = f.triggerid
WHERE h.flags = 0
  AND h.status IN (0, 1)
GROUP BY t.triggerid, t.status, t.priority
ORDER BY t.triggerid;

-- @id: 10
-- @output: 10_dependencias_triggers.csv
-- @description: Cataloga dependências entre triggers relacionadas ao escopo usando somente chaves técnicas e estados brutos.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH triggers_escopo AS (
    SELECT DISTINCT f.triggerid
    FROM items i
    JOIN hosts h
        ON h.hostid = i.hostid
    JOIN functions f
        ON f.itemid = i.itemid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
)
SELECT
    td.triggerdepid,
    td.triggerid_down,
    down_t.status AS trigger_down_status_bruto,
    down_t.priority AS trigger_down_priority_bruto,
    td.triggerid_up,
    up_t.status AS trigger_up_status_bruto,
    up_t.priority AS trigger_up_priority_bruto,
    CASE WHEN down_scope.triggerid IS NULL THEN 0 ELSE 1 END AS trigger_down_no_escopo,
    CASE WHEN up_scope.triggerid IS NULL THEN 0 ELSE 1 END AS trigger_up_no_escopo
FROM trigger_depends td
JOIN triggers down_t
    ON down_t.triggerid = td.triggerid_down
JOIN triggers up_t
    ON up_t.triggerid = td.triggerid_up
LEFT JOIN triggers_escopo down_scope
    ON down_scope.triggerid = td.triggerid_down
LEFT JOIN triggers_escopo up_scope
    ON up_scope.triggerid = td.triggerid_up
WHERE down_scope.triggerid IS NOT NULL
   OR up_scope.triggerid IS NOT NULL
ORDER BY td.triggerid_down, td.triggerid_up, td.triggerdepid;

-- @id: 11
-- @output: 11_macros_nomes_cobertura.csv
-- @description: Cataloga exclusivamente nomes de macros e cobertura por host regular, template vinculado e escopo global.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
SELECT
    'HOST_REGULAR' AS macro_escopo,
    hm.macro AS macro_nome,
    COUNT(*) AS macros_configuradas,
    COUNT(DISTINCT hm.hostid) AS objetos_origem_distintos,
    COUNT(DISTINCT hm.hostid) AS hosts_regulares_cobertos
FROM hostmacro hm
JOIN hosts h
    ON h.hostid = hm.hostid
WHERE h.flags = 0
  AND h.status IN (0, 1)
GROUP BY hm.macro
UNION ALL
SELECT
    'TEMPLATE_VINCULADO' AS macro_escopo,
    hm.macro AS macro_nome,
    COUNT(DISTINCT hm.hostmacroid) AS macros_configuradas,
    COUNT(DISTINCT hm.hostid) AS objetos_origem_distintos,
    COUNT(DISTINCT h.hostid) AS hosts_regulares_cobertos
FROM hostmacro hm
JOIN hosts t
    ON t.hostid = hm.hostid
JOIN hosts_templates ht
    ON ht.templateid = t.hostid
JOIN hosts h
    ON h.hostid = ht.hostid
WHERE t.flags = 0
  AND t.status = 3
  AND h.flags = 0
  AND h.status IN (0, 1)
GROUP BY hm.macro
UNION ALL
SELECT
    'GLOBAL' AS macro_escopo,
    gm.macro AS macro_nome,
    COUNT(*) AS macros_configuradas,
    COUNT(*) AS objetos_origem_distintos,
    135 AS hosts_regulares_cobertos
FROM globalmacro gm
GROUP BY gm.macro
ORDER BY macro_escopo, macro_nome;

-- @id: 12
-- @output: 12_trigger_tags_catalogo.csv
-- @description: Cataloga tags das triggers relacionadas aos hosts regulares após confirmação estrutural na Rodada 3A.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
SELECT
    tt.tag,
    tt.value,
    t.status AS trigger_status_bruto,
    t.priority AS priority_bruto,
    COUNT(DISTINCT t.triggerid) AS triggers,
    COUNT(DISTINCT i.hostid) AS hosts_regulares_distintos
FROM trigger_tag tt
JOIN triggers t ON t.triggerid = tt.triggerid
JOIN functions f ON f.triggerid = t.triggerid
JOIN items i ON i.itemid = f.itemid
JOIN hosts h ON h.hostid = i.hostid
WHERE h.flags = 0
  AND h.status IN (0, 1)
GROUP BY tt.tag, tt.value, t.status, t.priority
ORDER BY tt.tag, tt.value, t.status, t.priority
LIMIT 5000;

-- @id: 13
-- @output: 13_matriz_itens_disponibilidade.csv
-- @description: Matriz por host dos itens candidatos de ICMP, agente, SNMP e uptime comprovados na Rodada 3A.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
SELECT
    i.hostid,
    i.itemid,
    i.key_ AS item_key,
    i.name AS item_name,
    CASE
        WHEN i.key_ = 'icmpping' THEN 'DISPONIBILIDADE_ICMP'
        WHEN i.key_ = 'agent.ping' THEN 'DISPONIBILIDADE_AGENTE_CHECK'
        WHEN i.key_ = 'zabbix[host,agent,available]' THEN 'DISPONIBILIDADE_AGENTE_INTERNA'
        WHEN i.key_ = 'zabbix[host,snmp,available]' THEN 'DISPONIBILIDADE_SNMP_INTERNA'
        WHEN i.key_ IN (
            'system.uptime',
            'system.hw.uptime[hrSystemUptime.0]',
            'system.net.uptime[sysUpTime.0]'
        ) THEN 'UPTIME_CONFIGURADO'
    END AS papel_candidato,
    i.status AS item_status_bruto,
    i.type AS item_type_bruto,
    i.value_type AS value_type_bruto,
    i.flags AS item_flags_bruto,
    origem.itemid AS item_origem_id,
    template.hostid AS template_hostid,
    template.name AS template_nome,
    'CHAVE_OBSERVADA_NA_REMESSA_3A_20260814_191925' AS evidencia_classificacao
FROM items i
JOIN hosts h ON h.hostid = i.hostid
LEFT JOIN items origem ON origem.itemid = i.templateid
LEFT JOIN hosts template ON template.hostid = origem.hostid
WHERE h.flags = 0
  AND h.status IN (0, 1)
  AND i.key_ IN (
      'icmpping',
      'agent.ping',
      'zabbix[host,agent,available]',
      'zabbix[host,snmp,available]',
      'system.uptime',
      'system.hw.uptime[hrSystemUptime.0]',
      'system.net.uptime[sysUpTime.0]'
  )
ORDER BY i.hostid, papel_candidato, i.key_, i.itemid;

-- @id: 14
-- @output: 14_matriz_triggers_disponibilidade.csv
-- @description: Relaciona triggers ao subconjunto controlado de itens candidatos de disponibilidade observado na Rodada 3A.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
SELECT
    i.hostid,
    t.triggerid,
    t.description AS trigger_description,
    t.priority AS priority_bruto,
    t.status AS trigger_status_bruto,
    t.flags AS trigger_flags_bruto,
    t.recovery_mode AS recovery_mode_bruto,
    t.correlation_mode AS correlation_mode_bruto,
    t.manual_close AS manual_close_bruto,
    t.expression,
    t.recovery_expression,
    f.functionid,
    f.name AS function_name,
    i.itemid,
    i.key_ AS item_key,
    CASE
        WHEN i.key_ = 'icmpping' THEN 'DISPONIBILIDADE_ICMP'
        WHEN i.key_ IN ('agent.ping', 'zabbix[host,agent,available]') THEN 'DISPONIBILIDADE_AGENTE'
        WHEN i.key_ = 'zabbix[host,snmp,available]' THEN 'DISPONIBILIDADE_SNMP'
    END AS papel_candidato
FROM items i
JOIN hosts h ON h.hostid = i.hostid
JOIN functions f ON f.itemid = i.itemid
JOIN triggers t ON t.triggerid = f.triggerid
WHERE h.flags = 0
  AND h.status IN (0, 1)
  AND i.key_ IN (
      'icmpping',
      'agent.ping',
      'zabbix[host,agent,available]',
      'zabbix[host,snmp,available]'
  )
ORDER BY i.hostid, t.triggerid, f.functionid, i.itemid;

-- @id: 15
-- @output: 15_cobertura_icmp_por_classe.csv
-- @description: Mede cobertura do item e de trigger candidatos de ICMP nas classes comprovadas pela Rodada 2.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
classes AS (
    SELECT hg.hostid, 'ACCESS_POINT' AS classe FROM hosts_groups hg WHERE hg.groupid = 41
    UNION ALL SELECT hg.hostid, 'SWITCH' FROM hosts_groups hg WHERE hg.groupid = 27
    UNION ALL SELECT hg.hostid, 'SERVIDOR' FROM hosts_groups hg WHERE hg.groupid = 22
    UNION ALL SELECT hg.hostid, 'SERVIDOR_FISICO' FROM hosts_groups hg WHERE hg.groupid = 23
    UNION ALL SELECT hg.hostid, 'SERVIDOR_VIRTUAL' FROM hosts_groups hg WHERE hg.groupid = 24
    UNION ALL SELECT hg.hostid, 'WINDOWS' FROM hosts_groups hg WHERE hg.groupid = 25
    UNION ALL SELECT hg.hostid, 'LINUX' FROM hosts_groups hg WHERE hg.groupid = 26
),
icmp AS (
    SELECT
        i.hostid,
        COUNT(*) AS itens_icmp,
        MAX(i.status = 0) AS possui_item_icmp_habilitado,
        COUNT(DISTINCT f.triggerid) AS triggers_icmp
    FROM items i
    LEFT JOIN functions f ON f.itemid = i.itemid
    WHERE i.key_ = 'icmpping'
    GROUP BY i.hostid
)
SELECT
    c.classe,
    COUNT(DISTINCT h.hostid) AS hosts_regulares,
    COUNT(DISTINCT CASE WHEN icmp.itens_icmp > 0 THEN h.hostid END) AS hosts_com_item_icmp,
    COUNT(DISTINCT CASE WHEN icmp.possui_item_icmp_habilitado = 1 THEN h.hostid END) AS hosts_com_icmp_habilitado,
    COUNT(DISTINCT CASE WHEN icmp.triggers_icmp > 0 THEN h.hostid END) AS hosts_com_trigger_icmp,
    SUM(COALESCE(icmp.itens_icmp, 0)) AS itens_icmp,
    SUM(COALESCE(icmp.triggers_icmp, 0)) AS triggers_icmp
FROM classes c
JOIN hosts h ON h.hostid = c.hostid
LEFT JOIN icmp ON icmp.hostid = h.hostid
WHERE h.flags = 0
  AND h.status IN (0, 1)
GROUP BY c.classe
ORDER BY c.classe;

-- @id: 16
-- @output: 16_cobertura_agente_servidores.csv
-- @description: Mede em servidores a cobertura de itens e triggers candidatos do agente, separada da interface de agente.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
classes_servidor AS (
    SELECT hg.hostid, 'SERVIDOR' AS classe FROM hosts_groups hg WHERE hg.groupid = 22
    UNION ALL
    SELECT so.hostid, 'SERVIDOR_WINDOWS'
    FROM hosts_groups so
    JOIN hosts_groups servidor ON servidor.hostid = so.hostid AND servidor.groupid = 22
    WHERE so.groupid = 25
    UNION ALL
    SELECT so.hostid, 'SERVIDOR_LINUX'
    FROM hosts_groups so
    JOIN hosts_groups servidor ON servidor.hostid = so.hostid AND servidor.groupid = 22
    WHERE so.groupid = 26
),
agente AS (
    SELECT
        i.hostid,
        MAX(i.key_ = 'agent.ping') AS possui_agent_ping,
        MAX(i.key_ = 'zabbix[host,agent,available]') AS possui_disponibilidade_interna,
        MAX(i.status = 0) AS possui_item_agente_habilitado,
        COUNT(DISTINCT f.triggerid) AS triggers_agente
    FROM items i
    LEFT JOIN functions f ON f.itemid = i.itemid
    WHERE i.key_ IN ('agent.ping', 'zabbix[host,agent,available]')
    GROUP BY i.hostid
),
interfaces_agente AS (
    SELECT i.hostid, COUNT(*) AS interfaces
    FROM interface i
    WHERE i.type = 1
    GROUP BY i.hostid
)
SELECT
    c.classe,
    COUNT(DISTINCT h.hostid) AS servidores,
    COUNT(DISTINCT CASE WHEN agente.possui_agent_ping = 1 THEN h.hostid END) AS servidores_com_agent_ping,
    COUNT(DISTINCT CASE WHEN agente.possui_disponibilidade_interna = 1 THEN h.hostid END) AS servidores_com_disponibilidade_interna,
    COUNT(DISTINCT CASE WHEN agente.possui_item_agente_habilitado = 1 THEN h.hostid END) AS servidores_com_item_agente_habilitado,
    COUNT(DISTINCT CASE WHEN agente.triggers_agente > 0 THEN h.hostid END) AS servidores_com_trigger_agente,
    COUNT(DISTINCT CASE WHEN ia.interfaces > 0 THEN h.hostid END) AS servidores_com_interface_agente
FROM classes_servidor c
JOIN hosts h ON h.hostid = c.hostid
LEFT JOIN agente ON agente.hostid = h.hostid
LEFT JOIN interfaces_agente ia ON ia.hostid = h.hostid
WHERE h.flags = 0
  AND h.status IN (0, 1)
GROUP BY c.classe
ORDER BY c.classe;

-- @id: 17
-- @output: 17_cobertura_snmp_rede.csv
-- @description: Mede em APs e switches a cobertura do item e de trigger candidatos SNMP, sem parâmetros sensíveis.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
classes_rede AS (
    SELECT hg.hostid, 'ACCESS_POINT' AS classe FROM hosts_groups hg WHERE hg.groupid = 41
    UNION ALL SELECT hg.hostid, 'SWITCH' FROM hosts_groups hg WHERE hg.groupid = 27
),
snmp AS (
    SELECT
        i.hostid,
        COUNT(*) AS itens_snmp,
        MAX(i.status = 0) AS possui_item_snmp_habilitado,
        COUNT(DISTINCT f.triggerid) AS triggers_snmp
    FROM items i
    LEFT JOIN functions f ON f.itemid = i.itemid
    WHERE i.key_ = 'zabbix[host,snmp,available]'
    GROUP BY i.hostid
),
interfaces_snmp AS (
    SELECT i.hostid, COUNT(*) AS interfaces
    FROM interface i
    WHERE i.type = 2
    GROUP BY i.hostid
)
SELECT
    c.classe,
    COUNT(DISTINCT h.hostid) AS ativos_rede,
    COUNT(DISTINCT CASE WHEN snmp.itens_snmp > 0 THEN h.hostid END) AS ativos_com_item_snmp,
    COUNT(DISTINCT CASE WHEN snmp.possui_item_snmp_habilitado = 1 THEN h.hostid END) AS ativos_com_item_snmp_habilitado,
    COUNT(DISTINCT CASE WHEN snmp.triggers_snmp > 0 THEN h.hostid END) AS ativos_com_trigger_snmp,
    COUNT(DISTINCT CASE WHEN isnmp.interfaces > 0 THEN h.hostid END) AS ativos_com_interface_snmp
FROM classes_rede c
JOIN hosts h ON h.hostid = c.hostid
LEFT JOIN snmp ON snmp.hostid = h.hostid
LEFT JOIN interfaces_snmp isnmp ON isnmp.hostid = h.hostid
WHERE h.flags = 0
  AND h.status IN (0, 1)
GROUP BY c.classe
ORDER BY c.classe;

-- @id: 18
-- @output: 18_cobertura_uptime.csv
-- @description: Mede itens de uptime configurados por classe e template de origem sem consultar seus valores.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
classes AS (
    SELECT hg.hostid, 'ACCESS_POINT' AS classe FROM hosts_groups hg WHERE hg.groupid = 41
    UNION ALL SELECT hg.hostid, 'SWITCH' FROM hosts_groups hg WHERE hg.groupid = 27
    UNION ALL SELECT hg.hostid, 'SERVIDOR' FROM hosts_groups hg WHERE hg.groupid = 22
    UNION ALL SELECT hg.hostid, 'SERVIDOR_FISICO' FROM hosts_groups hg WHERE hg.groupid = 23
    UNION ALL SELECT hg.hostid, 'SERVIDOR_VIRTUAL' FROM hosts_groups hg WHERE hg.groupid = 24
    UNION ALL SELECT hg.hostid, 'WINDOWS' FROM hosts_groups hg WHERE hg.groupid = 25
    UNION ALL SELECT hg.hostid, 'LINUX' FROM hosts_groups hg WHERE hg.groupid = 26
)
SELECT
    c.classe,
    i.key_ AS item_key,
    i.status AS item_status_bruto,
    template.hostid AS template_hostid,
    template.name AS template_nome,
    COUNT(*) AS itens_uptime,
    COUNT(DISTINCT i.hostid) AS hosts_regulares_distintos
FROM classes c
JOIN hosts h ON h.hostid = c.hostid
JOIN items i ON i.hostid = h.hostid
LEFT JOIN items origem ON origem.itemid = i.templateid
LEFT JOIN hosts template ON template.hostid = origem.hostid
WHERE h.flags = 0
  AND h.status IN (0, 1)
  AND i.key_ IN (
      'system.uptime',
      'system.hw.uptime[hrSystemUptime.0]',
      'system.net.uptime[sysUpTime.0]'
  )
GROUP BY c.classe, i.key_, i.status, template.hostid, template.name
ORDER BY c.classe, i.key_, template.name, template.hostid, i.status;

-- @id: 19
-- @output: 19_catalogo_saude_inventario.csv
-- @description: Consolida famílias observadas de CPU, RAM, storage, rede, serviços Windows e sistema operacional.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH itens_classificados AS (
    SELECT
        i.itemid,
        i.hostid,
        i.key_,
        i.name,
        i.status,
        i.type,
        i.value_type,
        i.templateid,
        CASE
            WHEN i.key_ IN ('system.sw.os', 'system.uname', 'agent.hostname', 'system.hostname')
                THEN 'INVENTARIO_SISTEMA_OPERACIONAL'
            WHEN LOWER(i.key_) LIKE 'system.cpu.%'
              OR LOWER(i.name) LIKE '%cpu%'
                THEN 'SAUDE_CPU'
            WHEN LOWER(i.key_) LIKE 'vm.memory.%'
              OR LOWER(i.key_) LIKE 'system.swap.%'
              OR LOWER(i.name) LIKE '%memory%'
              OR LOWER(i.name) LIKE '%memória%'
                THEN 'SAUDE_RAM'
            WHEN LOWER(i.key_) LIKE 'vfs.fs.%'
              OR LOWER(i.key_) LIKE 'vfs.dev.%'
              OR LOWER(i.name) LIKE '%filesystem%'
              OR LOWER(i.name) LIKE '%disk%'
                THEN 'SAUDE_STORAGE'
            WHEN LOWER(i.key_) LIKE 'net.if.%'
              OR LOWER(i.name) LIKE '%interface%'
                THEN 'SAUDE_REDE'
            WHEN LOWER(i.key_) LIKE 'service.%'
                THEN 'SAUDE_SERVICOS_WINDOWS'
        END AS categoria,
        CASE
            WHEN i.key_ IN ('system.sw.os', 'system.uname') THEN 'SISTEMA_OPERACIONAL'
            WHEN i.key_ IN ('agent.hostname', 'system.hostname') THEN 'IDENTIFICACAO_SISTEMA'
            WHEN LOWER(i.key_) LIKE 'system.cpu.%' THEN 'SYSTEM_CPU'
            WHEN LOWER(i.key_) LIKE 'perf_counter_en%' AND LOWER(i.name) LIKE '%cpu%' THEN 'PERF_COUNTER_CPU'
            WHEN LOWER(i.key_) LIKE 'vm.memory.%' THEN 'VM_MEMORY'
            WHEN LOWER(i.key_) LIKE 'system.swap.%' THEN 'SYSTEM_SWAP'
            WHEN LOWER(i.key_) LIKE 'perf_counter_en%' THEN 'PERF_COUNTER_RECURSO'
            WHEN LOWER(i.key_) LIKE 'vfs.fs.%' THEN 'VFS_FILESYSTEM'
            WHEN LOWER(i.key_) LIKE 'vfs.dev.%' THEN 'VFS_DEVICE'
            WHEN LOWER(i.key_) LIKE 'net.if.%' THEN 'NET_INTERFACE'
            WHEN LOWER(i.key_) LIKE 'service.info%' THEN 'WINDOWS_SERVICE_INFO'
            WHEN LOWER(i.key_) LIKE 'service.discovery%' THEN 'WINDOWS_SERVICE_DISCOVERY'
            ELSE 'OUTRA_FAMILIA_OBSERVADA'
        END AS familia
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
)
SELECT
    categoria,
    familia,
    status AS item_status_bruto,
    type AS item_type_bruto,
    value_type AS value_type_bruto,
    COUNT(*) AS itens,
    COUNT(DISTINCT hostid) AS hosts_regulares_distintos,
    COUNT(DISTINCT key_) AS chaves_distintas,
    COUNT(DISTINCT name) AS nomes_distintos,
    COUNT(DISTINCT templateid) AS origens_template_distintas,
    MIN(key_) AS exemplo_chave_tecnica
FROM itens_classificados
WHERE categoria IS NOT NULL
GROUP BY categoria, familia, status, type, value_type
ORDER BY categoria, familia, status, type, value_type;

-- @id: 20
-- @output: 20_semantica_triggers_candidatas.csv
-- @description: Consolida severidade, funções, recuperação, dependências, tags e presença de macros das triggers candidatas.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
candidatas AS (
    SELECT
        t.triggerid,
        COUNT(DISTINCT i.hostid) AS hosts_regulares_distintos,
        COUNT(DISTINCT i.itemid) AS itens_distintos,
        COUNT(DISTINCT f.functionid) AS funcoes,
        GROUP_CONCAT(DISTINCT i.key_ ORDER BY i.key_ SEPARATOR ' | ') AS item_keys,
        GROUP_CONCAT(DISTINCT f.name ORDER BY f.name SEPARATOR ' | ') AS function_names
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN (
          'icmpping',
          'agent.ping',
          'zabbix[host,agent,available]',
          'zabbix[host,snmp,available]'
      )
    GROUP BY t.triggerid
),
dependencias AS (
    SELECT x.triggerid, COUNT(DISTINCT x.triggerdepid) AS dependencias
    FROM (
        SELECT td.triggerdepid, td.triggerid_down AS triggerid FROM trigger_depends td
        UNION ALL
        SELECT td.triggerdepid, td.triggerid_up AS triggerid FROM trigger_depends td
    ) x
    GROUP BY x.triggerid
),
tags AS (
    SELECT
        tt.triggerid,
        GROUP_CONCAT(DISTINCT CONCAT(tt.tag, '=', tt.value) ORDER BY tt.tag, tt.value SEPARATOR ' | ') AS trigger_tags
    FROM trigger_tag tt
    GROUP BY tt.triggerid
)
SELECT
    t.triggerid,
    t.description AS trigger_description,
    t.priority AS priority_bruto,
    t.status AS trigger_status_bruto,
    t.flags AS trigger_flags_bruto,
    t.recovery_mode AS recovery_mode_bruto,
    t.correlation_mode AS correlation_mode_bruto,
    t.manual_close AS manual_close_bruto,
    c.hosts_regulares_distintos,
    c.itens_distintos,
    c.funcoes,
    c.item_keys,
    c.function_names,
    COALESCE(d.dependencias, 0) AS dependencias,
    CASE WHEN t.expression LIKE '%{$%' OR t.recovery_expression LIKE '%{$%' THEN 1 ELSE 0 END AS possui_macro_na_expressao,
    tags.trigger_tags,
    t.expression,
    t.recovery_expression
FROM candidatas c
JOIN triggers t ON t.triggerid = c.triggerid
LEFT JOIN dependencias d ON d.triggerid = t.triggerid
LEFT JOIN tags ON tags.triggerid = t.triggerid
ORDER BY t.triggerid;

-- @id: 21
-- @output: 21_qualidade_semantica_monitoramento.csv
-- @description: Mede por classe ausências, sinais concorrentes, itens/triggers desabilitados e candidatos sem trigger.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
hosts_regulares AS (
    SELECT h.hostid
    FROM hosts h
    WHERE h.flags = 0
      AND h.status IN (0, 1)
),
item_trigger AS (
    SELECT
        i.itemid,
        i.hostid,
        i.key_,
        i.status,
        COUNT(DISTINCT f.triggerid) AS triggers,
        MAX(COALESCE(t.status, 0) = 1) AS possui_trigger_desabilitada
    FROM items i
    LEFT JOIN functions f ON f.itemid = i.itemid
    LEFT JOIN triggers t ON t.triggerid = f.triggerid
    WHERE i.key_ IN (
        'icmpping',
        'agent.ping',
        'zabbix[host,agent,available]',
        'zabbix[host,snmp,available]',
        'system.uptime',
        'system.hw.uptime[hrSystemUptime.0]',
        'system.net.uptime[sysUpTime.0]'
    )
    GROUP BY i.itemid, i.hostid, i.key_, i.status
),
sinais AS (
    SELECT
        hr.hostid,
        COALESCE(SUM(it.key_ = 'icmpping'), 0) AS itens_icmp,
        COALESCE(SUM(it.key_ IN ('agent.ping', 'zabbix[host,agent,available]')), 0) AS itens_agente,
        COALESCE(SUM(it.key_ = 'zabbix[host,snmp,available]'), 0) AS itens_snmp,
        COALESCE(SUM(it.key_ IN (
            'system.uptime',
            'system.hw.uptime[hrSystemUptime.0]',
            'system.net.uptime[sysUpTime.0]'
        )), 0) AS itens_uptime,
        COALESCE(SUM(it.status = 1), 0) AS itens_candidatos_desabilitados,
        COALESCE(SUM(it.possui_trigger_desabilitada = 1), 0) AS itens_com_trigger_desabilitada,
        COALESCE(SUM(it.triggers = 0), 0) AS itens_candidatos_sem_trigger
    FROM hosts_regulares hr
    LEFT JOIN item_trigger it ON it.hostid = hr.hostid
    GROUP BY hr.hostid
),
classes AS (
    SELECT hr.hostid, 'TODOS_HOSTS_REGULARES' AS classe FROM hosts_regulares hr
    UNION ALL SELECT hg.hostid, 'ACCESS_POINT' FROM hosts_groups hg WHERE hg.groupid = 41
    UNION ALL SELECT hg.hostid, 'SWITCH' FROM hosts_groups hg WHERE hg.groupid = 27
    UNION ALL SELECT hg.hostid, 'SERVIDOR' FROM hosts_groups hg WHERE hg.groupid = 22
    UNION ALL SELECT hg.hostid, 'WINDOWS' FROM hosts_groups hg WHERE hg.groupid = 25
    UNION ALL SELECT hg.hostid, 'LINUX' FROM hosts_groups hg WHERE hg.groupid = 26
)
SELECT
    c.classe,
    COUNT(DISTINCT c.hostid) AS hosts,
    SUM(s.itens_icmp = 0) AS hosts_sem_icmp_candidato,
    SUM(c.classe IN ('SERVIDOR', 'WINDOWS', 'LINUX') AND s.itens_agente = 0) AS servidores_sem_agente_candidato,
    SUM(c.classe IN ('ACCESS_POINT', 'SWITCH') AND s.itens_snmp = 0) AS ativos_rede_sem_snmp_candidato,
    SUM(s.itens_uptime = 0) AS hosts_sem_uptime_candidato,
    SUM(s.itens_icmp > 1 OR s.itens_agente > 2 OR s.itens_snmp > 1 OR s.itens_uptime > 2) AS hosts_com_multiplos_sinais_concorrentes,
    SUM(s.itens_candidatos_desabilitados > 0) AS hosts_com_item_candidato_desabilitado,
    SUM(s.itens_com_trigger_desabilitada > 0) AS hosts_com_trigger_candidata_desabilitada,
    SUM(s.itens_candidatos_sem_trigger > 0) AS hosts_com_candidato_sem_trigger,
    0 AS trigger_candidata_sem_item_esperado_na_definicao
FROM classes c
JOIN sinais s ON s.hostid = c.hostid
GROUP BY c.classe
ORDER BY c.classe;

-- @id: 22
-- @output: 22_amostra_lacunas_semantica.csv
-- @description: Amostra técnica de até 50 hosts com lacunas, itens desabilitados ou candidatos sem trigger.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
hosts_regulares AS (
    SELECT h.hostid, h.status
    FROM hosts h
    WHERE h.flags = 0
      AND h.status IN (0, 1)
),
classificacao AS (
    SELECT
        hr.hostid,
        MAX(hg.groupid = 41) AS access_point,
        MAX(hg.groupid = 27) AS switch,
        MAX(hg.groupid = 22) AS servidor,
        MAX(hg.groupid = 25) AS windows,
        MAX(hg.groupid = 26) AS linux
    FROM hosts_regulares hr
    LEFT JOIN hosts_groups hg ON hg.hostid = hr.hostid
    GROUP BY hr.hostid
),
item_trigger AS (
    SELECT
        i.itemid,
        i.hostid,
        i.key_,
        i.status,
        COUNT(DISTINCT f.triggerid) AS triggers
    FROM items i
    LEFT JOIN functions f ON f.itemid = i.itemid
    WHERE i.key_ IN (
        'icmpping',
        'agent.ping',
        'zabbix[host,agent,available]',
        'zabbix[host,snmp,available]',
        'system.uptime',
        'system.hw.uptime[hrSystemUptime.0]',
        'system.net.uptime[sysUpTime.0]'
    )
    GROUP BY i.itemid, i.hostid, i.key_, i.status
),
sinais AS (
    SELECT
        hr.hostid,
        hr.status,
        COALESCE(SUM(it.key_ = 'icmpping'), 0) AS itens_icmp,
        COALESCE(SUM(it.key_ IN ('agent.ping', 'zabbix[host,agent,available]')), 0) AS itens_agente,
        COALESCE(SUM(it.key_ = 'zabbix[host,snmp,available]'), 0) AS itens_snmp,
        COALESCE(SUM(it.key_ IN (
            'system.uptime',
            'system.hw.uptime[hrSystemUptime.0]',
            'system.net.uptime[sysUpTime.0]'
        )), 0) AS itens_uptime,
        COALESCE(SUM(it.status = 1), 0) AS itens_candidatos_desabilitados,
        COALESCE(SUM(it.triggers = 0), 0) AS itens_candidatos_sem_trigger
    FROM hosts_regulares hr
    LEFT JOIN item_trigger it ON it.hostid = hr.hostid
    GROUP BY hr.hostid, hr.status
)
SELECT
    s.hostid,
    s.status AS host_status_bruto,
    c.access_point,
    c.switch,
    c.servidor,
    c.windows,
    c.linux,
    (s.itens_icmp = 0) AS sem_icmp_candidato,
    (c.servidor = 1 AND s.itens_agente = 0) AS servidor_sem_agente_candidato,
    ((c.access_point = 1 OR c.switch = 1) AND s.itens_snmp = 0) AS ativo_rede_sem_snmp_candidato,
    (s.itens_uptime = 0) AS sem_uptime_candidato,
    (s.itens_icmp > 1 OR s.itens_agente > 2 OR s.itens_snmp > 1 OR s.itens_uptime > 2) AS multiplos_sinais_concorrentes,
    s.itens_candidatos_desabilitados,
    s.itens_candidatos_sem_trigger
FROM sinais s
JOIN classificacao c ON c.hostid = s.hostid
WHERE s.itens_icmp = 0
   OR (c.servidor = 1 AND s.itens_agente = 0)
   OR ((c.access_point = 1 OR c.switch = 1) AND s.itens_snmp = 0)
   OR s.itens_uptime = 0
   OR s.itens_icmp > 1
   OR s.itens_agente > 2
   OR s.itens_snmp > 1
   OR s.itens_uptime > 2
   OR s.itens_candidatos_desabilitados > 0
   OR s.itens_candidatos_sem_trigger > 0
ORDER BY
    servidor_sem_agente_candidato DESC,
    ativo_rede_sem_snmp_candidato DESC,
    sem_icmp_candidato DESC,
    sem_uptime_candidato DESC,
    s.hostid
LIMIT 50;
