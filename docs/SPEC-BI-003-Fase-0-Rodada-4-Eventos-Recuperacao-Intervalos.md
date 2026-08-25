# SPEC BI-003 — Fase 0 — Rodada 4: Eventos, Recuperação e Intervalos

**Projeto:** BI-003 — MVP de Disponibilidade da Infraestrutura de TI  
**Fase:** 0 — Descoberta Técnica do Zabbix  
**Rodada:** 4 — Eventos, problemas, recuperação e reconstrução controlada de intervalos  
**Ferramenta:** Generic SQL Extractor 2.0  
**SGBD:** MySQL  
**Database:** `zabbix`  
**Branch de trabalho:** `feat/bi-003-zabbix-fase0-round4-events-recovery`  
**Pacote SQL previsto:** `sql/ZABBIX_BI_Fase0_Rodada4_Eventos_Recuperacao_MySQL.sql`  
**Status:** APROVADA PARA IMPLEMENTAÇÃO CONTROLADA  
**Versão:** 1.0  
**Data:** 14/08/2026

---

## 1. Autoridade e relação com a Fase 0

Este documento detalha operacionalmente a Rodada 4 da Fase 0 do BI-003.

A fonte global da Fase 0 permanece:

```text
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
```

As evidências das Rodadas 1, 2 e 3 estão consolidadas em:

```text
docs/ZABBIX_BI_Fase0_RELATORIO.md
```

Em qualquer divergência:

1. prevalecem as restrições de segurança de `AGENTS.md`;
2. prevalecem as restrições da SPEC principal;
3. esta SPEC define o escopo operacional específico da Rodada 4;
4. evidência observada no ambiente prevalece sobre suposições de nomes;
5. nenhuma regra candidata de indisponibilidade se torna regra oficial do BI sem reconciliação posterior.

---

## 2. Baseline comprovado das Rodadas 1–3

### 2.1 Ambiente e segurança

Está comprovado por evidência:

- MySQL `8.0.46-0ubuntu0.22.04.3`;
- database `zabbix`;
- schema Zabbix `7020000 / 7020004`;
- Generic SQL Extractor 2.0 operando em transação `READ ONLY`;
- parser e bloqueio de colunas sensíveis ativos;
- 31 testes locais aprovados nas remessas oficiais recentes;
- nenhuma DML ou DDL nas Rodadas 1–3;
- nenhum `--include-heavy` nas Rodadas 1–3;
- nenhuma consulta ao conteúdo de `history*` ou `trends*` nas Rodadas 1–3;
- núcleo Python preservado.

Permanece pendente:

> criar e substituir a credencial atual por um usuário dedicado exclusivamente read-only no database `zabbix`.

A conta operacional atual continua autorizada temporariamente somente sob as proteções do Generic SQL Extractor.

### 2.2 Inventário

Rodada 2 comprovou:

- 135 hosts regulares;
- 123 habilitados e 12 desabilitados;
- 352 templates;
- 46 outros registros;
- 19 Access Points candidatos;
- 16 switches candidatos;
- 45 servidores candidatos;
- 6 servidores físicos candidatos;
- 38 servidores virtuais candidatos;
- 32 Windows candidatos;
- 12 Linux candidatos.

As classificações permanecem candidatas e são sustentadas principalmente por grupos, com corroboração parcial de templates.

### 2.3 Semântica de monitoramento

Rodada 3 comprovou estruturalmente o caminho:

```text
host → item → function → trigger
```

Foram observados candidatos relevantes, incluindo:

- `icmpping`;
- `agent.ping`;
- `zabbix[host,agent,available]`;
- sinais internos de disponibilidade SNMP;
- famílias de uptime;
- triggers candidatas de disponibilidade;
- dependências de trigger;
- tags de trigger, com predominância de `scope=availability` nos candidatos observados.

A Rodada 3 concluiu:

