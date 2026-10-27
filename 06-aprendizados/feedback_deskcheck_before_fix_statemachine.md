---
name: feedback_deskcheck_before_fix_statemachine
description: "Antes de aplicar fix num catch de exceção genérica, ler a StateMachine completa (Main.xaml) e fazer table-top trace linha a linha antes de editar"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: df605594-f9f4-4ece-a476-4b31adabf360
  modified: 2026-09-01T11:34:20.957Z
---

Antes de corrigir um bug de "exceção X não trata Y corretamente", ler primeiro TODA a StateMachine/fluxo de controle relevante (ex: `Main.xaml` do REFramework) e fazer um teste de mesa (table-top trace) linha a linha do cenário real de log ANTES de editar qualquer catch/exception handler.

**Por quê:** no BT-75274 (ver [[project_bcbs_tx_newhireenrollment_stale_login_after_error]]), a primeira tentativa de fix (fechar o Chrome no catch genérico de `Process.xaml`) parecia óbvia e coerente com o histórico do bug — mas era 100% redundante: o `Main.xaml` JÁ tinha esse fechamento coberto numa transição do StateMachine (`Transition_4`), e a lacuna real estava numa transição DIFERENTE e menos óbvia (`Transition_9`, o self-loop de retry do Initialization após falha de LOGIN, não de transação). Só apareceu ao ler o arquivo inteiro e simular a execução real contra os logs de produção, atividade por atividade.

**Como aplicar:** quando o usuário pedir "faz um teste de mesa" ou questionar se o fix cobre o cenário, não confirmar de cabeça — reler o(s) arquivo(s) de orquestração de estado inteiros, mapear TODAS as transições/catches que podem levar ao mesmo destino (não só o caminho óbvio), e comparar contra o timeline exato dos logs reais antes de responder. Vale tanto pra REFramework (StateMachine) quanto pra qualquer fluxo com múltiplos catches/transições levando ao mesmo lugar.
