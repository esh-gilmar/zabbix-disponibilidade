/*
===============================================================================
BI-003 - Fase 0 - Rodada 5: Manutencao, Supressao e Reinicios
Rodadas 5A e 5B - Estrutura, seletividade e resets candidatos de uptime
SGBD: MySQL
Database esperado: zabbix
Ferramenta: Generic SQL Extractor 2.0
===============================================================================

REGRAS DE SEGURANCA
- Somente SELECT/CTE em metadados, configuracao e amostras deterministicas.
- Consultas 01-13 formam o Gate 5A e nao leem valores de history* ou trends*.
- Consultas 14-24 foram habilitadas apos a remessa 5A 20260814_205026 com 0 ERROR.
- O Gate 5A comprovou value_type 3, history_uint e PK (itemid, clock, ns).
- Nenhuma tabela historica pode ser lida sem itemid e janela temporal.
- A primeira amostra historica sera limitada a 8 itemids e 14 dias.
- Queda de uptime sera chamada somente RESET_UPTIME_CANDIDATO.
- Nenhuma proximidade temporal comprova causalidade ou reboot oficial.
- Nenhum hostname, IP, DNS, segredo, nome de usuario ou texto livre e retornado.
===============================================================================
*/

-- @id: 1
-- @output: 01_estrutura_manutencao_uptime.csv
-- @description: Cataloga colunas comprovadas das estruturas de manutencao, supressao, uptime e historico candidato sem ler dados historicos.
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
      'maintenances',
      'maintenances_hosts',
      'maintenances_groups',
      'maintenances_windows',
      'timeperiods',
      'maintenance_tag',
      'event_suppress',
      'events',
      'event_recovery',
      'items',
      'hosts',
      'hosts_groups',
      'hstgrp',
      'history_uint'
  )
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

-- @id: 2
-- @output: 02_indices_constraints_manutencao_uptime.csv
-- @description: Cataloga PKs, FKs, constraints e indices dos caminhos de manutencao, supressao e uptime.
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
      'maintenances', 'maintenances_hosts', 'maintenances_groups',
      'maintenances_windows', 'timeperiods', 'maintenance_tag',
      'event_suppress', 'events', 'event_recovery', 'items', 'hosts',
      'hosts_groups', 'hstgrp', 'history_uint'
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
      'maintenances', 'maintenances_hosts', 'maintenances_groups',
      'maintenances_windows', 'timeperiods', 'maintenance_tag',
      'event_suppress', 'events', 'event_recovery', 'items', 'hosts',
      'hosts_groups', 'hstgrp', 'history_uint'
  )
ORDER BY table_name, registro_tipo, objeto_nome, ordinal_position;

-- @id: 3
-- @output: 03_volumetria_manutencao_uptime.csv
-- @description: Mede por metadados linhas e tamanhos estimados sem COUNT global nas tabelas historicas.
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
      'maintenances', 'maintenances_hosts', 'maintenances_groups',
      'maintenances_windows', 'timeperiods', 'maintenance_tag',
      'event_suppress', 'events', 'event_recovery', 'items', 'hosts',
      'hosts_groups', 'hstgrp', 'history_uint'
  )
ORDER BY t.TABLE_NAME;

-- @id: 4
-- @output: 04_catalogo_manutencoes.csv
-- @description: Retorna cadastro tecnico de manutencoes sem nome ou descricao e com limite deterministico.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    m.maintenanceid,
    m.maintenance_type AS maintenance_type_bruto,
    m.active_since,
    m.active_till,
    m.tags_evaltype AS tags_evaltype_bruto
FROM maintenances m
ORDER BY m.maintenanceid
LIMIT 200;

-- @id: 5
-- @output: 05_manutencao_hosts.csv
-- @description: Mapeia vinculos tecnicos manutencao-host e codigos do host sem expor nomes ou enderecos.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    mh.maintenance_hostid,
    mh.maintenanceid,
    mh.hostid,
    h.status AS host_status_bruto,
    h.flags AS host_flags_bruto,
    h.maintenance_status AS host_maintenance_status_bruto,
    h.maintenance_type AS host_maintenance_type_bruto
FROM maintenances_hosts mh
JOIN hosts h ON h.hostid = mh.hostid
ORDER BY mh.maintenanceid, mh.hostid, mh.maintenance_hostid
LIMIT 500;

-- @id: 6
-- @output: 06_manutencao_grupos.csv
-- @description: Mapeia vinculos tecnicos manutencao-grupo e tipo bruto do grupo sem expor nomes.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    mg.maintenance_groupid,
    mg.maintenanceid,
    mg.groupid,
    g.type AS group_type_bruto,
    COUNT(DISTINCT hg.hostid) AS hosts_vinculados_ao_grupo
FROM maintenances_groups mg
JOIN hstgrp g ON g.groupid = mg.groupid
LEFT JOIN hosts_groups hg ON hg.groupid = mg.groupid
GROUP BY
    mg.maintenance_groupid,
    mg.maintenanceid,
    mg.groupid,
    g.type
