# 🛡️ MCP-Shield: Roadmap Estratégico e Relatório de Benchmark (mcpsec)

Este documento define a trajetória técnica do **arbiter**, consolidando o desempenho atual e o plano de evolução dividido em quatro pilares: **Segurança de Deep-Filtering**, **Funcionalidades de Produto**, **Escala Kubernetes-Native** e **Arquitetura Híbrida**.

---

## 🎯 Ordem de Execução

O benchmark com score 4.38/100 deixa claro que o modelo de regex pura não é uma camada de segurança — é um filtro de texto. Antes de adicionar features, o foundation precisa ser sólido.

| Fase | Itens | Justificativa |
| :--- | :--- | :--- |
| **Fase 1 — Foundation** | 2.3 (mcpsec), 2.1 (Schema), 2.2 (Scan Avançado) | P2 em 0%, encoding bypass, unicode — gaps que invalidam o produto como "security gateway" |
| **Fase 2 — Diferenciadores** | 3.7 (HITL), 3.10 (Shadow), 3.11 (Time-Travel), 2.12 (Sigstore), 3.13 (CloudEvents) | Alto valor, segurança de supply chain e integração enterprise (SIEM/Webhook) |
| **Fase 3 — Produto** | 3.1 (Federation), 3.2 (OAuth), 3.4 (Dashboard), 3.5 (Custos), 3.14 (OpenAI Bridge), 3.15 (OpenLineage) | Expansão de mercado, compatibilidade e linhagem de dados (GDPR/LGPD) |
| **Fase 4 — Enterprise** | 2.4 (Dynamic Rules), 2.6 (OPA), 2.9 (SPIFFE), 2.11 (Merkle), 4.x (K8s) | Só faz sentido com adoção real e infraestrutura complexa |
| **Fase 5 — Exploratório** | 2.5 (WASM Plugins), 2.7 (MCP Full-Spec), 2.10 (Honey-Tools), 3.3, 3.6, 3.8, 3.9, 3.12 | Extensibilidade e edge cases sem sair do escopo do proxy |

---


## 📊 1. Relatório de Benchmark Oficial (mcpsec v1.0.0)
**Data:** 29 de Março de 2026 | **Versão:** 0.7.0 | **Score:** **4.38 / 100** (🔴 Unsafe)

O benchmark inicial serviu como um "stress test" para a infraestrutura de rede, provando que o motor Rust é rápido e estável, mas que a filtragem baseada puramente em Regex é vulnerável a ataques de codificação e evasão.

| Propriedade de Segurança | Score | Status | Diagnóstico |
| :--- | :--- | :--- | :--- |
| **P1: Tool-Level Access Control** | 0% | ❌ | Falta de controle granular e isolamento por agente. |
| **P2: Parameter Constraint Enforcement** | 0% | ❌ | Ausência de validação contra JSON Schema. |
| **P4: Injection Resistance** | 6.25% | ⚠️ | Bloqueia texto puro, mas falha contra Base64/URL-encoding. |
| **P5: Schema Integrity** | 8.33% | ⚠️ | O gateway não impede mutações de esquema em tempo de execução. |
| **P6: Response Confidentiality** | 6.25% | ⚠️ | Filtro de resposta ignora segredos codificados. |
| **P9: Unicode Normalization** | 7.69% | ⚠️ | Vulnerável a ataques de homóglifos Unicode. |
| **P10: Temporal Consistency** | 25% | ✅ | Boa resistência a ataques de DoS por volume. |

---

## 🛡️ 2. Roadmap de Segurança e Hardening (O Caminho para o 100/100)

### 2.1. Schema Validation (Validação de Argumentos) `[Fase 1]`
*   **O que envolve:** Antes de enviar uma chamada para o servidor, o gateway valida se os argumentos passados pelo agente batem com o JSON Schema que o servidor anunciou. Isso evita que o agente envie dados malformados ou ataques de estouro de memória.
*   **Estimativa de Código:** ~200 a 300 linhas de Rust.
*   **Mudanças Principais:** Integrar a crate `jsonschema`, extrair os esquemas durante o `tools/list` (que agora precisaria ser cacheado pelo gateway) e adicionar um passo de validação no `handle` da chamada.
*   **Complexidade:** Média/Baixa (a crate `jsonschema` faz o trabalho pesado).

