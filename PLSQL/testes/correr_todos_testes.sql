SET SERVEROUTPUT ON;
SET VERIFY OFF;

PROMPT ========================================================================
PROMPT INICIANDO SUITE DE TESTES DO PROJETO BD2
PROMPT ========================================================================

-- 1. Testes Unitários Básicos
PROMPT [1/8] Executando Testes Unitários...
@@executar_testes.sql

-- 2. Testes de Lógica de Negócio
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [2/8] Executando Lógica de Negócio...
@@testes_logica_negocio.sql

-- 3. Testes Avançados
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [3/8] Executando Testes Avançados...
@@testes_avancados.sql

-- 4. Testes de Limites
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [4/8] Executando Testes de Limites...
@@testes_limites.sql

-- 5. Testes de Regras de Avaliação
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [5/8] Executando Regras de Avaliação...
@@testes_regras_avaliacao.sql

-- 6. Teste de Segurança de Logs
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [6/8] Executando Teste de Segurança de Logs...
@@teste_seguranca_log.sql

-- 7. Teste de Vistas
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [7/8] Validando Vistas e Relatórios...
@@testar_vistas.sql

-- 8. Gerar Dados de Demonstração
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [8/8] Gerando Dados de Demonstração Finais...
@@demo_data.sql

PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT ========================================================================
PROMPT TODOS OS TESTES FORAM EXECUTADOS.
PROMPT OS DADOS FORAM PERSISTIDOS (COMMIT).
PROMPT ========================================================================

COMMIT;
EXIT;