- hipótese `servidor = ICMP + agente`: **não suportada pela configuração atual**;
- hipótese `AP/switch = ICMP + SNMP`: **parcialmente suportada**;
- 43 dos 45 servidores não possuem ICMP candidato;
- 15 dos 16 switches não possuem candidato SNMP nem uptime;
- nenhuma dessas lacunas é, por si só, falha de monitoramento oficialmente aprovada.

Essas conclusões definem o universo candidato da Rodada 4, mas não autorizam cálculo oficial de disponibilidade.

---

## 3. Objetivo exclusivo da Rodada 4

Demonstrar, com amostras controladas e evidências reproduzíveis, como o Zabbix registra e relaciona problemas, recuperações e eventos ligados aos sinais candidatos de disponibilidade identificados na Rodada 3.

A Rodada 4 deve responder, sem calcular indicadores oficiais:

1. quais tabelas e campos participam do modelo de eventos e problemas;
2. como um evento de problema é identificado estruturalmente;
3. como um evento de recuperação é relacionado ao problema;
4. como distinguir problema aberto e recuperado;
5. como um evento é ligado à trigger;
6. como a trigger é ligada ao host;
7. se severidade histórica está armazenada no evento/problema e como se compara à trigger atual;
8. como reconhecimentos se relacionam aos eventos;
9. como correlações se relacionam aos eventos ou recuperações;
10. como supressões se relacionam aos eventos;
11. como dependências de trigger podem afetar interpretação ou duplicidade;
12. se início e fim de um intervalo podem ser reconstruídos com segurança;
13. se duração técnica pode ser calculada para uma amostra controlada;
14. como eventos ainda abertos aparecem;
15. se existem intervalos sobrepostos para sinais candidatos do mesmo host;
16. se existem múltiplos sinais candidatos no mesmo intervalo;
17. quais lacunas impedem transformar os eventos observados em indisponibilidade oficial;
18. quais hipóteses precisam ser reconciliadas na etapa de casos reais.

---

## 4. Princípio central da Rodada 4

Esta rodada **não é uma extração histórica do Zabbix**.

É uma prova controlada do modelo de reconstrução temporal.

A sequência obrigatória é:

```text
metadados
→ índices e volumetria
→ códigos brutos recentes
→ universo candidato de triggers
→ amostra temporal seletiva
→ problema/recuperação
→ host/trigger
→ atributos auxiliares
→ qualidade e sobreposição
```

Nenhuma consulta temporal deve ser habilitada antes de confirmar estrutura, índices e seletividade.

---

## 5. Escopo permitido

A Rodada 4 pode consultar, quando existentes e depois de confirmados por metadados:

- `information_schema.COLUMNS`;
- `information_schema.STATISTICS`;
- `information_schema.TABLE_CONSTRAINTS`;
- `information_schema.KEY_COLUMN_USAGE`;
- `information_schema.REFERENTIAL_CONSTRAINTS`;
- `information_schema.TABLES`;
- `events`;
- `problem`;
- `event_recovery`;
- `acknowledges`;
- `event_suppress`;
- estruturas de tags/correlação/sintomas relacionadas a eventos, somente se identificadas pelos metadados;
- `triggers`;
- `functions`;
- `items`;
- `hosts`;
- `trigger_depends`;
- `trigger_tag`;
- grupos necessários exclusivamente para preservar o recorte de classes da Rodada 2;
- tabelas cadastrais pequenas diretamente demonstradas pelas FKs/metadados como necessárias à reconstrução.

Outras estruturas só podem ser adicionadas se forem necessárias para responder a um objetivo explícito desta SPEC e se o custo for demonstravelmente baixo ou controlado.

---

## 6. Fora de escopo

Não executar nesta rodada:

- leitura de `history`;
- leitura de `history_uint`;
- leitura de `history_str`;
- leitura de `history_text`;
- leitura de `history_log`;
- leitura de `trends`;
- leitura de `trends_uint`;
- extração global de `events`;
- extração global de `problem`;
- extração global de reconhecimentos;
- cálculo oficial de disponibilidade;
- MTTR;
- MTBF;
- MTTF;
- SLA;
- consolidação mensal oficial;
- exclusão de manutenção programada;
- classificação definitiva de reinícios;
- análise de uptime histórico;
- construção do PostgreSQL;
- coletor produtivo via API;
- Power BI;
- MCP;
- mudanças no Zabbix;
- mudanças no MySQL;
- alterações de templates, itens ou triggers.

