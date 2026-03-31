# Arbiter: Estratégia e Posicionamento

## Missão

Ser a camada de segurança e governança entre agentes de IA e servidores MCP — aplicando políticas, autenticando identidades, auditando chamadas de ferramentas e protegendo contra injeção e ataques à cadeia de suprimentos.

O Arbiter é um **proxy**. Ele não processa modelos, não interpreta intenções e não toma decisões semânticas. Aplica regras determinísticas na fronteira do protocolo.

---

## Mapa de Guerra: Posicionamento de Mercado

| Categoria | Competidores | Lacuna | O Diferencial do Arbiter |
| :--- | :--- | :--- | :--- |
| **LLM Gateways** | LiteLLM, Portkey | Focam no custo do modelo. Ignoram segurança da ferramenta. | **Control Plane de Execução:** foco total na semântica do protocolo MCP. |
| **AI Firewalls** | Lakera, Pangea | APIs externas com latência. Filtram apenas a entrada (Prompt). | **Nativo/In-flight (Rust).** Filtro de entrada E saída com latência <1ms, sem chamadas externas. |
| **Agentes Ops** | LangSmith, Helicone | Observabilidade passiva — registram o erro, não o impedem. | **Segurança Ativa:** bloqueio em tempo real, Shadow Mode e HITL. |
| **MCP Proxies** | mcp-proxy, aggregator | Apenas conectividade técnica. Sem governança ou conformidade. | **Enterprise-Ready:** OPA, HITL e auditoria imutável (Merkle Trees). |

---

## Lições do Incidente LiteLLM (Março/2026)

O ataque revelou falhas sistêmicas em gateways baseados em linguagens dinâmicas (Python/JS). O Arbiter foi projetado para ser imune a esses vetores:

1. **Supply Chain Immunity:** Binário estático em Rust, verificável via Sigstore/Cosign. Sem herança de dependências frágeis do PyPI/NPM.
2. **Sandbox Isolation:** Servidores MCP executados via `stdio` são isolados em sandboxes de sistema (Bubblewrap/gVisor), impedindo acesso a segredos do host.
3. **Zero-Trust Identity:** Substitui API Keys estáticas por identidades criptográficas (SPIFFE/mTLS), eliminando credenciais expostas em logs ou código.

---

## Pilares do Produto

1. **Performance (Rust/tokio):** Latência sub-milissegundo. A camada de segurança é transparente para o agente.
2. **Human-in-the-Loop (HITL):** Interrupção e aprovação manual de ações críticas via WebSocket/Slack antes que cheguem ao upstream.
3. **Inverse Firewall:** Filtragem de dados *retornados* pelas ferramentas — bloqueia injeção indireta (Indirect Prompt Injection) e vazamento de segredos em respostas.
4. **Shadow Mode:** Dry-run de ferramentas de alto risco em produção — loga intenção e argumentos sem executar a chamada real.
5. **Policy as Code (OPA/Rego):** Governança padronizada, auditável e portátil do ambiente local ao cluster Kubernetes.

---

## Fases de Execução

| Fase | Foco | Itens |
| :--- | :--- | :--- |
| **Fase 1 — Foundation** ✅ | Corrigir gaps críticos de segurança | Schema Validation (2.1) ✅, Scan Avançado/Encoding-aware (2.2) ✅, Suite de testes de segurança interna (2.3) ✅ |
| **Fase 2 — Differentiators** | Features únicas de produto e supply chain | HITL (3.7), Shadow Mode (3.10), Time-Travel Replay (3.11), Sigstore (2.13), CloudEvents (3.13) |
| **Fase 3 — Produto** | Interoperabilidade e expansão de mercado | Tool Federation (3.1), OAuth 2.1+PKCE (3.2), Dashboard (3.4), Cost Observability (3.5), OpenAI Bridge (3.14), OpenLineage (3.15) |
| **Fase 4 — Enterprise** | Adoção corporativa e cloud-native | OPA (2.6), SPIFFE/mTLS (2.9), Merkle Audit (2.12), K8s CRDs + Sidecar (4.x), OTLP (5.1), TEE (2.1) |
| **Fase 5 — Exploratório** | Extensibilidade sem sair do escopo do proxy | WASM Plugins para filtros customizados (2.5), MCP Full-Spec Resources/Prompts (2.8), Honey-Tools IDS (2.11) |

> **Fase 1 concluída em v0.7.0.** Próxima prioridade: Fase 2 — HITL, Shadow Mode, Sigstore e CloudEvents.

---

## Fora do Escopo

O Arbiter **não** é:

- Um orquestrador de agentes (não compõe tool calls, não roteia por semântica)
- Um processador de dados (não aplica ML, OCR ou análise semântica de conteúdo)
- Uma camada de inferência (não interpreta intenções do agente)
- Um runtime de agentes (não executa nem hospeda lógica de agente)

Qualquer feature que exija processar o *significado* dos dados — em vez de aplicar regras sobre sua *forma e estrutura* — está fora do escopo.

---

## Governança Institucional

O Arbiter resolve as três maiores dores do C-Level:

- **Segurança (CISO):** Identidade Zero-Trust, proteção contra injeção indireta e integridade de hardware (TEE).
- **Conformidade (Jurídico):** License Guardrails, JIT Access e linhagem de dados (OpenLineage) para LGPD/GDPR.
- **Custo (CFO):** Observabilidade de tokens e chargeback por agente/departamento.

---

## Cloud-Native & Padrões Abertos

O Arbiter acompanha a evolução da infraestrutura de IA sem assumir responsabilidades que são do agente ou do modelo:

- **Sigstore/Cosign:** Verificação de integridade de binários MCP antes do `spawn`.
- **SPIFFE/mTLS:** Identidade criptográfica por agente, substituindo API Keys estáticas.
- **OPA/Rego:** Policy as Code para regras contextuais auditáveis.
- **CloudEvents:** Webhooks de auditoria no formato padrão CNCF para ingestão em SIEMs.
- **OTLP (OpenTelemetry):** Métricas, traces e logs nativos para qualquer stack de observabilidade.
- **K8s Gateway API (MCPRoute):** CRD nativo para gerenciamento declarativo de tráfego MCP em Kubernetes.
- **OpenVEX (OpenSSF):** Transparência de vulnerabilidades para supply chain de servidores MCP.
- **OpenLineage:** Linhagem de dados para rastreabilidade de conformidade.

---

## Conclusão

O Arbiter é o **proxy de segurança e governança para o ecossistema MCP** — determinístico, auditável e baseado em regras. Não processa dados dos agentes; aplica políticas sobre as chamadas que os agentes fazem. Simples de entender, difícil de substituir.