ORDER BY mg.maintenanceid, mg.groupid, mg.maintenance_groupid
LIMIT 500;

-- @id: 7
-- @output: 07_periodos_janelas_manutencao.csv
-- @description: Cataloga periodos e recorrencia de manutencao sem expandir calendario futuro.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    mw.maintenance_timeperiodid,
    mw.maintenanceid,
    mw.timeperiodid,
    tp.timeperiod_type AS timeperiod_type_bruto,
    tp.every AS every_bruto,
    tp.month AS month_bruto,
    tp.dayofweek AS dayofweek_bruto,
    tp.day AS day_bruto,
    tp.start_time,
    tp.period,
    tp.start_date
FROM maintenances_windows mw
JOIN timeperiods tp ON tp.timeperiodid = mw.timeperiodid
ORDER BY mw.maintenanceid, mw.timeperiodid, mw.maintenance_timeperiodid
LIMIT 500;

-- @id: 8
-- @output: 08_tags_manutencao.csv
-- @description: Cataloga chaves, operadores e cobertura de tags de manutencao sem retornar valores textuais.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    mt.maintenanceid,
    mt.tag AS tag_chave,
    mt.operator AS operator_bruto,
    COUNT(*) AS tags_configuradas,
    COUNT(DISTINCT mt.value) AS valores_distintos
FROM maintenance_tag mt
GROUP BY mt.maintenanceid, mt.tag, mt.operator
ORDER BY mt.maintenanceid, mt.tag, mt.operator
LIMIT 500;

-- @id: 9
-- @output: 09_amostra_event_suppress.csv
-- @description: Retorna ate 200 supressoes recentes somente com chaves tecnicas e clock limite comprovados.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    es.event_suppressid,
    es.eventid,
    es.maintenanceid,
    es.suppress_until
FROM event_suppress es
ORDER BY es.event_suppressid DESC
LIMIT 200;

-- @id: 10
-- @output: 10_cobertura_manutencao_hosts_regulares.csv
-- @description: Mede cobertura atual de manutencao nos hosts regulares por estado, tipo e chave tecnica.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    h.maintenance_status AS maintenance_status_bruto,
    h.maintenance_type AS maintenance_type_bruto,
    CASE WHEN h.maintenanceid IS NULL THEN 0 ELSE 1 END AS possui_maintenanceid,
    h.maintenanceid,
    COUNT(*) AS hosts_regulares
FROM hosts h
WHERE h.flags = 0
  AND h.status IN (0, 1)
GROUP BY
    h.maintenance_status,
    h.maintenance_type,
    CASE WHEN h.maintenanceid IS NULL THEN 0 ELSE 1 END,
    h.maintenanceid
ORDER BY
    h.maintenance_status,
    h.maintenance_type,
    possui_maintenanceid,
    h.maintenanceid;

-- @id: 11
-- @output: 11_itens_uptime_value_type.csv
-- @description: Confirma itemid, hostid, familia, value_type, intervalo, origem e tabela historica candidata dos itens de uptime.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH classes AS (
    SELECT
        h.hostid,
        CASE
            WHEN MAX(hg.groupid = 41) = 1 THEN 'ACCESS_POINT'
            WHEN MAX(hg.groupid = 27) = 1 THEN 'SWITCH'
            WHEN MAX(hg.groupid = 25) = 1 THEN 'WINDOWS'
            WHEN MAX(hg.groupid = 26) = 1 THEN 'LINUX'
            WHEN MAX(hg.groupid = 22) = 1 THEN 'SERVIDOR_OUTRO'
            ELSE 'OUTRA_CLASSE'
        END AS classe_candidata
    FROM hosts h
    LEFT JOIN hosts_groups hg ON hg.hostid = h.hostid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
    GROUP BY h.hostid
)
SELECT
    i.itemid,
    i.hostid,
    c.classe_candidata,
    i.key_ AS item_key,
    CASE
        WHEN i.key_ = 'system.uptime' THEN 'UPTIME_SISTEMA_OPERACIONAL'
        WHEN i.key_ = 'system.hw.uptime[hrSystemUptime.0]' THEN 'UPTIME_SNMP_HARDWARE'
        WHEN i.key_ = 'system.net.uptime[sysUpTime.0]' THEN 'UPTIME_SNMP_REDE'
    END AS familia_uptime,
    i.status AS item_status_bruto,
    i.type AS item_type_bruto,
    i.value_type AS value_type_bruto,
    i.delay AS intervalo_configurado,
    i.templateid AS item_origem_id,
    origem.hostid AS template_hostid,
    origem.value_type AS origem_value_type_bruto,
    CASE
        WHEN i.value_type = 3 THEN 'history_uint'
        ELSE 'REVISAO_OBRIGATORIA'
    END AS tabela_historica_candidata
FROM items i
JOIN hosts h ON h.hostid = i.hostid
JOIN classes c ON c.hostid = i.hostid
LEFT JOIN items origem ON origem.itemid = i.templateid
WHERE h.flags = 0
  AND h.status IN (0, 1)
  AND i.key_ IN (
      'system.uptime',
      'system.hw.uptime[hrSystemUptime.0]',
      'system.net.uptime[sysUpTime.0]'
  )
