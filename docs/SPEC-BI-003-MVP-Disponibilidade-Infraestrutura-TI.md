# SPEC BI-003 — MVP de Disponibilidade da Infraestrutura de TI

**Projeto:** Desenvolvimento dos Dashboards do GLPI  
**Produto:** Dashboard de Disponibilidade da Infraestrutura de TI  
**Fontes principais:** Zabbix, PostgreSQL e Power BI  
**Versão:** 1.0  
**Data:** 30/07/2026  
**Status:** DESENHO CONCEITUAL APROVADO — PRONTO PARA PLANEJAMENTO TÉCNICO

---

## 1. Objetivo

Construir um MVP rápido, confiável e evolutivo para medir e apresentar a disponibilidade da infraestrutura de TI, utilizando o Zabbix como fonte oficial dos eventos técnicos, uma base histórica própria em PostgreSQL e o Power BI como camada de visualização.

O MVP deverá permitir o acompanhamento da disponibilidade geral, por tipo de ativo, por localização e por equipamento, além dos indicadores de confiabilidade e recuperação.

---

## 2. Problema

O Zabbix já monitora os ativos e componentes da infraestrutura, porém os dados estão orientados ao monitoramento técnico e não a uma visão executiva consolidada.

O gestor de TI solicitou uma visão hierárquica da disponibilidade da TI. O desenho futuro deverá partir da disponibilidade geral, separar sistemas e infraestrutura e permitir drill-down até sistemas e ativos específicos.

Para reduzir risco e acelerar a entrega, o primeiro MVP será restrito à infraestrutura. Senior, PIMS e outros sistemas serão tratados em uma evolução posterior.

---

## 3. Escopo

### 3.1 Incluído

- Access Points;
- switches;
- servidores físicos;
- servidores virtuais;
- servidores Windows;
- servidores Linux.

### 3.2 Monitoramento disponível

#### Windows

- CPU;
- RAM;
- storage;
- services;
- network;
- uptime;
- sistema operacional.

#### Linux

- CPU;
- RAM;
- storage;
- network;
- uptime;
- sistema operacional.

#### Switches e APs

- ICMP;
- SNMP;
- indicadores dos templates atuais do Zabbix.

### 3.3 Fora do escopo inicial

- Senior;
- PIMS;
- demais sistemas;
- no-breaks;
- integração obrigatória com chamados do GLPI;
- ponderação por criticidade;
- previsão de falhas;
- alteração da configuração produtiva do Zabbix.

---

## 4. Arquitetura aprovada

```text
API do Zabbix — somente leitura
            ↓
Coletor Python com carga incremental diária
            ↓
Camada bruta de hosts, grupos, tags, itens, triggers e eventos
            ↓
Camada tratada de indisponibilidade, falhas e saúde operacional
            ↓
PostgreSQL
            ↓
Modelo semântico
            ↓
Power BI
```

### 4.1 Responsabilidades

**Zabbix:** fonte oficial de eventos técnicos, hosts, grupos, tags, ICMP, agente, SNMP, uptime, itens e triggers.

**Coletor Python:** autenticação, paginação, extração incremental, retry controlado, normalização, persistência, reprocessamento, idempotência e controle das execuções.

**PostgreSQL:** armazenamento histórico, camada bruta, camada tratada, consolidação diária e mensal e suporte ao modelo dimensional.

**Power BI:** visão executiva, drill-down, filtros, métricas, análise por tipo, localização e ativo.

**GLPI:** fora do caminho crítico do MVP; poderá enriquecer futuramente o modelo com patrimônio, responsáveis, chamados, causas, soluções, SLA, fornecedores e impacto.

---

## 5. Período e frequência

### 5.1 Período padrão

O dashboard deverá usar o exercício atual:

```text
Data inicial: 01/01 do ano vigente
Data final: data da última atualização válida
```

A base poderá preservar exercícios anteriores, mas o filtro padrão abrirá no exercício vigente.

### 5.2 Frequência

- atualização diária;
- carga incremental;
- reprocessamento por período;
- falha de carga não poderá apagar dados anteriores.

---

## 6. Hierarquias

