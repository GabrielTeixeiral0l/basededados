-- =============================================================================
-- SCRIPT DE TESTES UNITÁRIOS E INTEGRADOS (CORRIGIDO)
-- =============================================================================
SET SERVEROUTPUT ON;
SET FEEDBACK ON;

PROMPT === INICIANDO LIMPEZA DE DADOS DE TESTE ===

-- 1. LIMPEZA NA ORDEM CORRETA (FILHOS -> PAIS)
DELETE FROM nota;
DELETE FROM presenca;
DELETE FROM estudante_entrega;
DELETE FROM ficheiro_entrega;
DELETE FROM ficheiro_recurso;
DELETE FROM entrega;
DELETE FROM recurso;
DELETE FROM aula;
DELETE FROM avaliacao;
DELETE FROM inscricao;
DELETE FROM parcela_propina;
DELETE FROM matricula;
DELETE FROM turma;
DELETE FROM uc_docente;
DELETE FROM uc_curso;
DELETE FROM docente;
DELETE FROM curso;
DELETE FROM estudante;
DELETE FROM unidade_curricular;
DELETE FROM sala;
DELETE FROM tipo_avaliacao;
DELETE FROM tipo_aula;
DELETE FROM tipo_curso;
DELETE FROM estado_matricula;
DELETE FROM log;

COMMIT;

PROMPT === INSERINDO DADOS DE CONFIGURAÇÃO (IDs EXPLICITOS) ===

-- Usamos IDs fixos nos testes para evitar dependência de triggers/sequências
INSERT INTO estado_matricula (id, nome) VALUES (1, 'Ativa');
INSERT INTO estado_matricula (id, nome) VALUES (2, 'Suspensa');

INSERT INTO tipo_curso (id, nome, valor_propinas) VALUES (1, 'Licenciatura', 1000);
INSERT INTO tipo_aula (id, nome) VALUES (1, 'Teórica');
INSERT INTO tipo_avaliacao (id, nome, descricao, requer_entrega, permite_grupo, permite_filhos) 
VALUES (1, 'Exame', 'Exame Final', '0', '0', '1');

INSERT INTO sala (id, nome, capacidade) VALUES (1, 'Sala 101', 30);

PROMPT === TESTE 1: INSERÇÃO DE ESTUDANTE ===
INSERT INTO estudante (id, nome, morada, data_nascimento, cc, nif, email, telemovel)
VALUES (1, 'JOAO SILVA', 'Rua A', TO_DATE('2000-01-01','YYYY-MM-DD'), '123456789ZZ0', '123456789', 'joao@email.com', '911111111');

PROMPT === TESTE 2: CURSOS E MATRÍCULAS ===
INSERT INTO curso (id, nome, codigo, descricao, duracao, ects, max_alunos, tipo_curso_id)
VALUES (1, 'Engenharia', 'ENG-INF', 'Eng. Informática', 3, 180, 30, 1);

INSERT INTO matricula (id, curso_id, estudante_id, estado_matricula_id, ano_inscricao, numero_parcelas)
VALUES (1, 1, 1, 1, 2025, 10);

PROMPT === TESTE 3: UNIDADE CURRICULAR E DOCENTE ===
INSERT INTO unidade_curricular (id, nome, codigo, horas_teoricas, horas_praticas)
VALUES (1, 'Base de Dados', 'BD1', 40, 20);

INSERT INTO docente (id, nome, data_contratacao, nif, cc, email, telemovel)
VALUES (1, 'Prof. Alberto', SYSDATE, '500123456', '987654321ZX0', 'alberto@docente.com', '933333333');

PROMPT === TESTE 4: TURMA E INSCRIÇÃO ===
INSERT INTO turma (id, nome, ano_letivo, unidade_curricular_id, max_alunos, docente_id)
VALUES (1, 'Turma A', '2025/26', 1, 20, 1);

INSERT INTO inscricao (id, turma_id, matricula_id, data)
VALUES (1, 1, 1, SYSDATE);

PROMPT === TESTE 5: AULAS E PRESENÇAS ===
INSERT INTO aula (id, data, hora_inicio, hora_fim, sumario, tipo_aula_id, sala_id, turma_id)
VALUES (1, SYSDATE, SYSDATE, SYSDATE+1/24, 'Aula inicial', 1, 1, 1);

-- Presença (vinculada à inscrição)
INSERT INTO presenca (inscricao_id, aula_id, presente) VALUES (1, 1, '1');

PROMPT === TESTE 6: AVALIAÇÃO E NOTA ===
INSERT INTO avaliacao (id, titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id)
VALUES (1, 'Teste 1', SYSDATE, SYSDATE, 100, 1, 1, 1);

-- Nota usa inscricao_id no esquema ddlv3.sql
INSERT INTO nota (inscricao_id, avaliacao_id, nota, comentario)
VALUES (1, 1, 18, 'Ótimo trabalho');

COMMIT;

PROMPT =========================================================================
PROMPT === RESULTADOS DA VERIFICAÇÃO ===
PROMPT =========================================================================

SET PAGESIZE 50;
SET LINESIZE 150;
COLUMN nome FORMAT A20;
COLUMN titulo FORMAT A15;
COLUMN nota FORMAT 99.99;

PROMPT [ESTUDANTE] Dados do Estudante:
SELECT nome, nif, email FROM estudante WHERE id = 1;

PROMPT [MATRICULA] Estado e Média:
SELECT m.id, c.nome as curso, em.nome as estado, m.media_geral 
FROM matricula m 
JOIN curso c ON m.curso_id = c.id 
JOIN estado_matricula em ON m.estado_matricula_id = em.id;

PROMPT [NOTAS] Notas do Aluno:
SELECT e.nome, a.titulo, n.nota 
FROM nota n
JOIN avaliacao a ON n.avaliacao_id = a.id
JOIN inscricao i ON n.inscricao_id = i.id
JOIN matricula m ON i.matricula_id = m.id
JOIN estudante e ON m.estudante_id = e.id;

PROMPT [PROPINAS] Verificação de Parcelas:
SELECT count(*) as qtd_parcelas, sum(valor) as valor_total 
FROM parcela_propina WHERE matricula_id = 1;

PROMPT [LOGS] Verificação de Erros/Alertas:
COLUMN acao FORMAT A15;
COLUMN tabela FORMAT A20;
COLUMN data FORMAT A50;
SELECT acao, tabela, data FROM log ORDER BY created_at DESC;