ORDER BY c.classe_candidata, i.hostid, i.key_, i.itemid;

-- @id: 12
-- @output: 12_selecao_itemids_uptime.csv
-- @description: Seleciona deterministicamente ate 8 itemids, um por host antes da distribuicao por classe, sem ler historico.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
classes AS (
    SELECT
        h.hostid,
        CASE
            WHEN MAX(hg.groupid = 41) = 1 THEN 'ACCESS_POINT'
            WHEN MAX(hg.groupid = 27) = 1 THEN 'SWITCH'
            WHEN MAX(hg.groupid = 25) = 1 THEN 'WINDOWS'
            WHEN MAX(hg.groupid = 26) = 1 THEN 'LINUX'
            WHEN MAX(hg.groupid = 22) = 1 THEN 'SERVIDOR_OUTRO'
            ELSE 'OUTRA_CLASSE'
        END AS classe_candidata,
        CASE
            WHEN MAX(hg.groupid = 41) = 1 THEN 1
            WHEN MAX(hg.groupid = 27) = 1 THEN 2
            WHEN MAX(hg.groupid = 25) = 1 THEN 3
            WHEN MAX(hg.groupid = 26) = 1 THEN 4
            WHEN MAX(hg.groupid = 22) = 1 THEN 5
            ELSE 6
        END AS classe_ordem
    FROM hosts h
    LEFT JOIN hosts_groups hg ON hg.hostid = h.hostid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
    GROUP BY h.hostid
),
uptime_por_host AS (
    SELECT
        i.itemid,
        i.hostid,
        i.key_ AS item_key,
        i.value_type AS value_type_bruto,
        i.templateid AS item_origem_id,
        origem.hostid AS template_hostid,
        c.classe_candidata,
        c.classe_ordem,
        ROW_NUMBER() OVER (
            PARTITION BY i.hostid
            ORDER BY
                CASE
                    WHEN i.key_ = 'system.uptime' THEN 1
                    WHEN i.key_ = 'system.hw.uptime[hrSystemUptime.0]' THEN 2
                    WHEN i.key_ = 'system.net.uptime[sysUpTime.0]' THEN 3
                    ELSE 4
                END,
                i.itemid
        ) AS ordem_no_host
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN classes c ON c.hostid = i.hostid
    LEFT JOIN items origem ON origem.itemid = i.templateid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.status = 0
      AND i.key_ IN (
          'system.uptime',
          'system.hw.uptime[hrSystemUptime.0]',
          'system.net.uptime[sysUpTime.0]'
      )
),
representantes AS (
    SELECT
        u.*,
        ROW_NUMBER() OVER (
            PARTITION BY u.classe_candidata
            ORDER BY u.hostid, u.itemid
        ) AS ordem_na_classe
    FROM uptime_por_host u
    WHERE u.ordem_no_host = 1
)
SELECT
    ROW_NUMBER() OVER (
        ORDER BY r.ordem_na_classe, r.classe_ordem, r.itemid
    ) AS ordem_selecao,
    r.itemid,
    r.hostid,
    r.classe_candidata,
    r.item_key,
    r.value_type_bruto,
    r.item_origem_id,
    r.template_hostid,
    CASE
        WHEN r.value_type_bruto = 3 THEN 'history_uint'
        ELSE 'REVISAO_OBRIGATORIA'
    END AS tabela_historica_candidata
FROM representantes r
ORDER BY r.ordem_na_classe, r.classe_ordem, r.itemid
LIMIT 8;

-- @id: 13
-- @output: 13_indice_historico_uptime.csv
-- @description: Confirma metadados do indice de history_uint com itemid como primeiro componente e clock em seguida, sem ler valores.
-- @heavy: false
-- @enabled: true
-- @timeout: 90
SELECT
    s.TABLE_NAME AS table_name,
    s.INDEX_NAME AS index_name,
    s.NON_UNIQUE AS non_unique,
    s.SEQ_IN_INDEX AS seq_in_index,
    s.COLUMN_NAME AS column_name,
    s.CARDINALITY AS cardinalidade_estimada,
    s.INDEX_TYPE AS index_type
FROM information_schema.STATISTICS s
WHERE s.TABLE_SCHEMA = DATABASE()
  AND s.TABLE_NAME = 'history_uint'
ORDER BY s.INDEX_NAME, s.SEQ_IN_INDEX;

-- @id: 14
-- @output: 14_supressoes_manutencao_recorte.csv
-- @description: Relaciona supressoes e manutencoes somente aos 500 eventos candidatos mais recentes dos ultimos 14 dias.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
candidatas AS (
    SELECT DISTINCT t.triggerid
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
),
eventos_recorte AS (
    SELECT e.eventid
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.clock >= UNIX_TIMESTAMP() - 1209600
       AND e.clock <= UNIX_TIMESTAMP()
    ORDER BY e.eventid DESC
    LIMIT 500
)
SELECT
    er.eventid,
    es.event_suppressid,
    es.maintenanceid,
    es.suppress_until,
    CASE WHEN m.maintenanceid IS NULL THEN 0 ELSE 1 END AS manutencao_cadastrada_observada
