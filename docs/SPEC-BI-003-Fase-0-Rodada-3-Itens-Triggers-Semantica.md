# SPEC BI-003 — Fase 0 — Rodada 3: Itens, Triggers e Semântica do Monitoramento

**Projeto:** BI-003 — MVP de Disponibilidade da Infraestrutura de TI  
**Fase:** 0 — Descoberta Técnica do Zabbix  
**Rodada:** 3 — Itens, triggers e semântica do monitoramento  
**Ferramenta:** Generic SQL Extractor 2.0  
**SGBD:** MySQL  
**Database:** `zabbix`  
**Branch de trabalho:** `feat/bi-003-zabbix-fase0-round3-semantica`  
**Pacote SQL previsto:** `sql/ZABBIX_BI_Fase0_Rodada3_Semantica_Monitoramento_MySQL.sql`  
**Status:** APROVADA PARA IMPLEMENTAÇÃO CONTROLADA  
**Versão:** 1.0  
**Data:** 14/08/2026

---

## 1. Autoridade e relação com a Fase 0

Este documento detalha operacionalmente a Rodada 3 da Fase 0 do BI-003.

A fonte da verdade global continua sendo:

```text
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
```

A Rodada 2 foi concluída e seu resultado está consolidado em:

```text
docs/ZABBIX_BI_Fase0_RELATORIO.md
```

Em qualquer divergência:

1. prevalecem as restrições de segurança de `AGENTS.md`;
2. prevalecem as restrições da SPEC principal da Fase 0;
3. esta SPEC define o escopo operacional específico da Rodada 3;
4. a evidência observada no ambiente prevalece sobre suposições de nomes ou padrões;
5. nenhuma regra candidata de disponibilidade se torna regra oficial do BI sem reconciliação posterior.

---

## 2. Baseline comprovado das Rodadas 1 e 2

### 2.1 Ambiente

Está comprovado por evidência:

- MySQL `8.0.46-0ubuntu0.22.04.3`;
- database `zabbix`;
- schema Zabbix `7020000 / 7020004`;
- 203 tabelas base e 28 views observadas na Rodada 1;
- 272 FKs declaradas;
- ausência observada de particionamento;
- aproximadamente 17,47 GB nas tabelas;
- `history`, `history_uint`, `trends` e `trends_uint` concentram aproximadamente 97,7% do tamanho estimado do database.

### 2.2 Inventário

A Rodada 2 comprovou:

- 135 hosts regulares;
- 123 habilitados;
- 12 desabilitados;
- 352 templates;
- 46 outros registros;
- 57 grupos;
- 624 vínculos host-grupo totais;
- 267 vínculos envolvendo hosts regulares;
- 1.078 tags, porém nenhuma tag cadastrada nos hosts regulares;
- 49 templates distintos vinculados;
- 173 vínculos de template;
- 84 hosts regulares com interface de agente;
- 48 hosts regulares com interface SNMP;
- 3 hosts regulares com agente e SNMP;
- 6 hosts regulares sem interface;
- nenhum proxy utilizado.

A interpretação estrutural candidata atual é:

```text
host regular: flags = 0 e status IN (0,1)
template:     flags = 0 e status = 3
```

Essa interpretação está sustentada por evidências da Rodada 2, mas continua classificada como inferência técnica até reconciliação funcional final.

### 2.3 Classificação candidata

A Rodada 2 observou os seguintes sinais de classificação por grupos exatos:

- 19 Access Points;
- 16 switches;
- 45 servidores;
- 6 servidores físicos;
- 38 servidores virtuais;
- 32 servidores Windows;
- 12 servidores Linux.

Também foram observados:

- 55 hosts sem classe principal AP/switch/servidor;
- nenhum conflito entre classes principais;
- nenhum conflito físico/virtual;
- nenhum conflito Windows/Linux;
- um servidor sem físico/virtual;
- um servidor sem Windows/Linux.

Essas classificações são candidatas e servem como recorte técnico para a Rodada 3. Não constituem regra final do BI.

### 2.4 Localização

A Rodada 2 comprovou baixa cobertura cadastral:

- Unidade: cobertura de 1 host;
- Prédio: cobertura de 21 hosts;
- Sala: sem fonte cadastral comprovada;
- Setor: sem fonte cadastral comprovada;
- Departamento: sem fonte cadastral comprovada;
- 0 hosts completos nas cinco dimensões;
- 22 parcialmente preenchidos;
- 113 sem localização nas fontes comprovadas.

