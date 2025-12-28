--- START OF FILE correr_todos_testes.sql ---

SET SERVEROUTPUT ON;
SET VERIFY OFF;

PROMPT ========================================================================
PROMPT INICIANDO SUITE DE TESTES DO PROJETO BD2 (V2 - LIMITES DE GRUPOS)
PROMPT ========================================================================

-- 1. Testes Unitários Básicos
PROMPT [1/11] Executando Testes Unitários...
@@executar_testes.sql

-- 1.1. Testes de Validação de Dados
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [2/11] Executando Validação e Formatação de Dados...
@@testes_validacao_dados.sql

-- 1.2. Testes Funcionais Extra
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [3/11] Executando Testes Funcionais Extra (Multas, Logs)...
@@testes_funcionais_extra.sql

-- 2. Testes de Lógica de Negócio
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [4/11] Executando Lógica de Negócio (Médias e Pagamentos)...
@@testes_logica_negocio.sql

-- 3. Testes Avançados
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [5/11] Executando Testes Avançados (NIF, Conflitos)...
@@testes_avancados.sql

-- 4. Testes de Limites de ECTS
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [6/11] Executando Testes de Limites de ECTS...
@@testes_limites.sql

-- 5. Testes de Regras de Avaliação (Gerais)
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [7/11] Executando Regras de Avaliação (Hierarquia e Entregas)...
@@testes_regras_avaliacao.sql

-- 6. Teste de Limites de Alunos e Grupos (NOVO)
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [8/11] Executando Regras de Max_Alunos e Grupos...
@@teste_max_alunos.sql

-- 7. Teste de Segurança de Logs
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [9/11] Executando Teste de Segurança de Logs (Imutabilidade)...
@@teste_seguranca_log.sql

-- 8. Teste de Vistas
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [10/11] Validando Vistas e Relatórios...
@@testar_vistas.sql

-- 9. Gerar Dados de Demonstração
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [11/11] Gerando Dados de Demonstração Finais (Cenário Realista)...
@@demo_data.sql


PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT ========================================================================
PROMPT TODOS OS TESTES FORAM EXECUTADOS COM SUCESSO.
PROMPT OS DADOS FORAM PERSISTIDOS (COMMIT).
PROMPT ========================================================================

COMMIT;
-- EXIT; -- Descomenta se quiseres que o SQLPlus feche sozinho no fim