FROM eventos_recorte er
JOIN event_suppress es ON es.eventid = er.eventid
LEFT JOIN maintenances m ON m.maintenanceid = es.maintenanceid
ORDER BY er.eventid DESC, es.event_suppressid
LIMIT 200;

-- @id: 15
-- @output: 15_eventos_suprimidos_nao_suprimidos.csv
-- @description: Compara tecnicamente eventos de problema candidatos suprimidos e nao suprimidos em amostra de 14 dias.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
candidatas AS (
    SELECT DISTINCT t.triggerid
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
),
eventos_recorte AS (
    SELECT e.eventid
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.value = 1
       AND e.clock >= UNIX_TIMESTAMP() - 1209600
       AND e.clock <= UNIX_TIMESTAMP()
    ORDER BY e.eventid DESC
    LIMIT 500
)
SELECT
    CASE WHEN es.eventid IS NULL THEN 0 ELSE 1 END AS suprimido_observado,
    COUNT(*) AS eventos_problema_candidatos,
    COUNT(DISTINCT es.maintenanceid) AS manutencoes_tecnicas_distintas
FROM eventos_recorte er
LEFT JOIN event_suppress es ON es.eventid = er.eventid
GROUP BY CASE WHEN es.eventid IS NULL THEN 0 ELSE 1 END
ORDER BY suprimido_observado;

-- @id: 16
-- @output: 16_amostra_uptime_seletiva.csv
-- @description: Amostra ate 200 valores recentes por item para os 8 itemids comprovados e somente nos ultimos 14 dias.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH historico_filtrado AS (
    SELECT
        hu.itemid,
        hu.clock,
        hu.ns,
        hu.value,
        ROW_NUMBER() OVER (
            PARTITION BY hu.itemid
            ORDER BY hu.clock DESC, hu.ns DESC
        ) AS ordem_recente_item
    FROM history_uint hu
    WHERE hu.itemid IN (56135, 57286, 50648, 42240, 58869, 56207, 50934, 54314)
      AND hu.clock >= UNIX_TIMESTAMP() - 1209600
      AND hu.clock <= UNIX_TIMESTAMP()
)
SELECT
    hf.itemid,
    hf.clock,
    hf.ns,
    hf.value
FROM historico_filtrado hf
WHERE hf.ordem_recente_item <= 200
ORDER BY hf.itemid, hf.clock, hf.ns;

-- @id: 17
-- @output: 17_quedas_uptime_item.csv
-- @description: Detecta e agrega quedas por item usando LAG somente depois do filtro de 8 itemids e 14 dias.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
historico_filtrado AS (
    SELECT hu.itemid, hu.clock, hu.ns, hu.value
    FROM history_uint hu
    WHERE hu.itemid IN (56135, 57286, 50648, 42240, 58869, 56207, 50934, 54314)
      AND hu.clock >= UNIX_TIMESTAMP() - 1209600
      AND hu.clock <= UNIX_TIMESTAMP()
),
sequenciado AS (
    SELECT
        hf.itemid,
        hf.clock,
        hf.ns,
        hf.value,
        LAG(hf.clock) OVER (PARTITION BY hf.itemid ORDER BY hf.clock, hf.ns) AS clock_anterior,
        LAG(hf.value) OVER (PARTITION BY hf.itemid ORDER BY hf.clock, hf.ns) AS valor_anterior
    FROM historico_filtrado hf
)
SELECT
    s.itemid,
    COUNT(*) AS resets_uptime_candidatos,
    MIN(s.clock) AS primeiro_reset_clock,
    MAX(s.clock) AS ultimo_reset_clock,
    MIN(s.valor_anterior - s.value) AS menor_reducao_observada,
    MAX(s.valor_anterior - s.value) AS maior_reducao_observada
FROM sequenciado s
WHERE s.clock_anterior IS NOT NULL
  AND s.clock > s.clock_anterior
  AND s.value < s.valor_anterior
GROUP BY s.itemid
ORDER BY s.itemid;

-- @id: 18
-- @output: 18_resets_uptime_candidatos.csv
-- @description: Retorna ate 200 RESET_UPTIME_CANDIDATO com clocks e valores, sem declarar reboot oficial.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
historico_filtrado AS (
    SELECT hu.itemid, hu.clock, hu.ns, hu.value
    FROM history_uint hu
    WHERE hu.itemid IN (56135, 57286, 50648, 42240, 58869, 56207, 50934, 54314)
      AND hu.clock >= UNIX_TIMESTAMP() - 1209600
      AND hu.clock <= UNIX_TIMESTAMP()
),
sequenciado AS (
    SELECT
        hf.itemid,
        hf.clock,
        hf.ns,
        hf.value,
        LAG(hf.clock) OVER (PARTITION BY hf.itemid ORDER BY hf.clock, hf.ns) AS clock_anterior,
        LAG(hf.value) OVER (PARTITION BY hf.itemid ORDER BY hf.clock, hf.ns) AS valor_anterior
    FROM historico_filtrado hf
)
SELECT
    s.itemid,
    i.hostid,
    CASE
        WHEN i.key_ = 'system.uptime' THEN 'UPTIME_SISTEMA_OPERACIONAL'
        WHEN i.key_ = 'system.hw.uptime[hrSystemUptime.0]' THEN 'UPTIME_SNMP_HARDWARE'
        WHEN i.key_ = 'system.net.uptime[sysUpTime.0]' THEN 'UPTIME_SNMP_REDE'
    END AS familia_uptime,
    s.clock_anterior,
    s.clock AS clock_atual,
    s.valor_anterior,
    s.value AS valor_atual,
    s.valor_anterior - s.value AS reducao_observada,
    'RESET_UPTIME_CANDIDATO' AS classificacao_tecnica
