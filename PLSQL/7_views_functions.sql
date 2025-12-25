-- =============================================================================
-- 7. VISTAS E FUNÇÕES AUXILIARES (DASHBOARDS E RELATÓRIOS)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Função para verificar se um aluno tem dívidas
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FUN_IS_DEVEDOR(p_estudante_id IN NUMBER) RETURN CHAR IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM parcela_propina p JOIN matricula m ON p.matricula_id = m.id
    WHERE m.estudante_id = p_estudante_id AND p.estado != 'P' AND p.data_vencimento < SYSDATE AND m.status = '1' AND p.status = '1';
    IF v_count > 0 THEN RETURN 'S'; ELSE RETURN 'N'; END IF;
EXCEPTION WHEN OTHERS THEN RETURN 'N'; END FUN_IS_DEVEDOR;
/

-- -----------------------------------------------------------------------------
-- Vista 1: Pauta de Notas Detalhada
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_PAUTA_TURMA AS
SELECT 
    t.nome AS turma,
    uc.nome AS unidade_curricular,
    e.nome AS estudante,
    e.id AS numero_estudante,
    av.titulo AS avaliacao,
    n.nota
FROM nota n
JOIN inscricao i ON n.inscricao_id = i.id
JOIN estudante e ON i.matricula_id = e.id
JOIN avaliacao av ON n.avaliacao_id = av.id
JOIN turma t ON i.turma_id = t.id
JOIN unidade_curricular uc ON t.unidade_curricular_id = uc.id
WHERE n.status = '1'
ORDER BY t.nome, e.nome;
/

-- -----------------------------------------------------------------------------
-- Vista 2: Dashboard Financeiro por Curso
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_DASHBOARD_FINANCEIRO AS
SELECT 
    c.nome AS curso,
    COUNT(DISTINCT m.id) AS total_alunos,
    SUM(pp.valor) AS valor_total_propinas,
    SUM(CASE WHEN pp.estado = 'P' THEN pp.valor ELSE 0 END) AS valor_pago,
    SUM(CASE WHEN pp.estado != 'P' AND pp.data_vencimento < SYSDATE THEN pp.valor ELSE 0 END) AS valor_em_divida
FROM curso c
JOIN matricula m ON m.curso_id = c.id
JOIN parcela_propina pp ON pp.matricula_id = m.id
WHERE m.status = '1' AND pp.status = '1'
GROUP BY c.nome
ORDER BY valor_em_divida DESC;
/

-- -----------------------------------------------------------------------------
-- Vista 3: Mapa de Ocupação de Salas
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_OCUPACAO_SALAS AS
SELECT 
    s.nome AS sala,
    s.capacidade,
    TO_CHAR(a.data, 'YYYY-MM-DD') AS dia,
    TO_CHAR(a.hora_inicio, 'HH24:MI') AS inicio,
    TO_CHAR(a.hora_fim, 'HH24:MI') AS fim,
    uc.nome AS disciplina,
    t.nome AS turma,
    (SELECT COUNT(*) FROM inscricao i WHERE i.turma_id = t.id AND i.status = '1') AS inscritos
FROM aula a
JOIN sala s ON a.sala_id = s.id
JOIN turma t ON a.turma_id = t.id
JOIN unidade_curricular uc ON t.unidade_curricular_id = uc.id
WHERE a.status = '1'
ORDER BY s.nome, a.data, a.hora_inicio;
/

-- -----------------------------------------------------------------------------
-- Vista 4: Alerta de Reprovação por Faltas
-- Filtra apenas UCs onde a presença é obrigatória e o aluno está abaixo do limite.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_ALERTA_ASSIDUIDADE AS
WITH assiduidade_calc AS (
    SELECT 
        i.id AS inscricao_id,
        i.matricula_id,
        t.unidade_curricular_id,
        COUNT(p.aula_id) AS total_aulas_registadas,
        SUM(CASE WHEN p.presente = '1' THEN 1 ELSE 0 END) AS total_presencas
    FROM inscricao i
    JOIN turma t ON i.turma_id = t.id
    LEFT JOIN presenca p ON i.id = p.inscricao_id
    WHERE i.status = '1'
    GROUP BY i.id, i.matricula_id, t.unidade_curricular_id
)
SELECT 
    e.nome AS estudante,
    uc.nome AS disciplina,
    ucc.percentagem_presenca AS limite_minimo,
    ROUND((ac.total_presencas / NULLIF(ac.total_aulas_registadas, 0)) * 100, 2) AS percentagem_atual,
    ac.total_aulas_registadas - ac.total_presencas AS faltas_acumuladas
FROM assiduidade_calc ac
JOIN matricula m ON ac.matricula_id = m.id
JOIN estudante e ON m.estudante_id = e.id
JOIN unidade_curricular uc ON ac.unidade_curricular_id = uc.id
JOIN uc_curso ucc ON (uc.id = ucc.unidade_curricular_id AND m.curso_id = ucc.curso_id)
WHERE ucc.presenca_obrigatoria = '1' -- Só UCs onde a presença conta para nota
  AND (ac.total_presencas / NULLIF(ac.total_aulas_registadas, 0)) * 100 < ucc.percentagem_presenca;
/