A Rodada 3 não deve tentar resolver localização.

### 2.5 Views customizadas

As sete views de infraestrutura analisadas:

- usam grupos como regra estrutural de classificação;
- acessam `items` e `interface`;
- calculam métricas por nomes de itens;
- utilizam histórico para obter valores recentes;
- apresentam diferenças de filtro e de significado do campo `STATUS`.

Nenhuma view foi executada porque todas dependem de histórico proibido na Rodada 2.

Na Rodada 3, suas definições já observadas podem ser utilizadas apenas como pista documental para localizar itens candidatos, sem executar as views nem seu histórico.

---

## 3. Objetivo exclusivo da Rodada 3

Descobrir, por configuração e relacionamentos estruturais, como o ambiente representa os sinais técnicos que futuramente poderão sustentar a regra de disponibilidade do MVP.

A Rodada 3 deve responder, com evidência:

1. quais itens existem nos 135 hosts regulares;
2. quais chaves de item são recorrentes por tipo de ativo;
3. quais itens são herdados de templates e de quais templates se originam;
4. quais itens são habilitados ou desabilitados;
5. quais sinais candidatos representam ICMP;
6. quais sinais candidatos representam disponibilidade do agente Zabbix;
7. quais sinais candidatos representam disponibilidade SNMP;
8. quais sinais candidatos representam uptime;
9. quais itens representam saúde operacional, como CPU, RAM, storage, rede e serviços;
10. quais itens representam inventário ou contexto, como sistema operacional;
11. quais triggers existem para os hosts do escopo;
12. quais triggers estão ligadas aos itens candidatos de disponibilidade;
13. quais severidades e estados de configuração são utilizados;
14. quais funções compõem as expressões das triggers candidatas;
15. quais mecanismos de recuperação, correlação ou fechamento manual estão configurados;
16. quais dependências existem entre triggers candidatas;
17. quais macros são referenciadas ou disponibilizadas para esses hosts/templates, sem expor valores;
18. quais tags de trigger participam da semântica, quando aplicável;
19. quais diferenças existem entre APs, switches, servidores Windows e servidores Linux;
20. qual cobertura dos sinais candidatos existe por classe de ativo;
21. quais lacunas, ambiguidades ou múltiplos sinais concorrentes existem;
22. se a hipótese conceitual `ICMP + agente` para servidores e `ICMP + SNMP` para ativos de rede possui suporte estrutural no ambiente.

A Rodada 3 não deve calcular disponibilidade, duração de indisponibilidade, MTTR, MTBF ou MTTF.

---

## 4. Pergunta central da Rodada 3

Até a Rodada 2 foi respondido:

> O que é cada ativo e como ele está cadastrado?

A Rodada 3 deve responder:

> Quais sinais configurados no Zabbix podem representar disponibilidade e como eles se relacionam com itens, triggers, templates e classes de ativos?

Ela ainda não responde:

> Quando exatamente ocorreu uma indisponibilidade e quanto tempo ela durou?

Essa última pergunta pertence à Rodada 4 — eventos e recuperação.

---

## 5. Escopo permitido

A Rodada 3 pode consultar, de forma controlada, as seguintes estruturas quando comprovadas no schema:

- `information_schema.COLUMNS`;
- `information_schema.STATISTICS`;
- `information_schema.TABLE_CONSTRAINTS`;
- `information_schema.KEY_COLUMN_USAGE`;
- `information_schema.REFERENTIAL_CONSTRAINTS`;
- `information_schema.TABLES`;
- `hosts`;
- `hosts_groups`;
- `hstgrp`;
- `hosts_templates`;
- `items`;
- `functions`;
- `triggers`;
- `trigger_depends`;
- `trigger_tag`;
- `interface`;
- `hostmacro`, somente coluna de nome da macro e chaves técnicas necessárias;
- `globalmacro`, somente coluna de nome da macro e chaves técnicas necessárias;
- tabelas cadastrais pequenas diretamente relacionadas a item/trigger que forem comprovadas pela Consulta 01/02.

O uso de qualquer objeto adicional deverá ser justificado por relacionamento estrutural observado e permanecer dentro do objetivo desta rodada.

---

## 6. Estruturas proibidas nesta rodada

É proibido consultar conteúdo das tabelas históricas:

```text
history
history_uint
history_str
history_text
history_log
trends
trends_uint
```

Também não consultar conteúdo de estruturas de eventos e indisponibilidade nesta rodada, incluindo:

```text
events
problem
event_recovery
acknowledges
alerts
```

Manutenção também permanece fora do escopo funcional da Rodada 3:

```text
maintenances
maintenances_hosts
maintenances_groups
maintenances_windows
event_suppress
```

Não consultar tabelas runtime adicionais apenas para descobrir estado atual quando isso não for necessário para explicar a configuração.

A Rodada 3 é predominantemente uma descoberta de **configuração e semântica**, não de histórico nem de estado operacional em tempo real.

---

## 7. Segurança obrigatória

### 7.1 Conta de banco

Permanece a exceção operacional temporária já declarada para a Fase 0.

A conexão poderá continuar utilizando temporariamente a conta operacional do Zabbix até a criação de usuário dedicado exclusivamente a leitura.

Permanece pendente:

> criar e substituir a credencial atual por um usuário dedicado exclusivamente read-only no database `zabbix`.

Esse requisito não pode ser marcado como concluído sem comprovação externa.

### 7.2 Proteções obrigatórias

Toda execução deve manter:

- somente `SELECT` ou `WITH`;
- nenhuma DML;
- nenhuma DDL;
- nenhuma procedure;
- nenhuma função com efeito colateral conhecido;
- nenhuma criação de objeto;
- nenhuma alteração de configuração;
- nenhuma escrita no banco;
- execução exclusivamente pelo Generic SQL Extractor;
- transação `READ ONLY`;
- parser e safety ativos;
- timeout por consulta;
- limites em amostras;
- nenhum segredo em saída;
- nenhum `.env` exibido, resumido ou versionado;
- nenhuma execução de view customizada que acesse histórico;
- nenhum `--include-heavy` sem nova autorização explícita.

### 7.3 Macros e segredos

É permitido levantar:

- nome da macro;
- escopo técnico;
- quantidade de hosts/templates que a possuem;
- presença ou ausência da macro.

É proibido retornar:

- valor da macro;
- senha;
- token;
- community SNMP;
- segredo de autenticação;
- chave privada;
- PSK;
- credencial;
- conteúdo que possa funcionar como segredo.

Se a estrutura exigir selecionar uma coluna potencialmente sensível para responder à pergunta, a consulta não deve ser executada; aplicar a regra de parada.

---

## 8. Núcleo Python

Não alterar o núcleo Python para acomodar regras do Zabbix.

Uma alteração somente poderá ser considerada se houver defeito técnico comprovado no extrator envolvendo:

- parser;
- safety;
- compatibilidade MySQL;
- exportação;
- manifesto;
- log;
- execução read-only.

Caso isso ocorra, parar antes de modificar o núcleo e solicitar revisão.

---

## 9. Governança Git

A branch desta rodada é:

```text
feat/bi-003-zabbix-fase0-round3-semantica
```

Ela parte do fechamento documentado da Rodada 2.

Antes de qualquer implementação local:

```powershell
git fetch --all --prune
git status --short --branch
git rev-parse HEAD
git rev-parse main
git rev-parse origin/main
git rev-parse origin/feat/bi-003-zabbix-fase0-round3-semantica
```

Confirmar:

- working tree limpo;
- branch correta;
- nenhuma alteração direta em `main`;
- baseline da Rodada 2 presente na branch de trabalho.

Não fazer merge automático em `main`.

---

## 10. Estratégia da Rodada 3

A Rodada 3 será executada em dois gates internos.

### 10.1 Rodada 3A — Estrutura e vocabulário

Objetivo:

- confirmar schema real dos objetos de item/trigger;
- confirmar índices e FKs;
- medir volume aproximado das tabelas de configuração;
- catalogar tipos/status de itens;
- catalogar chaves e nomes recorrentes;
- identificar herança de templates;
- catalogar triggers, severidades e relacionamentos;
- catalogar nomes de macros sem valores;
- identificar o vocabulário real necessário para ICMP, agente, SNMP, uptime, CPU, RAM, storage, rede, serviços e SO.

Nesta etapa não criar classificação semântica rígida baseada apenas em memória ou em padrões genéricos do Zabbix.

### 10.2 Rodada 3B — Matriz semântica e cobertura

