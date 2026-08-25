# Migração da Fase 0 — `sql_extractor` → `zabbix-disponibilidade`

## Objetivo

Centralizar no repositório `esh-gilmar/zabbix-disponibilidade` os artefatos específicos do BI-003 produzidos durante a descoberta técnica do Zabbix, mantendo o `esh-gilmar/sql_extractor` como histórico da ferramenta genérica de extração.

## Origem congelada

Baseline de origem utilizado na migração:

```text
Repositório: esh-gilmar/sql_extractor
Branch: feat/bi-003-zabbix-fase0-round6-reconciliation
```

## Artefatos migrados

### SQLs

```text
sql/ZABBIX_BI_Fase0_Descoberta_MySQL.sql
sql/ZABBIX_BI_Fase0_Rodada2_Inventario_MySQL.sql
sql/ZABBIX_BI_Fase0_Rodada3_Semantica_Monitoramento_MySQL.sql
sql/ZABBIX_BI_Fase0_Rodada4_Eventos_Recuperacao_MySQL.sql
sql/ZABBIX_BI_Fase0_Rodada5_Manutencao_Reinicios_MySQL.sql
```

Não existe SQL da Rodada 6 no baseline de origem. A Rodada 6 foi preparada documentalmente, mas depende da identificação de casos reais antes da criação do pacote específico.

### Documentação principal

```text
docs/BASE-CONHECIMENTO-ZABBIX-BI003.md
docs/SPEC-BI-003-MVP-Disponibilidade-Infraestrutura-TI.md
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
docs/SPEC-BI-003-Fase-0-Rodada-2-Inventario-Classificacao.md
docs/SPEC-BI-003-Fase-0-Rodada-3-Itens-Triggers-Semantica.md
docs/SPEC-BI-003-Fase-0-Rodada-4-Eventos-Recuperacao-Intervalos.md
docs/SPEC-BI-003-Fase-0-Rodada-5-Manutencao-Supressao-Reinicios.md
docs/SPEC-BI-003-Fase-0-Rodada-6-Reconciliacao-Casos-Reais.md
docs/ZABBIX_BI_Fase0_RELATORIO.md
```

### Prompts históricos Codex

Os prompts específicos das Rodadas 2–6 foram preservados em:

```text
docs/archive/codex/
```

Eles continuam apontando para o fluxo antigo do `sql_extractor` e são mantidos somente como trilha histórica.

Não foi localizado um prompt Zabbix específico da Rodada 1 no baseline final de origem.

## Artefatos deliberadamente não migrados

Não são versionados no novo repositório:

- `.env` e credenciais;
- CSVs de execução;
- ZIPs das remessas;
- logs;
- `execucao.json` e manifestos brutos das execuções;
- screenshots potencialmente sensíveis;
- respostas brutas da API;
- código genérico do `sql_extractor` que não pertence ao produto BI-003.

Esses itens permanecem locais ou no histórico operacional apropriado. O `.gitignore` do novo repositório reforça essa separação.

## Estado funcional transferido

A migração preserva como baseline técnico:

- Rodadas 1–5 concluídas;
- reconstrução candidata `problema → recuperação → trigger → item → host` comprovada;
- necessidade de união temporal de intervalos para evitar dupla contagem;
- severidade histórica deve ser preservada;
- `problem` não deve ser usado isoladamente como histórico completo;
- manutenção/supressão ainda requer caso real para validação funcional;
- `RESET_UPTIME_CANDIDATO` não equivale automaticamente a reboot;
- regras uniformes `ICMP + agente` para servidores e `ICMP + SNMP` para switches não são suportadas pela configuração observada em toda a frota;
- arquitetura produtiva permanece `Zabbix API → Python → PostgreSQL → Power BI`.

## Continuidade

O novo repositório passa a ser a origem do desenvolvimento do produto de disponibilidade. O `sql_extractor` permanece como repositório histórico e ferramenta de descoberta, sem necessidade de apagar os commits ou branches já existentes.
