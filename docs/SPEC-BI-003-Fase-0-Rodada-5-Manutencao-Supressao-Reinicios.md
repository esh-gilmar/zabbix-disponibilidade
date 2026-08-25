# SPEC BI-003 — Fase 0 — Rodada 5: Manutenção, Supressão Programada e Reinícios

**Projeto:** BI-003 — MVP de Disponibilidade da Infraestrutura de TI  
**Fase:** 0 — Descoberta Técnica do Zabbix  
**Rodada:** 5 — manutenção, supressão programada e reinícios  
**Ferramenta:** Generic SQL Extractor 2.0  
**SGBD:** MySQL  
**Database:** `zabbix`  
**Branch de trabalho:** `feat/bi-003-zabbix-fase0-round5-maintenance-reboots`  
**Pacote SQL previsto:** `sql/ZABBIX_BI_Fase0_Rodada5_Manutencao_Reinicios_MySQL.sql`  
**Status:** APROVADA PARA IMPLEMENTAÇÃO CONTROLADA  
**Versão:** 1.0  
**Data:** 14/08/2026

---

## 1. Autoridade e relação com a Fase 0

Este documento detalha operacionalmente a Rodada 5 da Fase 0 do BI-003.

A fonte global continua sendo:

```text
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
```

As evidências das Rodadas 1–4 estão consolidadas em:

```text
docs/ZABBIX_BI_Fase0_RELATORIO.md
```

Em qualquer divergência:

1. prevalecem as restrições de segurança de `AGENTS.md`;
2. prevalece a SPEC principal da Fase 0;
3. esta SPEC define apenas o escopo operacional da Rodada 5;
4. evidência observada no ambiente prevalece sobre suposições;
5. documentação oficial do Zabbix pode ser usada como evidência **Declarada**, mas não substitui a observação do schema real;
6. nenhum reset de uptime será promovido automaticamente a reinício oficial do ativo;
7. nenhuma supressão observada será automaticamente tratada como manutenção programada sem vínculo comprovado.

---

## 2. Baseline comprovado até a Rodada 4

### 2.1 Segurança e ambiente

- MySQL `8.0.46-0ubuntu0.22.04.3`;
- database `zabbix`;
- schema Zabbix `7020000 / 7020004`;
- transação `READ ONLY` aplicada pelo extrator;
- 31 testes locais aprovados nos gates recentes;
- nenhuma DML/DDL nas Rodadas 1–4;
- nenhum `--include-heavy`;
- núcleo Python preservado;
- conta operacional do Zabbix ainda usada temporariamente;
- usuário dedicado exclusivamente read-only permanece pendente.

### 2.2 Eventos e intervalos

A Rodada 4 demonstrou, em amostra controlada, o caminho candidato:

```text
events(value=1)
→ event_recovery
→ events(value=0)
→ trigger
→ function
→ item
→ host
```

Foram observados 249 problemas na amostra comum, 241 recuperados e 8 abertos. Foram observadas 2 sobreposições e 1 par simultâneo `SNMP + ICMP`.

A tabela `problem` não é suficiente isoladamente para reconstruir todo o histórico observado: 224 dos 249 eventos de problema já não possuíam linha correspondente em `problem`.

### 2.3 Uptime

A Rodada 3 identificou famílias candidatas de uptime. A Rodada 5 deverá confirmar, por item, `value_type`, origem e tabela histórica aplicável antes de consultar qualquer valor histórico.

---

## 3. Objetivo exclusivo da Rodada 5

Demonstrar com evidência reproduzível:

1. como manutenções são representadas no schema real;
2. como hosts e grupos são associados às manutenções;
3. como períodos e recorrências são representados;
4. como tags de manutenção, se existentes, limitam o escopo;
5. como `event_suppress` se relaciona a eventos e manutenções;
6. se existem manutenções configuradas ou executadas no ambiente observado;
7. se eventos candidatos de disponibilidade foram suprimidos por manutenção;
8. como itens de uptime estão armazenados e qual histórico devem usar;
9. se quedas de uptime podem ser detectadas por consulta seletiva;
10. quais quedas de uptime constituem apenas **candidatos de reinício/reset**;
11. se candidatos de reset possuem proximidade temporal com eventos de indisponibilidade da Rodada 4;
12. se a informação disponível permite distinguir manutenção, supressão e falha;
13. quais lacunas precisam ser reconciliadas com casos reais.