Somente depois de analisar a Rodada 3A:

- selecionar itens candidatos por chaves/nomes efetivamente observados;
- relacionar candidatos a triggers;
- interpretar funções e expressões somente dos candidatos;
- medir cobertura por classe de ativo;
- medir sinais concorrentes, ausentes ou desabilitados;
- classificar candidatos em disponibilidade, saúde e inventário;
- testar estruturalmente as hipóteses `ICMP + agente` e `ICMP + SNMP`.

Essa classificação continua candidata e não substitui a reconciliação com casos reais prevista em etapa posterior da Fase 0.

---

## 11. Uso de documentação oficial do Zabbix

Quando um código numérico, tipo de item, prioridade, função ou semântica técnica não puder ser comprovado apenas pelos dados, o Codex pode consultar documentação ou código-fonte oficial do Zabbix.

Regras:

- usar somente fonte oficial do Zabbix;
- preferir versão compatível com o schema observado `7020000 / 7020004`;
- não declarar a versão exata do Zabbix Server apenas pelo schema;
- classificar essa informação como **Declarada**;
- manter separadas evidência documental e evidência observada no banco;
- não usar documentação externa para inventar chaves que não existam no ambiente.

---

## 12. Minimização de dados

Preferir sempre:

- contagens agregadas;
- `hostid`, `itemid` e `triggerid` como chaves técnicas;
- nomes de templates apenas quando necessários à semântica;
- chaves de item necessárias à descoberta;
- descrições de trigger somente quando necessárias à semântica;
- nenhum IP/DNS/hostname quando a pergunta puder ser respondida sem eles;
- amostras de no máximo 50 registros para lacunas/ambiguidades;
- nenhuma exportação de valores históricos ou valores de macros.

Outputs da execução permanecem locais e não devem ser versionados no GitHub.

---

## 13. Pacote SQL

Criar:

```text
sql/ZABBIX_BI_Fase0_Rodada3_Semantica_Monitoramento_MySQL.sql
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

- uma única instrução por bloco;
- somente `SELECT` ou `WITH`;
- ordenação determinística;
- `LIMIT` em amostras;
- nenhuma consulta histórica;
- nenhuma consulta de evento;
- nenhuma coluna de segredo;
- nenhuma classificação semântica baseada em valor não observado;
- filtros explícitos para hosts regulares ou templates relevantes quando necessário.

---

## 14. Consultas mínimas propostas

### Consulta 01 — Estrutura dos objetos de monitoramento

**Output:** `01_estrutura_objetos_monitoramento.csv`  
**Gate:** 3A  
**Risco:** Baixo

Catalogar via `information_schema.COLUMNS` os objetos necessários:

- `items`;
- `functions`;
- `triggers`;
- `trigger_depends`;
- `trigger_tag`;
- `hostmacro`;
- `globalmacro`;
- estruturas auxiliares diretamente comprovadas no schema.

Objetivo: eliminar suposições de colunas antes de escrever joins ou interpretar expressões.

### Consulta 02 — Índices, PKs e FKs do monitoramento

**Output:** `02_indices_constraints_monitoramento.csv`  
**Gate:** 3A  
**Risco:** Baixo

Levantar índices e relacionamentos estruturais dos objetos da Rodada 3.

Objetivo: comprovar caminhos `host → item → função → trigger` e verificar acesso seletivo.

### Consulta 03 — Volumetria estimada dos objetos de configuração

**Output:** `03_volumetria_configuracao_monitoramento.csv`  
**Gate:** 3A  
**Risco:** Baixo

Usar metadados para estimar volume de `items`, `functions`, `triggers`, dependências, tags e macros sem fazer contagem exata desnecessária em tabela grande.

### Consulta 04 — Distribuição bruta dos itens dos hosts regulares

**Output:** `04_itens_distribuicao_bruta.csv`  
**Gate:** 3A  
**Risco:** Baixo-Médio

Agrupar itens de hosts regulares pelos campos brutos relevantes descobertos na Consulta 01, como:

- status;
- type;
- value_type;
- flags;
- interfaceid presente/ausente;
- templateid presente/ausente.

Não interpretar códigos antes de comprová-los.

### Consulta 05 — Catálogo agregado de chaves e nomes de itens

**Output:** `05_itens_catalogo_chaves.csv`  
**Gate:** 3A  
**Risco:** Médio

Catalogar chaves e nomes de item com quantidade de hosts distintos, status e tipo bruto.

Aplicar limite determinístico se o vocabulário for muito amplo.

Objetivo: descobrir o vocabulário real do ambiente para ICMP, agente, SNMP, uptime, CPU, RAM, storage, rede, serviços e SO.

### Consulta 06 — Origem por template dos itens

**Output:** `06_itens_origem_templates.csv`  
**Gate:** 3A  
**Risco:** Médio

Mapear a herança de itens para templates quando o schema permitir, agregando por template e chave de item.

Objetivo: identificar diferenças semânticas entre classes de ativos e origem das configurações.

### Consulta 07 — Distribuição bruta das triggers

**Output:** `07_triggers_distribuicao_bruta.csv`  
**Gate:** 3A  
**Risco:** Baixo-Médio

Agrupar triggers relacionadas aos hosts regulares por campos brutos de configuração, incluindo quando existentes:

- status;
- priority;
- recovery_mode;
- correlation_mode;
- manual_close;
- flags.

Não consultar eventos.

### Consulta 08 — Catálogo agregado de descrições de trigger

**Output:** `08_triggers_catalogo_descricoes.csv`  
**Gate:** 3A  
**Risco:** Médio

Catalogar descrições de trigger relacionadas aos hosts regulares, com quantidade de hosts e prioridade bruta.

Aplicar limite determinístico se necessário.

### Consulta 09 — Resumo estrutural de função, item e trigger

**Output:** `09_funcoes_relacao_item_trigger.csv`  
**Gate:** 3A  
**Risco:** Médio

Comprovar a relação `items → functions → triggers` e medir:

- quantidade de itens por trigger;
- quantidade de funções por trigger;
- quantidade de triggers por item;
- hosts distintos envolvidos.

Não retornar expressão completa nesta etapa salvo se necessária e limitada.

### Consulta 10 — Dependências de trigger

**Output:** `10_dependencias_triggers.csv`  
**Gate:** 3A  
**Risco:** Baixo-Médio

Catalogar dependências estruturais entre triggers relacionadas ao escopo, preferindo IDs e contagens.

Detalhes textuais devem ser limitados ao necessário.

### Consulta 11 — Nomes de macros sem valores

**Output:** `11_macros_nomes_cobertura.csv`  
**Gate:** 3A  
**Risco:** Médio

Listar somente nomes de macros e cobertura por host/template/escopo.

É proibido selecionar a coluna de valor.

### Consulta 12 — Tags de trigger

**Output:** `12_trigger_tags_catalogo.csv`  
**Gate:** 3A  
**Risco:** Baixo-Médio  
**Estado inicial:** habilitar somente se a Consulta 01 confirmar a estrutura esperada.

Catalogar tag/valor de trigger e quantidade de triggers/hosts associados, sem extrapolar semântica.

### Consulta 13 — Matriz candidata de itens de disponibilidade

**Output:** `13_matriz_itens_disponibilidade.csv`  
**Gate:** 3B  
**Risco:** Médio  
**Estado inicial obrigatório:** `@enabled: false`

Somente após a Rodada 3A, selecionar itens candidatos efetivamente observados para:

- ICMP;
- agente;
- SNMP;
- uptime.

Por hostid, registrar:

- chave técnica;
- tipo bruto;
- status;
- template de origem quando comprovado;
- papel candidato;
- evidência usada para essa classificação.

### Consulta 14 — Matriz candidata de trigger → item

**Output:** `14_matriz_triggers_disponibilidade.csv`  
**Gate:** 3B  
**Risco:** Médio  
**Estado inicial obrigatório:** `@enabled: false`

Relacionar triggers candidatas de disponibilidade com os itens da Consulta 13.

Para o subconjunto candidato, pode retornar de forma controlada:

- triggerid;
- descrição;
- prioridade;
- status;
- recovery_mode;
- correlation_mode;
- manual_close;
- expressão;
- recovery_expression;
- funções/itens usados.

Não retornar todas as expressões do ambiente indiscriminadamente.

### Consulta 15 — Cobertura de ICMP por classe

**Output:** `15_cobertura_icmp_por_classe.csv`  
**Gate:** 3B  
**Risco:** Médio  
**Estado inicial obrigatório:** `@enabled: false`

Medir cobertura de sinal candidato de ICMP para:

- Access Points;
- switches;
- servidores;
- físicos/virtuais;
- Windows/Linux.

### Consulta 16 — Cobertura de agente em servidores

**Output:** `16_cobertura_agente_servidores.csv`  
**Gate:** 3B  
**Risco:** Médio  
**Estado inicial obrigatório:** `@enabled: false`

Medir quais servidores possuem itens/triggers candidatos de disponibilidade do agente.

Não confundir presença de interface tipo agente com existência de regra de disponibilidade do agente.

### Consulta 17 — Cobertura SNMP em ativos de rede

**Output:** `17_cobertura_snmp_rede.csv`  
**Gate:** 3B  
**Risco:** Médio  
**Estado inicial obrigatório:** `@enabled: false`

Medir quais APs e switches possuem itens/triggers candidatos de disponibilidade SNMP.

Não retornar parâmetros SNMP sensíveis.

### Consulta 18 — Cobertura de uptime

**Output:** `18_cobertura_uptime.csv`  
**Gate:** 3B  
**Risco:** Médio  
**Estado inicial obrigatório:** `@enabled: false`

Medir itens candidatos de uptime por classe de ativo e template de origem.

A Rodada 3 não deve consultar valores de uptime nem detectar reinício.

### Consulta 19 — Catálogo semântico de saúde e inventário

**Output:** `19_catalogo_saude_inventario.csv`  
**Gate:** 3B  
**Risco:** Médio  
**Estado inicial obrigatório:** `@enabled: false`

Classificar de forma agregada os itens efetivamente observados nas categorias candidatas:

- CPU;
- RAM;
- storage;
- rede;
- serviços Windows;
- sistema operacional;
- outros sinais de saúde;
- inventário/contexto.

Objetivo: separar disponibilidade de saúde operacional, preservando a arquitetura conceitual do MVP.

### Consulta 20 — Severidades, funções e dependências dos candidatos

**Output:** `20_semantica_triggers_candidatas.csv`  
**Gate:** 3B  
**Risco:** Médio  
**Estado inicial obrigatório:** `@enabled: false`

Para triggers candidatas de disponibilidade, consolidar:

- severidade/prioridade;
- funções utilizadas;
- quantidade de itens na expressão;
- dependências;
- modo de recuperação;
- fechamento manual;
- presença de macros por nome.

### Consulta 21 — Qualidade e lacunas da semântica

**Output:** `21_qualidade_semantica_monitoramento.csv`  
**Gate:** 3B  
**Risco:** Médio  
**Estado inicial obrigatório:** `@enabled: false`

Medir, por classe:

- hosts sem ICMP candidato;
- servidores sem agente candidato;
- AP/switch sem SNMP candidato;
- hosts sem uptime candidato;
- hosts com múltiplos sinais concorrentes;
- itens candidatos desabilitados;
- triggers candidatas desabilitadas;
- candidatos sem trigger relacionada;
- trigger candidata sem item esperado.

Esses resultados são lacunas técnicas candidatas, não falhas de monitoramento oficialmente aprovadas.

### Consulta 22 — Amostra controlada de lacunas e ambiguidades

**Output:** `22_amostra_lacunas_semantica.csv`  
**Gate:** 3B  
**Risco:** Médio  
**Estado inicial obrigatório:** `@enabled: false`

Retornar no máximo 50 registros com chaves técnicas mínimas para permitir revisão de:

- ausência de sinal esperado;
- múltiplos candidatos;
- item desabilitado;
- trigger desabilitada;
- regra ambígua.

Evitar hostname e IP salvo necessidade técnica justificada.

---

## 15. Hipóteses conceituais a testar

A Rodada 3 pode testar estruturalmente, sem aprovar, as hipóteses:

### Servidores

```text
ICMP + agente Zabbix
```

### Access Points e switches

```text
ICMP + SNMP
```

A conclusão permitida é do tipo:

- `suportada estruturalmente`;
- `parcialmente suportada`;
- `não suportada pelos dados atuais`;
- `ambígua`.

É proibido concluir nesta rodada que essa combinação já constitui a regra oficial de indisponibilidade.

A aprovação definitiva depende de eventos, recuperação e reconciliação com casos reais em rodadas posteriores.

---

## 16. Política de consultas pesadas

`--include-heavy` não está autorizado.

Se alguma consulta exigir:

- full scan de tabela de alto volume;
- expressão de custo incerto;
- retorno muito acima do esperado;
- consulta ampla sem filtro por hosts do escopo;
- acesso a histórico;

então:

1. não executá-la;
2. marcar `@heavy: true` ou `@enabled: false` conforme o caso;
3. documentar o motivo;
4. aplicar a regra de parada.

---

## 17. Processo obrigatório

### Gate 0 — Git

- `git fetch --all --prune`;
- working tree limpo;
- checkout da branch da Rodada 3;
- confirmar baseline da Rodada 2;
- não alterar `main`.

### Gate 1 — Leitura

Ler integralmente:

```text
AGENTS.md
README.md
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
docs/SPEC-BI-003-Fase-0-Rodada-2-Inventario-Classificacao.md
docs/SPEC-BI-003-Fase-0-Rodada-3-Itens-Triggers-Semantica.md
docs/ZABBIX_BI_Fase0_RELATORIO.md
sql/ZABBIX_BI_Fase0_Descoberta_MySQL.sql
sql/ZABBIX_BI_Fase0_Rodada2_Inventario_MySQL.sql
```

### Gate 2 — Implementação 3A

- criar o novo pacote SQL;
- implementar Consultas 01–12;
- manter 13–22 desabilitadas ou ainda não materializadas até haver evidência;
- não alterar núcleo Python.

### Gate 3 — Revisão estática

- revisar SQL completo;
- confirmar ausência de histórico/eventos;
- confirmar ausência de colunas de macro com valor;
- confirmar ausência de IP/DNS quando desnecessários;
- confirmar IDs e outputs únicos;
- confirmar limites e ordenação.

### Gate 4 — Testes/parser/listagem

- executar suíte local;
- validar parser;
- executar `--list` para o pacote da Rodada 3;
- revisar metadados de cada consulta.

### Gate 5 — Preflight

Executar:

```powershell
.\preflight.ps1
```

Continuar somente se:

- testes aprovados;
- conexão aprovada;
- database correto;
- transação read-only aplicada;
- nenhuma falha crítica.

### Gate 6 — Execução 3A

Executar:

```powershell
.\run_extractor.ps1
```

Sem `--include-heavy`.

Analisar:

- manifesto CSV/JSON;
- `execucao.json`;
- CSVs;
- log;
- snapshot SQL;
- ZIP local.

Exigir 0 `ERROR`.

### Gate 7 — Análise 3A

Classificar conclusões como:

- Declarada;
- Observada;
- Inferida;
- Hipótese.

Determinar o vocabulário real de itens, triggers, funções, severidades, macros e dependências.

### Gate 8 — Implementação 3B

Somente após evidência suficiente:

- implementar/ajustar Consultas 13–22;
- selecionar candidatos observados;
- não inventar chave por memória;
- não promover hipótese a regra oficial.

### Gate 9 — Revalidação

Repetir:

- testes;
- parser;
- `--list`;
- revisão SQL;
- `preflight.ps1`.

### Gate 10 — Execução 3B

Executar:

```powershell
.\run_extractor.ps1
```

Sem `--include-heavy`.

Exigir 0 `ERROR`.

### Gate 11 — Consolidação

Montar matriz por pergunta da Rodada 3 com:

```text
Pergunta
Resposta
Classificação da evidência
Consulta/arquivo que comprova
Limitação
```

### Gate 12 — Documentação

Atualizar somente depois de evidência final:

```text
docs/ZABBIX_BI_Fase0_RELATORIO.md
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
```

Documentar:

- itens candidatos;
- triggers candidatas;
- funções;
- severidades;
- dependências;
- macros por nome;
- diferenças entre classes;
- cobertura ICMP/agente/SNMP/uptime;
- separação disponibilidade × saúde × inventário;
- lacunas;
- hipóteses conceituais;
- limitações;
- ausência de consultas históricas.

### Gate 13 — Git final

- revisar diff;
- garantir que nenhum output, CSV, ZIP, log ou `.env` foi versionado;
- executar testes finais;
- criar commits coerentes;
- push da branch quando permitido;
- não fazer merge automático em `main`.

---

## 18. Regra de parada obrigatória

Parar imediatamente e solicitar revisão se ocorrer:

- qualquer `ERROR` em remessa;
- falha crítica no preflight;
- necessidade de `--include-heavy`;
- necessidade de consultar `history*` ou `trends*`;
- necessidade de consultar eventos para concluir semântica;
- necessidade de DML/DDL;
- necessidade de procedure ou função com efeito colateral;
- necessidade de selecionar valor de macro ou segredo;
- necessidade de alterar núcleo Python;
- custo de consulta incerto;
- volume inesperado;
- divergência material entre SPEC e dados;
- impossibilidade de diferenciar candidato de disponibilidade e saúde sem ampliar escopo;
- necessidade de avançar para eventos, recuperação, manutenção ou reinício.

Não contornar a regra de parada para concluir o loop.

---

## 19. Classificação de evidências

### Declarada

Confirmada por documentação oficial, configuração declarada ou responsável técnico.

### Observada

Comprovada diretamente por remessa extraída.

### Inferida

Conclusão lógica suportada por evidências observadas.

### Hipótese

Possibilidade ainda pendente de validação.

Um item ou trigger pode ser classificado como **candidato de disponibilidade** sem se tornar regra aprovada do BI.

---

## 20. Critérios de aceite da Rodada 3

A Rodada 3 só estará concluída quando houver evidência suficiente para responder ou documentar formalmente a lacuna dos itens abaixo:

- [ ] estrutura de `items` comprovada;
- [ ] estrutura de `functions` comprovada;
- [ ] estrutura de `triggers` comprovada;
- [ ] relação item → função → trigger comprovada;
- [ ] distribuição de itens por status/tipo catalogada;
- [ ] chaves de item catalogadas;
- [ ] origem por template avaliada;
- [ ] candidatos de ICMP identificados;
- [ ] candidatos de agente identificados;
- [ ] candidatos de SNMP identificados;
- [ ] candidatos de uptime identificados;
- [ ] itens de CPU catalogados;
- [ ] itens de RAM catalogados;
- [ ] itens de storage catalogados;
- [ ] itens de rede catalogados;
- [ ] itens de serviços Windows catalogados;
- [ ] itens de sistema operacional/inventário catalogados;
- [ ] triggers candidatas identificadas;
- [ ] severidades/prioridades catalogadas;
- [ ] funções das triggers candidatas analisadas;
- [ ] modos de recuperação analisados;
- [ ] dependências de trigger analisadas;
- [ ] macros relevantes catalogadas somente por nome;
- [ ] tags de trigger avaliadas quando presentes;
- [ ] cobertura de ICMP por classe medida;
- [ ] cobertura de agente em servidores medida;
- [ ] cobertura de SNMP em AP/switch medida;
- [ ] cobertura de uptime medida;
- [ ] disponibilidade separada de saúde e inventário;
- [ ] lacunas e ambiguidades medidas;
- [ ] hipótese `ICMP + agente` avaliada estruturalmente;
- [ ] hipótese `ICMP + SNMP` avaliada estruturalmente;
- [ ] nenhuma consulta histórica executada;
- [ ] nenhum evento consultado funcionalmente;
- [ ] nenhuma DML/DDL executada;
- [ ] nenhum valor de macro/segredo retornado;
- [ ] nenhum `--include-heavy` utilizado;
- [ ] 0 `ERROR` nas remessas oficiais;
- [ ] documentação atualizada;
- [ ] conta dedicada read-only continua marcada como pendente;
- [ ] branch limpa e pronta para revisão.

Um item pode ser encerrado como lacuna somente se a impossibilidade for comprovada sem ampliar o escopo.

---

## 21. Resultado final esperado

Ao concluir a Rodada 3, deverão existir:

```text
sql/ZABBIX_BI_Fase0_Rodada3_Semantica_Monitoramento_MySQL.sql
```

além de:

- remessa(s) local(is) auditável(is);
- manifestos;
- `execucao.json`;
- snapshot SQL;
- CSVs locais;
- ZIP local;
- relatório da Fase 0 atualizado;
- matriz item/trigger → papel candidato no MVP;
- matriz de cobertura por classe;
- lista de lacunas/ambiguidades;
- avaliação estrutural das hipóteses de disponibilidade;
- próximo passo recomendado para a Rodada 4.

Nenhum resultado bruto deve ser versionado no GitHub.

---

## 22. Próximo passo permitido

Somente depois da Rodada 3 estar concluída e revisada será permitido preparar a Rodada 4:

> eventos, problemas, recuperação e reconstrução de intervalos de indisponibilidade.

A Rodada 3 não deve antecipar a Rodada 4.