Manutenção e reinício continuam reservados para a Rodada 5.

---

## 7. Segurança obrigatória

Toda execução deverá manter:

- somente `SELECT` ou `WITH`;
- nenhuma DML;
- nenhuma DDL;
- nenhuma procedure;
- nenhuma função de efeito colateral conhecido;
- nenhuma criação de tabela temporária no servidor;
- nenhum lock explícito;
- nenhum `FOR UPDATE`;
- nenhuma alteração de configuração;
- nenhuma escrita no banco;
- transação `READ ONLY`;
- parser/safety ativos;
- timeout por consulta;
- limites determinísticos em amostras;
- nenhum segredo, token ou valor de macro;
- nenhum `.env` exibido ou versionado;
- nenhum CSV, log, ZIP ou output bruto enviado ao GitHub.

### 7.1 Regra adicional de custo

Toda consulta que toque tabelas de eventos deverá satisfazer pelo menos uma destas condições:

- ser exclusivamente de metadados;
- usar uma janela pequena baseada em chave/indexação comprovada;
- usar conjunto limitado de `triggerid`/`objectid` candidatos;
- usar período temporal limitado ao exercício vigente **e** índice apropriado comprovado;
- usar uma amostra determinística com `LIMIT` e ordenação por chave indexada.

Se a seletividade não puder ser demonstrada, a consulta não deve ser executada.

---

## 8. Núcleo Python

Não alterar o núcleo Python do Generic SQL Extractor para implementar regras do Zabbix.

Se houver defeito técnico comprovado de parser, safety, compatibilidade MySQL, timeout, exportação ou manifesto:

1. parar;
2. registrar o defeito;
3. solicitar revisão antes de modificar o núcleo.

---

## 9. Governança Git

Antes de qualquer implementação local:

```powershell
git fetch --all --prune
git status --short --branch
git rev-parse HEAD
git rev-parse main
git rev-parse origin/main
```

Utilizar exclusivamente:

```text
feat/bi-003-zabbix-fase0-round4-events-recovery
```

A branch foi preparada a partir do fechamento da Rodada 3.

Não alterar `main` diretamente e não fazer merge automático.

---

## 10. Estratégia em dois gates

### 10.1 Rodada 4A — Estrutura, custo e códigos brutos

Objetivo:

- descobrir o schema real das estruturas de eventos;
- comprovar índices e FKs;
- medir volumetria estimada;
- inspecionar apenas janelas recentes e limitadas;
- descobrir os códigos brutos usados no ambiente;
- confirmar se existe um caminho seletivo seguro para a Rodada 4B.

Nenhuma reconstrução funcional completa deve ser executada antes desse gate.

### 10.2 Rodada 4B — Reconstrução controlada

Somente após a Rodada 4A demonstrar seletividade adequada:

- selecionar uma amostra limitada de eventos ligados às triggers candidatas da Rodada 3;
- reconstruir problema e recuperação;
- mapear host/trigger;
- avaliar aberto/fechado;
- medir duração apenas da amostra;
- avaliar reconhecimentos, correlação e supressão dentro do mesmo conjunto de eventids;
- detectar sobreposição e múltiplos sinais somente dentro da amostra controlada;
- produzir matriz de qualidade.

A Rodada 4B não transforma a amostra em indicador oficial.

---

## 11. Janela temporal

Quando houver consulta temporal na Rodada 4B:

- usar no máximo o exercício vigente;
- preferir subconjunto ainda menor quando suficiente;
- registrar explicitamente o limite temporal utilizado;
- tratar o timezone como **timezone técnico da sessão**, pois o timezone funcional/oficial ainda permanece pendente;
- não interpretar fronteiras de dia/mês como regra funcional definitiva enquanto o timezone oficial não for confirmado.

