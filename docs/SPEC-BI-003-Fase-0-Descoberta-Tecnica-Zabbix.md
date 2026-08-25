# SPEC BI-003 — Fase 0: Descoberta Técnica do Zabbix

**Projeto:** MVP de Disponibilidade da Infraestrutura de TI  
**Produto futuro:** Dashboard Power BI de Disponibilidade da Infraestrutura  
**Fase:** 0 — Descoberta técnica, evidências e base de conhecimento  
**Fonte investigada:** Banco de dados do Zabbix  
**SGBD confirmado:** MySQL  
**Ferramenta:** Generic SQL Extractor 2.0  
**Status:** EM EXECUÇÃO — RODADA 5 CONCLUÍDA  
**Versão:** 1.5  
**Data de abertura:** 31/07/2026  
**Documento de acompanhamento:** este arquivo é a fonte oficial do checklist da Fase 0.

---

## 1. Objetivo

Executar uma descoberta técnica controlada, somente leitura e reproduzível na base MySQL do Zabbix, produzindo evidências suficientes para transformar a SPEC conceitual do MVP em um plano de implementação tecnicamente confiável.

A Fase 0 deve esclarecer como o ambiente realmente representa:

- hosts e sua classificação;
- grupos, tags, templates e interfaces;
- localização física e organizacional;
- itens de ICMP, agente Zabbix, SNMP e uptime;
- triggers e severidades;
- eventos de problema e recuperação;
- indisponibilidades abertas e encerradas;
- manutenções e supressões;
- reinícios;
- retenção histórica;
- volumes e riscos de consulta;
- relacionamento entre tabelas do banco e objetos da API do Zabbix.

O resultado será utilizado para:

1. validar ou corrigir as regras conceituais de disponibilidade;
2. definir o contrato de extração via API;
3. definir o modelo físico do PostgreSQL;
4. reduzir incertezas antes do `writing-plans`;
5. construir a base de conhecimento técnica do projeto.

---

## 2. Decisões já aprovadas

- [x] O desenho conceitual do MVP de infraestrutura foi aprovado.
- [x] O Zabbix será a fonte oficial dos eventos técnicos do MVP.
- [x] A arquitetura operacional continuará sendo `API do Zabbix → Python → PostgreSQL → Power BI`.
- [x] O acesso direto ao banco será usado somente para descoberta, documentação, reconciliação e validação.
- [x] O SGBD do Zabbix foi confirmado como **MySQL**.
- [x] O nome do database foi confirmado como **zabbix**.
- [x] O Generic SQL Extractor 2.0 foi localizado no Google Drive.
- [x] Foi confirmado que o extrator suporta MySQL com driver PyMySQL e transação somente leitura.
- [x] Foi decidido não criar um MCP nesta fase.
- [x] Foi decidido executar a Fase 0 antes do `writing-plans` definitivo.

---

## 3. Princípios e limites

### 3.1 Somente leitura

Toda consulta deve iniciar por `SELECT` ou `WITH` e ser executada com conta exclusivamente de leitura.

São proibidos:

- DML;
- DDL;
- procedures;
- jobs;
- locks explícitos;
- `SELECT ... FOR UPDATE`;
- criação de tabelas temporárias no servidor;
- gravação de arquivos pelo banco;
- alterações de configuração;
- execução de funções com efeito colateral conhecido;
- qualquer consulta que exponha credenciais, tokens ou segredos.

### 3.2 Núcleo genérico preservado

A investigação específica do Zabbix deve ser implementada preferencialmente por novos arquivos em `sql/` e `docs/`.

O núcleo Python do Generic SQL Extractor não deverá ser alterado para acomodar regras específicas do Zabbix. Alterações no núcleo serão permitidas apenas se houver defeito comprovado de compatibilidade, segurança, parser, exportação ou execução em MySQL.

### 3.3 Produção tratada como ambiente crítico

- Não executar `SELECT *` irrestrito em tabelas históricas ou transacionais.
- Consultar primeiro metadados, índices, cardinalidade estimada e retenção.
- Filtrar amostras pelo exercício vigente e por hosts selecionados.
- Marcar consultas potencialmente pesadas com `@heavy: true`.
- Não executar consultas pesadas na primeira rodada.
- Usar timeout por consulta.
- Preservar logs, manifestos e SQL executado.