### 6.1 Tipo de ativo

```text
Infraestrutura
├── Access Points
├── Switches
├── Servidores físicos
└── Servidores virtuais
```

### 6.2 Localização

```text
Unidade
└── Prédio
    └── Sala
        └── Setor
            └── Departamento
                └── Ativo
```

Grupos e tags do Zabbix serão utilizados para classificar equipamento e localização. A solução não dependerá apenas do nome dos hosts.

---

## 7. Disponibilidade e saúde operacional

Disponibilidade e saúde operacional serão tratadas separadamente.

- **Disponibilidade:** ativo online ou offline.
- **Saúde operacional:** normal, atenção ou crítico.

CPU, RAM, storage, services, interfaces e outros indicadores não reduzirão automaticamente a disponibilidade, salvo quando uma regra aprovada determinar impacto real.

---

## 8. Regras conceituais de indisponibilidade

### 8.1 Servidores

```text
Servidor indisponível =
ICMP indisponível
E agente Zabbix indisponível
durante uma janela mínima de confirmação
```

Interpretações:

- ICMP indisponível e agente ativo: possível problema de rota, firewall ou teste;
- agente indisponível e ICMP ativo: problema no agente ou no sistema operacional;
- CPU, RAM ou storage críticos: degradação;
- redução do uptime: evento de reinício;
- serviço parado: indisponibilidade funcional somente quando o serviço estiver formalmente classificado como crítico.

### 8.2 Switches e Access Points

```text
Ativo indisponível =
ICMP indisponível
E SNMP indisponível
durante uma janela mínima de confirmação
```

Interpretações:

- ICMP indisponível e SNMP ativo: possível falha de teste;
- ICMP ativo e SNMP indisponível: problema de gerenciamento;
- saturação, erros ou perda em interfaces: degradação;
- redução do uptime SNMP: evento de reinício.

### 8.3 Janela de confirmação

A janela será parametrizável e validada com eventos reais. A referência inicial para validação será entre 3 e 5 minutos, sem caráter definitivo.

---

## 9. Operação e manutenção

- todos os ativos serão considerados 24x7;
- manutenção programada contará como indisponibilidade;
- manutenção programada não contará como falha para MTTR, MTBF ou MTTF.

---

## 10. Fórmulas e KPIs

### 10.1 Disponibilidade por ativo

```text
Disponibilidade % =
(Tempo previsto - Tempo indisponível)
÷ Tempo previsto
× 100
```

Regras:

- consolidar intervalos sobrepostos;
- não contar o mesmo período duas vezes;
- excluir ativos desativados ou fora de escopo;
- lacuna de coleta deverá ser tratada como problema de qualidade, não como indisponibilidade automática.

### 10.2 Disponibilidade geral

Média aritmética simples da disponibilidade dos ativos válidos.

Não haverá ponderação por criticidade no MVP. A visão geral deverá ser acompanhada da abertura por tipo de ativo.

### 10.3 MTTR

**Mean Time to Repair/Recover — Tempo Médio para Reparo ou Recuperação**

```text
MTTR =
Soma das durações das falhas não planejadas encerradas
÷ Quantidade de falhas não planejadas encerradas
```

- somente falhas encerradas;
- excluir falhas abertas;
- excluir manutenção programada;
- consolidar sobreposições.

### 10.4 MTBF

**Mean Time Between Failures — Tempo Médio Entre Falhas**

Aplicável a ativos reparáveis.

```text
MTBF =
Tempo total em operação
÷ Quantidade de falhas não planejadas
```

```text
Tempo total em operação =
Tempo previsto - Tempo indisponível não planejado
```

Quanto maior, maior a estabilidade.

### 10.5 MTTF

**Mean Time to Failure — Tempo Médio Até a Falha**

Aplicável principalmente a componentes ou ativos não reparáveis, substituídos ou retirados após falha definitiva.

```text
MTTF =
Soma do tempo de funcionamento até a falha definitiva
÷ Quantidade de itens com falha definitiva
```

- exibir somente quando houver dados válidos;
- não substituir MTBF em ativos reparáveis;
- dependerá de informação de substituição, descarte ou retirada.

