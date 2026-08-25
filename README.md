# Zabbix Disponibilidade — BI-003

Repositório dedicado ao MVP de **Disponibilidade da Infraestrutura de TI**.

## Objetivo

Transformar sinais técnicos do Zabbix em uma visão analítica de **indisponibilidade observada**, com histórico próprio e consumo pelo Power BI.

Arquitetura alvo:

```text
Zabbix API (somente leitura)
        ↓
ETL Python incremental
        ↓
PostgreSQL
        ↓
Power BI
```

O acesso direto ao MySQL do Zabbix foi utilizado na **Fase 0 — descoberta técnica**, para comprovar estrutura, relacionamentos, itens, triggers, eventos, recuperação, manutenção e sinais de uptime. Ele não substitui a arquitetura produtiva via API.

## Estado do projeto

- Fase 0 — Rodadas 1 a 5: concluídas e documentadas.
- Rodada 6 — reconciliação com casos reais: **preparada e pendente dos casos de entrada**.
- A reconciliação de causa/manutenção/reboot não bloqueia a construção da primeira camada de `INDISPONIBILIDADE_OBSERVADA`.
- Próxima frente de produto: contrato de extração, ETL incremental, PostgreSQL e primeira visualização no Power BI.

## Princípio semântico atual

A primeira versão trabalha com o conceito explícito de:

```text
INDISPONIBILIDADE_OBSERVADA
```

Não classificar automaticamente uma janela como reboot, manutenção, falha de rede, falha de agente, falha SNMP, queda elétrica ou causa raiz sem evidência posterior.

Da mesma forma:

```text
RESET_UPTIME_CANDIDATO ≠ REBOOT_VALIDADO
```

Intervalos simultâneos do mesmo host também não devem ter suas durações simplesmente somadas: a camada analítica deverá realizar união temporal para evitar dupla contagem.

## Estrutura

```text
docs/                    documentação, SPECs, relatório e base de conhecimento
docs/archive/codex/      prompts históricos das Rodadas 2–6
sql/                     pacotes SQL controlados das Rodadas 1–5
```

Referências principais para continuidade:

- `docs/BASE-CONHECIMENTO-ZABBIX-BI003.md` — referência técnica consolidada;
- `docs/SPEC-BI-003-MVP-Disponibilidade-Infraestrutura-TI.md` — escopo do MVP;
- `docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md` — governança e checklist da descoberta;
- `docs/ZABBIX_BI_Fase0_RELATORIO.md` — evidências acumuladas das Rodadas 1–5;
- `docs/MIGRACAO-Fase0-sql_extractor.md` — manifesto da migração.

## Origem da migração

Os artefatos da Fase 0 foram originalmente produzidos no repositório `esh-gilmar/sql_extractor`, que continua preservado como histórico do Generic SQL Extractor. O desenvolvimento do produto BI-003 passa a ser concentrado neste repositório.

Resultados brutos, credenciais, `.env`, CSVs, logs e ZIPs de remessa não fazem parte deste repositório.
