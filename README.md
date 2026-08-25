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
- Rodada 6 — reconciliação semântica com casos reais: **pausada**.
- Próxima frente: ETL mínimo funcional + PostgreSQL + primeira visualização no Power BI.

## Princípio semântico atual

A primeira versão trabalha com o conceito explícito de:

`INDISPONIBILIDADE_OBSERVADA`

Não classificar automaticamente uma janela como reboot, manutenção, falha de rede, falha de agente, falha SNMP, queda elétrica ou causa raiz sem evidência posterior.

Da mesma forma, `RESET_UPTIME_CANDIDATO` não equivale a `REBOOT`.

## Estrutura

```text
docs/      documentação, SPECs, relatório cumulativo e base de conhecimento
sql/       pacotes SQL controlados das Rodadas 1–5
prompts/   prompts históricos de execução das rodadas
```

A referência consolidada para continuidade é `docs/BASE-CONHECIMENTO-ZABBIX-BI003.md`.

## Origem da migração

Os artefatos da Fase 0 foram originalmente produzidos no repositório `esh-gilmar/sql_extractor`, que continua preservado como histórico do Generic SQL Extractor. O desenvolvimento do produto BI-003 passa a ser concentrado neste repositório.
