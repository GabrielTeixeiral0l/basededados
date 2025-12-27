-- =============================================================================
-- 7. VISTAS E FUNÇÕES AUXILIARES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 7.1. FUNÇÃO: VERIFICAR SE ALUNO É DEVEDOR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FUN_IS_DEVEDOR(p_estudante_id IN NUMBER) 
RETURN CHAR 
IS
    v_atrasos NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_atrasos 
    FROM parcela_propina p
    JOIN matricula m ON p.matricula_id = m.id
    WHERE m.estudante_id = p_estudante_id
      AND p.data_vencimento < SYSDATE
      AND p.estado != '1'
      AND p.status = '1';

    IF v_atrasos > 0 THEN RETURN '1'; END IF;
    RETURN '0';
EXCEPTION WHEN OTHERS THEN RETURN '0';
END;
/


-- =============================================================================
-- 7. VISTAS E RELATÓRIOS DO SISTEMA UNIVERSITÁRIO
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 7.1. [EXISTENTE] PAUTA POR TURMA
-- Mostra notas finais e o estado de aprovação usando a constante do pacote.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_PAUTA_TURMA AS
SELECT 
    t.nome as TURMA,
    uc.nome as UNIDADE_CURRICULAR,
    e.codigo as CODIGO_ALUNO,
    e.nome as NOME_ESTUDANTE,
    i.nota_final as NOTA_FINAL,
    CASE 
        WHEN i.nota_final >= PKG_CONSTANTES.NOTA_APROVACAO THEN 'APROVADO'
        ELSE 'REPROVADO'
    END as RESULTADO
FROM inscricao i
JOIN turma t ON i.turma_id = t.id
JOIN unidade_curricular uc ON t.unidade_curricular_id = uc.id
JOIN matricula m ON i.matricula_id = m.id
JOIN estudante e ON m.estudante_id = e.id
WHERE i.status = '1';
/

-- -----------------------------------------------------------------------------
-- 7.2. [EXISTENTE] ALERTAS DE ASSIDUIDADE (> 25% de faltas)
-- Identifica alunos em risco de reprovação por faltas.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_ALERTA_ASSIDUIDADE AS
SELECT 
    e.nome as NOME_ESTUDANTE,
    t.nome as NOME_TURMA,
    COUNT(CASE WHEN p.presente = '0' THEN 1 END) as TOTAL_FALTAS,
    COUNT(*) as TOTAL_AULAS,
    ROUND((COUNT(CASE WHEN p.presente = '0' THEN 1 END) / COUNT(*)) * 100, 2) as PERC_FALTAS
FROM presenca p
JOIN inscricao i ON p.inscricao_id = i.id
JOIN matricula m ON i.matricula_id = m.id
JOIN estudante e ON m.estudante_id = e.id
JOIN turma t ON i.turma_id = t.id
WHERE i.status = '1' AND p.status = '1'
GROUP BY e.nome, t.nome
HAVING (COUNT(CASE WHEN p.presente = '0' THEN 1 END) / COUNT(*)) > 0.25;
/

-- -----------------------------------------------------------------------------
-- 7.3. PERFIL ACADÉMICO DO ALUNO (CURRÍCULO)
-- Resumo de ECTS conquistados e média global do curso.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_PERFIL_ACADEMICO_ALUNO AS
SELECT 
    e.codigo AS num_mecanografico,
    e.nome AS nome_estudante,
    c.nome AS nome_curso,
    COUNT(i.id) AS total_ucs_inscritas,
    SUM(CASE WHEN i.nota_final >= 9.5 THEN uc.ects ELSE 0 END) AS ects_concluidos,
    ROUND(AVG(i.nota_final), 2) AS media_global
FROM estudante e
JOIN matricula m ON e.id = m.estudante_id
JOIN curso c ON m.curso_id = c.id
LEFT JOIN inscricao i ON m.id = i.matricula_id
LEFT JOIN turma t ON i.turma_id = t.id
LEFT JOIN unidade_curricular uc ON t.unidade_curricular_id = uc.id
WHERE m.status = '1'
GROUP BY e.codigo, e.nome, c.nome;
/

-- -----------------------------------------------------------------------------
-- 7.4. OCUPAÇÃO DE SALAS (HOJE)
-- Útil para ecrãs de informação nos corredores da universidade.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_OCUPACAO_SALAS_HOJE AS
SELECT 
    s.nome AS sala,
    TO_CHAR(a.hora_inicio, 'HH24:MI') AS inicio,
    TO_CHAR(a.hora_fim, 'HH24:MI') AS fim,
    uc.nome AS unidade_curricular,
    d.nome AS docente,
    t.nome AS turma
FROM sala s
JOIN aula a ON s.id = a.sala_id
JOIN turma t ON a.turma_id = t.id
JOIN unidade_curricular uc ON t.unidade_curricular_id = uc.id
JOIN docente d ON t.docente_id = d.id
WHERE TRUNC(a.data) = TRUNC(SYSDATE)
  AND a.status = '1';