### 10.6 Tempo até a primeira falha do exercício

```text
Tempo até a primeira falha =
Data/hora da primeira falha válida
- 01/01 do exercício
```

Este indicador não deverá ser denominado MTTF.

---

## 11. Eventos de reinício

Serão identificados pela redução ou zeragem do uptime.

Objetivos:

- identificar reinícios inesperados;
- relacionar reinícios com indisponibilidades;
- diferenciar queda de rede de reinicialização;
- apoiar análise de estabilidade e causa.

O reinício não será automaticamente classificado como falha.

---

## 12. Modelo mínimo de dados

### 12.1 Dimensões

#### Dim_Ativo

- identificador interno;
- hostid do Zabbix;
- nome técnico;
- nome visível;
- tipo de ativo;
- físico ou virtual;
- sistema operacional;
- status;
- data de ativação;
- data de desativação;
- grupos;
- tags;
- unidade;
- prédio;
- sala;
- setor;
- departamento.

#### Dim_Tipo_Ativo

- tipo;
- categoria;
- descrição.

#### Dim_Localizacao

- unidade;
- prédio;
- sala;
- setor;
- departamento;
- chave hierárquica.

#### Dim_Calendario

- data;
- dia;
- mês;
- trimestre;
- exercício;
- início do exercício;
- indicador de período atual.

#### Dim_Metrica

- métrica;
- unidade de medida;
- classe;
- disponibilidade ou saúde;
- origem.

### 12.2 Fatos de negócio

#### Fato_Indisponibilidade

- ativo;
- início;
- término;
- duração;
- planejada;
- status aberto ou encerrado;
- regra aplicada;
- evento de origem;
- trigger de origem;
- severidade;
- observação técnica.

#### Fato_Falha

- ativo;
- início da falha;
- fim da falha;
- duração;
- retorno à operação;
- falha definitiva;
- tipo de falha;
- planejada;
- evento relacionado;
- indisponibilidade relacionada.

#### Fato_Disponibilidade_Diaria

- ativo;
- data;
- tempo previsto;
- tempo disponível;
- tempo indisponível planejado;
- tempo indisponível não planejado;
- disponibilidade percentual;
- quantidade de indisponibilidades;
- quantidade de falhas;
- indicador de dado completo.

#### Fato_Saude_Ativo

- ativo;
- data/hora;
- métrica;
- valor;
- unidade;
- estado;
- severidade;
- trigger de origem.

#### Fato_Reinicio

- ativo;
- data/hora do reinício;
- uptime anterior;
- uptime posterior;
- provável classificação;
- indisponibilidade relacionada;
- origem.

### 12.3 Controle técnico

#### Controle_Execucao_Carga

Não é fato de negócio.

- identificador da execução;
- data/hora de início;
- data/hora de fim;
- status;
- etapa;
- registros lidos;
- registros inseridos;
- registros atualizados;
- registros rejeitados;
- marcador incremental;
- período processado;
- mensagem de erro;
- versão do coletor.

---

## 13. KPIs do MVP

### Disponibilidade

- disponibilidade geral;
- disponibilidade por tipo;
- disponibilidade por unidade, prédio, sala, setor e departamento;
- disponibilidade por ativo;
- tempo total indisponível;
- quantidade de indisponibilidades;
- maior indisponibilidade;
- evolução diária;
- evolução mensal.

### Confiabilidade e recuperação

- MTTR;
- MTBF;
- MTTF, quando aplicável;
- tempo até a primeira falha do exercício;
- quantidade de falhas;
- ativos com maior reincidência;
- ativos com menor MTBF;
- ativos com maior MTTR;
- reinícios inesperados.

### Saúde operacional

- CPU;
- RAM;
- storage;
- network;
- services;
- uptime;
- sistema operacional;
- normal, atenção ou crítico;
- quantidade e duração de condições críticas.

Os limites deverão respeitar os templates, triggers e regras vigentes no Zabbix.

---

## 14. Páginas do Power BI

### 14.1 Visão executiva

- disponibilidade geral;
- tempo total indisponível;
- quantidade de falhas;
- MTTR;
- MTBF;
- MTTF quando aplicável;
- evolução mensal;
- comparação por tipo;
- data e status da última carga válida.

