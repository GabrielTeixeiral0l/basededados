-- =============================================================================
-- SCRIPT MESTRE DE TESTES (Versão Final Consolidada)
-- Executa toda a suite de testes do projeto BD2
-- =============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED;
SET FEEDBACK OFF;
SET VERIFY OFF;

PROMPT ========================================================================
PROMPT INICIANDO SUITE DE TESTES DO PROJETO BD2 (INTEGRIDADE TOTAL)
PROMPT ========================================================================

PROMPT [01/25] Executando Testes Unitários Integrados...
@@executar_testes.sql

PROMPT [02/25] Executando Validação e Formatação de Dados...
@@testes_validacao_dados.sql

PROMPT [03/25] Executando Testes de Integridade da Tabela SALA...
@@testes_tabela_sala.sql

PROMPT [04/25] Executando Testes de Integridade da Tabela TURMA...
@@testes_tabela_turma.sql

PROMPT [05/25] Executando Testes de Integridade da Tabela AULA...
@@testes_tabela_aula.sql

PROMPT [06/25] Executando Testes de Integridade da Tabela AVALIACAO...
@@testes_tabela_avaliacao.sql

PROMPT [07/25] Executando Testes de Integridade da Tabela CURSO...
@@testes_tabela_curso.sql

PROMPT [08/25] Executando Testes de Integridade da Tabela DOCENTE...
@@testes_tabela_docente.sql

PROMPT [09/25] Executando Testes de Integridade da Tabela ESTUDANTE...
@@testes_tabela_estudante.sql

PROMPT [10/25] Executando Testes de Integridade da Tabela ENTREGA...
@@testes_tabela_entrega.sql

PROMPT [11/25] Executando Testes de Integridade da Tabela ESTUDANTE_ENTREGA...
@@testes_tabela_estudante_entrega.sql

PROMPT [12/25] Executando Testes Funcionais Extra (Multas, Logs)...
@@testes_funcionais_extra.sql

PROMPT [13/25] Executando Lógica de Negócio (Médias e Pagamentos)...
@@testes_logica_negocio.sql

PROMPT [14/25] Executando Testes Avançados (NIF, Conflitos)...
@@testes_avancados.sql

PROMPT [15/25] Executando Testes de Limites de ECTS...
@@testes_limites.sql

PROMPT [16/25] Executando Testes de Regras de Avaliação (Hierarquia e Entregas)...
@@testes_regras_avaliacao.sql

PROMPT [17/25] Executando Regras de Max_Alunos e Grupos...
@@teste_max_alunos.sql

PROMPT [18/25] Executando Teste de Segurança de Logs (Imutabilidade)...
@@teste_seguranca_log.sql

PROMPT [19/25] Validando Vistas e Relatórios...
@@testar_vistas.sql

PROMPT [20/25] Executando Testes de Integridade da Tabela FICHEIRO_ENTREGA...
@@testes_tabela_ficheiro_entrega.sql

PROMPT [21/25] Executando Testes de Integridade da Tabela FICHEIRO_RECURSO...
@@testes_tabela_ficheiro_recurso.sql

PROMPT [22/25] Executando Testes de Regras Académicas de INSCRICAO...
@@testes_tabela_inscricao.sql

PROMPT [23/25] Executando Testes de Regras da Tabela MATRICULA...
@@testes_tabela_matricula.sql

PROMPT [24/25] Executando Testes de Validação de NOTA (Status, Turma)...
@@teste_validacao_nota.sql

PROMPT [25/25] Executando Teste Integrado (Notas -> Media Geral)...
@@teste_integrado_notas_media.sql

PROMPT [FINAL] Gerando Dados de Demonstração Permanentes...
@@demo_data.sql

PROMPT ========================================================================
PROMPT TODOS OS TESTES FORAM EXECUTADOS COM SUCESSO.
PROMPT ========================================================================
COMMIT;