A Rodada 5 **não calcula disponibilidade oficial, MTTR, MTBF, MTTF ou SLA**.

---

## 4. Contexto declarado do Zabbix

Como referência externa declarada, a documentação oficial do Zabbix descreve manutenção como mecanismo para suprimir problemas durante períodos definidos e distingue manutenção com e sem coleta de dados. Também documenta `system.uptime` como uptime do sistema em segundos; redução do valor pode ser usada como indício técnico de reinício.

Essas informações devem ser tratadas como **Declaradas** e reconciliadas com o schema e os dados observados antes de qualquer regra funcional.

---

## 5. Escopo permitido

Após confirmação por metadados, podem ser consultadas:

- `information_schema.COLUMNS`;
- `information_schema.STATISTICS`;
- `information_schema.TABLE_CONSTRAINTS`;
- `information_schema.KEY_COLUMN_USAGE`;
- `information_schema.TABLES`;
- `maintenances`;
- `maintenances_hosts`;
- `maintenances_groups`;
- `maintenances_windows`;
- `timeperiods`;
- `maintenance_tag`;
- `event_suppress`;
- `events`;
- `event_recovery`;
- `triggers`;
- `functions`;
- `items`;
- `hosts`;
- `hosts_groups` e `hstgrp` apenas para preservar as classes candidatas;
- `history_uint` **somente após o gate histórico desta SPEC**;
- outra tabela histórica somente se o `value_type` observado exigir isso e após nova revisão obrigatória.

---

## 6. Fora de escopo

É proibido nesta rodada:

- varrer `history_uint` sem `itemid` e janela temporal;
- consultar globalmente `history`, `history_str`, `history_text`, `history_log`, `trends` ou `trends_uint`;
- usar `history_uint` para qualquer item que não seja uptime candidato comprovado;
- consultar o exercício inteiro por padrão;
- calcular disponibilidade oficial;
- calcular MTTR, MTBF ou MTTF;
- excluir manutenção de indicadores oficiais;
- declarar reboot oficial apenas por redução de uptime;
- considerar reset de SNMP como reboot do equipamento sem reconciliação;
- coletor produtivo/API;
- PostgreSQL;
- Power BI;
- MCP;
- alterar o Zabbix, MySQL, templates, itens ou triggers;
- alterar o núcleo Python sem defeito técnico comprovado e revisão.

---

## 7. Segurança obrigatória

Toda execução deve preservar:

- somente `SELECT` ou `WITH`;
- transação `READ ONLY`;
- parser/safety ativos;
- nenhuma DML/DDL/procedure/função de efeito colateral;
- nenhum lock ou `FOR UPDATE`;
- nenhum segredo ou valor de macro;
- nenhum `.env` exposto;
- nenhum output bruto versionado;
- limites determinísticos;
- timeout por consulta;
- filtros seletivos por chave e tempo nas tabelas históricas.

### 7.1 Gate histórico obrigatório

Antes de qualquer leitura de `history_uint`, a Rodada 5A deve comprovar:

1. itemids de uptime candidatos;
2. `value_type` de cada candidato;
3. índice com `itemid` como componente principal e `clock` utilizável;
4. janela e quantidade máxima de itemids;
5. ausência de necessidade de `--include-heavy`.

Sem essas cinco condições, a parte histórica permanece desabilitada.

### 7.2 Limite inicial de histórico

A primeira execução histórica deve utilizar:

- no máximo **8 itemids** representativos;
- no máximo **14 dias**;
- somente uptime;
- ordenação por `itemid, clock`;
- limite determinístico de saída;
- nenhuma consulta global de contagem.

Uma ampliação para até **30 dias** pode ocorrer dentro da mesma rodada somente se a primeira amostra tiver custo baixo, 0 `ERROR` e seletividade comprovada. Acima disso, parar para revisão.

---

## 8. Estratégia em dois gates

### Rodada 5A — manutenção, estrutura e preparo histórico

Objetivos:

- descobrir schema real das estruturas de manutenção;
- confirmar índices/FKs e volumetria;
- identificar configurações de manutenção;
- mapear hosts/grupos/períodos/tags;
- inspecionar `event_suppress` com amostras técnicas;
- confirmar itens de uptime, `value_type` e índices históricos;
- selecionar amostra representativa de até 8 itemids.