### 3.4 Evidência e classificação

Toda conclusão deverá ser classificada como:

- **Declarada:** confirmada por documentação, configuração ou responsável técnico;
- **Observada:** comprovada diretamente pelos dados extraídos;
- **Inferida:** conclusão lógica apoiada por evidências;
- **Hipótese:** pendente de validação.

Relacionamentos funcionais não deverão ser afirmados somente por semelhança de nomes.

---

## 4. Escopo da descoberta

### 4.1 Ambiente e versão

Levantar:

- versão do MySQL;
- database selecionado;
- charset e collation;
- timezone do banco e da sessão;
- versão do schema do Zabbix, quando identificável;
- tamanho estimado do database;
- tabelas e views disponíveis;
- engine das tabelas;
- política e indícios de retenção.

### 4.2 Catálogo técnico

Levantar:

- tabelas;
- views;
- colunas;
- tipos de dados;
- nulabilidade;
- valores default;
- chaves primárias;
- chaves estrangeiras declaradas;
- índices;
- cardinalidade estimada;
- tamanho estimado por tabela;
- tabelas sem chave primária;
- tabelas de maior volume.

### 4.3 Inventário monitorado

Levantar:

- hosts ativos e desativados;
- nomes técnicos e nomes visíveis;
- grupos de hosts;
- tags de hosts;
- templates vinculados;
- interfaces;
- tipo de interface;
- endereço/IP/DNS, com cuidado para não expor dados além do necessário;
- proxy, quando aplicável;
- classificação de ativo;
- classificação física ou virtual;
- sistema operacional;
- Unidade;
- Prédio;
- Sala;
- Setor;
- Departamento.

### 4.4 Semântica do monitoramento

Identificar os itens e triggers usados para:

- ICMP;
- disponibilidade do agente Zabbix;
- disponibilidade SNMP;
- uptime;
- CPU;
- RAM;
- storage;
- rede;
- serviços Windows;
- sistema operacional;
- status e disponibilidade das interfaces;
- reinícios;
- falhas de comunicação;
- condições de degradação.

### 4.5 Eventos e recuperação

Descobrir como reconstruir:

- início do problema;
- evento de recuperação;
- horário de recuperação;
- duração;
- evento ainda aberto;
- host afetado;
- trigger ou item de origem;
- severidade;
- reconhecimento;
- correlação;
- supressão;
- dependência entre triggers;
- múltiplos eventos sobrepostos.

### 4.6 Manutenção

Levantar:

- janelas de manutenção;
- períodos;
- recorrência;
- hosts vinculados;
- grupos vinculados;
- tags ou filtros;
- supressão de problemas;
- possibilidade de distinguir manutenção programada de falha não planejada.

### 4.7 Amostras controladas

Selecionar e reconciliar ao menos:

- um servidor Windows que ficou indisponível;
- um servidor Linux que ficou indisponível;
- um switch que ficou indisponível;
- um Access Point que ficou indisponível;
- um reinício de servidor;
- um reinício de ativo SNMP, quando houver;
- um caso de ICMP indisponível com agente ou SNMP ainda respondendo;
- um caso de agente ou SNMP indisponível com ICMP respondendo;
- uma manutenção programada;
- um evento ainda aberto.

---

## 5. Fora do escopo

- construir o coletor produtivo via API;
- criar o PostgreSQL do BI;
- construir o modelo dimensional definitivo;
- criar o Power BI;
- alterar templates, hosts, itens, triggers ou manutenções no Zabbix;
- criar MCP;
- extrair todo o histórico bruto de todas as tabelas;
- calcular indicadores oficiais sem reconciliação;
- implantar MTTR, MTBF ou MTTF nesta fase;
- incluir Senior, PIMS ou outros sistemas de negócio.

---

## 6. Artefatos previstos

Os seguintes arquivos deverão ser criados no Generic SQL Extractor:

```text
sql/ZABBIX_BI_Fase0_Descoberta_MySQL.sql
docs/ZABBIX_BI_Fase0_GUIA.md
docs/ZABBIX_BI_Fase0_DICIONARIO.md
docs/ZABBIX_BI_Fase0_RELATORIO.md
CODEX_PROMPT_ZABBIX_FASE0.md
```

