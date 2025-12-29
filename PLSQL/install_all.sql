-- =============================================================================
-- SCRIPT DE INSTALAÇÃO MESTRE (ORDEM DE DEPENDÊNCIA)
-- =============================================================================
PROMPT === INICIANDO INSTALAÇÃO DOS COMPONENTES PL/SQL ===

-- 1. Configurações e Sequências
PROMPT [1/10] Compilando Sequências...
@@1_auto_increment.sql
SHOW ERRORS;

-- 2. Configuração de Logs
PROMPT [2/10] Compilando Configuração de Logs...
@@0_pkg_config_audit.sql
SHOW ERRORS;

-- 3. Gestão de Dados (Base para logs)
PROMPT [3/10] Compilando Pacote de Gestão de Dados...
@@4_pkg_gestao_dados.sql
SHOW ERRORS;

-- 4. Constantes
PROMPT [4/10] Compilando Constantes...
@@10_pkg_constantes.sql
SHOW ERRORS;

-- 5. Validações
PROMPT [5/10] Compilando Validações...
@@12_pkg_validacao.sql
SHOW ERRORS;

PROMPT [5b/10] Compilando Buffer Matricula...
@@13_pkg_buffer_matricula.sql
SHOW ERRORS;

PROMPT [6/10] Compilando Triggers de Auditoria...
@@2_audit_and_maintenance.sql
SHOW ERRORS;

-- 7. Vistas e Funções
PROMPT [7/10] Compilando Vistas e Funções...
@@7_views_functions.sql
SHOW ERRORS;

-- 8. Buffers (Apoio a Triggers complexos)
PROMPT [8/10] Compilando Buffers...
@@11_pkg_buffer_nota.sql
SHOW ERRORS;

-- 9. Pacotes Funcionais (Secretaria e Tesouraria)
PROMPT [9/10] Compilando Pacotes Funcionais...
@@6_functional_packages.sql
SHOW ERRORS;

-- 10. Triggers de Integridade (Dependem de tudo acima)
PROMPT [10/10] Compilando Triggers de Integridade...
@@5_integrity_triggers.sql
SHOW ERRORS;

-- 11. Formatação de Dados
PROMPT [11/11] Compilando Triggers de Formatação...
@@9_data_formatting.sql
SHOW ERRORS;

PROMPT === INSTALAÇÃO CONCLUÍDA ===