FROM sequenciado s
JOIN items i ON i.itemid = s.itemid
WHERE s.clock_anterior IS NOT NULL
  AND s.clock > s.clock_anterior
  AND s.value < s.valor_anterior
ORDER BY s.clock DESC, s.itemid, s.ns DESC
LIMIT 200;

-- @id: 19
-- @output: 19_resets_por_classe_familia.csv
-- @description: Agrega RESET_UPTIME_CANDIDATO por classe e familia sem promover o resultado a reboot.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
historico_filtrado AS (
    SELECT hu.itemid, hu.clock, hu.ns, hu.value
    FROM history_uint hu
    WHERE hu.itemid IN (56135, 57286, 50648, 42240, 58869, 56207, 50934, 54314)
      AND hu.clock >= UNIX_TIMESTAMP() - 1209600
      AND hu.clock <= UNIX_TIMESTAMP()
),
sequenciado AS (
    SELECT
        hf.itemid,
        hf.clock,
        hf.ns,
        hf.value,
        LAG(hf.clock) OVER (PARTITION BY hf.itemid ORDER BY hf.clock, hf.ns) AS clock_anterior,
        LAG(hf.value) OVER (PARTITION BY hf.itemid ORDER BY hf.clock, hf.ns) AS valor_anterior
    FROM historico_filtrado hf
),
resets AS (
    SELECT s.itemid, s.clock
    FROM sequenciado s
    WHERE s.clock_anterior IS NOT NULL
      AND s.clock > s.clock_anterior
      AND s.value < s.valor_anterior
),
classes AS (
    SELECT
        h.hostid,
        CASE
            WHEN MAX(hg.groupid = 41) = 1 THEN 'ACCESS_POINT'
            WHEN MAX(hg.groupid = 27) = 1 THEN 'SWITCH'
            WHEN MAX(hg.groupid = 25) = 1 THEN 'WINDOWS'
            WHEN MAX(hg.groupid = 26) = 1 THEN 'LINUX'
            WHEN MAX(hg.groupid = 22) = 1 THEN 'SERVIDOR_OUTRO'
            ELSE 'OUTRA_CLASSE'
        END AS classe_candidata
    FROM hosts h
    LEFT JOIN hosts_groups hg ON hg.hostid = h.hostid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
    GROUP BY h.hostid
)
SELECT
    c.classe_candidata,
    CASE
        WHEN i.key_ = 'system.uptime' THEN 'UPTIME_SISTEMA_OPERACIONAL'
        WHEN i.key_ = 'system.hw.uptime[hrSystemUptime.0]' THEN 'UPTIME_SNMP_HARDWARE'
        WHEN i.key_ = 'system.net.uptime[sysUpTime.0]' THEN 'UPTIME_SNMP_REDE'
    END AS familia_uptime,
    COUNT(*) AS resets_uptime_candidatos,
    COUNT(DISTINCT r.itemid) AS itemids_com_reset,
    COUNT(DISTINCT i.hostid) AS hosts_com_reset
FROM resets r
JOIN items i ON i.itemid = r.itemid
JOIN classes c ON c.hostid = i.hostid
GROUP BY c.classe_candidata, familia_uptime
ORDER BY c.classe_candidata, familia_uptime;