Saídas esperadas por execução:

```text
output/AAAAMMDD_HHMMSS/
├── csv/
├── sql/
├── execucao.json
├── manifesto.csv
└── manifesto.json

output/AAAAMMDD_HHMMSS.zip
logs/generic_sql_extractor_AAAAMMDD_HHMMSS.log
```

---

## 7. Plano de tarefas e acompanhamento

### 7.1 Governança e preparação

- [x] Confirmar o objetivo e o limite da Fase 0.
- [x] Confirmar MySQL como SGBD.
- [x] Confirmar o Generic SQL Extractor como ferramenta.
- [x] Confirmar que a arquitetura produtiva continuará usando a API.
- [x] Confirmar que o MCP não faz parte desta fase.
- [x] Definir o nome do database do Zabbix no MySQL: **zabbix**.
- [ ] Confirmar versão do Zabbix.
- [x] Confirmar versão do MySQL.
- [ ] Confirmar timezone oficial do ambiente.
- [ ] Confirmar que o usuário de banco possui somente privilégios de leitura.
- [x] Confirmar conectividade entre a estação de execução e o MySQL.
- [ ] Confirmar que a pasta de trabalho local não contém resultados antigos indevidos.

**Critério de saída:** ambiente e limites registrados sem exposição de credenciais.

### 7.2 Baseline do Generic SQL Extractor

- [x] Obter uma cópia local íntegra do extrator.
- [ ] Verificar a versão em `VERSAO.txt`.
- [ ] Conferir `SHA256SUMS.txt`, quando aplicável.
- [x] Ler `README.md`, `AGENTS.md` e testes relevantes.
- [x] Executar a suíte local sem conexão com o banco.
- [x] Confirmar baseline verde antes de qualquer alteração.
- [x] Criar branch ou worktree específica somente se houver repositório Git disponível.

**Critério de saída:** extrator íntegro e testes locais aprovados.

### 7.3 Configuração segura para MySQL

- [x] Criar `.env` local a partir de `.env.example`.
- [x] Configurar `DB_TYPE=mysql`.
- [x] Configurar host, porta, database e usuário localmente.
- [x] Não exibir nem versionar o conteúdo do `.env`.
- [x] Configurar `DB_SCHEMAS` ou equivalente para o database do Zabbix.
- [x] Configurar o pacote SQL da rodada no `EXTRACTOR_SQL_FILE`.
- [x] Configurar timeouts conservadores.
- [x] Executar `preflight`.
- [x] Confirmar conexão e transação somente leitura.
- [x] Confirmar que os testes continuam aprovados.

**Critério de saída:** preflight concluído sem credenciais expostas.

### 7.4 Construção do pacote SQL — Rodada 1: metadados leves

- [ ] Criar `sql/ZABBIX_BI_Fase0_Descoberta_MySQL.sql`.
- [ ] Incluir cabeçalho, objetivo, regras de segurança e identificação da fase.
- [ ] Criar consulta de versão e contexto da sessão.
- [ ] Criar consulta de charset, collation e timezone.
- [ ] Criar catálogo de tabelas e views.
- [ ] Criar catálogo de colunas.
- [ ] Criar catálogo de índices.
- [ ] Criar catálogo de constraints e relacionamentos declarados.
- [ ] Criar volumetria estimada por tabela.
- [ ] Criar ranking de tabelas por tamanho.
- [ ] Criar levantamento das tabelas sem chave primária.
- [ ] Marcar consultas de volumetria mais custosas como `@heavy: true`.
- [ ] Limitar saídas e ordenar de forma determinística.
- [ ] Validar o pacote com o parser do extrator.
- [ ] Listar as consultas usando a CLI antes da execução.

**Critério de saída:** pacote SQL válido, documentado e sem consultas transacionais amplas.

### 7.5 Execução da Rodada 1

- [ ] Executar sem `--include-heavy`.
- [ ] Conferir `manifesto.csv`.
- [ ] Confirmar ausência de `ERROR`.
- [ ] Confirmar consultas pesadas como `SKIPPED_HEAVY`.
- [ ] Conferir o snapshot do SQL executado.
- [ ] Conferir `execucao.json`.
- [ ] Verificar ausência de credenciais nos logs e saídas.
- [ ] Registrar duração e linhas por consulta.
- [ ] Preservar pasta e ZIP da remessa.