### 14.2 Disponibilidade por localização

Hierarquia:

```text
Unidade > Prédio > Sala > Setor > Departamento > Ativo
```

### 14.3 Disponibilidade por tipo

- APs;
- switches;
- servidores físicos;
- servidores virtuais;
- ranking;
- MTTR;
- MTBF;
- reincidência.

### 14.4 Detalhamento do ativo

- cadastro técnico;
- localização;
- disponibilidade diária e mensal;
- períodos de indisponibilidade;
- falhas;
- MTTR;
- MTBF;
- MTTF quando aplicável;
- reinícios;
- saúde operacional;
- eventos relacionados.

### 14.5 Qualidade da informação

- última carga válida;
- cargas com erro;
- registros rejeitados;
- lacunas;
- ativos sem classificação;
- eventos sem correlação;
- cobertura do período.

---

## 15. Meta anual

A meta será parametrizável por exercício conforme o planejamento anual.

Enquanto não houver meta definida:

- apresentar a linha de base;
- não classificar automaticamente como atingido ou não atingido;
- indicar que a meta do exercício não foi informada.

Estrutura esperada:

```text
Exercício | Tipo de escopo | Escopo | Meta %
```

---

## 16. Requisitos não funcionais

- API do Zabbix em modo somente leitura;
- credenciais fora do código;
- logs sem segredos;
- carga idempotente;
- reprocessamento seguro;
- tolerância a falhas temporárias;
- paginação;
- timeout e retry controlados;
- deduplicação;
- auditoria;
- versionamento;
- testes automatizados;
- documentação das regras;
- rastreabilidade até o evento de origem;
- Power BI sem acesso direto ao banco produtivo do Zabbix.

---

## 17. Critérios de aceite

1. Classificação automática por grupos e tags.
2. Hierarquia Unidade > Prédio > Sala > Setor > Departamento.
3. Exercício atual carregado desde 01/01.
4. Atualização diária incremental.
5. Reexecução sem duplicidade.
6. Amostras reconciliadas com o Zabbix.
7. Regras específicas para servidores, switches e APs.
8. Janela de confirmação parametrizada.
9. Sobreposições consolidadas.
10. Disponibilidade separada da saúde.
11. Manutenção programada reduz disponibilidade.
12. Manutenção programada não entra em MTTR, MTBF ou MTTF.
13. Falhas abertas fora do MTTR.
14. MTTF exibido somente quando aplicável.
15. Drill-down por tipo, localização e ativo.
16. Falha de coleta sem perda de dados anteriores.
17. Última atualização e qualidade visíveis.
18. Meta anual parametrizável.
19. Filtro padrão no exercício vigente.
20. Evidência de testes automatizados e reconciliação.

---

## 18. Pontos técnicos em aberto

- versão do Zabbix;
- método de autenticação;
- endpoints necessários;
- timezone oficial;
- retenção disponível;
- valor definitivo da janela de confirmação;
- ambiente PostgreSQL;
- agendamento;
- nomenclatura física das tabelas;
- política de retenção;
- tratamento de hosts desativados;
- identificação formal de manutenção programada;
- dados disponíveis para falha definitiva e MTTF;
- publicação, gateway e atualização do Power BI;
- responsáveis técnicos e operacionais.

---

## 19. Evoluções previstas

### Sistemas

- PIMS;
- Senior;
- demais serviços;
- composição por componentes;
- disponível, degradado e indisponível.

### Integração GLPI

- patrimônio;
- responsáveis;
- chamados;
- causa;
- solução;
- SLA;
- fornecedor;
- reincidência;
- impacto.

### Governança e inteligência

- criticidade;
- pesos;
- metas por escopo;
- previsão de falhas;
- capacidade;
- recomendações;
- priorização de investimentos.

---

## 20. Aprovação e próxima etapa

O desenho conceitual foi aprovado.

A próxima etapa é produzir o plano de implementação técnico, decompondo esta SPEC em tarefas executáveis, testes, dependências, arquivos previstos, checkpoints, commits e critérios de conclusão.