-- @id: 20
-- @output: 20_qualidade_serie_uptime.csv
-- @description: Mede cobertura, gaps, clocks duplicados, nulos e densidade das series filtradas de uptime.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
historico_filtrado AS (
    SELECT hu.itemid, hu.clock, hu.ns, hu.value
    FROM history_uint hu
    WHERE hu.itemid IN (56135, 57286, 50648, 42240, 58869, 56207, 50934, 54314)
      AND hu.clock >= UNIX_TIMESTAMP() - 1209600
      AND hu.clock <= UNIX_TIMESTAMP()
),
sequenciado AS (
    SELECT
        hf.itemid,
        hf.clock,
        hf.ns,
        hf.value,
        LAG(hf.clock) OVER (PARTITION BY hf.itemid ORDER BY hf.clock, hf.ns) AS clock_anterior
    FROM historico_filtrado hf
),
duplicados AS (
    SELECT d.itemid, COUNT(*) AS clocks_com_multiplos_registros
    FROM (
        SELECT hf.itemid, hf.clock
        FROM historico_filtrado hf
        GROUP BY hf.itemid, hf.clock
        HAVING COUNT(*) > 1
    ) d
    GROUP BY d.itemid
)
SELECT
    s.itemid,
    COUNT(*) AS amostras_14_dias,
    MIN(s.clock) AS primeiro_clock,
    MAX(s.clock) AS ultimo_clock,
    MAX(CASE WHEN s.clock_anterior IS NOT NULL THEN s.clock - s.clock_anterior END) AS maior_gap_segundos,
    ROUND(AVG(CASE WHEN s.clock_anterior IS NOT NULL THEN s.clock - s.clock_anterior END), 2) AS gap_medio_segundos,
    SUM(CASE WHEN s.clock_anterior IS NOT NULL AND s.clock - s.clock_anterior > 3600 THEN 1 ELSE 0 END) AS gaps_maiores_1_hora,
    COALESCE(d.clocks_com_multiplos_registros, 0) AS clocks_com_multiplos_registros,
    SUM(CASE WHEN s.value IS NULL THEN 1 ELSE 0 END) AS valores_nulos,
    ROUND(COUNT(*) / GREATEST((MAX(s.clock) - MIN(s.clock)) / 3600.0, 1), 2) AS amostras_por_hora_observada
FROM sequenciado s
LEFT JOIN duplicados d ON d.itemid = s.itemid
GROUP BY s.itemid, d.clocks_com_multiplos_registros
ORDER BY s.itemid;

-- @id: 21
-- @output: 21_proximidade_reset_evento.csv
-- @description: Mede o evento de problema candidato mais proximo de cada reset em ate mais ou menos 30 minutos, sem causalidade.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
historico_filtrado AS (
    SELECT hu.itemid, hu.clock, hu.ns, hu.value
    FROM history_uint hu
    WHERE hu.itemid IN (56135, 57286, 50648, 42240, 58869, 56207, 50934, 54314)
      AND hu.clock >= UNIX_TIMESTAMP() - 1209600
      AND hu.clock <= UNIX_TIMESTAMP()
),
sequenciado AS (
    SELECT
        hf.itemid,
        hf.clock,
        hf.ns,
        hf.value,
        LAG(hf.clock) OVER (PARTITION BY hf.itemid ORDER BY hf.clock, hf.ns) AS clock_anterior,
        LAG(hf.value) OVER (PARTITION BY hf.itemid ORDER BY hf.clock, hf.ns) AS valor_anterior
    FROM historico_filtrado hf
),
resets AS (
    SELECT s.itemid, i.hostid, s.clock, s.ns, i.key_
    FROM sequenciado s
    JOIN items i ON i.itemid = s.itemid
    WHERE s.clock_anterior IS NOT NULL
      AND s.clock > s.clock_anterior
      AND s.value < s.valor_anterior
    ORDER BY s.clock DESC, s.itemid, s.ns DESC
    LIMIT 200
),
candidatas AS (
    SELECT
        t.triggerid,
        MIN(i.hostid) AS hostid,
        MIN(CASE
            WHEN i.key_ = 'icmpping' THEN 'DISPONIBILIDADE_ICMP'
            WHEN i.key_ IN ('agent.ping', 'zabbix[host,agent,available]') THEN 'DISPONIBILIDADE_AGENTE'
            WHEN i.key_ = 'zabbix[host,snmp,available]' THEN 'DISPONIBILIDADE_SNMP'
        END) AS sinal_candidato
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
    GROUP BY t.triggerid
),
eventos_candidatos AS (
    SELECT e.eventid, e.clock, c.hostid, c.sinal_candidato
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.value = 1
       AND e.clock >= UNIX_TIMESTAMP() - 1211400
       AND e.clock <= UNIX_TIMESTAMP()
),
proximidade AS (
    SELECT
        r.itemid,
        r.hostid,
        r.clock AS reset_clock,
        r.ns AS reset_ns,
        r.key_ AS item_key,
        e.eventid,
        e.clock AS evento_clock,
        e.sinal_candidato,
        e.clock - r.clock AS distancia_assinada_segundos,
        ABS(e.clock - r.clock) AS distancia_absoluta_segundos,
        ROW_NUMBER() OVER (
            PARTITION BY r.itemid, r.clock, r.ns
            ORDER BY ABS(e.clock - r.clock), e.eventid
        ) AS ordem_proximidade
    FROM resets r
    LEFT JOIN eventos_candidatos e
        ON e.hostid = r.hostid
       AND e.clock BETWEEN r.clock - 1800 AND r.clock + 1800
)
SELECT
    p.itemid,
    p.hostid,
    p.reset_clock,
    p.item_key,
    p.eventid AS evento_problema_candidato,
    p.evento_clock,
    p.sinal_candidato,
    p.distancia_assinada_segundos,
    p.distancia_absoluta_segundos,
    'PROXIMIDADE_TECNICA_SEM_CAUSALIDADE' AS classificacao
FROM proximidade p
WHERE p.ordem_proximidade = 1
ORDER BY p.reset_clock DESC, p.itemid, p.reset_ns DESC;