Para amostras recentes, preferir ordenação por chave indexada e `LIMIT` em vez de varredura completa do exercício.

---

## 12. Universo candidato de eventos

A Rodada 4 não deve começar por todos os eventos do banco.

O universo preferencial é:

```text
triggers candidatas da Rodada 3
→ object/event semantics comprovada na Rodada 4A
→ eventos associados
```

A seleção das triggers candidatas deve ser reproduzível a partir da configuração atual e dos critérios documentados na Rodada 3, sem depender de CSV local como fonte de verdade.

Se a semântica `events.objectid → triggerid` não puder ser comprovada para os códigos observados, a Rodada 4B deve permanecer desabilitada.

---

## 13. Pacote SQL

Criar:

```text
sql/ZABBIX_BI_Fase0_Rodada4_Eventos_Recuperacao_MySQL.sql
```

Cada consulta deve possuir:

```sql
-- @id: <inteiro único>
-- @output: <arquivo.csv>
-- @description: <objetivo claro>
-- @heavy: false|true
-- @enabled: true|false
-- @timeout: <segundos>
```

Requisitos:

- uma instrução por bloco;
- somente `SELECT` ou `WITH`;
- IDs e outputs únicos;
- ordenação determinística;
- amostras limitadas;
- sem identificadores humanos quando não necessários;
- preferir `hostid`, `triggerid`, `eventid`;
- não retornar mensagens/comentários de reconhecimento se não forem necessários;
- não retornar nomes de usuários em reconhecimentos;
- não retornar conteúdo textual potencialmente sensível quando contagens/códigos forem suficientes.

---

## 14. Consultas mínimas obrigatórias

### Consulta 01 — Estrutura dos objetos de eventos

**Output:** `01_estrutura_objetos_eventos.csv`  
**Gate:** 4A  
**Risco:** Baixo

Levantar colunas das estruturas candidatas de eventos, problemas, recuperação, reconhecimento, supressão e correlação.

Objetivo:

- confirmar nomes e tipos reais;
- descobrir campos de source/object/value/clock/severity/eventid/recovery;
- impedir joins baseados em memória ou suposição.

### Consulta 02 — Índices, PKs, FKs e constraints

**Output:** `02_indices_constraints_eventos.csv`  
**Gate:** 4A  
**Risco:** Baixo

Levantar índices e relacionamentos apenas das estruturas necessárias à Rodada 4.

Deve permitir avaliar especialmente acesso por:

- `eventid`;
- `objectid`;
- `source`;
- `object`;
- `clock`;
- eventids de recuperação;
- eventids em acknowledges/suppressions.

### Consulta 03 — Volumetria estimada das estruturas

**Output:** `03_volumetria_eventos.csv`  
**Gate:** 4A  
**Risco:** Baixo

Usar `information_schema.TABLES` para linhas e tamanho estimados.

Não executar `COUNT(*)` global em tabelas de eventos apenas para volumetria.

### Consulta 04 — Inventário das estruturas auxiliares existentes

**Output:** `04_estruturas_auxiliares_eventos.csv`  
**Gate:** 4A  
**Risco:** Baixo

Identificar, por metadados, estruturas de:

- reconhecimentos;
- tags de evento/problema;
- correlação;
- sintomas/causas;
- supressão.

Não assumir nomes de tabelas não existentes.

### Consulta 05 — Amostra bruta recente de eventos

**Output:** `05_amostra_eventos_brutos.csv`  
**Gate:** 4A  
**Risco:** Baixo-Condicional

Retornar no máximo 200 eventos recentes, ordenados por chave primária/índice comprovado.

Campos preferenciais:

- `eventid`;
- códigos brutos de `source`, `object`, `value`;
- `objectid`;
- `clock`;
- severidade bruta, se existir.

Não interpretar os códigos nesta consulta.

### Consulta 06 — Distribuição bruta em janela recente