**Critério de saída:** primeira remessa íntegra, auditável e sem erros críticos.

### 7.6 Análise da Rodada 1

- [ ] Identificar tabelas candidatas de cadastro, monitoramento e eventos.
- [ ] Identificar tabelas de maior volume.
- [ ] Identificar índices adequados para consultas do exercício vigente.
- [ ] Identificar riscos de varredura.
- [ ] Identificar a retenção observável das tabelas históricas.
- [ ] Classificar relacionamentos como declarados, observados, inferidos ou hipóteses.
- [ ] Definir quais consultas podem avançar para a Rodada 2.
- [ ] Atualizar este checklist.

**Critério de saída:** mapa inicial de tabelas e riscos aprovado.

### 7.7 Construção do pacote SQL — Rodada 2: inventário e classificação

- [x] Criar consultas de hosts ativos e desativados.
- [x] Criar consultas de grupos de hosts.
- [x] Criar consultas de vínculo host-grupo.
- [x] Criar consultas de tags de hosts.
- [x] Criar consultas de templates vinculados.
- [x] Criar consultas de interfaces.
- [x] Identificar proxies, quando aplicável.
- [x] Extrair classificação de AP, switch, servidor físico e servidor virtual.
- [x] Extrair sistema operacional, quando disponível.
- [x] Avaliar Unidade, Prédio, Sala, Setor e Departamento, registrando lacunas comprovadas.
- [x] Criar relatório de hosts sem tipo.
- [x] Criar relatório de hosts sem localização completa.
- [x] Criar relatório de duplicidades ou classificações conflitantes.
- [x] Limitar saídas ao necessário para a descoberta.

**Critério de saída:** inventário reconciliável e classificação mensurável.

### 7.8 Construção do pacote SQL — Rodada 3: itens, triggers e semântica

- [x] Catalogar itens vinculados aos hosts do escopo.
- [x] Catalogar chaves de ICMP.
- [x] Catalogar disponibilidade do agente.
- [x] Catalogar disponibilidade SNMP.
- [x] Catalogar uptime.
- [x] Catalogar CPU.
- [x] Catalogar RAM.
- [x] Catalogar storage.
- [x] Catalogar rede.
- [x] Catalogar serviços Windows.
- [x] Catalogar sistema operacional.
- [x] Catalogar triggers.
- [x] Catalogar severidades.
- [x] Catalogar expressões e funções usadas nas triggers.
- [x] Catalogar dependências de triggers.
- [x] Identificar macros relevantes sem expor valores sensíveis.
- [x] Classificar itens como disponibilidade, saúde ou inventário.
- [x] Identificar diferenças entre templates por tipo de ativo.

**Critério de saída:** matriz item/trigger → papel no MVP documentada.

### 7.9 Construção do pacote SQL — Rodada 4: eventos e recuperação

- [x] Identificar as tabelas de eventos e problemas.
- [x] Mapear problema para evento de recuperação.
- [x] Identificar eventos ainda abertos.
- [x] Mapear evento para trigger.
- [x] Mapear trigger para host.
- [x] Identificar reconhecimentos.
- [x] Identificar correlações.
- [x] Identificar supressões.
- [x] Identificar severidade histórica.
- [x] Identificar dependências que possam evitar contagem duplicada.
- [x] Criar amostras limitadas ao exercício atual.
- [x] Criar consultas para detectar intervalos sobrepostos.
- [x] Criar consultas para detectar múltiplos sinais no mesmo intervalo.
- [x] Validar se início, fim e duração podem ser reconstruídos com segurança.

**Critério de saída:** modelo de reconstrução de indisponibilidade demonstrado com evidências.

### 7.10 Construção do pacote SQL — Rodada 5: manutenção e reinício