-- @id: 22
-- @output: 22_reset_manutencao_supressao.csv
-- @description: Identifica coincidencia de reset com evento suprimido em ate mais ou menos 30 minutos e manutencao cadastrada.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
historico_filtrado AS (
    SELECT hu.itemid, hu.clock, hu.ns, hu.value
    FROM history_uint hu
    WHERE hu.itemid IN (56135, 57286, 50648, 42240, 58869, 56207, 50934, 54314)
      AND hu.clock >= UNIX_TIMESTAMP() - 1209600
      AND hu.clock <= UNIX_TIMESTAMP()
),
sequenciado AS (
    SELECT
        hf.itemid,
        hf.clock,
        hf.ns,
        hf.value,
        LAG(hf.clock) OVER (PARTITION BY hf.itemid ORDER BY hf.clock, hf.ns) AS clock_anterior,
        LAG(hf.value) OVER (PARTITION BY hf.itemid ORDER BY hf.clock, hf.ns) AS valor_anterior
    FROM historico_filtrado hf
),
resets AS (
    SELECT s.itemid, i.hostid, s.clock, s.ns
    FROM sequenciado s
    JOIN items i ON i.itemid = s.itemid
    WHERE s.clock_anterior IS NOT NULL
      AND s.clock > s.clock_anterior
      AND s.value < s.valor_anterior
    ORDER BY s.clock DESC, s.itemid, s.ns DESC
    LIMIT 200
),
candidatas AS (
    SELECT t.triggerid, MIN(i.hostid) AS hostid
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
    GROUP BY t.triggerid
),
eventos_candidatos AS (
    SELECT e.eventid, e.clock, c.hostid
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.value = 1
       AND e.clock >= UNIX_TIMESTAMP() - 1211400
       AND e.clock <= UNIX_TIMESTAMP()
)
SELECT
    r.itemid,
    r.hostid,
    r.clock AS reset_clock,
    e.eventid,
    e.clock AS evento_clock,
    es.event_suppressid,
    es.maintenanceid,
    es.suppress_until,
    CASE WHEN m.maintenanceid IS NULL THEN 0 ELSE 1 END AS manutencao_cadastrada_observada,
    ABS(e.clock - r.clock) AS distancia_absoluta_segundos
FROM resets r
JOIN eventos_candidatos e
    ON e.hostid = r.hostid
   AND e.clock BETWEEN r.clock - 1800 AND r.clock + 1800
JOIN event_suppress es ON es.eventid = e.eventid
LEFT JOIN maintenances m ON m.maintenanceid = es.maintenanceid
ORDER BY r.clock DESC, r.itemid, e.eventid
LIMIT 200;

-- @id: 23
-- @output: 23_divergencias_lacunas_rodada5.csv
-- @description: Amostra ate 50 lacunas objetivas de item, serie, proximidade e supressao somente por chaves tecnicas.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
selecionados AS (
    SELECT i.itemid, i.hostid, i.value_type
    FROM items i
    WHERE i.itemid IN (56135, 57286, 50648, 42240, 58869, 56207, 50934, 54314)
),
historico_filtrado AS (
    SELECT hu.itemid, hu.clock, hu.ns, hu.value
    FROM history_uint hu
    WHERE hu.itemid IN (56135, 57286, 50648, 42240, 58869, 56207, 50934, 54314)
      AND hu.clock >= UNIX_TIMESTAMP() - 1209600
      AND hu.clock <= UNIX_TIMESTAMP()
),
sequenciado AS (
    SELECT
        hf.itemid,
        hf.clock,
        hf.ns,
        hf.value,
        LAG(hf.clock) OVER (PARTITION BY hf.itemid ORDER BY hf.clock, hf.ns) AS clock_anterior,
        LAG(hf.value) OVER (PARTITION BY hf.itemid ORDER BY hf.clock, hf.ns) AS valor_anterior
    FROM historico_filtrado hf
),
resets AS (
    SELECT s.itemid, si.hostid, s.clock, s.ns
    FROM sequenciado s
    JOIN selecionados si ON si.itemid = s.itemid
    WHERE s.clock_anterior IS NOT NULL
      AND s.clock > s.clock_anterior
      AND s.value < s.valor_anterior
),
candidatas AS (
    SELECT t.triggerid, MIN(i.hostid) AS hostid
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
    GROUP BY t.triggerid
),
eventos_candidatos AS (
    SELECT e.eventid, e.clock, c.hostid
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.value = 1
       AND e.clock >= UNIX_TIMESTAMP() - 1211400
       AND e.clock <= UNIX_TIMESTAMP()
),
lacunas AS (
    SELECT
        'ITEM_VALUE_TYPE_DIVERGENTE' AS motivo,
        s.itemid,
        s.hostid,
        NULL AS eventid,
        NULL AS maintenanceid,
        NULL AS clock_referencia
    FROM selecionados s
    WHERE s.value_type <> 3
    UNION ALL
    SELECT
        'ITEM_SEM_AMOSTRA_14_DIAS',
        s.itemid,
        s.hostid,
        NULL,
        NULL,
        NULL
    FROM selecionados s
    WHERE NOT EXISTS (
        SELECT 1 FROM historico_filtrado hf WHERE hf.itemid = s.itemid
    )
    UNION ALL
    SELECT
        'RESET_SEM_EVENTO_CANDIDATO_30_MIN',
        r.itemid,
        r.hostid,
        NULL,
        NULL,
        r.clock
    FROM resets r
    WHERE NOT EXISTS (
        SELECT 1
        FROM eventos_candidatos e
        WHERE e.hostid = r.hostid
          AND e.clock BETWEEN r.clock - 1800 AND r.clock + 1800
    )
    UNION ALL
    SELECT
        'SUPRESSAO_SEM_MANUTENCAO_CADASTRADA',
        NULL,
        e.hostid,
        e.eventid,
        es.maintenanceid,
        e.clock
    FROM eventos_candidatos e
    JOIN event_suppress es ON es.eventid = e.eventid
    LEFT JOIN maintenances m ON m.maintenanceid = es.maintenanceid
    WHERE m.maintenanceid IS NULL
)
SELECT
    l.motivo,
    l.itemid,
    l.hostid,
    l.eventid,
    l.maintenanceid,
    l.clock_referencia