**Output:** `06_distribuicao_recente_source_object_value.csv`  
**Gate:** 4A  
**Risco:** Médio-Condicional  
**Estado inicial recomendado:** `@enabled: false`

Agrupar códigos brutos somente dentro de uma janela pequena e indexada, por exemplo os últimos N `eventid` determinados de forma segura.

Não agrupar a tabela `events` inteira.

### Consulta 07 — Amostra bruta de problemas

**Output:** `07_amostra_problem_bruto.csv`  
**Gate:** 4A  
**Risco:** Baixo-Condicional

Retornar no máximo 200 registros recentes de `problem` usando chave/indexação comprovada.

Objetivo:

- descobrir representação de problemas abertos/fechados;
- observar campos de recuperação, source/object, severity e correlação sem inferência prematura.

### Consulta 08 — Amostra estrutural de `event_recovery`

**Output:** `08_amostra_event_recovery.csv`  
**Gate:** 4A  
**Risco:** Baixo

Retornar no máximo 200 relações recentes, somente com chaves técnicas e códigos necessários.

Objetivo:

- comprovar caminho entre evento de problema e evento de recuperação;
- descobrir campos auxiliares de correlação/causa se existirem.

### Consulta 09 — Universo de triggers candidatas da Rodada 3

**Output:** `09_triggers_candidatas_disponibilidade.csv`  
**Gate:** 4A  
**Risco:** Baixo

Reconstruir por configuração o universo de triggers candidatas de disponibilidade definido na Rodada 3.

Retornar:

- `triggerid`;
- classificação candidata do sinal;
- prioridade/códigos necessários;
- quantidade de hosts associados.

Evitar descrições extensas quando não necessárias.

### Consulta 10 — Avaliação estrutural de seletividade

**Output:** `10_seletividade_indices_eventos.csv`  
**Gate:** 4A  
**Risco:** Baixo

Produzir evidência de quais índices disponíveis suportam as consultas planejadas da 4B.

A Rodada 4B somente pode ser habilitada se houver caminho indexado razoável para o recorte escolhido.

### Consulta 11 — Amostra de eventos das triggers candidatas

**Output:** `11_eventos_candidatos_amostra.csv`  
**Gate:** 4B  
**Risco:** Médio-Condicional  
**Estado inicial:** `@enabled: false`

Selecionar no máximo 500 eventos do exercício vigente ou de janela menor, restritos ao universo de triggers candidatas e aos códigos source/object comprovados na 4A.

Retornar somente chaves técnicas, timestamp/códigos e atributos indispensáveis.

### Consulta 12 — Reconstrução problema → recuperação

**Output:** `12_intervalos_problema_recuperacao.csv`  
**Gate:** 4B  
**Risco:** Médio-Condicional  
**Estado inicial:** `@enabled: false`

Para a amostra da Consulta 11, relacionar:

```text
evento problema
→ event_recovery
→ evento recuperação
```

Produzir:

- `problem_eventid`;
- `recovery_eventid` quando existir;
- início;
- fim;
- indicador técnico aberto/fechado;
- duração técnica em segundos apenas quando recuperado.

A duração não é MTTR nem disponibilidade oficial.

### Consulta 13 — Mapeamento evento → trigger → host

**Output:** `13_evento_trigger_host.csv`  
**Gate:** 4B  
**Risco:** Médio-Condicional

Mapear a amostra para:

- `eventid`;
- `triggerid`;
- `hostid`;
- classe candidata do host;
- sinal candidato.

Não retornar hostname/IP por padrão.

### Consulta 14 — Problemas ainda abertos

**Output:** `14_problemas_abertos_amostra.csv`  
**Gate:** 4B  
**Risco:** Médio-Condicional

Identificar problemas abertos dentro do mesmo universo candidato e recorte temporal.

Limitar a no máximo 200 registros.

Não inferir duração encerrada para problema aberto.

### Consulta 15 — Severidade histórica versus trigger atual

**Output:** `15_severidade_evento_trigger.csv`  
**Gate:** 4B  
**Risco:** Médio-Condicional