### 2.2. Scan de Vulnerabilidades (Segurança Avançada) `[Fase 1]`
*   **O que envolve:** Ir além do regex simples. Analisar se o código retornado ou os argumentos contêm padrões de injeção de SQL, Path Traversal ou comandos de shell maliciosos de forma heurística. Inclui **encoding-awareness** — detectar padrões sensíveis codificados em Base64, URL-encoding e Unicode normalizado antes de aplicar os filtros.
*   **Estimativa de Código:** ~300 a 500 linhas de Rust.
*   **Mudanças Principais:** Implementar um motor de regras mais complexo (usando YARA ou uma DSL de segurança) e integrar com o pipeline de `PayloadFilterMiddleware`. Adicionar etapa de normalização/decode antes da avaliação de regex — resolve diretamente P4, P6 e P9 do benchmark.
*   **Complexidade:** Média/Alta.

### 2.3. ~~Benchmark com mcpsec~~ → Suite de Testes de Segurança Interna `[Fase 1 — ✅ Concluído]`
*   **Decisão:** mcpsec descartado. Os cenários de ataque são cobertos diretamente na suíte de integração Rust.
*   **Implementado em v0.7.0:** `tests/attack_scenarios.rs` (SSRF, path traversal multi-camada, credential leaks, SQL injection, prototype pollution, prompt injection via Base64) e `tests/security_coverage.rs` (payload filters, detecção de injeção). Executados no CI com `cargo test`.

### 2.4. Motor de Injeção Dinâmico (External Rulesets) `[Fase 4]`
*   **O que envolve:** Desacoplar as regras de injeção do binário. O gateway passará a consumir um arquivo `rules.json` ou uma URL externa com padrões atualizados (estilo assinaturas de antivírus).
*   **Diferencial:** Permite atualização de segurança "over-the-air" sem downtime, usando `ArcSwap` para hot-reload.
*   **Integração:** Possibilidade de consultar APIs especialistas (ex: Lakera, PromptArmor) para ferramentas de alto risco.

### 2.5. Sistema de Plugins WASM (The Moat) `[Fase 5]`
*   **O que envolve:** Implementação de um runtime WebAssembly (Extism/Wasmtime) para permitir que usuários escrevam filtros de segurança customizados em qualquer linguagem (Go, Rust, TS, Python). (Scope Consideration: Ensure implementation focuses on validating agent code/plugins, not hosting agent execution)
*   **Impacto:** Cria uma sandbox segura para lógica de compliance complexa (ex: "Só permita acesso ao DB se o AgentID vier do time de RH") sem expor o core do gateway.
*   **Pré-requisito:** Só faz sentido depois que o core de segurança (Fases 1-3) estiver sólido e houver demanda real de usuários por extensibilidade customizada. Um runtime WASM adiciona complexidade de manutenção significativa.

### 2.6. Integração com OPA (Open Policy Agent) via WASM `[Fase 4]`
*   **O que envolve:** Implementação do motor de decisão OPA para permitir "Policy as Code" usando a linguagem Rego.
*   **Diferencial:** Permite que o time de segurança defina regras contextuais dinâmicas (ex: restrição por horário, IP, geolocalização ou argumentos específicos de ferramentas) de forma padronizada e auditável.
*   **Performance:** As políticas são executadas em memória via WASM, mantendo o benchmark de latência sub-milissegundo do motor Rust.

### 2.7. Governança Full-Spec MCP (Resources & Prompts) `[Fase 5]`
*   **O que envolve:** Expansão das políticas de segurança para cobrir todos os aspectos do protocolo MCP, não apenas ferramentas (`Tools`).
*   **Impacto:** Controle granular de acesso a `Resources` (dados estáticos) e `Prompts` (templates), garantindo que o agente só veja o contexto estritamente necessário para sua função.

### 2.9. Zero-Trust Agent Identity (SPIFFE/mTLS) `[Fase 4]`
*   **O que envolve:** Implementação de identidades criptográficas para cada Agente de IA usando o padrão SPIFFE (Secure Production Identity Framework for Everyone) ou Mutual TLS (mTLS).
*   **Diferencial:** Elimina a dependência de API Keys estáticas. Cada chamada de ferramenta é validada através de certificados de curta duração, garantindo que apenas agentes autenticados e com identidade comprovada possam acessar a malha de ferramentas.
*   **Segurança:** Protege contra "Agent Spoofing" (un agente malicioso se passando por outro) e vazamento de credenciais em logs ou código.

### 2.10. Honey-Tools (Ferramentas de Intrusão e Decepção) `[Fase 5]`
*   **O que envolve:** Criação de ferramentas "isca" no catálogo do gateway (ex: `get_internal_backdoor`, `list_admin_passwords`) que não possuem implementação real.
*   **Impacto:** Qualquer tentativa de chamada a essas ferramentas dispara um alerta crítico de segurança (IDS), indicando que o agente sofreu um ataque de injeção de prompt ou está tentando ultrapassar seus limites de autoridade de forma maliciosa.