Nenhum valor de `history_uint` deve ser lido antes do fechamento desse gate.

### Rodada 5B — supressão e resets de uptime

Somente após a 5A aprovada:

- correlacionar supressão com manutenção, quando houver;
- consultar seletivamente uptime histórico;
- detectar reduções de valor usando ordenação temporal por item;
- classificar resultados como **RESET_UPTIME_CANDIDATO**;
- medir distância temporal entre reset e eventos candidatos de indisponibilidade;
- avaliar qualidade, lacunas e limitações.

---

## 9. Pacote SQL

Criar:

```text
sql/ZABBIX_BI_Fase0_Rodada5_Manutencao_Reinicios_MySQL.sql
```

Cada consulta deve conter:

```sql
-- @id: <inteiro único>
-- @output: <arquivo.csv>
-- @description: <objetivo>
-- @heavy: false|true
-- @enabled: true|false
-- @timeout: <segundos>
```

A saída deve preferir chaves técnicas (`hostid`, `itemid`, `eventid`, `maintenanceid`) e evitar hostname/IP/DNS quando não forem indispensáveis.

---

## 10. Consultas obrigatórias

### Gate 5A

**01 — Estrutura dos objetos de manutenção e uptime**  
Metadados de manutenção, supressão, itens e histórico candidato.

**02 — Índices, PKs, FKs e constraints**  
Confirmar caminhos seletivos, especialmente `eventid`, `maintenanceid`, `itemid` e `clock`.

**03 — Volumetria estimada**  
Usar `information_schema.TABLES`; não usar `COUNT(*)` global em histórico.

**04 — Catálogo de manutenções**  
Retornar somente atributos técnicos necessários: `maintenanceid`, períodos ativos, tipo e campos estruturais comprovados. Nome/descrição somente se comprovadamente necessários; por padrão, omitir.

**05 — Vínculos manutenção → host**  
Contagens e chaves técnicas.

**06 — Vínculos manutenção → grupo**  
Contagens e chaves técnicas.

**07 — Períodos/janelas de manutenção**  
Catalogar representação de períodos e recorrências sem ainda expandir calendário futuro.

**08 — Tags de manutenção**  
Catalogar chaves, operadores e cobertura; evitar valor textual se não for necessário.

**09 — Amostra técnica de `event_suppress`**  
Máximo 200 registros, somente chaves/códigos técnicos comprovados.

**10 — Cobertura de manutenção atual nos hosts regulares**  
Agregada por estado/tipo; sem nomes de hosts.

**11 — Itens de uptime candidatos e `value_type`**  
Reproduzir candidatos da Rodada 3 e confirmar `itemid`, `hostid`, chave, origem, `value_type`, intervalo configurado e classe candidata.

**12 — Seleção representativa para histórico**  
Escolher no máximo 8 itemids por critério determinístico e documentado, buscando diversidade entre Windows, Linux, AP e switch quando os dados permitirem.

**13 — Validação de índice histórico para uptime**  
Confirmar novamente índice de `history_uint` ou da tabela histórica efetivamente comprovada.

### Gate 5B — inicialmente desabilitado

**14 — Supressões ligadas a manutenção no recorte candidato**  
Relacionar `event_suppress` e manutenção somente para eventos candidatos seletivos.

**15 — Eventos candidatos suprimidos × não suprimidos**  
Contagem técnica controlada, sem promover a regra a disponibilidade oficial.

**16 — Amostra bruta seletiva de uptime**  
No máximo 8 itemids e 14 dias inicialmente; limite determinístico.

**17 — Quedas de uptime por item**  
Usar `LAG` somente sobre o subconjunto filtrado. Identificar `valor_atual < valor_anterior` sem chamar isso de reboot oficial.

**18 — Candidatos de reset de uptime**  
Retornar no máximo 200 candidatos com `itemid`, `hostid`, clocks, valores anterior/atual, diferença e família de uptime.

**19 — Resets candidatos por classe/família**  
Agregação técnica para Windows, Linux, AP e switch quando a classificação estiver disponível.

**20 — Qualidade da série de uptime**  
Detectar gaps grandes, relógios duplicados, valores nulos quando aplicável e densidade insuficiente para inferência.