Comparar, somente na amostra:

- severidade/prioridade armazenada historicamente, se disponível;
- prioridade atual da trigger.

Objetivo:

- determinar se o BI futuro deve preservar severidade histórica em vez de consultar apenas estado atual da trigger.

### Consulta 16 — Reconhecimentos agregados

**Output:** `16_reconhecimentos_eventos.csv`  
**Gate:** 4B  
**Risco:** Baixo-Médio

Para os eventids da amostra, medir:

- existência de reconhecimento;
- quantidade de registros;
- códigos de ação necessários à interpretação.

Não retornar nome de usuário, mensagem/comentário ou conteúdo textual do reconhecimento, salvo necessidade técnica excepcional e revisão prévia.

### Consulta 17 — Correlação e recuperação auxiliar

**Output:** `17_correlacao_recuperacao.csv`  
**Gate:** 4B  
**Risco:** Médio-Condicional

Usar somente campos e estruturas comprovados na 4A para identificar evidências de correlação ou recuperação causada por outro evento.

Não assumir semântica de campos apenas pelo nome.

### Consulta 18 — Supressão dos eventos da amostra

**Output:** `18_supressao_eventos.csv`  
**Gate:** 4B  
**Risco:** Baixo-Médio

Consultar supressões apenas para eventids já selecionados.

Objetivo:

- comprovar se um evento candidato pode aparecer como suprimido;
- preparar a Rodada 5, sem interpretar ainda manutenção programada.

### Consulta 19 — Dependências de trigger na amostra

**Output:** `19_dependencias_triggers_eventos.csv`  
**Gate:** 4B  
**Risco:** Baixo

Relacionar triggers da amostra com `trigger_depends`.

Objetivo:

- identificar eventos cuja trigger possui dependência;
- preparar análise de possível dupla contagem.

Não excluir eventos automaticamente por dependência.

### Consulta 20 — Sobreposição de intervalos por host

**Output:** `20_intervalos_sobrepostos_host.csv`  
**Gate:** 4B  
**Risco:** Médio-Condicional

Detectar sobreposições somente dentro da amostra reconstruída.

Retornar no máximo 100 pares.

Objetivo:

- comprovar se múltiplos problemas candidatos podem coexistir no mesmo host;
- impedir futura soma ingênua de durações.

### Consulta 21 — Múltiplos sinais candidatos no mesmo intervalo

**Output:** `21_multiplos_sinais_mesmo_intervalo.csv`  
**Gate:** 4B  
**Risco:** Médio-Condicional

Identificar, dentro da amostra, intervalos simultâneos associados a sinais candidatos diferentes no mesmo host.

Exemplos conceituais a testar sem assumir como regra:

- ICMP e agente;
- ICMP e SNMP;
- múltiplas triggers de disponibilidade.

### Consulta 22 — Qualidade da reconstrução

**Output:** `22_qualidade_reconstrucao.csv`  
**Gate:** 4B  
**Risco:** Baixo-Médio

Produzir contagens agregadas para a amostra:

- problemas selecionados;
- recuperados;
- abertos;
- sem trigger mapeada;
- sem host mapeado;
- recuperação ausente quando esperada;
- duração negativa/inconsistente;
- triggers com dependência;
- eventos reconhecidos;
- eventos suprimidos;
- intervalos com sobreposição.

### Consulta 23 — Amostra de anomalias

**Output:** `23_amostra_anomalias_reconstrucao.csv`  
**Gate:** 4B  
**Risco:** Médio  
**Limite:** 50 registros

Retornar apenas chaves técnicas e flags de anomalia.

Sem hostname, IP, comentários ou textos desnecessários.

### Consulta 24 — Matriz de conclusão da reconstrução

**Output:** `24_matriz_modelo_eventos.csv`  
**Gate:** 4B  
**Risco:** Baixo

Produzir uma saída compacta que permita documentar:

- caminho estrutural comprovado;
- campos de início/fim;
- condição de aberto/fechado;
- severidade histórica;
- reconhecimento;
- supressão;
- dependência;
- limitações.