### 2.11. Immutable Audit Proofs (Integridade Criptográfica de Logs) `[Fase 4]`
*   **O que envolve:** Implementação de assinaturas digitais (Merkle Trees) para cada entrada no log de auditoria SQLite.
*   **Diferencial:** Garante a "Não-Violação" dos registros. Um auditor pode provar matematicamente que nenhum humano ou processo alterou os logs de execução da IA após o fato.
*   **Valor:** Essencial para conformidade em setores ultra-regulados (Bancos, Defesa, Saúde).

### 2.12. Sigstore/Cosign (Supply Chain Security) `[Fase 2]`
*   **O que envolve:** Verificação da assinatura digital do binário do servidor MCP antes do `spawn` (especialmente no transporte `stdio`).
*   **Impacto:** Protege contra ataques de substituição de binários ou servidores MCP maliciosos, garantindo que o gateway só execute ferramentas assinadas e aprovadas pelo time de infraestrutura.
*   **Complexidade:** Baixa — integra-se como um check de pré-execução no `StdioTransport`.

---

## 🛠️ 3. Roadmap de Produto e Funcionalidades

### 3.1. Tool Federation (Agregação de Servidores) `[Fase 3]`
*   **O que envolve:** Em vez de mapear um agente para um upstream, o gateway consulta todos os upstreams configurados, mescla as respostas de `tools/list` em uma única lista e gerencia colisões de nomes (ex: adicionando prefixos como `fs_read_file` e `db_read_file`).
*   **Estimativa de Código:** ~350 a 500 linhas de Rust.
*   **Mudanças Principais:** Criar um `FederatedUpstream` que implementa a trait `McpUpstream`, lógica de cache para as listas de ferramentas e um mapeamento de roteamento interno para saber qual prefixo pertence a qual servidor original.
*   **Complexidade:** Média.

### 3.2. OAuth 2.1 + PKCE `[Fase 3]`
*   **O que envolve:** Suporte para que o gateway se autentique em servidores MCP remotos usando o fluxo moderno de OAuth. Isso exige gerenciar o ciclo de vida dos tokens (access/refresh tokens) e os desafios de código (PKCE).
*   **Estimativa de Código:** ~400 a 600 linhas de Rust.
*   **Mudanças Principais:** Integração com crates como `oauth2`, armazenamento seguro de tokens (em memória ou criptografado em disco) e um novo tipo de `ClientAuth` na configuração.
*   **Complexidade:** Alta (exige lidar com estados assíncronos e renovação de tokens).

### 3.3. Ecossistema de Conectores (Universal Upstream) `[Fase 5]`
*   **O que envolve:** Implementação de um "Process Manager" interno para auto-spawn de servidores MCP locais (`stdio`).
*   **Funcionalidade:** O gateway gerencia o ciclo de vida de binários externos (ex: `npx @modelcontextprotocol/server-postgres`), simplificando a orquestração de múltiplas ferramentas de diferentes linguagens (Node, Python, Go).

### 3.4. UI/Dashboard de Observabilidade Real-Time `[Fase 3]`
*   **O que envolve:** Evolução do dashboard atual para uma interface moderna (HTMX ou React) com foco em monitoramento de fluxo corporativo.
*   **Funcionalidades:** Live Tail de tool calls, "Kill Switch" instantâneo para ferramentas comprometidas, editor visual de políticas de acesso e métricas de latência detalhadas por upstream.

### 3.5. Observabilidade de Custos (Token Counting & Chargeback) `[Fase 3]`
*   **O que envolve:** Contagem de tokens (via `tiktoken`) e rastreamento de uso financeiro por Agente, IP e Ferramenta.
*   **Valor Corporativo:** Permite auditoria de custos e cobrança interna (Chargeback), identificando ferramentas ou agentes que geram gastos excessivos de infraestrutura ou API.

### 3.6. Circuit Breaker Avançado (Resiliência de Upstreams) `[Fase 5]`
*   **O que envolve:** Proteção da estabilidade geral da malha de ferramentas. Se um servidor MCP falhar ou ficar lento, o Shield "abre o circuito" para evitar falhas em cascata e latência desnecessária no agente.
*   **Métrica:** Fallback inteligente e proteção de recursos de hardware.