/

-- -----------------------------------------------------------------------------
-- 7.5. CARGA HORÁRIA DOS DOCENTES
-- Relatório para gestão de RH sobre o tempo em sala de cada professor.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_CARGA_HORARIA_DOCENTE AS
SELECT 
    d.nome AS nome_docente,
    COUNT(DISTINCT t.id) AS total_turmas,
    SUM(ROUND((a.hora_fim - a.hora_inicio) * 24, 2)) AS total_horas_semanais
FROM docente d
JOIN turma t ON d.id = t.docente_id
JOIN aula a ON t.id = a.turma_id
WHERE d.status = '1'
GROUP BY d.nome;
/

-- -----------------------------------------------------------------------------
-- 7.6. RELATÓRIO DE DÍVIDAS (TESOURARIA)
-- Lista alunos com pagamentos em atraso e o valor total em falta.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_RELATORIO_DIVIDAS AS
SELECT 
    e.nome AS estudante,
    e.telemovel,
    c.nome AS curso,
    COUNT(p.id) AS parcelas_em_atraso,
    SUM(p.valor) AS valor_total_divida
FROM parcela_propina p
JOIN matricula m ON p.matricula_id = m.id
JOIN estudante e ON m.estudante_id = e.id
JOIN curso c ON m.curso_id = c.id
WHERE p.estado = '0' -- Não Pago
  AND p.data_vencimento < SYSDATE
  AND p.status = '1'
GROUP BY e.nome, e.telemovel, c.nome;
/

-- -----------------------------------------------------------------------------
-- 7.7. RECEITA PREVISTA VS REALIZADA POR CURSO
-- Análise financeira de desempenho por curso.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_FINANCEIRO_CURSOS AS
SELECT 
    c.nome AS curso,
    SUM(CASE WHEN p.estado = '1' THEN p.valor ELSE 0 END) AS total_recebido,
    SUM(CASE WHEN p.estado = '0' THEN p.valor ELSE 0 END) AS total_pendente
FROM curso c
JOIN matricula m ON c.id = m.curso_id
JOIN parcela_propina p ON m.id = p.matricula_id
WHERE p.status = '1'
GROUP BY c.nome;
/

-- -----------------------------------------------------------------------------
-- 7.8. CALENDÁRIO DE AVALIAÇÕES (PRÓXIMOS 30 DIAS)
-- Para consulta dos alunos e planeamento de salas.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_EXAMES_PROXIMOS AS
SELECT 
    av.data AS data_exame,
    uc.nome AS unidade_curricular,
    av.titulo AS avaliacao,
    ta.nome AS tipo,
    t.nome AS turma
FROM avaliacao av
JOIN turma t ON av.turma_id = t.id
JOIN unidade_curricular uc ON t.unidade_curricular_id = uc.id
JOIN tipo_avaliacao ta ON av.tipo_avaliacao_id = ta.id
WHERE av.data BETWEEN SYSDATE AND SYSDATE + 30
  AND av.status = '1'
ORDER BY av.data ASC;
/

-- -----------------------------------------------------------------------------
-- 7.9. MONITORIZAÇÃO DE ENTREGAS DE GRUPO
-- Cruza quem entregou trabalhos e o tamanho dos ficheiros.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_MONITOR_ENTREGAS AS
SELECT 
    av.titulo AS avaliacao,
    en.id AS entrega_id,
    e.nome AS aluno,
    fe.nome AS ficheiro,
    ROUND(fe.tamanho / 1024, 2) AS tamanho_mb,
    en.data_entrega AS data_submissao
FROM entrega en
JOIN avaliacao av ON en.avaliacao_id = av.id
JOIN estudante_entrega ee ON en.id = ee.entrega_id
JOIN inscricao i ON ee.inscricao_id = i.id
JOIN matricula m ON i.matricula_id = m.id
JOIN estudante e ON m.estudante_id = e.id
LEFT JOIN ficheiro_entrega fe ON en.id = fe.entrega_id
WHERE en.status = '1';
/

-- -----------------------------------------------------------------------------
-- 7.10. ESTATÍSTICA DE OCUPAÇÃO DE CURSOS
-- Verifica a taxa de preenchimento de vagas por curso.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_ESTATISTICA_VAGAS AS
SELECT 
    c.nome AS curso,
    c.max_alunos AS vagas_totais,
    COUNT(m.id) AS alunos_matriculados,
    c.max_alunos - COUNT(m.id) AS vagas_livres,
    ROUND((COUNT(m.id) / NVL(c.max_alunos, 1)) * 100, 2) AS taxa_preenchimento
FROM curso c
LEFT JOIN matricula m ON c.id = m.curso_id AND m.status = '1'
WHERE c.status = '1'
GROUP BY c.nome, c.max_alunos;
/