**21 — Proximidade reset × evento de indisponibilidade**  
Para cada reset candidato, medir distância para evento candidato mais próximo dentro de janela máxima técnica de ±30 minutos. Não aprovar causalidade.

**22 — Reset durante manutenção/supressão**  
Quando houver dados, identificar coincidência temporal com manutenção/supressão comprovada.

**23 — Divergências e lacunas**  
Amostra máxima de 50 chaves técnicas com motivos objetivos.

**24 — Matriz de conclusão da Rodada 5**  
Consolidar fontes, evidência e limitações sem calcular indicadores oficiais.

---

## 11. Regras para detecção de reset

Um registro só pode ser chamado de **RESET_UPTIME_CANDIDATO** quando:

```text
mesmo itemid
clock atual > clock anterior
valor atual < valor anterior
```

Isso não prova reboot.

A interpretação deve considerar a família do item:

- `system.uptime`: candidato forte de reinício do sistema operacional, ainda sujeito a reconciliação;
- uptime SNMP: pode indicar reinício do equipamento **ou** do subsistema/agente de gerenciamento; não declarar reboot definitivo;
- outras famílias: manter como hipótese até documentação/reconciliação.

Nenhum limiar arbitrário de valor deve ser usado para excluir candidatos sem evidência.

---

## 12. Manutenção e supressão

A Rodada 5 deve diferenciar:

```text
configuração de manutenção
≠
manutenção efetivamente aplicável a host/trigger
≠
evento suprimido
≠
problema ausente
```

`event_suppress` vazio em uma amostra não comprova ausência histórica de manutenção.

Se as tabelas de manutenção estiverem vazias, registrar a lacuna sem inventar fonte alternativa.

---

## 13. Evidência e documentação

Toda conclusão deve ser classificada como:

- **Declarada**;
- **Observada**;
- **Inferida**;
- **Hipótese**.

Ao final, atualizar somente após evidência:

- `docs/ZABBIX_BI_Fase0_RELATORIO.md`;
- `docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md`.

Manter explícita a pendência do usuário dedicado read-only.

---

## 14. Regra de parada obrigatória

Parar imediatamente se ocorrer:

- qualquer `ERROR`;
- necessidade de `--include-heavy`;
- necessidade de consultar histórico sem `itemid`;
- necessidade de janela acima de 30 dias nesta rodada;
- índice histórico inadequado;
- volume inesperado;
- timeout;
- necessidade de outra tabela histórica não previamente aprovada;
- necessidade de DML/DDL/procedure/função de efeito colateral;
- necessidade de alterar o núcleo Python;
- divergência material entre SPEC e schema real;
- dúvida real de custo.

A remessa com `ERROR` não é evidência oficial.

---

## 15. Critérios de aceite

A Rodada 5 será concluída quando:

- [ ] 5A executar com 0 `ERROR`;
- [ ] schema de manutenção estiver documentado;
- [ ] vínculos host/grupo/período/tag estiverem documentados ou classificados como ausentes;
- [ ] relação `event_suppress`/manutenção estiver comprovada ou limitada por evidência;
- [ ] uptime candidato e `value_type` estiverem comprovados;
- [ ] gate histórico estiver satisfeito;
- [ ] 5B executar com 0 `ERROR` ou permanecer parcialmente desabilitada por evidência formal;
- [ ] resets de uptime forem detectados ou ausência for documentada;
- [ ] nenhum reset for declarado reboot oficial sem reconciliação;
- [ ] proximidade com eventos for avaliada sem causalidade presumida;
- [ ] nenhuma consulta histórica ampla ocorrer;
- [ ] nenhuma DML/DDL ocorrer;
- [ ] núcleo Python permanecer preservado;
- [ ] outputs brutos permanecerem fora do GitHub;
- [ ] relatório e checklist principal forem atualizados;
- [ ] usuário dedicado read-only permanecer pendente até comprovação externa.

---

## 16. Próximo passo após a Rodada 5

Se a Rodada 5 for aprovada, o próximo passo da Fase 0 será **reconciliação com casos reais**, conforme a SPEC principal: servidor Windows, servidor Linux, switch, Access Point, reinício, evento aberto e manutenção programada, comparando banco, interface Zabbix e API quando aplicável.

Não iniciar `writing-plans`, PostgreSQL, coletor produtivo ou Power BI dentro desta rodada.