### 3.7. Human-in-the-Loop (HITL) — Aprovação em Tempo Real `[Fase 2]`
*   **O que envolve:** Interface via WebSocket ou integração com mensageiros (Slack/Teams) para interrupção de chamadas críticas.
*   **Fluxo:** Ferramentas marcadas como `high-risk` no gateway (ex: `delete_user`, `transfer_funds`) pausarão a execução e aguardarão um "OK" de um operador humano através de uma notificação push antes de seguir para o upstream.
*   **Valor:** O diferenciador mais único de produto — nenhum outro gateway MCP oferece isso. Garante que a IA nunca tomará ações irreversíveis sem supervisão humana explícita.

### 3.8. Agent Explainability (Smart Error Feedback) `[Fase 5]`
*   **O que envolve:** Respostas de erro semanticamente ricas para a IA quando uma chamada é bloqueada por política (ex: OPA).
*   **Impacto:** Evita que o agente entre em loops infinitos de retentativas inúteis, economizando tokens e ensinando a IA o limite das permissões (ex: "Bloqueado pela regra 'No-Deletes-Weekend'. Tente novamente em horário comercial.").

### 3.9. Tool Versioning & Adaptation (Compatibility Bridge) `[Fase 5]`
*   **O que envolve:** O gateway atua como um adaptador de esquema para ferramentas que sofreram mudanças no upstream (breaking changes).
*   **Funcionalidade:** Mapeia parâmetros antigos para novos (ex: de `user_id` para `id`), garantindo que agentes com instruções de sistema legadas continuem funcionando sem necessidade de re-treinamento ou atualização de prompts.

### 3.10. Shadow Mode (O "Dry-Run" de Ferramentas) `[Fase 2]`
*   **O que envolve:** Modo de execução simulada para ferramentas de alto risco em ambiente de produção.
*   **Fluxo:** O gateway intercepta a chamada, loga a intenção e os argumentos, mas não a envia para o servidor real. Pode retornar um "Mock" de sucesso para testar os passos seguintes do agente.
*   **Valor:** Alta relação valor/esforço — o audit log já existe, o shadow mode é basicamente um "dry-run flag" no middleware. Permite testar novas políticas de segurança sem impacto em dados reais.

### 3.11. Time-Travel Debugging & Replay (O "VCR" da IA) `[Fase 2]`
*   **O que envolve:** Gravação completa do estado exato dos argumentos e respostas das ferramentas em uma sessão específica.
*   **Funcionalidade:** Permite que desenvolvedores "repleiem" uma falha de agente em um sandbox idêntico ao original, facilitando a reprodução e correção de erros em fluxos multi-passos complexos.
*   **Valor:** Alta relação valor/esforço — o audit log já captura tudo, o replay é uma query + replay engine sobre os dados existentes.

### 3.12. Inter-Agent Resource Locking (O "Semáforo" da IA) `[Fase 5]`
*   **O que envolve:** Sistema de travamento distribuído (Distributed Locking) para evitar condições de corrida (Race Conditions) entre múltiplos agentes.
*   **Impacto:** Se um agente está editando um arquivo ou recurso via MCP, o gateway bloqueia o acesso de outros agentes ao mesmo recurso até a conclusão da tarefa, garantindo a integridade dos dados.
*   **Atenção:** Locking distribuído pressupõe múltiplas instâncias do gateway com estado compartilhado — salto de complexidade que requer infraestrutura adicional (Redis, etcd). Só faz sentido após adoção enterprise real.

### 3.13. CloudEvents Integration (Enterprise Webhooks) `[Fase 2]`
*   **O que envolve:** Padronização das notificações de auditoria enviadas via Webhook para o formato CloudEvents (CNCF).
*   **Valor:** Baixo esforço para um alto valor de integração corporativa. Facilita a ingestão de logs por SIEMs (Splunk, Elastic, Datadog), integrando o Shield ao ecossistema de observabilidade existente.

### 3.14. OpenAI Tools Bridge (Market Compatibility) `[Fase 3]`
*   **O que envolve:** Adaptador que converte funções/ferramentas no formato OpenAI para o protocolo MCP.
*   **Impacto:** Jogada estratégica de mercado. Permite que aplicações legadas construídas para OpenAI utilizem a infraestrutura de segurança do Arbiter sem refatoração profunda.

### 3.15. OpenLineage (Data Lineage for AI) `[Fase 3]`
*   **O que envolve:** Captura da linhagem de dados ("Data Lineage") dentro do log de auditoria.
*   **Diferencial:** Rastreia o caminho da informação (ex: "IA gerou resposta X baseada na ferramenta Y que consultou o Banco Z"). Essencial para conformidade com LGPD/GDPR e transparência de auditoria.