Não incluir regra oficial de disponibilidade.

---

## 15. Política de consultas pesadas

`--include-heavy` não está autorizado por esta SPEC.

Se uma consulta planejada exigir varredura ampla ou índice insuficiente:

1. não executá-la;
2. deixá-la `@enabled: false`;
3. se pertinente, marcá-la `@heavy: true` apenas como documentação de risco;
4. registrar o motivo;
5. aplicar regra de parada.

A conclusão da Rodada 4 pode registrar uma lacuna em vez de forçar uma consulta pesada.

---

## 16. Processo obrigatório

### Gate 0 — Git

- atualizar refs;
- confirmar working tree limpo;
- usar a branch da Rodada 4;
- não trabalhar em `main`.

### Gate 1 — Leitura

Ler integralmente:

```text
AGENTS.md
README.md
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
docs/SPEC-BI-003-Fase-0-Rodada-4-Eventos-Recuperacao-Intervalos.md
docs/ZABBIX_BI_Fase0_RELATORIO.md
sql/ZABBIX_BI_Fase0_Rodada3_Semantica_Monitoramento_MySQL.sql
```

Consultar SPECs anteriores somente quando necessário para preservar decisões já tomadas.

### Gate 2 — Implementar Rodada 4A

Criar o novo pacote SQL.

Implementar inicialmente as Consultas 01–10.

Consultas 11–24 devem permanecer desabilitadas até análise da 4A, se o parser permitir o bloco desabilitado.

### Gate 3 — Validação estática

Antes de banco:

- revisar SQL integralmente;
- confirmar ausência de history/trends;
- confirmar ausência de DML/DDL;
- confirmar limites;
- confirmar que nenhuma consulta 4B está habilitada prematuramente;
- validar parser;
- executar `--list`;
- executar testes locais.

### Gate 4 — Preflight

Executar:

```powershell
.\preflight.ps1
```

Continuar somente com preflight aprovado.

### Gate 5 — Executar Rodada 4A

Executar:

```powershell
.\run_extractor.ps1
```

Sem `--include-heavy`.

Analisar integralmente:

- manifestos;
- `execucao.json`;
- CSVs;
- snapshot SQL;
- log;
- ZIP local.

Exigir 0 `ERROR`.

### Gate 6 — Decisão de seletividade

Antes de habilitar a 4B, documentar:

- tamanho estimado das tabelas;
- índices relevantes;
- códigos source/object/value observados;
- caminho `event → trigger` comprovado ou não;
- caminho `problem → recovery` comprovado ou não;
- universo de triggers candidatas;
- filtro temporal planejado;
- limites de linhas;
- risco residual de scan.

Se houver dúvida material de custo, parar.

### Gate 7 — Implementar/ajustar Rodada 4B

Somente com seletividade demonstrada:

- implementar ou habilitar Consultas 11–24;
- manter amostras limitadas;
- restringir ao universo candidato;
- preservar códigos brutos quando a semântica não estiver comprovada;
- não transformar hipótese em regra funcional.

### Gate 8 — Revalidar

Repetir:

- testes;
- parser;
- `--list`;
- revisão estática;
- preflight.

### Gate 9 — Executar Rodada 4B

Executar sem `--include-heavy`.

Exigir 0 `ERROR` na remessa oficial.

### Gate 10 — Análise final

Classificar conclusões como:

- Declarada;
- Observada;
- Inferida;
- Hipótese.

Não chamar duração da amostra de MTTR.

Não chamar intervalo reconstruído de indisponibilidade oficial sem reconciliação.

### Gate 11 — Documentação

Atualizar após evidência:

```text
docs/ZABBIX_BI_Fase0_RELATORIO.md
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
```

Registrar:

- remessas oficiais;
- consultas/status/linhas;
- seletividade usada;
- códigos observados;
- relacionamento problema/recuperação;
- aberto/fechado;
- severidade histórica;
- reconhecimentos;
- correlação;
- supressão;
- dependências;
- sobreposição;
- lacunas;
- próximos passos.