FROM lacunas l
ORDER BY l.motivo, l.hostid, l.itemid, l.eventid, l.clock_referencia
LIMIT 50;

-- @id: 24
-- @output: 24_matriz_conclusao_rodada5.csv
-- @description: Consolida fontes, evidencia e limitacoes da Rodada 5 sem calcular disponibilidade ou reboot oficial.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
historico_filtrado AS (
    SELECT hu.itemid, hu.clock, hu.ns, hu.value
    FROM history_uint hu
    WHERE hu.itemid IN (56135, 57286, 50648, 42240, 58869, 56207, 50934, 54314)
      AND hu.clock >= UNIX_TIMESTAMP() - 1209600
      AND hu.clock <= UNIX_TIMESTAMP()
),
sequenciado AS (
    SELECT
        hf.itemid,
        hf.clock,
        hf.ns,
        hf.value,
        LAG(hf.clock) OVER (PARTITION BY hf.itemid ORDER BY hf.clock, hf.ns) AS clock_anterior,
        LAG(hf.value) OVER (PARTITION BY hf.itemid ORDER BY hf.clock, hf.ns) AS valor_anterior
    FROM historico_filtrado hf
),
resets AS (
    SELECT s.itemid, s.clock
    FROM sequenciado s
    WHERE s.clock_anterior IS NOT NULL
      AND s.clock > s.clock_anterior
      AND s.value < s.valor_anterior
)
SELECT
    'MANUTENCOES_CONFIGURADAS' AS componente,
    COUNT(*) AS registros_observados,
    'OBSERVADA' AS classificacao_evidencia,
    'CONFIGURACAO_NAO_EQUIVALE_A_EVENTO_SUPRIMIDO' AS limitacao
FROM maintenances
UNION ALL
SELECT 'VINCULOS_MANUTENCAO_HOST', COUNT(*), 'OBSERVADA', 'CHAVES_TECNICAS'
FROM maintenances_hosts
UNION ALL
SELECT 'VINCULOS_MANUTENCAO_GRUPO', COUNT(*), 'OBSERVADA', 'CHAVES_TECNICAS'
FROM maintenances_groups
UNION ALL
SELECT 'PERIODOS_MANUTENCAO', COUNT(*), 'OBSERVADA', 'SEM_EXPANDIR_CALENDARIO'
FROM maintenances_windows
UNION ALL
SELECT 'TAGS_MANUTENCAO', COUNT(*), 'OBSERVADA', 'SEM_VALORES_TEXTUAIS_NA_5A'
FROM maintenance_tag
UNION ALL
SELECT 'EVENTOS_SUPRIMIDOS_REGISTRADOS', COUNT(*), 'OBSERVADA', 'AUSENCIA_ATUAL_NAO_PROVA_AUSENCIA_HISTORICA'
FROM event_suppress
UNION ALL
SELECT 'HOSTS_REGULARES_EM_MANUTENCAO', COUNT(*), 'OBSERVADA', 'ESTADO_ATUAL'
FROM hosts h
WHERE h.flags = 0
  AND h.status IN (0, 1)
  AND h.maintenance_status <> 0
UNION ALL
SELECT 'ITEMIDS_UPTIME_SELECIONADOS', COUNT(*), 'OBSERVADA', 'MAXIMO_8_ITEMIDS'
FROM items i
WHERE i.itemid IN (56135, 57286, 50648, 42240, 58869, 56207, 50934, 54314)
UNION ALL
SELECT 'AMOSTRAS_UPTIME_14_DIAS', COUNT(*), 'OBSERVADA', 'HISTORY_UINT_FILTRADA_POR_ITEMID_E_CLOCK'
FROM historico_filtrado
UNION ALL
SELECT 'RESET_UPTIME_CANDIDATO', COUNT(*), 'OBSERVADA', 'NAO_PROVA_REBOOT'
FROM resets
ORDER BY componente;