- [x] Identificar tabelas de manutenção.
- [x] Mapear manutenções para hosts, grupos ou tags, registrando a ausência observada de vínculos.
- [x] Identificar períodos e recorrência, registrando a ausência observada de configurações.
- [x] Identificar supressão associada, limitada pela ausência observada em `event_suppress`.
- [x] Verificar se manutenção programada pode ser diferenciada de falha; a amostra real permanece pendente.
- [x] Identificar itens de uptime por tipo de ativo.
- [x] Criar amostras de redução de uptime com oito itemids e janela de 14 dias.
- [x] Medir proximidade entre resets candidatos e eventos de indisponibilidade sem inferir causalidade.
- [x] Documentar limitações de classificação de reinícios.

**Critério de saída:** manutenção e reinício representados ou explicitamente classificados como lacuna.

### 7.11 Reconciliação com casos reais

- [ ] Selecionar amostras com o responsável pelo Zabbix.
- [ ] Reconciliar um servidor Windows.
- [ ] Reconciliar um servidor Linux.
- [ ] Reconciliar um switch.
- [ ] Reconciliar um Access Point.
- [ ] Reconciliar um reinício.
- [ ] Reconciliar um evento aberto.
- [ ] Reconciliar uma manutenção programada.
- [ ] Comparar os dados do banco com a interface do Zabbix.
- [ ] Comparar os dados do banco com a API do Zabbix, quando possível.
- [ ] Registrar divergências e hipóteses.
- [ ] Validar ou ajustar a janela de confirmação.
- [ ] Validar ou ajustar a regra `ICMP + agente` para servidores.
- [ ] Validar ou ajustar a regra `ICMP + SNMP` para APs e switches.

**Critério de saída:** regras conceituais confirmadas ou corrigidas por evidência.

### 7.12 Base de conhecimento e documentação

- [ ] Criar `docs/ZABBIX_BI_Fase0_GUIA.md`.
- [ ] Criar `docs/ZABBIX_BI_Fase0_DICIONARIO.md`.
- [ ] Criar `docs/ZABBIX_BI_Fase0_RELATORIO.md`.
- [ ] Documentar tabelas e relacionamentos relevantes.
- [ ] Documentar itens e triggers relevantes.
- [ ] Documentar retenção e limitações.
- [ ] Documentar regras de indisponibilidade aprovadas.
- [ ] Documentar campos necessários na API.
- [ ] Documentar riscos de performance.
- [ ] Documentar qualidade e lacunas.
- [ ] Criar `CODEX_PROMPT_ZABBIX_FASE0.md`.
- [ ] Atualizar este checklist com evidências e caminhos.

**Critério de saída:** documentação suficiente para outro desenvolvedor reproduzir a descoberta.

### 7.13 Adendo técnico à SPEC do MVP

- [ ] Atualizar versão e autenticação do Zabbix.
- [ ] Atualizar timezone.
- [ ] Atualizar retenção disponível.
- [ ] Atualizar modelo de eventos e recuperação.
- [ ] Atualizar identificação de manutenção programada.
- [ ] Atualizar regra de reinícios.
- [ ] Atualizar aplicabilidade do MTTF.
- [ ] Atualizar janela de confirmação.
- [ ] Atualizar riscos e premissas.
- [ ] Registrar decisões técnicas definitivas.

**Critério de saída:** SPEC conceitual complementada por evidência técnica.

### 7.14 Gate para `writing-plans`

- [ ] Confirmar que não há `ERROR` nas remessas oficiais.
- [ ] Confirmar que consultas pesadas foram justificadas e controladas.
- [ ] Confirmar que os dados do exercício atual estão disponíveis.
- [ ] Confirmar que hosts podem ser classificados por tipo e localização.
- [x] Confirmar que eventos podem ser ligados a recuperações.
- [x] Confirmar que intervalos técnicos candidatos podem ser reconstruídos.
- [x] Confirmar a estrutura técnica de manutenção e declarar a ausência de caso observado para aprovação funcional.
- [x] Confirmar que resets de uptime candidatos podem ser detectados, sem promovê-los a reinícios oficiais.
- [ ] Confirmar que a API possui os objetos necessários para produção.
- [ ] Aprovar o Relatório Final da Fase 0.
- [ ] Aplicar a skill `writing-plans`.

**Critério de saída:** incertezas críticas removidas e plano técnico autorizado.

---

## 8. Pacote mínimo da primeira rodada

A primeira execução deverá ser exclusivamente de metadados leves.

Consultas mínimas:

1. contexto e versão da sessão;
2. charset, collation e timezone;
3. tabelas e views;
4. colunas;
5. índices;
6. constraints declaradas;
7. estimativa de linhas;
8. tamanho estimado por tabela;
9. tabelas sem chave primária;
10. possíveis tabelas do Zabbix por nomenclatura, sem afirmar semântica.

Não deverá consultar histórico detalhado, eventos, problemas, trends ou history na primeira execução.

---

## 9. Critérios de aceite da Fase 0

A Fase 0 será considerada concluída quando:

1. o extrator estiver configurado para MySQL com usuário somente leitura;
2. o preflight estiver aprovado;
3. as remessas oficiais não possuírem erro crítico;
4. o catálogo do banco estiver documentado;
5. hosts, grupos, tags, templates e interfaces estiverem mapeados;
6. a hierarquia `Unidade > Prédio > Sala > Setor > Departamento` estiver avaliada;
7. os itens e triggers relevantes estiverem identificados;
8. o relacionamento problema-recuperação estiver comprovado;
9. manutenção e supressão estiverem avaliadas;
10. reinícios estiverem avaliados;
11. pelo menos uma amostra de cada tipo principal estiver reconciliada;
12. as regras de indisponibilidade estiverem confirmadas ou ajustadas;
13. as limitações de retenção estiverem documentadas;
14. o mapeamento banco → API estiver definido;
15. o adendo técnico da SPEC estiver aprovado;
16. o projeto estiver pronto para `writing-plans`.

---

## 10. Entregáveis finais

- pacote SQL da Fase 0;
- CSVs das remessas oficiais;
- manifestos CSV e JSON;
- logs;
- snapshots dos SQLs;
- ZIPs das remessas;
- guia de execução;
- dicionário técnico;
- relatório de descoberta;
- matriz de itens e triggers;
- matriz de classificação de ativos e localização;
- mapa de eventos e recuperação;
- análise de manutenção;
- análise de reinícios;
- reconciliação de amostras;
- adendo técnico da SPEC;
- prompt operacional para o Codex;
- checklist integralmente atualizado.

---

## 11. Registro de progresso

### Estado atual

**Status:** Fase 0 em execução; Rodadas 1, 2, 3, 4 e 5 concluídas.  
**Último avanço:** manutenção, supressão e resets candidatos de uptime avaliados nas remessas oficiais `20260814_205026` e `20260814_205609`, ambas com 0 `ERROR`, oito itemids e janela histórica de 14 dias.  
**Próxima ação:** reconciliar casos reais de manutenção e reinício com o responsável pelo Zabbix, a interface e a API, sem promover proximidade temporal ou redução de uptime a causalidade oficial.

### Histórico de atualizações

| Data | Versão | Alteração |
|---|---:|---|
| 31/07/2026 | 1.0 | Criação da SPEC, confirmação do MySQL e abertura do checklist. |
| 31/07/2026 | 1.1 | Confirmação do database `zabbix` e atualização do checklist de preparação. |
| 14/08/2026 | 1.2 | Conclusão das Rodadas 1 e 2; inventário/classificação documentados e lacunas de localização/views registradas. |
| 14/08/2026 | 1.3 | Conclusão da Rodada 3; vocabulário de itens/triggers, cobertura por classe e hipóteses estruturais documentados. |
| 14/08/2026 | 1.4 | Conclusão da Rodada 4; modelo candidato problema → recuperação → trigger → host, qualidade e sobreposições documentados. |
| 14/08/2026 | 1.5 | Conclusão da Rodada 5; estruturas de manutenção/supressão e resets candidatos de uptime documentados sem aprovação funcional de reboot. |

---

## 12. Próxima ação operacional

Executar a reconciliação com casos reais prevista na seção 7.11, priorizando:

- uma manutenção programada comprovada na interface ou pela equipe responsável;
- um reinício conhecido de servidor com `system.uptime`;
- um reset conhecido de ativo SNMP, distinguindo equipamento e subsistema de gerenciamento;
- comparação dos mesmos casos entre banco, interface Zabbix e API;
- validação funcional sem transformar os candidatos técnicos das Rodadas 4 e 5 em indicadores oficiais.

As credenciais devem permanecer somente no `.env` local e nunca devem ser enviadas ao chat, Google Drive ou repositório.