### Gate 12 — Git final

- `git diff --check`;
- testes finais;
- nenhum output bruto versionado;
- commits coerentes;
- push da branch;
- working tree limpo;
- não fazer merge.

---

## 17. Regra obrigatória de parada

Parar imediatamente e solicitar revisão se ocorrer:

- qualquer `ERROR` em remessa candidata a oficial;
- falha crítica no preflight;
- necessidade de `--include-heavy`;
- índice insuficiente para consulta temporal planejada;
- dúvida relevante de custo;
- necessidade de varrer `events` ou `problem` sem recorte seletivo;
- necessidade de history/trends;
- necessidade de DML/DDL;
- necessidade de procedure/função de efeito colateral;
- necessidade de alterar núcleo Python;
- volume inesperado;
- timeout;
- exposição inesperada de segredo ou conteúdo sensível;
- semântica de source/object incompatível com a hipótese de trigger;
- relacionamento problema/recuperação divergente do modelo esperado;
- necessidade de incluir manutenção ou reinício para concluir a rodada;
- divergência material entre a SPEC e os dados observados.

Não contornar a regra de parada para concluir o Engineering Loop.

---

## 18. Classificação de evidências

### Declarada

Confirmada por documentação/configuração/responsável técnico.

### Observada

Comprovada diretamente pela remessa.

### Inferida

Conclusão lógica apoiada por evidência observada.

### Hipótese

Interpretação ainda não validada.

A reconstrução temporal só poderá ser chamada de **modelo candidato de indisponibilidade** nesta fase.

---

## 19. Critérios de aceite

A Rodada 4 estará concluída quando houver evidência suficiente para responder ou registrar lacuna para:

- [ ] estrutura de `events`;
- [ ] estrutura de `problem`;
- [ ] estrutura de `event_recovery`;
- [ ] índices e seletividade;
- [ ] códigos source/object/value relevantes;
- [ ] evento de problema candidato;
- [ ] evento de recuperação;
- [ ] problema aberto;
- [ ] problema recuperado;
- [ ] evento → trigger;
- [ ] trigger → host;
- [ ] início do intervalo;
- [ ] fim do intervalo;
- [ ] duração técnica da amostra;
- [ ] severidade histórica;
- [ ] reconhecimentos;
- [ ] correlação/causa, quando existente;
- [ ] supressão;
- [ ] dependências;
- [ ] sobreposição de intervalos;
- [ ] múltiplos sinais no mesmo intervalo;
- [ ] qualidade da reconstrução;
- [ ] amostra de anomalias;
- [ ] nenhuma consulta global de eventos/problemas;
- [ ] nenhuma consulta history/trends;
- [ ] nenhuma DML/DDL;
- [ ] nenhum `--include-heavy`;
- [ ] 0 `ERROR` nas remessas oficiais;
- [ ] documentação atualizada;
- [ ] conta dedicada read-only continua pendente salvo comprovação externa;
- [ ] branch limpa e pronta para revisão.

Um item pode ser concluído como lacuna comprovada se avançar exigiria violar segurança, custo ou escopo.

---

## 20. Resultado final esperado

Ao concluir, entregar:

```text
sql/ZABBIX_BI_Fase0_Rodada4_Eventos_Recuperacao_MySQL.sql
```

além de:

- remessas 4A/4B locais auditáveis;
- relatório consolidado atualizado;
- checklist principal atualizado;
- modelo documentado `problema → recuperação → trigger → host`;
- amostras limitadas de intervalos reconstruídos;
- matriz de qualidade;
- lacunas/riscos documentados;
- preparação da Rodada 5 sem implementá-la.

Resultados brutos permanecem locais.

---

## 21. Próxima rodada permitida

Somente depois da conclusão da Rodada 4 será permitido preparar a Rodada 5:

> manutenção, supressão programada e reinícios.

A Rodada 4 pode observar existência de supressão, mas não deve classificar manutenção programada nem reinício de forma definitiva.
